import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_survive_objective_observation.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';

final class _ObservedSurviveFlow
    implements Phase0aBattleFlow, Phase0aSurviveObjectiveObservationSource {
  _ObservedSurviveFlow({required int elapsedTicks, required this.outcome})
    : objectiveController = ObjectiveController(
        completionRule: ObjectiveCompletionRule.all,
        clauses: [
          ObjectiveClause(
            id: 'survive',
            objective: SurviveDurationObjective(const Duration(seconds: 3)),
          ),
        ],
      ) {
    final tracker = Phase0aObjectiveRuntimeTracker(
      controller: objectiveController,
    );
    for (var tick = 1; tick <= elapsedTicks; tick += 1) {
      tracker.advanceExternal(
        TimeElapsed(const Duration(seconds: 1), eventId: 'survive:$tick'),
      );
    }
    objectiveProgress = tracker.progress;
  }

  final ObjectiveController objectiveController;
  late final ObjectiveControllerProgress objectiveProgress;

  @override
  final Phase0aBattleOutcome outcome;

  @override
  Phase0aArenaState get state => const Phase0aArenaState(
    tick: 1,
    nextSeq: 1,
    player: Phase0aActor(
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
  Phase0aSurviveObjectiveObservation get surviveObjectiveObservation =>
      Phase0aSurviveObjectiveObservation(
        requiredDuration: const Duration(seconds: 3),
        elapsed: objectiveProgress.clauses.single.progress.elapsed,
      );

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) => const [];
}

Phase0aBattleController _controller(_ObservedSurviveFlow flow) =>
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
  testWidgets('typed survive progress drives existing HUD and outcome copy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ongoing = _controller(
      _ObservedSurviveFlow(
        elapsedTicks: 1,
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
      find.byKey(const ValueKey('phase0a_survive_condition_banner')),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.surviveConditionRemaining(3, 2)),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final completed = _controller(
      _ObservedSurviveFlow(
        elapsedTicks: 3,
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

    expect(find.text(UiStrings.battleResultSurvived), findsOneWidget);
  });
}
