/// Composition-layer adapter: neutral encounter events in, semantic
/// [FeedbackEvent]s out.
///
/// This is the ONLY layer allowed to depend on both the encounter and the
/// feedback slices: `phase0b/encounter` never imports `phase0b/feedback`
/// and vice versa (pinned by the integration isolation guard test). The
/// mapping is deterministic — same event sequence in, same HUD commands
/// out — and carries no copy, no loot payloads, and no persistence.
library;

import 'package:phase0minus_probe/phase0b/encounter/encounter_events.dart'
    as enc;
import 'package:phase0minus_probe/phase0b/encounter/encounter_orchestrator.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';
import 'package:phase0minus_probe/phase0b/playable/draft_tuning.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

/// Presentation-only style mapping for the draft: the surge-current draft
/// reads as the rigid burst rhythm, the sinister draft as sinister. The
/// agile plaque stays reserved for a future third draft style.
FeedbackStyle feedbackStyleForDraft(DraftStyleKind kind) => switch (kind) {
  DraftStyleKind.surgeCurrent => FeedbackStyle.rigid,
  DraftStyleKind.sinisterDraft => FeedbackStyle.sinister,
};

/// Which slice currently owns the danger telegraph, so a strike from one
/// slice never clears the other's telegraph.
enum _DangerOwner { none, enemy, boss }

/// Translates neutral encounter events into HUD presentation events.
///
/// Stateful in exactly one place: the danger-telegraph owner. Everything
/// else is a pure function of the incoming event. Deterministic for a
/// fixed event sequence.
final class EncounterFeedbackAdapter {
  _DangerOwner _dangerOwner = _DangerOwner.none;

  /// Map one encounter event to its HUD event, or `null` when the event
  /// has no presentation counterpart in this draft.
  FeedbackEvent? translate(enc.EncounterEvent event) => switch (event) {
    enc.EncounterStarted(:final style) => StylePresented(
      feedbackStyleForDraft(style),
    ),
    enc.HeroStyleChanged(:final style) => StylePresented(
      feedbackStyleForDraft(style),
    ),
    enc.HeroDamaged(:final amount) => PlayerDamaged(
      amount / PlayableDraftTuning.playerMaxHealth,
    ),
    enc.HeroResourceChanged(:final delta) => ResourceAdjusted(
      delta / PlayableDraftTuning.playerQiCapacity,
    ),
    enc.EnemyTelegraphStarted() => _presentDanger(
      FeedbackDanger.telegraph,
      _DangerOwner.enemy,
    ),
    enc.BossTelegraphStarted() => _presentDanger(
      FeedbackDanger.imminent,
      _DangerOwner.boss,
    ),
    enc.EnemyStrikeResolved() => _resolveDanger(_DangerOwner.enemy),
    enc.BossStrikeResolved() => _resolveDanger(_DangerOwner.boss),
    // A killing blow reads as the heavy hit; ordinary chip stays light.
    enc.EnemyDamaged(:final defeated) => EnemyHit(heavy: defeated),
    enc.BossDamaged() => const EnemyHit(heavy: true),
    enc.BossPhaseChanged(:final phase, :final total) => BossPhasePresented(
      phase: phase,
      total: total,
    ),
    // Display-only draft spoils: a bounded in-memory entry, never a real
    // drop, reward, or persisted record.
    enc.LootRequested(:final sourceId) => LootPresented(
      label: 'spoils · $sourceId',
      kind: LootKind.gear,
    ),
    enc.BattleConcluded(:final outcome) => BattleConcluded(
      outcome == enc.EncounterOutcome.victory
          ? FeedbackEndState.victory
          : FeedbackEndState.defeat,
    ),
    // Enter/retreat/clear bookkeeping, the boss exhaustion beat, and the
    // boss-defeated marker (its spoils arrive via LootRequested) carry no
    // dedicated HUD element in this draft.
    enc.EnemyEntered() ||
    enc.EnemyRetreated() ||
    enc.GroupCleared() ||
    enc.BossExhaustedStarted() ||
    enc.BossDefeated() => null,
  };

  FeedbackEvent _presentDanger(FeedbackDanger level, _DangerOwner owner) {
    // The boss telegraph always escalates; an enemy telegraph must not
    // downgrade an active boss window.
    if (owner == _DangerOwner.enemy && _dangerOwner == _DangerOwner.boss) {
      return const DangerPresented(FeedbackDanger.imminent);
    }
    _dangerOwner = owner;
    return DangerPresented(level);
  }

  FeedbackEvent? _resolveDanger(_DangerOwner owner) {
    if (_dangerOwner != owner) return null;
    _dangerOwner = _DangerOwner.none;
    // This slice has no player break mechanic, so a resolution is never a
    // break success; it only clears the telegraph.
    return const DangerResolved(broken: false);
  }
}

/// Incremental pump from an [EncounterOrchestrator] event log into a
/// [FeedbackHudController]. The orchestrator stays copy-free and knows
/// nothing about the HUD; this bridge is the only consumer that walks the
/// log. Rebuilt together with the orchestrator and controller on reset.
final class EncounterFeedbackBridge {
  EncounterFeedbackBridge({
    required EncounterOrchestrator orchestrator,
    required FeedbackHudController controller,
    EncounterFeedbackAdapter? adapter,
  }) : _orchestrator = orchestrator,
       _controller = controller,
       _adapter = adapter ?? EncounterFeedbackAdapter();

  final EncounterOrchestrator _orchestrator;
  final FeedbackHudController _controller;
  final EncounterFeedbackAdapter _adapter;
  int _consumed = 0;

  /// How many orchestrator events have been drained so far.
  int get consumedCount => _consumed;

  /// Apply every event appended since the last [sync]. Safe to call at any
  /// cadence; events are consumed exactly once, in log order.
  void sync() {
    final events = _orchestrator.events;
    while (_consumed < events.length) {
      final mapped = _adapter.translate(events[_consumed]);
      _consumed += 1;
      if (mapped != null) _controller.apply(mapped);
    }
  }
}
