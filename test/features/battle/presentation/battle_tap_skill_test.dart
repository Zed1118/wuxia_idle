import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 战斗交互重做：两段点选 tap 释放 widget 测试。
///
/// 复用 [battle_command_console_test] 的 no-op advance notifier 体例，避免 Timer
/// 触发时读 GameRepository 崩溃；tap 释放走 `interveneNow` 立即插队出手(预支 AP
/// 归零)属引擎层，由真玩 + Codex 验收，这里用 spy override `interveneNow` 只锁死
/// 「点 aoe 一键出手 / 点 single 进待发态→点敌出手 targetId / 取消 / 门控」UI 契约。

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
  group('两段点选 · tap 释放', () {
    testWidgets('点 aoe 技能按钮 → 立即出手(targetId 空走 AI)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();
      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.lastInterveneChar, 1);
      expect(notifier.lastInterveneTarget, isNull);
    });

    testWidgets('点 single 技能按钮进待发态(不出手) → 点敌头像出手指向该敌', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '单体技点按钮只进待发态');
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.lastInterveneSkill?.id, 'single1');
      expect(notifier.lastInterveneTarget, 11);
    });

    testWidgets('点 single 技能按钮 → 按钮显示待发视觉但不写 domain pending', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      expect(find.text(UiStrings.skillPendingStamp), findsNothing);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(find.text(UiStrings.skillPendingStamp), findsWidgets);
      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsOneWidget,
      );
      expect(notifier.state.pendingUltimates[1], isNull);
      expect(notifier.interveneCount, 0);
    });

    testWidgets('single 待发态敌头像显示可选提示，鼠标悬停目标显示锁定', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();

      expect(find.text(UiStrings.skillTargetable), findsWidgets);
      expect(
        find.byKey(ValueKey('enemy_target_hint_${right.first.characterId}')),
        findsOneWidget,
      );

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(enemy));
      await tester.pump();

      expect(find.text(UiStrings.skillTargetLocked), findsOneWidget);
      await mouse.removePointer();
    });

    testWidgets('非待发态点敌头像不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0);
    });

    testWidgets('待发态中点 AOE → AOE 出手且待发态清除(不冻结)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single, _aoe]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: 'single 先进待发态');
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();
      expect(notifier.lastInterveneSkill?.id, 'aoe1');
      expect(notifier.interveneCount, 1, reason: 'AOE 出手');
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 1, reason: 'AOE 出手后待发态已清,点敌不再触发 single');
    });

    testWidgets('待发态再点同一技能 → 取消(点敌不出手)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      final btn = find.byKey(const ValueKey('skill_cmd_1_single1'));
      await tester.tap(btn);
      await tester.pump();
      await tester.tap(btn);
      await tester.pump();
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '已取消');
    });

    testWidgets('待发态空白点击 → 取消(点敌不出手)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(find.text(UiStrings.skillPendingStamp), findsWidgets);

      await tester.tapAt(const Offset(640, 280));
      await tester.pump();
      expect(find.text(UiStrings.skillPendingStamp), findsNothing);

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '空白点击已取消待发');
    });

    testWidgets('待发态点暂停键 → 取消(点敌不出手)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      expect(find.text(UiStrings.skillPendingStamp), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('battle_pause_toggle')));
      await tester.pump();
      expect(find.text(UiStrings.skillPendingStamp), findsNothing);

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: '暂停键已取消待发');
    });

    testWidgets('待发态 ESC 键取消(点敌不出手)', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_single1')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0, reason: 'ESC 已取消待发,点敌不出手');
    });
  });

  group('门控 allowPlayerIntervention', () {
    testWidgets('false 时点 aoe 不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        right,
        allowPlayerIntervention: false,
      );
      await tester.tap(
        find.byKey(const ValueKey('skill_cmd_1_aoe1')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(notifier.interveneCount, 0);
    });

    testWidgets('false 时点 single 不进待发态、点敌不出手', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        right,
        allowPlayerIntervention: false,
      );
      await tester.tap(
        find.byKey(const ValueKey('skill_cmd_1_single1')),
        warnIfMissed: false,
      );
      await tester.pump();
      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await tester.tap(enemy);
      await tester.pump();
      expect(notifier.interveneCount, 0);
    });
  });

  group('技能 CD 读秒环', () {
    testWidgets('CD>0 技能按钮显读秒环 + 中心剩余拍数', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_single],
        skillCooldowns: {'single1': 2},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);
      final ring = find.descendant(
        of: find.byKey(const ValueKey('skill_cmd_1_single1')),
        matching: find.byType(BeatCountdownRing),
      );
      expect(ring, findsOneWidget);
      // 读秒环喂入剩余 = 该技能 CD(2)；渲染 ceil 随节拍插值,由 countdown_ring 单测覆盖。
      expect(tester.widget<BeatCountdownRing>(ring).remaining, 2);
    });

    testWidgets('CD=0 技能按钮无读秒环', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_single],
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('skill_cmd_1_single1')),
          matching: find.byType(BeatCountdownRing),
        ),
        findsNothing,
      );
    });
  });
}
