import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_pursue_objective_observation.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';

const _player = Phase0aActor(
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
);

final class _ObservedPursuitFlow
    implements Phase0aBattleFlow, Phase0aPursueObjectiveObservationSource {
  const _ObservedPursuitFlow({
    required this.distance,
    required this.completed,
    required this.outcome,
  });

  final double? distance;
  final bool completed;

  @override
  final Phase0aBattleOutcome outcome;

  @override
  Phase0aPursueObjectiveObservation get pursueObjectiveObservation =>
      Phase0aPursueObjectiveObservation(
        targetId: 'runner',
        targetActorId: 'runner-runtime',
        distance: distance,
        completed: completed,
      );

  @override
  Phase0aArenaState get state => const Phase0aArenaState(
    tick: 1,
    nextSeq: 1,
    player: _player,
    enemies: [],
    skillSlots: [
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
  );

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => const [];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) => const [];
}

Phase0aBattleController _controller(_ObservedPursuitFlow flow) =>
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
      fixedDeltaSeconds: 0.1,
    );

void main() {
  testWidgets('typed pursuit progress drives distance HUD and outcome copy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ongoing = _controller(
      const _ObservedPursuitFlow(
        distance: 81.2,
        completed: false,
        outcome: Phase0aBattleOutcome.ongoing,
      ),
    );
    addTearDown(ongoing.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: ongoing, autoStep: false),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('phase0a_pursue_condition_banner')),
      findsOneWidget,
    );
    expect(find.text('${UiStrings.skillInfoTarget}: 82'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final completed = _controller(
      const _ObservedPursuitFlow(
        distance: 0,
        completed: true,
        outcome: Phase0aBattleOutcome.victory,
      ),
    );
    addTearDown(completed.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: completed, autoStep: false),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.phase0aVictorySeal), findsOneWidget);
  });

  testWidgets('pursuit HUD remains structurally visible at 1440x900', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller(
      const _ObservedPursuitFlow(
        distance: null,
        completed: false,
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
      find.byKey(const ValueKey('phase0a_pursue_condition_banner')),
      findsOneWidget,
    );
    expect(find.text(UiStrings.skillInfoTarget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
