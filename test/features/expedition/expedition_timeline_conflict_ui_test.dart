import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_timeline.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_overview_screen.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_recap_screen.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_startup_gate.dart';
import 'package:wuxia_idle/features/progressive_unlock/application/progressive_unlock_providers.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

// UI coordination fixtures only: the production service's stored rewards,
// rollback and cold-open invariants are verified by separate native Isar tests.
// Any accidental database access here fails instead of silently simulating it.
class _UnusedIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected database call: ${invocation.memberName}');
}

final _conflict = ExpeditionTimelineConflict(
  runId: 42,
  nextNode: 3,
  passiveAt: DateTime.utc(2026, 9, 15, 12),
  nodeAt: DateTime.utc(2026, 9, 15, 9),
);

ExpeditionRun _run(int id) => ExpeditionRun()
  ..id = id
  ..saveDataId = 0
  ..policy = ExpeditionPolicy.yiZhanLiXing
  ..seed = 2
  ..departedAt = DateTime.utc(2026, 9, 15, 4)
  ..currentNode = 2
  ..members = [ActivityMemberSnapshot()..characterId = 7]
  ..stagedRewards = [
    RewardEntry()
      ..rewardKey = 'exp'
      ..quantity = 19,
  ];

class _ConflictService implements ExpeditionService {
  _ConflictService(this.events, {Object? failure})
    : failure = failure ?? _conflict;

  final List<String> events;
  final Object failure;
  ExpeditionRun? current = _run(42);
  final recalledIds = <int?>[];

  @override
  Future<ExpeditionRun?> activeRun() async => current;

  @override
  Future<ExpeditionSettlementResult> settleToNow({
    required ExpeditionCombat combat,
    required ExpeditionConfig config,
    DateTime? now,
    int maxNodesPerBatch = 24,
    int maxBatches = 4096,
  }) async {
    events.add('catch-up');
    throw failure;
  }

  @override
  Future<ExpeditionReturnResult> recall({
    int? expectedRunId,
    bool defeated = false,
    ExpeditionManualMilestoneGate? manualMilestoneGate,
    DateTime? now,
    Future<void> Function()? beforeCommitForTest,
    Future<void> Function()? afterRewardsInTxnForTest,
  }) async {
    events.add('recall:$expectedRunId');
    recalledIds.add(expectedRunId);
    final active = current;
    if (active == null || expectedRunId != active.id) {
      return const ExpeditionReturnResult(
        returned: false,
        deepestNode: 0,
        grantedRewards: [],
        downedCount: 0,
        defeated: false,
      );
    }
    current = null;
    return ExpeditionReturnResult(
      returned: true,
      participantCharacterId: 7,
      participantName: 'test participant',
      deepestNode: active.currentNode,
      grantedRewards: active.stagedRewards,
      downedCount: 0,
      defeated: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected service call: ${invocation.memberName}');
}

class _Presence extends OnlinePresenceController {
  _Presence(super.ref, this.events, {this.failure});

  final List<String> events;
  final Object? failure;
  bool started = false;

  @override
  Future<PassiveYield?> settlePassiveWindow({
    DateTime? now,
    bool recoverInjuries = true,
  }) async {
    events.add('presence:$recoverInjuries');
    if (failure case final error?) throw error;
    return null;
  }

  @override
  void markStartupSettleDone() {
    events.add('startup-resumed');
    started = true;
  }
}

const _config = ExpeditionConfig(
  normalNodeMinutes: 90,
  eliteNodeMinutes: 180,
  hpRecoverPctPerNode: 0.15,
  qiRecoverPctPerNode: 0.15,
  zhangshiPctPerLayer: 0.05,
);

Future<_Presence> _openOverview(
  WidgetTester tester,
  _ConflictService service,
) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late _Presence presence;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(_UnusedIsar()),
        expeditionServiceProvider.overrideWithValue(service),
        activeExpeditionProvider.overrideWith((ref) => service.activeRun()),
        expeditionConfigProvider.overrideWithValue(_config),
        expeditionCandidatesProvider.overrideWith((ref) async => []),
        pendingExpeditionMilestoneProvider.overrideWith((ref) async => null),
        expeditionMaxDepthProvider.overrideWith((ref) async => 2),
        onlinePresenceControllerProvider.overrideWith((ref) {
          presence = _Presence(ref, service.events);
          ref.onDispose(presence.dispose);
          return presence;
        }),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, child) {
            ref.read(onlinePresenceControllerProvider);
            return const ExpeditionOverviewScreen();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return presence;
}

Future<void> _reachConflictChoice(WidgetTester tester) async {
  await tester.tap(find.text(UiStrings.expeditionRecallButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(UiStrings.expeditionRecallConfirm));
  await tester.pumpAndSettle();
  expect(find.text(UiStrings.expeditionTimelineConflictTitle), findsOneWidget);
  expect(find.text(UiStrings.expeditionTimelineConflictBody), findsOneWidget);
}

void main() {
  testWidgets('startup shows the specific conflict without resuming presence', (
    tester,
  ) async {
    final events = <String>[];
    var observations = 0;
    late _Presence presence;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(null),
            activeRetreatSessionProvider.overrideWith((ref) async => null),
            currentProgressiveUnlockObservationProvider.overrideWith(
              (ref) async => null,
            ),
            onlinePresenceControllerProvider.overrideWith((ref) {
              presence = _Presence(ref, events, failure: _conflict);
              ref.onDispose(presence.dispose);
              return presence;
            }),
          ],
          child: MaterialApp(
            home: MainMenuStartupGate(
              progressiveUnlockObserver: (_, ref) async {
                observations++;
              },
              child: const Scaffold(body: Text('main menu')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(UiStrings.expeditionTimelineConflictHint),
        findsOneWidget,
      );
      expect(presence.started, isFalse);
      expect(observations, 1);
      expect(events, ['presence:true']);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  test('a conflict cannot hide another startup writer failure', () async {
    final failure = StateError('ordinary writer failure');
    var conflictNotices = 0;
    var observed = false;
    await expectLater(
      runMainMenuStartupSequence(
        offlineRecap: Future<void>.error(_conflict),
        monthlyTick: Future<void>.error(failure),
        expeditionSettlement: Future<void>.error(_conflict),
        journeyUnlock: Future<void>.value(),
        observeProgressiveUnlocks: () async {
          observed = true;
        },
        onTimelineConflict: (_) => conflictNotices++,
      ),
      throwsA(same(failure)),
    );
    expect(observed, isFalse);
    expect(conflictNotices, 0);
  });

  testWidgets('first confirmation cancel never starts catch-up', (
    tester,
  ) async {
    final service = _ConflictService([]);
    final presence = await _openOverview(tester, service);
    try {
      await tester.tap(find.text(UiStrings.expeditionRecallButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UiStrings.commonCancel));
      await tester.pumpAndSettle();
      expect(service.events, isEmpty);
      expect(service.current?.id, 42);
      expect(presence.started, isFalse);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('second confirmation keep preserves the run without recall', (
    tester,
  ) async {
    final service = _ConflictService([]);
    final presence = await _openOverview(tester, service);
    final original = service.current;
    try {
      await _reachConflictChoice(tester);
      expect(service.recalledIds, isEmpty);
      await tester.tap(find.text(UiStrings.expeditionTimelineConflictKeep));
      await tester.pumpAndSettle();
      expect(service.current, same(original));
      expect(service.events, ['catch-up']);
      expect(presence.started, isFalse);
      expect(find.byType(ExpeditionRecapScreen), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('second confirmation recalls only the exact run then resumes', (
    tester,
  ) async {
    final service = _ConflictService([]);
    final presence = await _openOverview(tester, service);
    final originalRewards = service.current!.stagedRewards;
    try {
      await _reachConflictChoice(tester);
      expect(service.recalledIds, isEmpty);
      await tester.tap(find.text(UiStrings.expeditionTimelineConflictEnd));
      await tester.pumpAndSettle();
      expect(service.recalledIds, [42]);
      expect(service.current, isNull);
      expect(service.events, [
        'catch-up',
        'recall:42',
        'presence:false',
        'startup-resumed',
      ]);
      expect(presence.started, isTrue);
      final recap = tester.widget<ExpeditionRecapScreen>(
        find.byType(ExpeditionRecapScreen),
      );
      expect(recap.result.deepestNode, 2);
      expect(recap.result.grantedRewards, same(originalRewards));
      expect(recap.result.defeated, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a changed run cannot be recalled by the old confirmation', (
    tester,
  ) async {
    final service = _ConflictService([]);
    final presence = await _openOverview(tester, service);
    try {
      await _reachConflictChoice(tester);
      final replacement = _run(43);
      service.current = replacement;
      await tester.tap(find.text(UiStrings.expeditionTimelineConflictEnd));
      await tester.pumpAndSettle();
      expect(service.recalledIds, [42]);
      expect(service.current, same(replacement));
      expect(service.events, ['catch-up', 'recall:42']);
      expect(presence.started, isFalse);
      expect(find.byType(ExpeditionRecapScreen), findsNothing);
      expect(find.text(UiStrings.expeditionRecallRacedSnack), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('ordinary catch-up failure never offers raw recall', (
    tester,
  ) async {
    final failure = StateError('ordinary catch-up failure');
    final service = _ConflictService([], failure: failure);
    final presence = await _openOverview(tester, service);
    final errors = <Object>[];
    try {
      await runZonedGuarded<Future<void>>(() async {
        await tester.tap(find.text(UiStrings.expeditionRecallButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(UiStrings.expeditionRecallConfirm));
        await tester.pumpAndSettle();
      }, (error, stack) => errors.add(error));
      expect(errors, [same(failure)]);
      expect(service.events, ['catch-up']);
      expect(service.recalledIds, isEmpty);
      expect(service.current?.id, 42);
      expect(presence.started, isFalse);
      expect(
        find.text(UiStrings.expeditionTimelineConflictTitle),
        findsNothing,
      );
      expect(find.byType(ExpeditionRecapScreen), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
