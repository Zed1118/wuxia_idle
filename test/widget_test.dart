import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/damage_popup.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

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
  projectileMs: 30,
  hitFlashMs: 30,
);

const _normalResult = AttackResult(
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

const _criticalResult = AttackResult(
  finalDamage: 3600,
  mainDamage: 3600,
  quakeDamage: 0,
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
  mainDamage: 0,
  quakeDamage: 0,
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
    state = state.copyWith(actionLog: [...state.actionLog, ...actions]);
  }

  void setResult(BattleResult result) {
    state = state.copyWith(result: result);
  }

  /// 模拟引擎消费完玩家排队技能后清空 pending（指令台"待发"印随之消失）。
  void clearPending() {
    state = state.copyWith(pendingUltimates: const {});
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
    final init =
        initialState ?? BattleState.initial(leftTeam: left, rightTeam: right);

    late _TestBattleNotifier notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(() {
            notifier = _TestBattleNotifier(init);
            return notifier;
          }),
        ],
        child: const MaterialApp(home: BattleScreen(animConfig: _testAnim)),
      ),
    );
    return notifier;
  }

  Finder assetImage(String path) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == path,
  );

  // ── T14 静态布局 ────────────────────────────────────────────────────────

  testWidgets('BattleScreen 渲染 3v3 + 顶栏 + 6 个 CharacterAvatar', (
    WidgetTester tester,
  ) async {
    await pumpBattle(tester);

    expect(find.text('战斗 3 v 2'), findsOneWidget);
    expect(find.byType(CharacterAvatar), findsNWidgets(6));
    expect(find.text('萧夜寒'), findsNWidgets(2));
    expect(find.text('黑风寨主'), findsOneWidget);
    expect(find.text('毒娘子'), findsOneWidget);
  });

  testWidgets('死亡角色 opacity = 0.45（P0-2 放大后灰化）', (WidgetTester tester) async {
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
    expect(opacity.opacity, 0.45);
  });

  testWidgets('Boss 头像叠加 MJ 圆环外框', (WidgetTester tester) async {
    await setSurface(tester);
    final (left, right) = BattleDemo.mockTeams();
    final boss = right.first.copyWith(isBoss: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleProvider.overrideWith(
            () => _TestBattleNotifier(
              BattleState.initial(
                leftTeam: left,
                rightTeam: [boss, ...right.skip(1)],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: BattleScreen(animConfig: _testAnim)),
      ),
    );
    await tester.pump();

    expect(assetImage(WuxiaUi.bossFrameLarge), findsOneWidget);
  });

  // ── T15 dispose ─────────────────────────────────────────────────────────

  testWidgets(
    'BattleScreen AnimationController 正确 dispose，无 ticker 泄漏（P0-2 后含受击闪/弹道）',
    (WidgetTester tester) async {
      await pumpBattle(tester);
      // 替换为空 widget 触发 _BattleScreenState.dispose()
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    },
  );

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

  testWidgets('actionLog 增长 - 暴击飘字出现显示伤害数字', (WidgetTester tester) async {
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

  testWidgets('actionLog 增长 - 闪避飘字显示「闪」字', (WidgetTester tester) async {
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

  testWidgets('T16 战斗结束 → 弹出胜负仪式 overlay', (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);
    expect(find.byType(VictoryOverlay), findsNothing);

    notifier.setResult(BattleResult.leftWin);
    await tester.pumpAndSettle(); // 等待 showGeneralDialog 280ms 过渡动画完成

    expect(find.byType(VictoryOverlay), findsOneWidget);
    expect(find.text(UiStrings.victoryTitle), findsOneWidget); // '勝'
    expect(find.text(UiStrings.battleContinue), findsOneWidget); // '继续'
  });

  testWidgets('T1 指令台大招按钮 enabled 状态随内力 / 重点角色变化', (
    WidgetTester tester,
  ) async {
    // BattleDemo mock 数据（每角色 1 个示例大招 cost=800，key=skill_cmd_<id>_demo_ult_<id>）：
    //   left[0] 萧夜寒 id=1 currentIf=5400 → ready
    //   left[2] 苏锦书 id=3 currentIf=600  → NOT ready（内力不够）
    await pumpBattle(tester);

    // 默认重点角色 = left[0]，其大招按钮 enabled。
    final focus0Ult = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('skill_cmd_1_demo_ult_1')),
    );
    expect(focus0Ult.enabled, true, reason: 'left[0] 萧夜寒 内力够');

    // 切重点角色到 left[2]（苏锦书 内力不够）→ 其大招按钮 disabled。
    await tester.tap(find.byKey(const ValueKey('focus_chip_2')));
    await tester.pump();
    final focus2Ult = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('skill_cmd_3_demo_ult_3')),
    );
    expect(focus2Ult.enabled, false, reason: 'left[2] 苏锦书 内力不够');
  });

  testWidgets('T1 技能按下盖「待发」印 + 禁用，引擎消费后恢复', (WidgetTester tester) async {
    final notifier = await pumpBattle(tester);

    const ultKey = ValueKey('skill_cmd_1_demo_ult_1');
    expect(find.text(UiStrings.skillPendingStamp), findsNothing);

    // 按下 left[0] 萧夜寒大招 → pending 写入。
    await tester.tap(find.byKey(ultKey));
    await tester.pump();

    expect(notifier.state.pendingUltimates[1]?.id, 'demo_ult_1');
    expect(tester.widget<ElevatedButton>(find.byKey(ultKey)).enabled, false,
        reason: '排队后禁用，避免连按');
    expect(find.text(UiStrings.skillPendingStamp), findsOneWidget,
        reason: '盖「待发」印');

    // 模拟引擎消费完该 pending（actor 行动后引擎清 pendingUltimates）。
    notifier.clearPending();
    await tester.pump();

    expect(tester.widget<ElevatedButton>(find.byKey(ultKey)).enabled, true,
        reason: '消费后恢复可用');
    expect(find.text(UiStrings.skillPendingStamp), findsNothing);
  });

  // ── B2 大招题字 overlay ───────────────────────────────────────────────────

  testWidgets('B2 大招 action → 题字 overlay 显示招式名', (tester) async {
    const ultSkill = SkillDef(
      id: 't_ult',
      name: '山岳崩',
      description: '',
      type: SkillType.ultimate,
      powerMultiplier: 5000,
      internalForceCost: 1000,
      cooldownTurns: 5,
      requiresManualTrigger: true,
      parentTechniqueDefId: null,
      visualEffect: '',
    );
    final notifier = await pumpBattle(tester);
    expect(find.byType(UltimateCaptionContent), findsNothing);

    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 1,
        targetId: 11,
        skill: ultSkill,
        attackResult: _normalResult,
        description: '萧夜寒大招',
      ),
    ]);
    await tester.pump(); // ref.listen → show()
    await tester.pump(); // build
    expect(find.text('山岳崩'), findsNWidgets(2)); // 题字描边+填充两层

    await tester.pumpAndSettle(const Duration(seconds: 3)); // 收尾动画
  });

  testWidgets('B2 普攻 action → 不弹题字', (tester) async {
    final notifier = await pumpBattle(tester);
    notifier.appendActions(const [
      BattleAction(
        tick: 1,
        actorId: 1,
        targetId: 11,
        attackResult: _normalResult,
        description: '普攻',
      ),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(UltimateCaptionContent), findsNothing);
  });
}
