import 'dart:async';
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
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_transition_screen.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

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

  testWidgets('真实等待到期时报告缺失页面，不无限等待', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await expectLater(
      _pumpUntil(
        tester,
        find.byType(Phase0aMainlineBattleHost),
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  Future<void> verifyFirstClearEntry(
    WidgetTester tester, {
    required bool delayedBinding,
  }) async {
    late Zone realIoZone;
    final seeded = await tester.runAsync(() async {
      realIoZone = Zone.current;
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
    Future<void>? bindingReady;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (delayedBinding)
            phase0aMainlineEncounterRuntimeBindingLoaderProvider
                .overrideWithValue(({
                  required stageId,
                  required encounterId,
                  required cycleIndex,
                }) async {
                  bindingReady = realIoZone.run(
                    () => Future<void>.delayed(const Duration(seconds: 1)),
                  );
                  await bindingReady;
                  return loadPhase0aMainlineRuntimeBindingBundleFromRepository(
                    stageId: stageId,
                    encounterId: encounterId,
                    cycleIndex: cycleIndex,
                  );
                }),
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

    try {
      await tester.tap(find.text('山门之外'));
      await _pumpUntil(tester, find.byType(Phase0aMainlineBattleHost));
      expect(find.byType(Phase0aMainlineBattleHost), findsOneWidget);
      final host = tester.widget<Phase0aMainlineBattleHost>(
        find.byType(Phase0aMainlineBattleHost),
      );
      await _pumpUntil(tester, find.byType(Phase0aBattleScreen));
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
      try {
        await tester.runAsync(() async {
          await bindingReady;
        });
        if (find.byType(Phase0aMainlineBattleHost).evaluate().isNotEmpty) {
          Navigator.of(
            tester.element(find.byType(Phase0aMainlineBattleHost)),
          ).pop();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 5),
          );
        }
      } finally {
        // Always unmount, including missing-host and failed-pop paths.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  }

  for (final delayedBinding in [false, true]) {
    testWidgets(
      'StageListScreen 首次可挑战入口消费连续 run 同一参与者快照 (delayedBinding=$delayedBinding)',
      (tester) => verifyFirstClearEntry(tester, delayedBinding: delayedBinding),
    );
  }

  testWidgets('生产 flow 从章末已结算空游标恢复卷轴并进入独立 version-1 run', (tester) async {
    final participant = await tester.runAsync(
      () => _seedMainlineParticipant('跨章掌门'),
    );
    final oldIdentity = MainlineSettlementIdentity(
      runId: 'chapter-1-run',
      stageId: 'stage_01_05',
      loadoutVersion: 5,
      participantId: participant!.id,
    );
    await tester.runAsync(() async {
      final service = MainlineSettlementJournalService(IsarSetup.instance);
      await service.prepare(
        saveDataId: IsarSetup.currentSlotId,
        identity: oldIdentity,
        loadoutSnapshotId: 'chapter-1-run:loadout:5',
        loadoutSnapshotIds: [
          for (var version = 1; version <= 5; version++)
            'chapter-1-run:loadout:$version',
        ],
        now: DateTime.utc(2026, 8, 31),
      );
      await service.commitCore(
        identity: oldIdentity,
        pendingEffectIds: const [],
        now: DateTime.utc(2026, 8, 31, 0, 1),
        applyInTxn: () async {},
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: _FirstClearFlowHarness(
            initialStage: repository.getStage('stage_01_01'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start-cross-chapter'));
    await _pumpUntil(tester, find.byType(ChapterTransitionScreen));

    expect(find.byType(ChapterTransitionScreen), findsOneWidget);
    expect(find.text(UiStrings.chapterScrollEnter), findsOneWidget);
    await tester.tap(find.text(UiStrings.chapterScrollEnter));
    await _pumpUntil(tester, find.text('done-cross-chapter'));

    final active = await tester.runAsync(
      () => MainlineSettlementJournalService(
        IsarSetup.instance,
      ).activeForSave(IsarSetup.currentSlotId),
    );
    expect(active, isNotNull);
    expect(active!.stageId, 'stage_02_01');
    expect(active.runId, isNot(oldIdentity.runId));
    expect(active.loadoutVersion, 1);
    expect(active.phase, MainlineSettlementPhase.prepared);
    expect(active.loadoutSnapshotIds, hasLength(1));
  });

  testWidgets('生产 flow 恢复终章卷轴后只合卷且不创建下一 run', (tester) async {
    final participant = await tester.runAsync(
      () => _seedMainlineParticipant('终章掌门'),
    );
    final identity = MainlineSettlementIdentity(
      runId: 'chapter-21-run',
      stageId: 'stage_21_05',
      loadoutVersion: 5,
      participantId: participant!.id,
    );
    await tester.runAsync(() async {
      final service = MainlineSettlementJournalService(IsarSetup.instance);
      await service.prepare(
        saveDataId: IsarSetup.currentSlotId,
        identity: identity,
        loadoutSnapshotId: 'chapter-21-run:loadout:5',
        loadoutSnapshotIds: [
          for (var version = 1; version <= 5; version++)
            'chapter-21-run:loadout:$version',
        ],
        now: DateTime.utc(2026, 8, 31),
      );
      await service.commitCore(
        identity: identity,
        pendingEffectIds: const [],
        now: DateTime.utc(2026, 8, 31, 0, 1),
        applyInTxn: () async {},
      );
      await service.recordPostSettlementAction(
        identity: identity,
        action: MainlinePostSettlementAction.showChapterScroll,
        now: DateTime.utc(2026, 8, 31, 0, 2),
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: _FirstClearFlowHarness(
            initialStage: repository.getStage('stage_01_01'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start-cross-chapter'));
    await _pumpUntil(tester, find.byType(ChapterTransitionScreen));

    expect(find.text(UiStrings.titleBarBack), findsOneWidget);
    expect(find.text(UiStrings.chapterScrollEnter), findsNothing);
    await tester.tap(find.text(UiStrings.titleBarBack));
    await _pumpUntil(tester, find.text('done-cross-chapter'));

    final active = await tester.runAsync(
      () => MainlineSettlementJournalService(
        IsarSetup.instance,
      ).activeForSave(IsarSetup.currentSlotId),
    );
    expect(active, isNull);
  });
}

Future<Character> _seedMainlineParticipant(String name) async {
  final isar = IsarSetup.instance;
  final participant = Character.create(
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime.utc(2026, 8, 31),
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
    learnedAt: DateTime.utc(2026, 8, 31),
  );
  await isar.writeTxn(() async {
    participant.mainTechniqueId = await isar.techniques.put(technique);
    await isar.characters.put(participant);
    final save = (await isar.saveDatas.get(0))!;
    save
      ..activeCharacterIds = [participant.id]
      ..founderCharacterId = participant.id;
    await isar.saveDatas.put(save);
  });
  return participant;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  // Isar and repository work need real event-loop time. Pump durations only
  // advance the widget test's fake clock and are not an I/O deadline.
  final elapsed = Stopwatch()..start();
  while (finder.evaluate().isEmpty && elapsed.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    finder,
    findsWidgets,
    reason: 'Widget not found within ${timeout.inMilliseconds}ms of real time',
  );
}

class _FirstClearFlowHarness extends ConsumerStatefulWidget {
  const _FirstClearFlowHarness({required this.initialStage});

  final StageDef initialStage;

  @override
  ConsumerState<_FirstClearFlowHarness> createState() =>
      _FirstClearFlowHarnessState();
}

class _FirstClearFlowHarnessState
    extends ConsumerState<_FirstClearFlowHarness> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: _done
            ? null
            : () async {
                await runStageFlow(
                  context: context,
                  ref: ref,
                  stage: widget.initialStage,
                  continueFirstClearRun: true,
                  phase0aBattleOutcomeForTest: () async =>
                      (won: false, surrendered: true, settlement: null),
                );
                if (mounted) setState(() => _done = true);
              },
        child: Text(_done ? 'done-cross-chapter' : 'start-cross-chapter'),
      ),
    );
  }
}
