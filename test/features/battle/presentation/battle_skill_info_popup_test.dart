import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

/// 技能方块手势：两段点选下「长按方块 = 弹技能简介浮层」(直接读 SkillDef 活数据)。
///
/// 点击 = 释放(single 进待发态 / aoe 一键出手)由 [battle_tap_skill_test] 守，
/// 不在此重复;这里只验「长按 = 简介浮层、不下发命令」。

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

class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void step() {}
}

/// 单体强力技(可打断破招技),带活描述/倍率/耗内/CD。
const _single = SkillDef(
  id: 'single1',
  name: '截脉手',
  description: '一指点向对手脉门，逼其招式中断。',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 200,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
  canInterrupt: true,
  style: TechniqueSchool.lingQiao,
);

/// 群体大招(aoe)。
const _aoe = SkillDef(
  id: 'aoe1',
  name: '万剑诀',
  description: '剑气漫天，覆盖全场之敌。',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 800,
  cooldownTurns: 5,
  requiresManualTrigger: true,
  visualEffect: '',
  targetType: TargetType.aoe,
);

Future<_TestBattleNotifier> _pumpWith(
  WidgetTester tester,
  List<BattleCharacter> left,
  List<BattleCharacter> right, {
  bool allowPlayerIntervention = true,
}) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      child: MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          allowPlayerIntervention: allowPlayerIntervention,
        ),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  group('长按技能方块 → 简介浮层', () {
    testWidgets('长按单体技方块 → 浮层含 description + 倍率/耗内/CD/目标/特性',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.longPress(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pumpAndSettle();

      // 描述活文本。
      expect(find.text('一指点向对手脉门，逼其招式中断。'), findsOneWidget);
      // 倍率(1500)、耗内(200)、CD(2)在浮层某处可见。
      expect(find.textContaining('1500'), findsWidgets);
      expect(find.textContaining('200'), findsWidgets);
      // 目标类型(单体)。
      expect(find.textContaining('单体'), findsWidgets);
      // 特性:可打断 → 破招。
      expect(find.textContaining('破招'), findsWidgets);
    });

    testWidgets('长按群体大招方块 → 浮层显示目标=群体', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.longPress(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pumpAndSettle();

      expect(find.text('剑气漫天，覆盖全场之敌。'), findsOneWidget);
      expect(find.textContaining('群体'), findsWidgets);
    });

    testWidgets('长按方块只弹浮层，不下发命令', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.longPress(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pumpAndSettle();

      // 长按 = 查看简介,不下发命令。
      expect(notifier.state.pendingUltimates[1], isNull,
          reason: '长按只弹浮层，不下发命令');
    });
  });
}
