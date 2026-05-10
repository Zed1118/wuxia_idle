import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/combat/battle_state.dart';
import 'package:wuxia_idle/combat/damage_calculator.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/ui/battle/battle_demo.dart';
import 'package:wuxia_idle/ui/battle/battle_screen.dart';
import 'package:wuxia_idle/ui/battle/character_avatar.dart';
import 'package:wuxia_idle/ui/battle/damage_popup.dart';

/// 短时序动画配置，加速 T15 widget test 运行。
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

/// 完整 AttackResult（const 构造，用于 mock 数据）。
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
  appliedEffects: const <String>[],
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
  appliedEffects: const <String>[],
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
  appliedEffects: const <String>[],
  formulaBreakdown: 'dodged',
);

// ─── 测试入口 ────────────────────────────────────────────────────────────────

/// T14 静态布局 smoke test：BattleScreen 用 BattleDemo mock 状态渲染不崩，
/// 6 个角色全部出现，标题反映存活人数（左 3 / 右 2，因 demo 右队 #2 已死）。
///
/// T15 追加：AnimationController dispose / 飘字渲染 / actionLog 串行播放。
///
/// 窗口锁 1280×720（phase1_tasks T14 §791 16:9 验收基线，desktop 默认尺寸）。
void main() {
  Future<void> setSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpBattle(WidgetTester tester) async {
    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: BattleScreen(state: BattleDemo.build()),
      ),
    );
  }

  // ── T14 ─────────────────────────────────────────────────────────────────

  testWidgets('BattleScreen 渲染 3v3 + 顶栏 + 6 个 CharacterAvatar',
      (WidgetTester tester) async {
    await pumpBattle(tester);

    // 顶栏标题：左 3 活 / 右 2 活
    expect(find.text('战斗 3 v 2'), findsOneWidget);

    // 6 个 CharacterAvatar
    expect(find.byType(CharacterAvatar), findsNWidgets(6));

    // 角色名字渲染（左队角色名同时出现在头像下方与底栏大招按钮里 = 2 次；
    // 右队仅在头像下方 = 1 次）。
    expect(find.text('萧夜寒'), findsNWidgets(2));
    expect(find.text('黑风寨主'), findsOneWidget);
    expect(find.text('毒娘子'), findsOneWidget);
  });

  testWidgets('死亡角色 opacity = 0.3', (WidgetTester tester) async {
    await pumpBattle(tester);

    // demo 右队 #2「毒娘子」isAlive=false，CharacterAvatar 内层 Opacity=0.3
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

  // ── T15 ─────────────────────────────────────────────────────────────────

  testWidgets('BattleScreen 7 个 AnimationController 正确 dispose，无 ticker 泄漏',
      (WidgetTester tester) async {
    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(
          state: BattleDemo.build(),
          animConfig: _testAnim,
        ),
      ),
    );
    // 替换为空 widget 触发 _BattleScreenState.dispose()
    // Flutter test framework 会在 tearDown 检查 ticker 泄漏，泄漏则测试失败
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  });

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

  testWidgets('actionLog 串行播放 - 普攻飘字在触发后出现', (WidgetTester tester) async {
    final baseState = BattleDemo.build();
    // actorId=1（萧夜寒 left[0]）攻击 targetId=11（黑风寨主 right[0]）
    const action = BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 11,
      attackResult: _normalResult,
      description: '普攻测试',
    );
    final state = baseState.copyWith(actionLog: [action]);

    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(state: state, animConfig: _testAnim),
      ),
    );

    // 定时器尚未触发，无飘字
    expect(find.byType(DamagePopup), findsNothing);

    // 推进超过 actionIntervalMs（50ms），触发第一次 timer callback
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(); // 处理 setState

    // 飘字应出现，显示伤害数字
    expect(find.byType(DamagePopup), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
  });

  testWidgets('actionLog 串行播放 - 暴击飘字出现显示伤害数字',
      (WidgetTester tester) async {
    final baseState = BattleDemo.build();
    const action = BattleAction(
      tick: 1,
      actorId: 2,   // 柳青衫 left[1]
      targetId: 12, // 影刺 right[1]
      attackResult: _criticalResult,
      description: '暴击测试',
    );
    final state = baseState.copyWith(actionLog: [action]);

    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(state: state, animConfig: _testAnim),
      ),
    );

    // 推进超过 actionIntervalMs（50ms），timer 触发
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.text('3600'), findsOneWidget);
  });

  testWidgets('actionLog 串行播放 - 闪避飘字显示「闪」字',
      (WidgetTester tester) async {
    final baseState = BattleDemo.build();
    const action = BattleAction(
      tick: 1,
      actorId: 11, // 黑风寨主 right[0]
      targetId: 1, // 萧夜寒 left[0]
      attackResult: _dodgeResult,
      description: '闪避测试',
    );
    final state = baseState.copyWith(actionLog: [action]);

    await setSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(state: state, animConfig: _testAnim),
      ),
    );

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.text('闪'), findsOneWidget);
  });
}
