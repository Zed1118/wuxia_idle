import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_narrative_manifest.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_run_coordinator.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late MainlineNarrativeManifest narrativeManifest;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
    narrativeManifest = await MainlineNarrativeManifest.load(
      loader: (path) => File(path).readAsString(),
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'mainline_ch1_continuous_entry_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真实第一章配置只连续推进 01..05，不跨入第二章', () async {
    StageDef? nextStageInChapterOne(StageDef current) {
      final nextId = nextMainlineStageId(repository, current.id);
      if (nextId == null || !nextId.startsWith('stage_01_')) return null;
      return repository.getStage(nextId);
    }

    final launches = <MainlineRunStageLaunch>[];
    final coordinator = MainlineRunCoordinator(
      executeStage: (launch) async {
        launches.add(launch);
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: nextStageInChapterOne,
      loadNextSnapshot: ({required run, required nextStage}) async {
        final version = run.currentLoadoutVersion + 1;
        return PreparedMainlineLoadoutSnapshot(
          playerSnapshot: testCombatantSnapshot(
            characterId: run.participantId,
            name: '锁定参与者-v$version',
          ),
          loadoutSnapshotId: '${run.runId}:loadout:$version',
        );
      },
    );

    final result = await coordinator.run(
      initialStage: repository.getStage('stage_01_01'),
      initialRun: MainlineRun.begin(
        runId: 'ch1-real-config',
        participantId: 19,
        stageId: 'stage_01_01',
        loadoutSnapshotId: 'ch1-real-config:loadout:1',
      ),
      initialPlayerSnapshot: testCombatantSnapshot(characterId: 19),
    );

    expect(launches.map((launch) => launch.stage.id), [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
      'stage_01_05',
    ]);
    expect(
      launches.map((launch) => launch.run.participantId),
      everyElement(19),
    );
    expect(launches.map((launch) => launch.run.currentLoadoutVersion), [
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(result.completedStageIds, [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
      'stage_01_05',
    ]);
    expect(result.reason, MainlineRunCompletionReason.chapterCompleted);
    expect(nextMainlineStageId(repository, 'stage_01_05'), isNull);
    expect(repository.getStage('stage_02_01').prevStageId, isNull);
  });

  testWidgets('StageListScreen 首次可挑战入口消费连续 run 同一参与者快照', (tester) async {
    final seeded = await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      final participant = Character.create(
        name: '连续首推掌门',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime.utc(2026, 8, 25),
        internalForce: 3000,
        school: TechniqueSchool.gangMeng,
        isFounder: true,
        isAlive: true,
      );
      await isar.writeTxn(() => isar.characters.put(participant));
      final technique = Technique.create(
        defId: 'tech_gangmeng_jichu',
        ownerCharacterId: participant.id,
        tier: TechniqueTier.values.first,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime.utc(2026, 8, 25),
      );
      final progress = MainlineProgress()
        ..saveDataId = IsarSetup.currentSlotId
        ..currentChapterIndex = 1;
      await isar.writeTxn(() async {
        participant.mainTechniqueId = await isar.techniques.put(technique);
        await isar.characters.put(participant);
        final save = (await isar.saveDatas.get(0))!;
        save
          ..activeCharacterIds = [participant.id]
          ..founderCharacterId = participant.id;
        await isar.saveDatas.put(save);
        await isar.mainlineProgress.put(progress);
      });
      return (participant: participant, progress: progress);
    });
    final participant = seeded!.participant;
    final progress = seeded.progress;

    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => progress),
          mainlineNarrativeManifestProvider.overrideWith(
            (ref) async => narrativeManifest,
          ),
          activeCharacterIdsProvider.overrideWith(
            (ref) async => [participant.id],
          ),
          characterByIdProvider(
            participant.id,
          ).overrideWith((ref) async => participant),
        ],
        child: const MaterialApp(home: StageListScreen(chapterIndex: 1)),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    await tester.tap(find.text('山门之外'));
    for (
      var i = 0;
      i < 120 && find.byType(Phase0aMainlineBattleHost).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    try {
      expect(find.byType(Phase0aMainlineBattleHost), findsOneWidget);
      final host = tester.widget<Phase0aMainlineBattleHost>(
        find.byType(Phase0aMainlineBattleHost),
      );
      for (
        var i = 0;
        i < 120 && find.byType(Phase0aBattleScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(Phase0aBattleScreen), findsOneWidget);
      final battleScreen = tester.widget<Phase0aBattleScreen>(
        find.byType(Phase0aBattleScreen),
      );
      expect(host.controller, ActivityController.human);
      expect(host.playerSnapshot?.characterId, participant.id);
      expect(host.playerSnapshot?.name, participant.name);
      expect(
        battleScreen.controller.roster.nameOf(
          battleScreen.controller.state.player.id,
        ),
        participant.name,
      );
    } finally {
      if (find.byType(Phase0aMainlineBattleHost).evaluate().isNotEmpty) {
        Navigator.of(
          tester.element(find.byType(Phase0aMainlineBattleHost)),
        ).pop();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pumpAndSettle();
      }
    }
  });
}
