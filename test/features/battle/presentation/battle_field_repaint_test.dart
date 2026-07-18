import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import '../../../support/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_action_template.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_stage_geometry.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_field.dart';

void main() {
  testWidgets('3v3 character slots are isolated by repaint boundaries', (
    tester,
  ) async {
    final (left, right) = BattleDemo.mockTeams();
    final attackControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    final hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    addTearDown(() {
      for (final controller in [...attackControllers, ...hitFlashControllers]) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleField(
            state: BattleState.initial(leftTeam: left, rightTeam: right),
            attackControllers: attackControllers,
            actionTemplates: List.filled(6, BattleActionTemplate.melee),
            popups: const {},
            animConfig: AnimationNumbers.defaults,
            chargeMaxTicks: 3,
            beat: const AlwaysStoppedAnimation<double>(0),
            staggerWindowTicks: 3,
            onPopupComplete: (_, _) {},
            hitFlashControllers: hitFlashControllers,
            hitFlashColors: const {},
            onEnemyTap: (_) {},
            hoveredEnemyId: null,
            onEnemyHover: (_, _) {},
          ),
        ),
      ),
    );

    for (var side = 0; side < 2; side++) {
      for (var slot = 0; slot < 3; slot++) {
        expect(
          find.byKey(ValueKey('battle.characterSlot.repaint.$side.$slot')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('battle.stageCharacter.$side.$slot')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('battle.stageStatusOverlay.$side.$slot')),
          findsOneWidget,
        );
      }
    }

    // 状态牌必须脱离按景深排序的人物槽，统一位于人物绘制层之后；否则
    // 前景角色的透明立绘会遮住后排角色血条。
    final stack = tester.widget<Stack>(
      find.byKey(const ValueKey('battle.stageLayerStack')),
    );
    final firstStatusLayer = stack.children.indexWhere(
      (child) => child.key == const ValueKey('battle.stageStatusOverlay.0.0'),
    );
    final lastCharacterLayer = stack.children.lastIndexWhere(
      (child) => child.key == const ValueKey('battle.stageCharacterLayer.1.1'),
    );
    expect(firstStatusLayer, greaterThan(lastCharacterLayer));
  });

  testWidgets('群战 3v7 只渲染六个完整人物并用墨影队列表达余敌', (tester) async {
    final (left, rightBase) = BattleDemo.mockTeams();
    final right = [
      for (var i = 0; i < 7; i++)
        rightBase[i % rightBase.length].copyWith(
          characterId: 100 + i,
          slotIndex: i,
          isAlive: true,
        ),
    ];
    final attackControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    final hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    addTearDown(() {
      for (final controller in [...attackControllers, ...hitFlashControllers]) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleField(
            state: BattleState.initial(leftTeam: left, rightTeam: right),
            stageLayout: BattleStageLayoutMode.massBattle,
            attackControllers: attackControllers,
            actionTemplates: List.filled(6, BattleActionTemplate.melee),
            popups: const {},
            animConfig: AnimationNumbers.defaults,
            chargeMaxTicks: 3,
            beat: const AlwaysStoppedAnimation<double>(0),
            staggerWindowTicks: 3,
            onPopupComplete: (_, _) {},
            hitFlashControllers: hitFlashControllers,
            hitFlashColors: const {},
            onEnemyTap: (_) {},
            hoveredEnemyId: null,
            onEnemyHover: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('battle.massBattleInkQueue')), findsOne);
    expect(
      find.byKey(const ValueKey('battle.stageCharacter.1.3')),
      findsNothing,
    );
    expect(find.byType(CharacterSlot), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('窗口重建的零高与浮点贴边约束不抛异常', (tester) async {
    final (left, right) = BattleDemo.mockTeams();
    final bossRight = List<BattleCharacter>.from(right);
    bossRight[0] = bossRight[0].copyWith(isBoss: true);
    final attackControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    final hitFlashControllers = List.generate(
      6,
      (_) => AnimationController(vsync: tester),
    );
    addTearDown(() {
      for (final controller in [...attackControllers, ...hitFlashControllers]) {
        controller.dispose();
      }
    });

    for (final size in const [Size(1280, 0), Size(1420, 507)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: BattleField(
                  state: BattleState.initial(
                    leftTeam: left,
                    rightTeam: bossRight,
                  ),
                  attackControllers: attackControllers,
                  actionTemplates: List.filled(6, BattleActionTemplate.melee),
                  popups: const {},
                  animConfig: AnimationNumbers.defaults,
                  chargeMaxTicks: 3,
                  beat: const AlwaysStoppedAnimation<double>(0),
                  staggerWindowTicks: 3,
                  onPopupComplete: (_, _) {},
                  hitFlashControllers: hitFlashControllers,
                  hitFlashColors: const {},
                  onEnemyTap: (_) {},
                  hoveredEnemyId: null,
                  onEnemyHover: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: '$size 不应抛布局异常');
    }
  });
}
