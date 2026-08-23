import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';

/// Read-only bridge from the production Phase 0A event stream to the C10
/// ordering contract.
///
/// This adapter deliberately consumes only the event snapshot. It does not
/// inspect an arena, replay damage, or feed anything back to the reducer.
final class Phase0aEventOrderAdapter {
  const Phase0aEventOrderAdapter._();

  /// Projects an already sequenced Phase 0A batch.
  ///
  /// [seq] is the source stream order and is therefore required to be strictly
  /// increasing. Accepting a shuffled or duplicated stream here would make a
  /// live/headless projection depend on the caller's collection order.
  static List<CombatEventRecord> project(Iterable<Phase0aEvent> input) {
    final events = input.toList(growable: false);
    var previousSeq = -1;
    final records = <CombatEventRecord>[];
    for (final event in events) {
      if (event.seq < 0 || event.tick < 0) {
        throw ArgumentError('Phase 0A event seq/tick must be non-negative');
      }
      if (event.seq <= previousSeq) {
        throw ArgumentError('Phase 0A events must be strictly seq ordered');
      }
      previousSeq = event.seq;
      final descriptor = _describe(event);
      final canonical = _canonicalPayload(event, descriptor.type);
      final eventId = 'phase0a.v1.$canonical';
      final isTerminal =
          event is Phase0aBattleVictory || event is Phase0aBattleDefeat;
      records.add(
        CombatEventRecord(
          eventId: eventId,
          tick: event.tick,
          stage: isTerminal ? CombatEventStage.presentation : descriptor.stage,
          tieBreak: event.seq,
          aggregateKey: isTerminal
              ? 'phase0a.v1.${descriptor.type}.$canonical'
              : null,
          priority: isTerminal ? 0 : null,
          feedKind: isTerminal
              ? (event is Phase0aBattleVictory
                    ? CombatFeedKind.action
                    : CombatFeedKind.defeat)
              : CombatFeedKind.none,
        ),
      );
    }
    return List<CombatEventRecord>.unmodifiable(records);
  }

  /// Alias used by callers that name the operation after its output type.
  static List<CombatEventRecord> toCombatEventRecords(
    Iterable<Phase0aEvent> input,
  ) => project(input);

  static _EventDescriptor _describe(Phase0aEvent event) => switch (event) {
    Phase0aAttackStarted() => const _EventDescriptor(
      'attack_started',
      CombatEventStage.startup,
    ),
    Phase0aHitLanded() => const _EventDescriptor(
      'hit_landed',
      CombatEventStage.damageAndPosture,
    ),
    Phase0aEnemyDefeated() => const _EventDescriptor(
      'enemy_defeated',
      CombatEventStage.killAndResources,
    ),
    Phase0aBossPhaseChanged() => const _EventDescriptor(
      'boss_phase_changed',
      CombatEventStage.status,
    ),
    Phase0aBossChargeStarted() => const _EventDescriptor(
      'boss_charge_started',
      CombatEventStage.startup,
    ),
    Phase0aGuardianCoopStrike() => const _EventDescriptor(
      'guardian_coop_strike',
      CombatEventStage.damageAndPosture,
    ),
    Phase0aGuardIntercepted() => const _EventDescriptor(
      'guard_intercepted',
      CombatEventStage.defense,
    ),
    Phase0aBossChargeInterrupted() => const _EventDescriptor(
      'boss_charge_interrupted',
      CombatEventStage.defense,
    ),
    Phase0aEnemySkillStarted() => const _EventDescriptor(
      'enemy_skill_started',
      CombatEventStage.startup,
    ),
    Phase0aGatherStarted() => const _EventDescriptor(
      'gather_started',
      CombatEventStage.displacementAndSelection,
    ),
    Phase0aGatherApplied() => const _EventDescriptor(
      'gather_applied',
      CombatEventStage.displacementAndSelection,
    ),
    Phase0aClearStarted() => const _EventDescriptor(
      'clear_started',
      CombatEventStage.startup,
    ),
    Phase0aClearApplied() => const _EventDescriptor(
      'clear_applied',
      CombatEventStage.damageAndPosture,
    ),
    Phase0aSkillStarted() => const _EventDescriptor(
      'skill_started',
      CombatEventStage.startup,
    ),
    Phase0aSkillApplied() => const _EventDescriptor(
      'skill_applied',
      CombatEventStage.damageAndPosture,
    ),
    Phase0aSkillAvailabilityChanged() => const _EventDescriptor(
      'skill_availability_changed',
      CombatEventStage.legalityAndResources,
    ),
    Phase0aWaveStarted() => const _EventDescriptor(
      'wave_started',
      CombatEventStage.killAndResources,
    ),
    Phase0aWaveCleared() => const _EventDescriptor(
      'wave_cleared',
      CombatEventStage.killAndResources,
    ),
    Phase0aBattleVictory() => const _EventDescriptor(
      'battle_victory',
      CombatEventStage.presentation,
    ),
    Phase0aBattleDefeat() => const _EventDescriptor(
      'battle_defeat',
      CombatEventStage.presentation,
    ),
  };

  static String _canonicalPayload(Phase0aEvent event, String type) {
    final values = <String>[type, 'seq=${event.seq}', 'tick=${event.tick}'];
    switch (event) {
      case Phase0aAttackStarted():
        values.addAll(['actor=${event.actor}', 'move=${event.moveKind.name}']);
      case Phase0aHitLanded():
        values.addAll([
          'actor=${event.actor}',
          'target=${event.target}',
          'move=${event.moveKind.name}',
          'critical=${event.isCritical}',
          'ultimate=${event.isUltimate}',
          'damage=${event.resolvedDamage}',
          'remaining=${event.remainingHealth}',
        ]);
      case Phase0aEnemyDefeated():
        values.addAll([
          'target=${event.target}',
          'kind=${event.defeatKind.name}',
        ]);
      case Phase0aBossPhaseChanged():
        values.addAll([
          'actor=${event.actor}',
          'phase=${event.phaseIndex}',
          'skills=${event.unlockedSkillIds.join(',')}',
        ]);
      case Phase0aBossChargeStarted():
        values.addAll([
          'actor=${event.actor}',
          'skill=${event.skillId}',
          'charge=${event.chargeTicks}',
        ]);
      case Phase0aGuardianCoopStrike():
        values.addAll([
          'main=${event.mainGuardian}',
          'partner=${event.partner}',
          'boss=${event.boss}',
          'target=${event.target}',
          'damage=${event.totalDamage}',
        ]);
      case Phase0aGuardIntercepted():
        values.addAll([
          'actor=${event.actor}',
          'boss=${event.boss}',
          'guardian=${event.guardian}',
          'skill=${event.skillId}',
          'damage=${event.resolvedDamage}',
        ]);
      case Phase0aBossChargeInterrupted():
        values.addAll([
          'actor=${event.actor}',
          'target=${event.target}',
          'skill=${event.skillId}',
          'stagger=${event.staggerTicks}',
        ]);
      case Phase0aEnemySkillStarted():
        values.addAll(['actor=${event.actor}', 'skill=${event.skillId}']);
      case Phase0aGatherStarted():
        values.addAll(['actor=${event.actor}', 'skill=${event.skillId}']);
      case Phase0aGatherApplied():
        values.addAll([
          'actor=${event.actor}',
          'outcomes=${event.outcomes.length}',
        ]);
      case Phase0aClearStarted():
        values.addAll(['actor=${event.actor}', 'skill=${event.skillId}']);
      case Phase0aClearApplied():
        values.addAll([
          'actor=${event.actor}',
          'outcomes=${event.outcomes.length}',
        ]);
      case Phase0aSkillStarted():
        values.addAll([
          'actor=${event.actor}',
          'hotkey=${event.hotkey}',
          'skill=${event.skillId}',
        ]);
      case Phase0aSkillApplied():
        values.addAll([
          'actor=${event.actor}',
          'hotkey=${event.hotkey}',
          'skill=${event.skillId}',
          'outcomes=${event.outcomes.length}',
        ]);
      case Phase0aSkillAvailabilityChanged():
        values.addAll([
          'slot=${event.slot}',
          'availability=${event.availability.name}',
          'cooldown=${event.cooldownRemaining}',
          'qi=${event.qiCurrent}',
          'required=${event.qiRequired}',
        ]);
      case Phase0aWaveStarted():
        values.addAll(['index=${event.waveIndex}', 'total=${event.waveTotal}']);
      case Phase0aWaveCleared():
        values.add('index=${event.waveIndex}');
      case Phase0aBattleVictory() || Phase0aBattleDefeat():
        // seq/tick/type are the complete terminal payload.
        break;
    }
    return values.map(_canonicalComponent).join('|');
  }

  static String _canonicalComponent(String value) => '${value.length}:$value';
}

final class _EventDescriptor {
  const _EventDescriptor(this.type, this.stage);

  final String type;
  final CombatEventStage stage;
}
