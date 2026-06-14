import 'package:flutter/gestures.dart';
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
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';

/// 战斗交互重做 Phase 4 拖招交互 widget/单元测试。
///
/// 复用 [battle_command_console_test] 的 no-op advance notifier 体例，避免 Timer
/// 触发时读 GameRepository 崩溃；拖招立即触发(C5)的「快进到出手」属表现层手感，
/// 由真玩 + Codex 验收，这里只锁死「拖到敌头像→下发 targetId / aoe 点触 / 门控」契约。

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

/// 在技能按钮上长按拖到目标全局坐标后松手。
Future<void> _longPressDragTo(
  WidgetTester tester,
  Finder skill,
  Offset target,
) async {
  final start = tester.getCenter(skill);
  final g = await tester.startGesture(start);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
  await g.moveTo(target);
  await tester.pump();
  await g.up();
  await tester.pump();
}

void main() {
  group('hitTestEnemyId 纯函数', () {
    test('指针落在某敌矩形内 → 返回该 enemyId', () {
      final r = hitTestEnemyId(const Offset(50, 50), const [
        (enemyId: 11, rect: Rect.fromLTWH(0, 0, 100, 100)),
        (enemyId: 12, rect: Rect.fromLTWH(200, 0, 100, 100)),
      ]);
      expect(r, 11);
    });

    test('指针落在第二个敌矩形 → 返回 12', () {
      final r = hitTestEnemyId(const Offset(250, 50), const [
        (enemyId: 11, rect: Rect.fromLTWH(0, 0, 100, 100)),
        (enemyId: 12, rect: Rect.fromLTWH(200, 0, 100, 100)),
      ]);
      expect(r, 12);
    });

    test('指针不在任何矩形 → null', () {
      final r = hitTestEnemyId(const Offset(500, 500), const [
        (enemyId: 11, rect: Rect.fromLTWH(0, 0, 100, 100)),
      ]);
      expect(r, isNull);
    });

    test('空目标列表 → null', () {
      final r = hitTestEnemyId(const Offset(0, 0), const []);
      expect(r, isNull);
    });
  });

  group('C4 群体技点触', () {
    testWidgets('点 aoe 技能按钮 → 立即触发 pending（targetId 为空走 AI 选）',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_aoe1')));
      await tester.pump();

      expect(notifier.state.pendingUltimates[1]?.id, 'aoe1');
      expect(notifier.state.pendingTargets[1], isNull,
          reason: 'aoe 点触不指定目标，targetId 为空');
    });
  });

  group('C3+C4 单体拖招命中下发 targetId', () {
    testWidgets('单体技长按拖到存活敌头像 → pending + pendingTargets 指向该敌',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      expect(enemy, findsOneWidget);

      await _longPressDragTo(
        tester,
        find.byKey(const ValueKey('skill_cmd_1_single1')),
        tester.getCenter(enemy),
      );

      expect(notifier.state.pendingUltimates[1]?.id, 'single1');
      expect(notifier.state.pendingTargets[1], 11);
    });

    testWidgets('单体技拖到空白处(未命中敌) → 不下发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await _longPressDragTo(
        tester,
        find.byKey(const ValueKey('skill_cmd_1_single1')),
        const Offset(640, 700), // 底栏附近空白，非敌头像
      );

      expect(notifier.state.pendingUltimates[1], isNull);
      expect(notifier.state.pendingTargets[1], isNull);
    });
  });

  group('门控 allowPlayerIntervention', () {
    testWidgets('false 时点技能不下发（群战纯自动）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_aoe]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        right,
        allowPlayerIntervention: false,
      );

      // 按钮存在但禁用：tap 不写 pending。
      await tester.tap(
        find.byKey(const ValueKey('skill_cmd_1_aoe1')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(notifier.state.pendingUltimates[1], isNull);
    });

    testWidgets('false 时拖单体技也不下发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_single]);
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        right,
        allowPlayerIntervention: false,
      );

      final enemy = find.byWidgetPredicate(
        (w) => w is CharacterAvatar && w.character.characterId == 11,
      );
      await _longPressDragTo(
        tester,
        find.byKey(const ValueKey('skill_cmd_1_single1')),
        tester.getCenter(enemy),
      );

      expect(notifier.state.pendingUltimates[1], isNull);
      expect(notifier.state.pendingTargets[1], isNull);
    });
  });
}
