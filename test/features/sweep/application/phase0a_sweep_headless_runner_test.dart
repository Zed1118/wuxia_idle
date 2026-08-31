import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_automation_policy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  test('扫荡装配必须转发波间 policy，保持手动与 headless 同核', () {
    final source = File(
      'lib/features/sweep/application/phase0a_sweep_headless_runner.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('waveTransitionPolicy: mapping.waveTransitionPolicy,'),
    );
    expect(source, contains('policy: botPolicy,'));
    expect(
      source,
      isNot(
        contains(
          'Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter)',
        ),
      ),
    );
  });

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase0a_sweep_runner_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final save = await IsarSetup.instance.saveDatas.get(0);
    final firstCharacter = await IsarSetup.instance.characters
        .where()
        .findFirst();
    await IsarSetup.instance.writeTxn(() async {
      save!.founderCharacterId = firstCharacter!.id;
      save.activeCharacterIds = [firstCharacter.id];
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = save.slotId
          ..clearedStageIds = GameRepository.instance.stageDefs.values
              .where((stage) => stage.stageType == StageType.mainline)
              .map((stage) => stage.id)
              .followedBy(const ['stage_light_foot_01', 'stage_mass_battle_01'])
              .toList(growable: false)
          ..clearedAt = [],
      );
      await IsarSetup.instance.towerProgress.put(
        TowerProgress()
          ..saveDataId = save.slotId
          ..highestClearedFloor = GameRepository.instance.towerMaxFloor
          ..highestClearedAt = DateTime(2026, 8, 25)
          ..createdAt = DateTime(2026, 8, 25)
          ..currentCycleIndex = 1
          ..maxClearedCycle = 1,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真实 Ch1/Ch21、cycle 2 与代表塔层含机制 Boss 均终局，正 id 参与者只有祖师', () async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final founderId = save!.founderCharacterId!;
    final results = <Phase0aSweepRunResult>[];
    for (var index = 1; index <= 5; index++) {
      results.add(
        await Phase0aSweepHeadlessRunner(
          isar: isar,
          numbers: GameRepository.instance.numbers,
          rng: Random(20260822 + index),
          botPolicy: const Phase0aBotTacticPolicy.assault(),
        ).runMainline(
          stage: GameRepository.instance.getStage('stage_01_0$index'),
          cycleIndex: 1,
        ),
      );
    }
    // 扩面：真实 Ch1 二周目(cycle 2)与 Ch21(武圣收官章)主线均须跑至终局。
    results.add(
      await Phase0aSweepHeadlessRunner(
        isar: isar,
        numbers: GameRepository.instance.numbers,
        rng: Random(20260822),
        botPolicy: const Phase0aBotTacticPolicy.assault(),
      ).runMainline(
        stage: GameRepository.instance.getStage('stage_01_01'),
        cycleIndex: 2,
      ),
    );
    results.add(
      await Phase0aSweepHeadlessRunner(
        isar: isar,
        numbers: GameRepository.instance.numbers,
        rng: Random(20260822),
        botPolicy: const Phase0aBotTacticPolicy.assault(),
      ).runMainline(
        stage: GameRepository.instance.getStage('stage_21_01'),
        cycleIndex: 1,
      ),
    );
    for (final floorIndex in [1, 25, 30, 49]) {
      results.add(
        await Phase0aSweepHeadlessRunner(
          isar: isar,
          numbers: GameRepository.instance.numbers,
          rng: Random(20260822 + floorIndex),
          botPolicy: const Phase0aBotTacticPolicy.assault(),
        ).runTower(
          floor: GameRepository.instance.towerFloors.firstWhere(
            (floor) => floor.floorIndex == floorIndex,
          ),
          cycleIndex: 1,
          request: _towerRequest(
            floorIndex: floorIndex,
            characterId: founderId,
          ),
        ),
      );
    }

    for (final result in results) {
      expect(result.timedOut, isFalse);
      expect(result.settlement?.isFinished, isTrue);
      expect(result.settlement!.participantCharacterIds.where((id) => id > 0), {
        founderId,
      });
    }
    for (final result in results.skip(results.length - 4)) {
      expect(result.expectedParticipantId, founderId);
      expect(result.participantName, isNotEmpty);
      expect(result.towerAutomationAdmission, isNotNull);
      expect(
        result.towerAutomationAdmission!.request,
        _towerRequest(
          floorIndex: result.towerAutomationAdmission!.floorIndex,
          characterId: founderId,
        ),
      );
    }
  });

  test('祖师已在远征时拒绝双占用，不进入战斗与结算', () async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final founderId = save!.founderCharacterId!;
    await isar.writeTxn(() async {
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yiZhanLiXing
          ..seed = 1
          ..departedAt = DateTime(2026, 8, 22)
          ..members = [ActivityMemberSnapshot()..characterId = founderId],
      );
    });
    final runner = Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: GameRepository.instance.numbers,
      rng: Random(1),
      botPolicy: const Phase0aBotTacticPolicy.assault(),
    );

    await expectLater(
      runner.runMainline(
        stage: GameRepository.instance.getStage('stage_01_01'),
        cycleIndex: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('轻功 durable admission 进入真实 mapLightFoot 同核 runner 并产终局', () async {
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final participantId = save.founderCharacterId!;
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final service = DurableActivityAutomationService(isar);
    final runId = await service.start(
      kind: DurableActivityKind.lightFoot,
      stage: stage,
      cycleIndex: 1,
      request: _durableRequest(
        kind: DurableActivityKind.lightFoot,
        stageId: stage.id,
        characterId: participantId,
      ),
    );
    final admission = await service.admit(runId: runId, stage: stage);
    final result = await Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: GameRepository.instance.numbers,
      rng: Random(admission.run.seed),
      botPolicy: const Phase0aBotTacticPolicy.production(),
    ).runLightFoot(stage: stage, admission: admission);

    expect(result.timedOut, isFalse);
    expect(result.settlement?.isFinished, isTrue);
    expect(result.expectedParticipantId, participantId);
    expect(result.settlement?.playerCharacterId, participantId);
  });

  test('守城 durable admission 消费持久阵型进入真实多波 mapper 并产终局', () async {
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final participantId = save.founderCharacterId!;
    final stage = GameRepository.instance.getStage('stage_mass_battle_01');
    final service = DurableActivityAutomationService(isar);
    final runId = await service.start(
      kind: DurableActivityKind.massBattle,
      stage: stage,
      cycleIndex: 1,
      request: _durableRequest(
        kind: DurableActivityKind.massBattle,
        stageId: stage.id,
        characterId: participantId,
      ),
      formation: Formation.fengShi,
    );
    final admission = await service.admit(runId: runId, stage: stage);
    expect(admission.run.formation, Formation.fengShi);
    final result = await Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: GameRepository.instance.numbers,
      rng: Random(admission.run.seed),
      botPolicy: const Phase0aBotTacticPolicy.production(),
    ).runMassBattle(stage: stage, admission: admission);

    expect(result.timedOut, isFalse);
    expect(result.settlement?.isFinished, isTrue);
    expect(result.expectedParticipantId, participantId);
    expect(result.settlement?.playerCharacterId, participantId);
  });

  test('真实 Ch1 快速 headless 重演返回当前掌门身份报告', () async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final founder = await isar.characters.get(save!.founderCharacterId!);
    final result =
        await Phase0aSweepHeadlessRunner(
          isar: isar,
          numbers: GameRepository.instance.numbers,
          rng: Random(20260825),
          botPolicy: const Phase0aBotTacticPolicy.assault(),
        ).runMainline(
          stage: GameRepository.instance.getStage('stage_01_01'),
          cycleIndex: 1,
          entryKind: ActivityEntryKind.replay,
        );

    expect(result.timedOut, isFalse);
    expect(result.settlement?.isFinished, isTrue);
    expect(result.expectedParticipantId, founder!.id);
    expect(result.participantName, founder.name);
    expect(result.settlement!.participantCharacterIds.where((id) => id > 0), {
      founder.id,
    });
  });

  test('未通关关卡的快速重演与扫荡均在装配前拒绝', () async {
    final isar = IsarSetup.instance;
    final progress = await isar.mainlineProgress.where().findFirst();
    await isar.writeTxn(() async {
      progress!.clearedStageIds = [];
      await isar.mainlineProgress.put(progress);
    });
    final runner = Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: GameRepository.instance.numbers,
      rng: Random(20260825),
      botPolicy: const Phase0aBotTacticPolicy.assault(),
    );
    for (final entryKind in [
      ActivityEntryKind.replay,
      ActivityEntryKind.sweep,
    ]) {
      await expectLater(
        runner.runMainline(
          stage: GameRepository.instance.getStage('stage_01_01'),
          cycleIndex: 1,
          entryKind: entryKind,
        ),
        throwsStateError,
      );
    }
  });
}

ActivityParticipationRequest _towerRequest({
  required int floorIndex,
  required int characterId,
}) => ActivityParticipationRequest(
  contentId: towerAutomationContentId(floorIndex),
  contentKind: ActivityContentKind.tower,
  characterId: characterId,
  loadoutPlanId: towerAutomationLoadoutPlanId(
    floorIndex: floorIndex,
    characterId: characterId,
  ),
  participation: ActivityParticipationMode.direct,
  controller: ActivityController.playerBot,
  clock: ActivityClock.headless,
  entryKind: ActivityEntryKind.sweep,
);

ActivityParticipationRequest _durableRequest({
  required DurableActivityKind kind,
  required String stageId,
  required int characterId,
}) => ActivityParticipationRequest(
  contentId: stageId,
  contentKind: kind == DurableActivityKind.lightFoot
      ? ActivityContentKind.lightFoot
      : ActivityContentKind.massBattle,
  characterId: characterId,
  loadoutPlanId: durableActivityLoadoutPlanId(
    kind: kind,
    stageId: stageId,
    characterId: characterId,
  ),
  participation: ActivityParticipationMode.dispatch,
  controller: ActivityController.playerBot,
  clock: ActivityClock.headless,
  entryKind: ActivityEntryKind.offlineResume,
);
