import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    SharedPreferences.setMockInitialValues({});
    // CachingAssetBundle retains Futures created in a prior widget test's
    // fake-async zone. That zone cannot service later narrative listeners.
    rootBundle.evict('data/narratives/chapters/chapter_01.yaml');
    rootBundle.evict('data/narratives/chapters/chapter_21.yaml');
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

  for (final (description, control) in const [
    ('生产 flow 从章末已结算空游标恢复卷轴并进入独立 version-1 run', _ChapterRecoveryControl.none),
    ('生产 flow 的真实掌门错误直接报告且保留旧 journal', _ChapterRecoveryControl.missingLeader),
    (
      '生产 flow 被真实 Isar 写事务阻塞时五秒失败，释放后完成原结算断言',
      _ChapterRecoveryControl.blockedWrite,
    ),
  ]) {
    testWidgets(description, (tester) async {
      final probe = _FlowProbe();
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
            navigatorObservers: [probe],
            home: _FirstClearFlowHarness(
              initialStage: repository.getStage('stage_01_01'),
              probe: probe,
            ),
          ),
        ),
      );
      await tester.tap(find.text('start-cross-chapter'));
      final route = await _readyChapterScroll(tester, probe);

      expect(find.byType(ChapterTransitionScreen), findsOneWidget);
      expect(find.text(UiStrings.chapterScrollEnter), findsOneWidget);
      if (control == _ChapterRecoveryControl.missingLeader) {
        // Corrupt only this temporary fixture; let the production resolver throw.
        await tester.runAsync(
          () => IsarSetup.instance.writeTxn(
            () => IsarSetup.instance.characters.delete(participant.id),
          ),
        );
      }

      Completer<void>? releaseWrite;
      Future<void>? blockedWrite;
      try {
        if (control == _ChapterRecoveryControl.blockedWrite) {
          await tester.runAsync(() async {
            releaseWrite = Completer<void>();
            final enteredWrite = Completer<void>();
            blockedWrite = IsarSetup.instance.writeTxn(() async {
              enteredWrite.complete();
              await releaseWrite!.future;
            });
            await enteredWrite.future.timeout(const Duration(seconds: 5));
          });
        }
        probe.continuationClock.start();
        await tester.tap(find.text(UiStrings.chapterScrollEnter));
        await _finishChapterExit(tester, route, probe);
        if (control == _ChapterRecoveryControl.missingLeader) {
          await expectLater(
            _waitForFlow(tester, probe),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'production resolver error',
                'Current leader pointer invalid: '
                    'SaveData.founderCharacterId=${participant.id} has no Character',
              ),
            ),
          );
          expect(probe.completed, isFalse);
          expect(find.text('done-cross-chapter'), findsNothing);
          final active = await tester.runAsync(
            () => MainlineSettlementJournalService(
              IsarSetup.instance,
            ).activeForSave(IsarSetup.currentSlotId),
          );
          expect(active!.identity, oldIdentity);
          expect(active.phase, MainlineSettlementPhase.coreApplied);
          expect(
            active.postSettlementAction,
            MainlinePostSettlementAction.showChapterScroll,
          );
          expect(active.loadoutSnapshotIds, hasLength(5));
          return;
        }
        if (control == _ChapterRecoveryControl.blockedWrite) {
          await expectLater(
            _waitForFlow(tester, probe),
            throwsA(
              isA<TestFailure>().having(
                (error) => error.message,
                'unchanged real deadline',
                contains('Production flow did not complete within 5000ms'),
              ),
            ),
          );
          expect(probe.completed, isFalse);
          expect(probe.error, isNull);
          expect(find.text('done-cross-chapter'), findsNothing);
          releaseWrite!.complete();
          await tester.runAsync(() => blockedWrite!);
          // Observe recovery for a separate bounded five seconds, while keeping
          // the original business clock. Even a now-completed late flow fails.
          await _pumpUntil(
            tester,
            find.text('done-cross-chapter'),
            probe: probe,
          );
          expect(probe.completed, isTrue);
          await expectLater(
            _waitForFlow(tester, probe),
            throwsA(
              isA<TestFailure>().having(
                (error) => error.message,
                'completion after the original deadline',
                contains('Production flow did not complete within 5000ms'),
              ),
            ),
          );
        } else {
          await _waitForFlow(tester, probe);
        }
        expect(find.text('done-cross-chapter'), findsOneWidget);

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
      } finally {
        // Never leave a held native transaction behind if an assertion fails.
        if (releaseWrite != null && !releaseWrite!.isCompleted) {
          releaseWrite!.complete();
          await tester.runAsync(() => blockedWrite!);
          // Cleanup has its own bounded observation after the test has failed.
          if (probe.continuationClock.isRunning) {
            await _pumpUntil(
              tester,
              find.text('done-cross-chapter'),
              probe: probe,
            );
          }
        }
      }
    });
  }

  testWidgets('生产 flow 恢复终章卷轴后只合卷且不创建下一 run', (tester) async {
    final probe = _FlowProbe();
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
          navigatorObservers: [probe],
          home: _FirstClearFlowHarness(
            initialStage: repository.getStage('stage_01_01'),
            probe: probe,
          ),
        ),
      ),
    );
    await tester.tap(find.text('start-cross-chapter'));
    final route = await _readyChapterScroll(tester, probe);

    expect(find.text(UiStrings.titleBarBack), findsOneWidget);
    expect(find.text(UiStrings.chapterScrollEnter), findsNothing);
    probe.continuationClock.start();
    await tester.tap(find.text(UiStrings.titleBarBack));
    await _finishChapterExit(tester, route, probe);
    await _waitForFlow(tester, probe);
    expect(find.text('done-cross-chapter'), findsOneWidget);

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
  _FlowProbe? probe,
}) async {
  // Isar and repository work need real event-loop time. Pump durations only
  // advance the widget test's fake clock and are not an I/O deadline.
  final elapsed = Stopwatch()..start();
  while (finder.evaluate().isEmpty &&
      probe?.error == null &&
      elapsed.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (probe?.error != null) {
    Error.throwWithStackTrace(probe!.error!, probe.stack!);
  }
  expect(
    finder,
    findsWidgets,
    reason: 'Widget not found within ${timeout.inMilliseconds}ms of real time',
  );
}

Future<PageRoute<dynamic>> _readyChapterScroll(
  WidgetTester tester,
  _FlowProbe probe,
) async {
  await _pumpUntil(tester, find.byType(ChapterTransitionScreen), probe: probe);
  final route =
      ModalRoute.of(tester.element(find.byType(ChapterTransitionScreen)))!
          as PageRoute<dynamic>;
  probe.chapterRoute = route;
  // Advance the route's own virtual animation independently of the real I/O
  // deadline. Finding a built page does not mean its entrance has completed.
  for (
    var frame = 0;
    route.animation!.status != AnimationStatus.completed && frame < 50;
    frame++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(route.animation!.status, AnimationStatus.completed);
  expect(route.isCurrent, isTrue);
  // The page can exist while its real narrative FutureBuilder is still loading.
  final chapter = tester.widget<ChapterTransitionScreen>(
    find.byType(ChapterTransitionScreen),
  );
  await _pumpUntil(
    tester,
    find.widgetWithText(
      FilledButton,
      chapter.nextChapterIndex == null
          ? UiStrings.titleBarBack
          : UiStrings.chapterScrollEnter,
    ),
    probe: probe,
  );
  return route;
}

Future<void> _finishChapterExit(
  WidgetTester tester,
  PageRoute<dynamic> route,
  _FlowProbe probe,
) async {
  await tester.pump();
  expect(
    probe.poppedRoutes,
    contains(route),
    reason: 'The real button must pop',
  );
  var removed = false;
  unawaited(route.completed.then((_) => removed = true));
  for (var frame = 0; !removed && frame < 50; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(removed, isTrue, reason: 'Chapter route exit did not finish');
  await tester.pump();
  expect(find.byType(ChapterTransitionScreen), findsNothing);
}

Future<void> _waitForFlow(WidgetTester tester, _FlowProbe probe) async {
  const timeout = Duration(seconds: 5);
  final elapsed = probe.continuationClock;
  var pumps = 0;
  while (!probe.completed && probe.error == null && elapsed.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    // Only flush microtasks/builds here; route animations have their own step.
    await tester.pump();
    pumps++;
  }
  final diagnostic = {
    ...probe.facts,
    'continuationMilliseconds': elapsed.elapsedMilliseconds,
    'pumps': pumps,
  };
  // One bounded record per flow wait, including the actual production error.
  // ignore: avoid_print
  print('MAINLINE_FLOW_WAIT ${jsonEncode(diagnostic)}');
  if (probe.error != null) {
    Error.throwWithStackTrace(probe.error!, probe.stack!);
  }
  expect(
    probe.completed && elapsed.elapsed <= timeout,
    isTrue,
    reason: 'Production flow did not complete within 5000ms: $diagnostic',
  );
  await tester.pump();
}

enum _ChapterRecoveryControl { none, missingLeader, blockedWrite }

final class _FlowProbe extends NavigatorObserver {
  bool started = false;
  bool completed = false;
  Object? error;
  StackTrace? stack;
  // Starts immediately before the real chapter button tap and stops when the
  // production Future completes/errors, independently of route pumping.
  final continuationClock = Stopwatch();
  PageRoute<dynamic>? chapterRoute;
  final poppedRoutes = <Route<dynamic>>[];

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }

  Map<String, Object?> get facts => {
    'started': started,
    'completed': completed,
    'error': error?.toString(),
    'chapterPopped': poppedRoutes.contains(chapterRoute),
    'chapterIsCurrent': chapterRoute?.isCurrent,
    'chapterAnimation': chapterRoute?.animation?.status.name,
  };
}

class _FirstClearFlowHarness extends ConsumerStatefulWidget {
  const _FirstClearFlowHarness({
    required this.initialStage,
    required this.probe,
  });

  final StageDef initialStage;
  final _FlowProbe probe;

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
                widget.probe.started = true;
                try {
                  await runStageFlow(
                    context: context,
                    ref: ref,
                    stage: widget.initialStage,
                    continueFirstClearRun: true,
                    phase0aBattleOutcomeForTest: () async =>
                        (won: false, surrendered: true, settlement: null),
                  );
                  widget.probe.continuationClock.stop();
                  widget.probe.completed = true;
                  if (mounted) setState(() => _done = true);
                } catch (error, stack) {
                  widget.probe.continuationClock.stop();
                  widget.probe.error = error;
                  widget.probe.stack = stack;
                }
              },
        child: Text(_done ? 'done-cross-chapter' : 'start-cross-chapter'),
      ),
    );
  }
}
