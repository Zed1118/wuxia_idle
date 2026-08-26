import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_screen.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/strings.dart';

final _victory = CombatSettlementSnapshot(
  result: BattleResult.leftWin,
  totalTicks: 1,
  hadActions: true,
  playerCharacterId: 1,
  participants: const [
    CombatParticipantSnapshot(characterId: 1, currentHp: 10, maxHp: 10),
  ],
  skillCasts: const [],
  totalDamage: 1,
  criticalCount: 0,
  damageByCharacterId: const {1: 1},
);

final _defeat = CombatSettlementSnapshot(
  result: BattleResult.rightWin,
  totalTicks: 1,
  hadActions: true,
  playerCharacterId: 1,
  participants: const [
    CombatParticipantSnapshot(characterId: 1, currentHp: 0, maxHp: 10),
  ],
  skillCasts: const [],
  totalDamage: 0,
  criticalCount: 0,
  damageByCharacterId: const {},
);

class _FakeUnit implements SweepUnit {
  _FakeUnit(this.result);

  final Phase0aSweepRunResult result;
  int settleCalls = 0;
  int runCalls = 0;
  Phase0aBotTacticPolicy? receivedPolicy;

  @override
  String get label => 'headless';

  @override
  String get battleHint => 'headless';

  @override
  String? get sceneBackgroundPath => null;

  @override
  BgmTrack get bgmTrack => BgmTrack.tower;

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) async {
    runCalls++;
    receivedPolicy = policy;
    return result;
  }

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    Phase0aSweepRunResult result,
  ) async {
    settleCalls++;
    return const SweepBattleOutcome(expGained: 7);
  }
}

class _PendingUnit extends _FakeUnit {
  _PendingUnit() : super(const Phase0aSweepRunResult.timeout());

  final completer = Completer<Phase0aSweepRunResult>();

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) {
    runCalls++;
    receivedPolicy = policy;
    return completer.future;
  }
}

class _ThrowingUnit extends _FakeUnit {
  _ThrowingUnit() : super(const Phase0aSweepRunResult.timeout());

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) {
    runCalls++;
    receivedPolicy = policy;
    return Future<Phase0aSweepRunResult>.error(StateError('boom'));
  }
}

Future<void> _chooseAssault(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.text(UiStrings.botTacticAssault));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('快速重演明确显示独立语义与实际参与者报告', (tester) async {
    final unit = _FakeUnit(
      Phase0aSweepRunResult.terminal(
        _victory,
        expectedParticipantId: 1,
        participantName: '掌门甲',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(
            units: [unit],
            unitName: '黑风岭',
            cycle: 1,
            presentationMode: HeadlessRunPresentationMode.mainlineReplay,
          ),
        ),
      ),
    );
    expect(
      find.text(UiStrings.headlessReplayTacticSelectionHint),
      findsOneWidget,
    );
    await _chooseAssault(tester);
    expect(find.text(UiStrings.headlessReplayRecapCompleted), findsOneWidget);
    expect(
      find.text(UiStrings.headlessReplayParticipant('掌门甲')),
      findsOneWidget,
    );
  });

  testWidgets('headless 胜利直结并显示 recap', (tester) async {
    final unit = _FakeUnit(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await _chooseAssault(tester);

    expect(unit.settleCalls, 1);
    expect(find.text(UiStrings.sweepRecapCompleted), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapExp(7)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('headless timeout 单独显示超时 recap，不结算', (tester) async {
    final unit = _FakeUnit(const Phase0aSweepRunResult.timeout());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await _chooseAssault(tester);

    expect(unit.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapTimedOut(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsNothing);
  });

  testWidgets('headless 非 leftWin 终局 halt 且不结算奖励', (tester) async {
    final unit = _FakeUnit(Phase0aSweepRunResult.terminal(_defeat));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await _chooseAssault(tester);

    expect(unit.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapCompleted), findsNothing);
  });

  testWidgets('headless 失败 halt 并显示战败 recap', (tester) async {
    final unit = _ThrowingUnit();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await _chooseAssault(tester);

    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepDefeatReason), findsOneWidget);
  });

  testWidgets('运行中返回请求安全停止，当前关完成后不启动下一关', (tester) async {
    final first = _PendingUnit();
    final second = _FakeUnit(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [first, second], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(UiStrings.botTacticAssault));
    await tester.pump();
    await tester.binding.handlePopRoute();
    first.completer.complete(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpAndSettle();

    expect(second.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapStopped), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapStages(1)), findsOneWidget);
  });

  testWidgets('选择前零运行，三战术逐值传入真实 SweepUnit 边界', (tester) async {
    final cases = <(String, Phase0aBotTactic)>[
      (UiStrings.botTacticSeekGap, Phase0aBotTactic.seekGap),
      (UiStrings.botTacticAssault, Phase0aBotTactic.assault),
      (UiStrings.botTacticSteadyGuard, Phase0aBotTactic.steadyGuard),
    ];
    for (final entry in cases) {
      final unit = _FakeUnit(Phase0aSweepRunResult.terminal(_victory));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SweepScreen(
              key: ValueKey(entry.$2),
              units: [unit],
              unitName: 'test',
              cycle: 1,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(UiStrings.botTacticSelectionTitle), findsOneWidget);
      expect(unit.runCalls, 0);
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();

      expect(unit.runCalls, 1);
      expect(unit.receivedPolicy?.tactic, entry.$2);
      expect(find.text(UiStrings.sweepRecapCompleted), findsOneWidget);
    }
  });
}
