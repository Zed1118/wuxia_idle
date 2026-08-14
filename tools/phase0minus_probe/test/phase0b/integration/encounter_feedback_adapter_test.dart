import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/encounter/encounter_orchestrator.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';
import 'package:phase0minus_probe/phase0b/integration/encounter_feedback_adapter.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

/// Boss east of the hero inside the basic arc: scripted clears push it
/// through phase 2 to defeat, emitting loot and a victory conclusion.
EncounterOrchestrator _victoryScenario() => EncounterOrchestrator(
  seed: 11,
  style: DraftStyleKind.surgeCurrent,
  heroStart: Vector2(1600, 500),
  bossSpawn: Vector2(1750, 500),
  commands: const [
    EncounterCommand(at: 4.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 8.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 12.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 16.0, kind: EncounterCommandKind.castClear),
  ],
);

/// Hero steps east next to the boss and never fights back: slam cycles
/// grind the hero down to a deterministic defeat.
EncounterOrchestrator _defeatScenario() => EncounterOrchestrator(
  seed: 21,
  style: DraftStyleKind.surgeCurrent,
  heroStart: Vector2(1600, 500),
  bossSpawn: Vector2(1750, 500),
  commands: const [
    EncounterCommand(at: 1.0, kind: EncounterCommandKind.moveBy, dx: 160),
  ],
);

/// Orchestrator + HUD controller + bridge, with the silent cue sink tapped
/// so tests can observe the deterministic cue sequence.
final class _Rig {
  _Rig(this.orchestrator) {
    controller = FeedbackHudController(
      cueSink: SilentFeedbackCueSink(onCue: cues.add),
    );
    bridge = EncounterFeedbackBridge(
      orchestrator: orchestrator,
      controller: controller,
    );
  }

  final EncounterOrchestrator orchestrator;
  late final FeedbackHudController controller;
  late final EncounterFeedbackBridge bridge;
  final List<FeedbackCue> cues = [];

  FeedbackHudState run(double seconds) {
    orchestrator.runSeconds(seconds);
    bridge.sync();
    return controller.value;
  }
}

void main() {
  group('event consumption', () {
    test('sync drains each orchestrator event exactly once', () {
      final rig = _Rig(_victoryScenario());
      rig.run(30);
      expect(rig.bridge.consumedCount, rig.orchestrator.events.length);
      final cuesAfterFirstSync = rig.cues.length;
      final stateAfterFirstSync = rig.controller.value;

      // A second sync has nothing left to drain: no extra cues, no state
      // change.
      rig.bridge.sync();
      expect(rig.cues.length, cuesAfterFirstSync);
      expect(identical(rig.controller.value, stateAfterFirstSync), isTrue);
    });
  });

  group('outcome and loot mapping', () {
    test('victory drives health/resource/phase/loot/end state', () {
      final rig = _Rig(_victoryScenario());
      final state = rig.run(30);

      expect(state.endState, FeedbackEndState.victory);
      // Hero took 32 damage (one slam + one sweep) out of 100 max.
      expect(state.health, closeTo(0.68, 1e-9));
      expect(state.resource, closeTo(0.8, 1e-9));
      expect(state.bossPhase, 2);
      expect(state.bossPhaseTotal, 2);
      expect(state.loot, hasLength(1));
      expect(state.loot.single.label, 'spoils · boss_draft_v1');
      expect(state.loot.single.kind, LootKind.gear);
      expect(rig.cues, contains(FeedbackCue.victory));
      expect(rig.cues, contains(FeedbackCue.lootArrived));
      expect(rig.cues, contains(FeedbackCue.bossPhaseShift));
      expect(rig.cues, contains(FeedbackCue.playerHurt));
    });

    test('defeat drives the terminal state through real strikes', () {
      final rig = _Rig(_defeatScenario());
      final state = rig.run(120);

      expect(rig.orchestrator.battleConcluded, isTrue);
      expect(state.endState, FeedbackEndState.defeat);
      expect(state.health, 0);
      expect(state.loot, isEmpty);
      expect(rig.cues, contains(FeedbackCue.playerHurt));
      expect(rig.cues.last, FeedbackCue.defeat);
    });
  });

  group('reset determinism', () {
    test('same-seed rebuild reproduces identical HUD state and cues', () {
      final rigA = _Rig(_victoryScenario());
      final stateA = rigA.run(30);
      final rigB = _Rig(_victoryScenario());
      final stateB = rigB.run(30);

      expect(rigA.cues, rigB.cues);
      expect(stateA.health, stateB.health);
      expect(stateA.resource, stateB.resource);
      expect(stateA.style, stateB.style);
      expect(stateA.bossPhase, stateB.bossPhase);
      expect(stateA.bossPhaseTotal, stateB.bossPhaseTotal);
      expect(stateA.danger, stateB.danger);
      expect(stateA.endState, stateB.endState);
      expect(stateA.loot.length, stateB.loot.length);
      expect(stateA.recentCues, stateB.recentCues);
    });
  });
}
