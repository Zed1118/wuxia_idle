import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

final class _CrossingActorFlow implements Phase0aBattleFlow {
  Phase0aArenaState _state = const Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector(0, 0),
      facing: ArenaVector(1, 0),
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 100,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: <Phase0aActor>[
      Phase0aActor(
        id: 'wave1_blade',
        side: Phase0aSide.enemy,
        position: ArenaVector(0, 150),
        facing: ArenaVector(-1, 0),
        maxHealth: 100,
        currentHealth: 100,
        moveSpeed: 0,
        qiCurrent: 0,
        qiMax: 0,
        attackCooldownRemaining: 0,
        defeatKind: Phase0aDefeatKind.normal,
      ),
    ],
    skillSlots: <Phase0aSkillSlot>[
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
  int _moveCount = 0;

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      const <CombatEventRecord>[];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final targetY = switch (_moveCount) {
      0 => 200.0,
      1 => 100.0,
      _ => null,
    };
    if (targetY == null) return const <Phase0aEvent>[];
    _moveCount += 1;
    _state = Phase0aArenaState(
      tick: _moveCount,
      nextSeq: _state.nextSeq,
      player: _state.player.copyWith(position: ArenaVector(0, targetY)),
      enemies: _state.enemies,
      skillSlots: _state.skillSlots,
    );
    return const <Phase0aEvent>[];
  }
}

void main() {
  const actorKeyPrefix = 'phase0a_actor_position_';

  List<String> actorPaintOrder(WidgetTester tester) {
    final stack = tester
        .widgetList<Stack>(find.byType(Stack))
        .singleWhere(
          (candidate) => candidate.children.any(
            (child) => child.key == const ValueKey('${actorKeyPrefix}player'),
          ),
        );
    return <String>[
      for (final child in stack.children)
        if (child.key case final ValueKey key
            when key.value is String &&
                (key.value as String).startsWith(actorKeyPrefix))
          (key.value as String).substring(actorKeyPrefix.length),
    ];
  }

  double actorFootY(WidgetTester tester, String actorId) =>
      tester.getBottomLeft(find.byKey(ValueKey('$actorKeyPrefix$actorId'))).dy;

  testWidgets('Stack 顺序在实际脚底双向越过滞回带后才翻转', (tester) async {
    final controller = Phase0aBattleController(
      flow: _CrossingActorFlow(),
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 1,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['player', 'wave1_blade']),
    );

    controller.step();
    await tester.pump();
    expect(
      actorFootY(tester, 'player'),
      lessThan(actorFootY(tester, 'wave1_blade')),
    );
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['player', 'wave1_blade']),
    );

    await tester.pump(const Duration(milliseconds: 740));
    expect(
      actorFootY(tester, 'player'),
      lessThan(actorFootY(tester, 'wave1_blade')),
    );
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['player', 'wave1_blade']),
    );

    await tester.pump(const Duration(milliseconds: 20));
    expect(
      actorFootY(tester, 'player'),
      greaterThan(actorFootY(tester, 'wave1_blade')),
    );
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['player', 'wave1_blade']),
      reason: '脚底刚交叉但未越过滞回带时应保持既有层级',
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['wave1_blade', 'player']),
    );

    controller.step();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      actorFootY(tester, 'player'),
      lessThan(actorFootY(tester, 'wave1_blade')),
    );
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['wave1_blade', 'player']),
      reason: '反向刚交叉但未越过滞回带时也应保持既有层级',
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(
      actorPaintOrder(tester),
      containsAllInOrder(['player', 'wave1_blade']),
    );
  });
}
