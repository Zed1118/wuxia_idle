import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/character_occupancy_service.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_automation_policy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late Character leader;
  late DurableActivityAutomationService service;

  setUpAll(() async {
    initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_durable_activity_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    leader = (await IsarSetup.instance.characters.where().findFirst())!;
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.founderCharacterId = leader.id;
      save.activeCharacterIds = [leader.id];
      await IsarSetup.instance.saveDatas.put(save);
      final rows = await IsarSetup.instance.mainlineProgress.where().findAll();
      final progress = rows.firstOrNull ?? MainlineProgress();
      progress.saveDataId = save.slotId;
      progress.clearedStageIds = {
        ...progress.clearedStageIds,
        'stage_light_foot_01',
        'stage_mass_battle_01',
      }.toList();
      progress.clearedAt = List.of(progress.clearedAt);
      await IsarSetup.instance.mainlineProgress.put(progress);
      final towerRows = await IsarSetup.instance.towerProgress
          .where()
          .findAll();
      final tower = towerRows.firstOrNull ?? TowerProgress();
      tower
        ..saveDataId = save.slotId
        ..highestClearedFloor = 1
        ..highestClearedAt = DateTime.utc(2026, 8, 31)
        ..createdAt = DateTime.utc(2026, 8, 31)
        ..currentCycleIndex = 1;
      await IsarSetup.instance.towerProgress.put(tower);
    });
    service = DurableActivityAutomationService(IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ActivityParticipationRequest request(
    DurableActivityKind kind,
    String stageId, {
    ActivityParticipationMode participation =
        ActivityParticipationMode.dispatch,
    ActivityClock clock = ActivityClock.headless,
    ActivityEntryKind entryKind = ActivityEntryKind.offlineResume,
  }) => ActivityParticipationRequest(
    contentId: stageId,
    contentKind: kind == DurableActivityKind.lightFoot
        ? ActivityContentKind.lightFoot
        : ActivityContentKind.massBattle,
    characterId: leader.id,
    loadoutPlanId: durableActivityLoadoutPlanId(
      kind: kind,
      stageId: stageId,
      characterId: leader.id,
    ),
    participation: participation,
    controller: ActivityController.playerBot,
    clock: clock,
    entryKind: entryKind,
  );

  test('轻功会话先落库并锁角色/装配，receipt 幂等且阅报后释放', () async {
    const kind = DurableActivityKind.lightFoot;
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final startedAt = DateTime.utc(2026, 8, 31, 1);
    final runId = await service.start(
      kind: kind,
      stage: stage,
      cycleIndex: 1,
      request: request(kind, stage.id),
      now: startedAt,
    );
    final run = (await service.runById(runId))!;
    expect(run.seed, runId);
    expect(
      run.lastAdvancedAt.millisecondsSinceEpoch,
      startedAt.millisecondsSinceEpoch,
    );
    expect(run.members.single.characterId, leader.id);
    expect(run.members.single.reservedTechniqueIds, isNotEmpty);
    expect(run.formation, isNull);
    final occupancy = await CharacterOccupancyService(
      IsarSetup.instance,
    ).snapshot();
    expect(occupancy.activityOf(leader.id), ActivityKind.lightFoot);
    expect(
      occupancy.reservedTechniqueIds,
      containsAll(run.members.single.reservedTechniqueIds),
    );

    await expectLater(
      service.start(
        kind: DurableActivityKind.massBattle,
        stage: GameRepository.instance.getStage('stage_mass_battle_01'),
        cycleIndex: 1,
        request: request(
          DurableActivityKind.massBattle,
          'stage_mass_battle_01',
        ),
        formation: Formation.yanXing,
      ),
      throwsStateError,
    );

    var businessWrites = 0;
    expect(
      await service.commitSettlement(
        runId: runId,
        outcome: DurableActivityOutcome.victory,
        applyInTxn: () async => businessWrites += 1,
      ),
      DurableActivitySettlementDisposition.applied,
    );
    expect(
      await service.commitSettlement(
        runId: runId,
        outcome: DurableActivityOutcome.victory,
        applyInTxn: () async => businessWrites += 1,
      ),
      DurableActivitySettlementDisposition.alreadyApplied,
    );
    expect(businessWrites, 1);
    expect(
      (await CharacterOccupancyService(
        IsarSetup.instance,
      ).snapshot()).activityOf(leader.id),
      ActivityKind.lightFoot,
    );

    await service.close(runId: runId);
    expect(
      (await CharacterOccupancyService(
        IsarSetup.instance,
      ).snapshot()).activityOf(leader.id),
      isNull,
    );
  });

  test('守城阵型持久化；恢复前装配漂移会 fail closed', () async {
    const kind = DurableActivityKind.massBattle;
    final stage = GameRepository.instance.getStage('stage_mass_battle_01');
    final runId = await service.start(
      kind: kind,
      stage: stage,
      cycleIndex: 1,
      request: request(kind, stage.id),
      formation: Formation.baGua,
    );
    expect((await service.runById(runId))!.formation, Formation.baGua);
    final admitted = await service.admit(runId: runId, stage: stage);
    expect(admitted.snapshot.characterId, leader.id);
    expect(admitted.request, request(kind, stage.id));

    await IsarSetup.instance.writeTxn(() async {
      final current = (await IsarSetup.instance.characters.get(leader.id))!;
      current.assistTechniqueIds = [999999];
      await IsarSetup.instance.characters.put(current);
    });
    await expectLater(
      service.admit(runId: runId, stage: stage),
      throwsStateError,
    );
  });

  test('快速推演持久化 direct + bot + headless + replay 且仍受首通门保护', () async {
    const kind = DurableActivityKind.lightFoot;
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final replayRequest = request(
      kind,
      stage.id,
      participation: ActivityParticipationMode.direct,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.replay,
    );
    final runId = await service.start(
      kind: kind,
      stage: stage,
      cycleIndex: 1,
      request: replayRequest,
    );
    final run = (await service.runById(runId))!;
    expect(run.request, replayRequest);
    expect(run.participation, ActivityParticipationMode.direct);
    expect(run.clock, ActivityClock.headless);
    expect(run.entryKind, ActivityEntryKind.replay);
    expect(
      (await CharacterOccupancyService(
        IsarSetup.instance,
      ).snapshot()).activityOf(leader.id),
      ActivityKind.lightFoot,
    );

    await IsarSetup.instance.writeTxn(() async {
      final progress = (await IsarSetup.instance.mainlineProgress
          .where()
          .findFirst())!;
      progress.clearedStageIds = progress.clearedStageIds
          .where((id) => id != stage.id)
          .toList();
      await IsarSetup.instance.mainlineProgress.put(progress);
    });
    await service.commitSettlement(
      runId: runId,
      outcome: DurableActivityOutcome.victory,
      applyInTxn: () async {},
    );
    await service.close(runId: runId);
    await expectLater(
      service.start(
        kind: kind,
        stage: stage,
        cycleIndex: 1,
        request: replayRequest,
      ),
      throwsA(isA<DurableActivityAutomationRejectedException>()),
    );
  });

  test('九霄塔已通层差遣落既有 durable run，并按 tower 占用与装配重验', () async {
    final floor = GameRepository.instance.towerFloors.firstWhere(
      (value) => value.floorIndex == 1,
    );
    final request = towerDurableDispatchRequest(
      floorIndex: floor.floorIndex,
      characterId: leader.id,
    );
    final startedAt = DateTime.utc(2026, 9, 1, 1);
    final runId = await service.startTower(
      floor: floor,
      cycleIndex: 1,
      request: request,
      now: startedAt,
    );
    final run = (await service.runById(runId))!;
    expect(run.kind, DurableActivityKind.tower);
    expect(run.request, request);
    expect(run.seed, runId);
    expect(
      run.startedAt.millisecondsSinceEpoch,
      startedAt.millisecondsSinceEpoch,
    );
    expect(run.members.single.characterId, leader.id);
    expect(run.members.single.reservedTechniqueIds, isNotEmpty);
    expect(
      (await CharacterOccupancyService(
        IsarSetup.instance,
      ).snapshot()).activityOf(leader.id),
      ActivityKind.tower,
    );

    final admission = await service.admitTower(
      runId: runId,
      floor: floor,
      now: startedAt.add(const Duration(minutes: 3)),
    );
    expect(admission.request, request);
    expect(admission.snapshot.characterId, leader.id);
    expect(
      admission.run.lastAdvancedAt.millisecondsSinceEpoch,
      startedAt.add(const Duration(minutes: 3)).millisecondsSinceEpoch,
    );

    await IsarSetup.instance.writeTxn(() async {
      final character = (await IsarSetup.instance.characters.get(leader.id))!;
      character.assistTechniqueIds = [999999];
      await IsarSetup.instance.characters.put(character);
    });
    await expectLater(
      service.admitTower(runId: runId, floor: floor),
      throwsStateError,
    );
  });

  test('九霄塔未通层与 sweep tuple 不得创建 durable 差遣', () async {
    final first = GameRepository.instance.towerFloors.firstWhere(
      (value) => value.floorIndex == 1,
    );
    final second = GameRepository.instance.towerFloors.firstWhere(
      (value) => value.floorIndex == 2,
    );
    await expectLater(
      service.startTower(
        floor: second,
        cycleIndex: 1,
        request: towerDurableDispatchRequest(
          floorIndex: second.floorIndex,
          characterId: leader.id,
        ),
      ),
      throwsA(isA<TowerAutomationRejectedException>()),
    );
    final sweep = ActivityParticipationRequest(
      contentId: towerAutomationContentId(first.floorIndex),
      contentKind: ActivityContentKind.tower,
      characterId: leader.id,
      loadoutPlanId: towerAutomationLoadoutPlanId(
        floorIndex: first.floorIndex,
        characterId: leader.id,
      ),
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.sweep,
    );
    await expectLater(
      service.startTower(floor: first, cycleIndex: 1, request: sweep),
      throwsStateError,
    );
  });
}
