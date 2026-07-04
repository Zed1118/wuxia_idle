import 'dart:ui';

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
import 'package:wuxia_idle/shared/strings.dart';

/// 技能目标快捷选择栏 widget 测试。
///
/// 复用 [battle_tap_skill_test] 的 no-op advance + spy interveneNow 体例:锁死
/// 「1 敌立即放 / ≥2 敌选择栏 → 点 chip 出手 / aoe 不显选择栏」的 UI 契约。

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

  int? lastInterveneChar;
  SkillDef? lastInterveneSkill;
  int? lastInterveneTarget;
  int interveneCount = 0;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void step() {}

  @override
  void interveneNow(int characterId, SkillDef skill, {int? targetId}) {
    lastInterveneChar = characterId;
    lastInterveneSkill = skill;
    lastInterveneTarget = targetId;
    interveneCount++;
  }
}

/// 单体技(默认 targetType.single)。
const _single = SkillDef(
  id: 'single1',
  name: '截脉手',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 200,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);

/// 群体技(targetType.aoe)。
const _aoe = SkillDef(
  id: 'aoe1',
  name: '万剑诀',
  description: '',
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
  Size size = const Size(1280, 720),
}) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(size);
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
  group('单体技 · 唯一敌人立即放', () {
    testWidgets('1 敌时点单体技 → 立即出手打该敌，不进待发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final soloEnemy = right.first; // characterId 11
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        [soloEnemy],
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 1, reason: '唯一敌人 → 点击即放');
      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, soloEnemy.characterId);
      expect(
        find.text(UiStrings.skillPendingStamp),
        findsNothing,
        reason: '不进待发态',
      );
    });

    testWidgets('1 敌时点 aoe → 立即出手（targetId 空）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        [right.first],
      );
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();
      expect(notifier.interveneCount, 1);
      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.lastInterveneTarget, isNull);
    });
  });
}
