import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/projectile_trail.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20.0,
  damagePopupFloatPx: 20.0,
  damagePopupMs: 100,
  actionIntervalMs: 50,
  fastForwardIntervalMs: 20,
  shakeOffsetPx: 1.0,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
);

/// no-op advance：避免 Timer 触发时读 GameRepository 崩溃。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  void appendActions(List<BattleAction> actions) {
    state = state.copyWith(actionLog: [...state.actionLog, ...actions]);
  }
}

Future<_TestBattleNotifier> _pumpBattle(WidgetTester tester) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() {
          notifier = _TestBattleNotifier(
            BattleState.initial(leftTeam: left, rightTeam: right),
          );
          return notifier;
        }),
      ],
      child: const MaterialApp(home: BattleScreen(animConfig: _testAnim)),
    ),
  );
  await tester.pump();
  return notifier;
}

const _attackResult = AttackResult(
  finalDamage: 1500,
  mainDamage: 1500,
  quakeDamage: 0,
  isCritical: false,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.0,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'test',
);

void main() {
  testWidgets('日志默认收起，点开显历史，再点收起（P0-2 Task6）', (tester) async {
    await _pumpBattle(tester);

    // 默认：日志抽屉关
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);

    // 点顶栏日志按钮 → 抽屉开
    await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsOneWidget);

    // 再点 → 收起
    await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);
  });

  testWidgets('攻击命中时出现弹道 ProjectileTrail（P0-2 Task7·不污染 state）',
      (tester) async {
    final notifier = await _pumpBattle(tester);
    expect(find.byType(ProjectileTrail), findsNothing);

    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 1, // 萧夜寒 left[0]
        targetId: 11, // 黑风寨主 right[0]
        attackResult: _attackResult,
        description: '普攻测试',
      ),
    ]);
    await tester.pump(); // ref.listen → _playAction setState
    await tester.pump(); // build
    expect(find.byType(ProjectileTrail), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle(); // 收尾弹道动画
  });

  testWidgets('3v3 战场在压矮高度不 RenderFlex overflow（P0-2 fix·2026-06-04）',
      (tester) async {
    // Codex 验收报 1280×720 下 _TeamColumn overflow 47px;此处用更矮的 560 高
    // 强制旧布局必溢出,验 Expanded+FittedBox(scaleDown) 修复后无异常。
    await tester.binding.setSurfaceSize(const Size(1100, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (left, right) = BattleDemo.mockTeams();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(
            () => _TestBattleNotifier(
              BattleState.initial(leftTeam: left, rightTeam: right),
            ),
          ),
        ],
        child: const MaterialApp(home: BattleScreen(animConfig: _testAnim)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
