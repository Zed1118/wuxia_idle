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

  testWidgets('群战首发阵亡后按队列递补空位并递减墨影', (tester) async {
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

    Widget field(BattleState state) => MaterialApp(
      home: Scaffold(
        body: BattleField(
          state: state,
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
    );

    final initial = BattleState.initial(leftTeam: left, rightTeam: right);
    await tester.pumpWidget(field(initial));
    for (final id in [100, 101, 102]) {
      expect(find.byKey(ValueKey('battle.stageCharacterId.$id')), findsOne);
    }
    expect(
      find.byKey(const ValueKey('battle.massBattleInkQueue.count.4')),
      findsOne,
    );

    final firstWaveDead = initial.copyWith(
      rightTeam: [
        for (var i = 0; i < right.length; i++)
          i < 3 ? right[i].copyWith(currentHp: 0, isAlive: false) : right[i],
      ],
      actionLog: [
        for (var i = 0; i < 3; i++)
          BattleAction(
            tick: i + 1,
            actorId: left.first.characterId,
            targetId: 100 + i,
            description: 'defeat',
            defeatedTarget: true,
          ),
      ],
    );
    await tester.pumpWidget(field(firstWaveDead));

    // 阵亡帧先保留原战位，让灰化与血条归零完整呈现。
    for (final id in [100, 101, 102]) {
      final slot = tester.widget<CharacterSlot>(
        find.byKey(ValueKey('battle.stageCharacterId.$id')),
      );
      expect(slot.character.isAlive, isFalse);
      expect(slot.character.currentHp, 0);
    }

    await tester.pump(
      Duration(milliseconds: AnimationNumbers.defaults.damagePopupMs + 1),
    );
    for (final id in [103, 104, 105]) {
      expect(find.byKey(ValueKey('battle.stageCharacterId.$id')), findsOne);
    }
    expect(
      find.byKey(const ValueKey('battle.massBattleInkQueue.count.1')),
      findsOne,
    );

    final secondWaveDead = firstWaveDead.copyWith(
      rightTeam: [
        for (var i = 0; i < right.length; i++)
          i < 6 ? right[i].copyWith(currentHp: 0, isAlive: false) : right[i],
      ],
      actionLog: [
        ...firstWaveDead.actionLog,
        for (var i = 3; i < 6; i++)
          BattleAction(
            tick: i + 1,
            actorId: left.first.characterId,
            targetId: 100 + i,
            description: 'defeat',
            defeatedTarget: true,
          ),
      ],
    );
    await tester.pumpWidget(field(secondWaveDead));
    for (final id in [103, 104, 105]) {
      expect(
        tester
            .widget<CharacterSlot>(
              find.byKey(ValueKey('battle.stageCharacterId.$id')),
            )
            .character
            .isAlive,
        isFalse,
      );
    }
    await tester.pump(
      Duration(milliseconds: AnimationNumbers.defaults.damagePopupMs + 1),
    );
    expect(find.byKey(const ValueKey('battle.stageCharacterId.106')), findsOne);
    expect(
      find.byKey(const ValueKey('battle.massBattleInkQueue')),
      findsNothing,
    );

    final allDead = secondWaveDead.copyWith(
      rightTeam: [
        for (final character in right)
          character.copyWith(currentHp: 0, isAlive: false),
      ],
      actionLog: [
        ...secondWaveDead.actionLog,
        BattleAction(
          tick: 7,
          actorId: left.first.characterId,
          targetId: 106,
          description: 'defeat',
          defeatedTarget: true,
        ),
      ],
    );
    await tester.pumpWidget(field(allDead));
    expect(
      tester
          .widget<CharacterSlot>(
            find.byKey(const ValueKey('battle.stageCharacterId.106')),
          )
          .character
          .isAlive,
      isFalse,
    );
    await tester.pump(
      Duration(milliseconds: AnimationNumbers.defaults.damagePopupMs + 1),
    );
    expect(find.byType(CharacterSlot), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey('battle.massBattleInkQueue')),
      findsNothing,
    );
  });

  testWidgets('轻功与心魔共用战位路径保持 3v3 人物映射', (tester) async {
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

    for (final mode in const [
      BattleStageLayoutMode.lightFoot,
      BattleStageLayoutMode.innerDemon,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattleField(
              state: BattleState.initial(leftTeam: left, rightTeam: right),
              stageLayout: mode,
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
      expect(find.byType(CharacterSlot), findsNWidgets(6), reason: mode.name);
      for (final character in [...left, ...right]) {
        expect(
          find.byKey(
            ValueKey('battle.stageCharacterId.${character.characterId}'),
          ),
          findsOne,
          reason: mode.name,
        );
      }
    }
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
