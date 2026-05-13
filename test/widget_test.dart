import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/combat/battle_state.dart';
import 'package:wuxia_idle/combat/damage_calculator.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/providers/battle_providers.dart';
import 'package:wuxia_idle/ui/battle/battle_demo.dart';
import 'package:wuxia_idle/ui/battle/battle_screen.dart';
import 'package:wuxia_idle/ui/battle/character_avatar.dart';
import 'package:wuxia_idle/ui/battle/damage_popup.dart';

/// 短时序动画配置，加速 widget test 运行。
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
);

const _normalResult = AttackResult(
  finalDamage: 1500,
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

const _criticalResult = AttackResult(
  finalDamage: 3600,
  isCritical: true,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.5,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'crit test',
);

const _dodgeResult = AttackResult(
  finalDamage: 0,
  isCritical: false,
  isDodged: true,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.0,
  defenseRate: 0.0,
  evasionRate: 0.15,
  appliedEffects: <String>[],
  formulaBreakdown: 'dodged',
);

/// 测试专用 BattleNotifier：
/// - `build()` 返回外部注入的初始 state（mock 队伍 + 空 actionLog）。
/// - `advance()` 改为 no-op，避免 Timer 触发时调 [numbersConfigProvider]
///   读 `GameRepository.instance` 崩溃（测试环境不加载 yaml）。
/// - `appendActions` / `setResult` 让测试手动驱动 actionLog 与 result，模拟
///   引擎产生的结果。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {
    // no-op：测试通过 appendActions 显式驱动
  }

  void appendActions(List<BattleAction> actions) {
    state = state.copyWith(
      actionLog: [...state.actionLog, ...actions],
    );
  }

  void setResult(BattleResult result) {
    state = state.copyWith(result: result);
  }
}

void main() {
  Future<void> setSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  /// pump BattleScreen with override notifier，返回 notifier 引用供测试控制。
  Future<_TestBattleNotifier> pumpBattle(
    WidgetTester tester, {
    BattleState? initialState,
  }) async {
    await setSurface(tester);
    final (left, right) = BattleDemo.mockTeams();
    final init = initialState ??
        BattleState.initial(leftTeam: left, rightTeam: right);

    late _TestBattleNotifier notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(() {
            notifier = _TestBattleNotifier(init);
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: BattleScreen(animConfig: _testAnim),
        ),
      ),
    );
    return notifier;
  }

  // ── T14 静态布局 ────────────────────────────────────────────────────────

  testWidgets('BattleScreen 渲染 3v3 + 顶栏 + 6 个 CharacterAvatar',
      (WidgetTester tester) async {
    await pumpBattle(tester);

    expect(find.text('战斗 3 v 2'), findsOneWidget);
    expect(find.byType(CharacterAvatar), findsNWidgets(6));
    expect(find.text('萧夜寒'), findsNWidgets(2));
    expect(find.text('黑风寨主'), findsOneWidget);
    expect(find.text('毒娘子'), findsOneWidget);
  });

  testWidgets('死亡角色 opacity = 0.3', (WidgetTester tester) async {
    await pumpBattle(tester);

    final avatars = tester.widgetList<CharacterAvatar>(
      find.byType(CharacterAvatar),
    );
    final dead = avatars.where((a) => !a.character.isAlive).toList();
    expect(dead.length, 1);

    final deadAvatarFinder = find.byWidgetPredicate(
      (w) => w is CharacterAvatar && !w.character.isAlive,
    );
    final opacity = tester
        .widgetList<Opacity>(
          find.descendant(of: deadAvatarFinder, matching: find.byType(Opacity)),
        )
        .first;
    expect(opacity.opacity, 0.3);
  });

  // ── T15 dispose ─────────────────────────────────────────────────────────

  testWidgets('BattleScreen 7 个 AnimationController 正确 dispose，无 ticker 泄漏',
      (WidgetTester tester) async {
    await pumpBattle(tester);
    // 替换为空 widget 触发 _BattleScreenState.dispose()
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });

  // ── DamagePopup 独立测试（不依赖 Riverpod） ────────────────────────────

  testWidgets('DamagePopup 普通伤害显示数字', (WidgetTester tester) async {
    const data = DamagePopupData(id: 0, text: '2400', type: PopupType.normal);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DamagePopup(
              data: data,
              config: _testAnim,
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('2400'), findsOneWidget);
  });

  testWidgets('DamagePopup 闪避显示「闪」字', (WidgetTester tester) async {
    const data = DamagePopupData(id: 0, text: '闪', type: PopupType.dodge);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DamagePopup(
              data: data,
              config: _testAnim,
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('闪'), findsOneWidget);
  });

  testWidgets('DamagePopup 克制标记 ⬆ 正确渲染', (WidgetTester tester) async {
    const data = DamagePopupData(
      id: 0,
      text: '3000',
      type: PopupType.normal,
      hasCounterUp: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DamagePopup(
              data: data,
              config: _testAnim,
              onComplete: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('3000'), findsOneWidget);
    expect(find.text('⬆'), findsOneWidget);
  });

  // ── T16 actionLog 增长 → ref.listen → 触发动画 ──────────────────────────

  testWidgets('actionLog 增长 - 普攻飘字出现', (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);
    expect(find.byType(DamagePopup), findsNothing);

    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 1, // 萧夜寒 left[0]
        targetId: 11, // 黑风寨主 right[0]
        attackResult: _normalResult,
        description: '普攻测试',
      ),
    ]);
    await tester.pump(); // ref.listen → setState
    await tester.pump(); // setState → build

    expect(find.byType(DamagePopup), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
  });

  testWidgets('actionLog 增长 - 暴击飘字出现显示伤害数字',
      (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);
    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 2, // 柳青衫 left[1]
        targetId: 12, // 影刺 right[1]
        attackResult: _criticalResult,
        description: '暴击测试',
      ),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('3600'), findsOneWidget);
  });

  testWidgets('actionLog 增长 - 闪避飘字显示「闪」字',
      (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);
    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 11,
        targetId: 1,
        attackResult: _dodgeResult,
        description: '闪避测试',
      ),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('闪'), findsOneWidget);
  });

  // ── T16 新增 ────────────────────────────────────────────────────────────

  testWidgets('T16 战斗结束 → 弹出结算 dialog', (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);
    expect(find.byType(AlertDialog), findsNothing);

    notifier.setResult(BattleResult.leftWin);
    await tester.pump(); // ref.listen → addPostFrameCallback
    await tester.pump(); // postFrame → showDialog

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
  });

  testWidgets('T16 大招按钮 - 内力不够 / 内力够 enabled 状态正确',
      (WidgetTester tester) async {
    // BattleDemo mock 数据：
    //   left[0] 萧夜寒  currentIf=5400 cost=800 → ready
    //   left[1] 柳青衫  currentIf=1800 cost=800 → ready
    //   left[2] 苏锦书  currentIf=600  cost=800 → NOT ready（内力不够）
    await pumpBattle(tester);

    final buttons = tester
        .widgetList<ElevatedButton>(find.byType(ElevatedButton))
        .toList();
    expect(buttons.length, 3, reason: '底栏 3 个大招按钮');
    expect(buttons[0].enabled, true, reason: 'left[0] 萧夜寒 内力够');
    expect(buttons[1].enabled, true, reason: 'left[1] 柳青衫 内力够');
    expect(buttons[2].enabled, false, reason: 'left[2] 苏锦书 内力不够');
  });

  testWidgets('T16 大招按下后置灰，actor 行动后解除',
      (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);

    // 按下 left[0] 萧夜寒大招
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    // 按钮置灰
    final buttonsAfterTap = tester
        .widgetList<ElevatedButton>(find.byType(ElevatedButton))
        .toList();
    expect(buttonsAfterTap[0].enabled, false,
        reason: '按下后立刻置灰，避免连按');

    // 模拟 actor (id=1=萧夜寒) 行动（actionLog 新增）
    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 1,
        targetId: 11,
        attackResult: _normalResult,
        description: '萧夜寒行动',
      ),
    ]);
    await tester.pump();
    await tester.pump();

    // 按钮解除置灰
    final buttonsAfterAction = tester
        .widgetList<ElevatedButton>(find.byType(ElevatedButton))
        .toList();
    expect(buttonsAfterAction[0].enabled, true,
        reason: 'actor 行动后大招按钮恢复可用');
  });
}
