import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_gate.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 假扫荡单位：起手即抛 → 触发 SweepScreen 装配失败 halt 路径，
/// 可在无 Isar/GameRepository 的轻量 widget 测下验「战败 recap」渲染。
class _ThrowingUnit implements SweepUnit {
  @override
  String get label => '试炼一关';
  @override
  String get battleHint => '试炼一关';
  @override
  String? get sceneBackgroundPath => null;
  @override
  BgmTrack get bgmTrack => BgmTrack.tower;
  @override
  Future<void> startBattle(WidgetRef ref) async => throw StateError('boom');
  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) async => null;
}

class _HeadlessUnit implements SweepUnit, Phase0aHeadlessSweepUnit {
  _HeadlessUnit(this.result);

  final Phase0aSweepRunResult result;
  int startCalls = 0;
  int settleCalls = 0;

  @override
  String get label => 'headless';
  @override
  String get battleHint => 'headless';
  @override
  String? get sceneBackgroundPath => null;
  @override
  BgmTrack get bgmTrack => BgmTrack.tower;
  @override
  bool get supportsPhase0aHeadless => true;
  @override
  Future<void> startBattle(WidgetRef ref) async => startCalls++;
  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) async => null;
  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(WidgetRef ref) async =>
      result;
  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    CombatSettlementSnapshot settlement,
  ) async {
    settleCalls++;
    return const SweepBattleOutcome(expGained: 7);
  }
}

class _PendingHeadlessUnit extends _HeadlessUnit {
  _PendingHeadlessUnit()
    : completer = Completer<Phase0aSweepRunResult>(),
      super(const Phase0aSweepRunResult.timeout());

  final Completer<Phase0aSweepRunResult> completer;

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(WidgetRef ref) =>
      completer.future;
}

final _victory = CombatSettlementSnapshot(
  result: BattleResult.leftWin,
  totalTicks: 1,
  hadActions: true,
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
  participants: const [
    CombatParticipantSnapshot(characterId: 1, currentHp: 0, maxHp: 10),
  ],
  skillCasts: const [],
  totalDamage: 0,
  criticalCount: 0,
  damageByCharacterId: const {},
);

void main() {
  tearDown(() => Phase0aSweepGate.testOverride = null);

  testWidgets('装配失败 → 战败 recap：显标题/原因/返回按钮 + 周目行', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(
            units: [_ThrowingUnit()],
            unitName: '问鼎江湖',
            cycle: 2,
          ),
        ),
      ),
    );
    // postFrameCallback → _startCurrent → startBattle 抛 → recordDefeat → recap。
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepDefeatReason), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapBack), findsOneWidget);
    // 战败仍记一行「通关 0 关」。
    expect(find.text(UiStrings.sweepRecapStages(0)), findsOneWidget);
    // recap 告知扫的是第几周目（用户要求：扫完知道扫的是哪个周目）。
    expect(find.text(UiStrings.sweepRecapCycle(2)), findsOneWidget);
  });

  testWidgets('灰度开：headless 胜利直结，不挂 BattleScreen/不走旧起手', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Phase0aSweepGate.testOverride = true;
    final unit = _HeadlessUnit(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unit.startCalls, 0);
    expect(unit.settleCalls, 1);
    expect(find.byType(BattleScreen), findsNothing);
    expect(find.text(UiStrings.sweepRecapCompleted), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapExp(7)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('灰度开：headless 败北 halt，不结算收益', (tester) async {
    Phase0aSweepGate.testOverride = true;
    final unit = _HeadlessUnit(Phase0aSweepRunResult.terminal(_defeat));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unit.startCalls, 0);
    expect(unit.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapStages(0)), findsOneWidget);
  });

  testWidgets('灰度开：timeout 单独报告，不伪装战败且不结算', (tester) async {
    Phase0aSweepGate.testOverride = true;
    final unit = _HeadlessUnit(const Phase0aSweepRunResult.timeout());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [unit], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unit.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapTimedOut(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepTimeoutReason), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapDefeated(1)), findsNothing);
  });

  testWidgets('headless 进行中系统返回转为安全停止，当前关结完且不跑下一关', (tester) async {
    Phase0aSweepGate.testOverride = true;
    final first = _PendingHeadlessUnit();
    final second = _HeadlessUnit(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SweepScreen(units: [first, second], unitName: 'test', cycle: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    first.completer.complete(Phase0aSweepRunResult.terminal(_victory));
    await tester.pumpAndSettle();

    expect(first.settleCalls, 1);
    expect(second.startCalls, 0);
    expect(second.settleCalls, 0);
    expect(find.text(UiStrings.sweepRecapStopped), findsOneWidget);
    expect(find.text(UiStrings.sweepRecapStages(1)), findsOneWidget);
  });
}
