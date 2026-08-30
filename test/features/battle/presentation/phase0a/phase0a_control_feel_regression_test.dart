import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/realtime_combat_rules.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_parallax_background.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

final class _MovementOnlyFlow implements Phase0aBattleFlow {
  _MovementOnlyFlow()
    : _state = const Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: Phase0aActor(
          id: 'player',
          side: Phase0aSide.player,
          position: ArenaVector(-80, 0),
          facing: ArenaVector(1, 0),
          maxHealth: 100,
          currentHealth: 100,
          moveSpeed: 210,
          qiCurrent: 0,
          qiMax: 100,
          attackCooldownRemaining: 0,
          defeatKind: Phase0aDefeatKind.normal,
        ),
        enemies: [],
        skillSlots: [
          Phase0aSkillSlot(
            slot: 'gather',
            cooldownRemaining: 0,
            qiCost: 20,
            availability: Phase0aSkillAvailability.ready,
          ),
          Phase0aSkillSlot(
            slot: 'clear',
            cooldownRemaining: 0,
            qiCost: 30,
            availability: Phase0aSkillAvailability.ready,
          ),
        ],
      );

  Phase0aArenaState _state;

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final moved = resolvePhase0aMovement(
      actor: _state.player,
      direction: normalizeMovementInput(
        left: command.left,
        right: command.right,
        up: command.up,
        down: command.down,
      ),
      deltaSeconds: deltaSeconds,
    );
    _state = Phase0aArenaState(
      tick: _state.tick + 1,
      nextSeq: _state.nextSeq,
      player: moved,
      enemies: _state.enemies,
      skillSlots: _state.skillSlots,
    );
    return const [];
  }
}

final class _AdvancingSlashFlow implements Phase0aBattleFlow {
  _AdvancingSlashFlow({this.distance = 120})
    : _state = const Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: Phase0aActor(
          id: 'player',
          side: Phase0aSide.player,
          position: ArenaVector.zero,
          facing: ArenaVector(1, 0),
          maxHealth: 100,
          currentHealth: 100,
          moveSpeed: 210,
          qiCurrent: 0,
          qiMax: 100,
          attackCooldownRemaining: 0,
          defeatKind: Phase0aDefeatKind.normal,
        ),
        enemies: [],
        skillSlots: [
          Phase0aSkillSlot(
            slot: 'gather',
            cooldownRemaining: 0,
            qiCost: 20,
            availability: Phase0aSkillAvailability.ready,
          ),
          Phase0aSkillSlot(
            slot: 'clear',
            cooldownRemaining: 0,
            qiCost: 30,
            availability: Phase0aSkillAvailability.ready,
          ),
        ],
      );

  final double distance;
  Phase0aArenaState _state;

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_state.tick > 0) return const [];
    _state = Phase0aArenaState(
      tick: 1,
      nextSeq: 2,
      player: _state.player.copyWith(position: ArenaVector(distance, 0)),
      enemies: _state.enemies,
      skillSlots: _state.skillSlots,
    );
    return [
      Phase0aAttackStarted(
        seq: 1,
        tick: 1,
        actor: 'player',
        moveKind: Phase0aMoveKind.light,
        basicAttackSegment: swordBasicAttackChain.segments[2],
      ),
    ];
  }
}

void main() {
  const viewport = Size(1280, 720);
  const translationKey = ValueKey('phase0a_background_parallax_translation');
  const scaleKey = ValueKey('phase0a_background_parallax_scale');

  Offset transformTranslation(WidgetTester tester) {
    final transform = tester.widget<Transform>(find.byKey(translationKey));
    final translation = transform.transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  test('中轴跟随区角色钉中时背景偏移仍持续提供世界移动参照', () {
    final leftStage = Phase0aStage(
      viewport: viewport,
      cameraCenter: const ArenaVector(-80, 0),
    );
    final rightStage = Phase0aStage(
      viewport: viewport,
      cameraCenter: const ArenaVector(80, 0),
    );
    final leftActor = leftStage.worldToScreen(const ArenaVector(-80, 0));
    final rightActor = rightStage.worldToScreen(const ArenaVector(80, 0));
    final leftBackground = Phase0aParallaxBackground.translationForCamera(
      leftStage.cameraWorldRect.center,
    );
    final rightBackground = Phase0aParallaxBackground.translationForCamera(
      rightStage.cameraWorldRect.center,
    );

    final actorMoves = (rightActor - leftActor).distance > 0.01;
    final backgroundMoves = (rightBackground - leftBackground).distance > 0.01;
    expect(actorMoves, isFalse, reason: '基线镜头会把中段角色钉在屏幕中轴');
    expect(
      actorMoves || backgroundMoves,
      isTrue,
      reason: '角色或背景至少一个必须持续变化，静态背景退化时本守卫必须红',
    );
    expect(leftBackground.dx, greaterThan(0));
    expect(rightBackground.dx, lessThan(0));
  });

  testWidgets('背景以 1.3 倍覆盖并在空树隔离后的两帧使用相反视差', (tester) async {
    Future<Offset> pumpFrame(Offset cameraOffset) async {
      await tester.pumpWidget(
        const SizedBox.shrink(key: ValueKey('empty_between_frames')),
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: Phase0aParallaxBackground(cameraOffset: cameraOffset),
          ),
        ),
      );
      await tester.pump();
      return transformTranslation(tester);
    }

    final left = await pumpFrame(const Offset(-160, 0));
    final leftScale = tester
        .widget<Transform>(find.byKey(scaleKey))
        .transform
        .getMaxScaleOnAxis();
    final right = await pumpFrame(const Offset(160, 0));

    expect(leftScale, Phase0aPresentationTokens.backgroundParallaxScale);
    expect(left.dx, greaterThan(0));
    expect(right.dx, lessThan(0));
    expect(right.dx, -left.dx);
  });

  testWidgets('1440x900 视口背景仍保持 1.3 倍覆盖且无布局异常', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Phase0aParallaxBackground(cameraOffset: Offset(120, -40)),
      ),
    );
    await tester.pump();

    final transform = tester.widget<Transform>(find.byKey(scaleKey));
    expect(
      transform.transform.getMaxScaleOnAxis(),
      Phase0aPresentationTokens.backgroundParallaxScale,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('正式战斗进步斩期间角色在屏幕上前冲而非被镜头钉住', (tester) async {
    final controller = Phase0aBattleController(
      flow: _AdvancingSlashFlow(),
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    final playerFinder = find.byKey(
      const ValueKey<String>('phase0a_standee_player'),
    );
    final initialBackground = transformTranslation(tester);
    final initialPlayer = tester.getCenter(playerFinder);
    controller.step(const Phase0aPlayerCommand(attack: true));
    await tester.pump();
    var previousBackground = transformTranslation(tester);
    final ordinaryTickPixels =
        controller.state.player.moveSpeed *
        controller.fixedDeltaSeconds *
        Phase0aPresentationTokens.backgroundParallaxFactor;
    expect(
      (previousBackground - initialBackground).distance,
      lessThanOrEqualTo(ordinaryTickPixels),
    );

    for (var frame = 0; frame < 9; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      final currentBackground = transformTranslation(tester);
      expect(
        (currentBackground - previousBackground).distance,
        lessThanOrEqualTo(ordinaryTickPixels),
      );
      previousBackground = currentBackground;
    }
    final finalPlayer = tester.getCenter(playerFinder);
    expect(
      finalPlayer.dx - initialPlayer.dx,
      greaterThan(40),
      reason: '进步斩必须表现为角色向前，不能仍由镜头追平造成怪物拉扯感',
    );
    expect(
      (previousBackground - initialBackground).distance,
      lessThan(120 * Phase0aPresentationTokens.backgroundParallaxFactor * 0.5),
      reason: '前冲期间镜头只能消化超出死区的少量位移',
    );
  });

  testWidgets('近敌截停的短进步斩屏幕脚点全程不回抽', (tester) async {
    final controller = Phase0aBattleController(
      flow: _AdvancingSlashFlow(distance: 18),
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    final playerFinder = find.byKey(
      const ValueKey<String>('phase0a_standee_player'),
    );
    controller.step(const Phase0aPlayerCommand(attack: true));
    await tester.pump();
    var previousX = tester.getCenter(playerFinder).dx;
    var totalForwardPixels = 0.0;
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      final currentX = tester.getCenter(playerFinder).dx;
      expect(
        currentX,
        greaterThanOrEqualTo(previousX - 0.01),
        reason: '近敌截停不得在收尾帧撤掉离散偏移而回抽',
      );
      totalForwardPixels += currentX - previousX;
      previousX = currentX;
    }
    expect(totalForwardPixels, greaterThan(0));
  });

  testWidgets('正式战斗输入层按住 D 十秒逐 tick 前进且消费背景视差', (tester) async {
    final controller = Phase0aBattleController(
      flow: _MovementOnlyFlow(),
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 0.1,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: Phase0aBattleScreen(controller: controller)),
    );
    await tester.pump();

    final initialBackground = transformTranslation(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await tester.pump(const Duration(milliseconds: 100));
    var previousTick = controller.state.tick;
    var previousX = controller.state.player.position.x;
    final ordinaryTickDistance =
        controller.state.player.moveSpeed * controller.fixedDeltaSeconds;

    for (var sample = 0; sample < 100; sample++) {
      await tester.pump(const Duration(milliseconds: 100));
      final tick = controller.state.tick;
      final x = controller.state.player.position.x;
      final advancedTicks = tick - previousTick;
      expect(advancedTicks, greaterThan(0));
      expect(
        x,
        closeTo(previousX + ordinaryTickDistance * advancedTicks, 1e-8),
      );
      previousTick = tick;
      previousX = x;
    }

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    final movedBackground = transformTranslation(tester);
    expect(movedBackground, isNot(initialBackground));
    expect(controller.state.tick, greaterThanOrEqualTo(100));
  });
}
