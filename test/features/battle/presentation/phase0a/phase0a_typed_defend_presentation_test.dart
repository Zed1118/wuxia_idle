import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_defend_objective_observation.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';

final class _ObservedDefendFlow
    implements Phase0aBattleFlow, Phase0aDefendObjectiveObservationSource {
  _ObservedDefendFlow({
    required this.currentDurability,
    required this.elapsedTicks,
    required this.outcome,
  });

  final int currentDurability;
  final int elapsedTicks;

  @override
  final Phase0aBattleOutcome outcome;

  @override
  Phase0aArenaState get state => Phase0aArenaState(
    tick: elapsedTicks,
    nextSeq: 1,
    player: const Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
      facing: ArenaVector(1, 0),
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 1,
      qiCurrent: 0,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: const [],
    skillSlots: const [
      Phase0aSkillSlot(
        slot: 'gather',
        cooldownRemaining: 0,
        qiCost: 0,
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: 'clear',
        cooldownRemaining: 0,
        qiCost: 0,
        availability: Phase0aSkillAvailability.ready,
      ),
    ],
    defendedEntity: Phase0aDefendedEntityState(
      id: 'ward',
      position: const ArenaVector(120, 40),
      maxDurability: 100,
      currentDurability: currentDurability,
      damagePerHit: 5,
    ),
  );

  @override
  Phase0aDefendObjectiveObservation get defendObjectiveObservation =>
      Phase0aDefendObjectiveObservation(
        entityId: 'ward',
        position: const ArenaVector(120, 40),
        maxDurability: 100,
        currentDurability: currentDurability,
        requiredDuration: const Duration(seconds: 3),
        elapsed: Duration(seconds: elapsedTicks),
        completed: elapsedTicks >= 3,
      );

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) => const [];
}

Phase0aBattleController _controller(_ObservedDefendFlow flow) =>
    Phase0aBattleController(
      flow: flow,
      roster: Phase0aVisualRoster(
        visuals: const {
          'player': Phase0aActorVisual(
            name: 'fixture',
            assetPath: 'assets/characters/battle_founder_v2.png',
            isElite: false,
          ),
        },
      ),
      fixedDeltaSeconds: 1,
    );

void main() {
  testWidgets('typed defend state renders world ward and durability HUD', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller(
      _ObservedDefendFlow(
        currentDurability: 75,
        elapsedTicks: 1,
        outcome: Phase0aBattleOutcome.ongoing,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('phase0a_defend_condition_banner')),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.defendConditionRemaining(75, 100, 2)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('phase0a_defended_entity_ward')),
      findsOneWidget,
    );
    expect(find.text(UiStrings.defendEntityLabel), findsOneWidget);
  });

  testWidgets('destroyed ward owns the defeat copy at 1440x900', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller(
      _ObservedDefendFlow(
        currentDurability: 0,
        elapsedTicks: 2,
        outcome: Phase0aBattleOutcome.defeat,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.battleResultWardLost), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
