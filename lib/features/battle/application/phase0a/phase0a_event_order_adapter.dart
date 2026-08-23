import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/arena_vector.dart';
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
    return CombatEventOrder.order(records);
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
    Phase0aSpawnWarningStarted() => const _EventDescriptor(
      'spawn_warning_started',
      CombatEventStage.startup,
    ),
    Phase0aEnemyEntered() => const _EventDescriptor(
      'enemy_entered',
      CombatEventStage.displacementAndSelection,
    ),
    Phase0aSpawnGraceExpired() => const _EventDescriptor(
      'spawn_grace_expired',
      CombatEventStage.status,
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
    final values = <String>[
      _component('type', type),
      _component('seq', event.seq),
      _component('tick', event.tick),
    ];
    switch (event) {
      case Phase0aAttackStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('move', event.moveKind.name),
        ]);
      case Phase0aHitLanded():
        values.addAll([
          _component('actor', event.actor),
          _component('target', event.target),
          _component('move', event.moveKind.name),
          _component('critical', event.isCritical),
          _component('ultimate', event.isUltimate),
          _component('damage', event.resolvedDamage),
          _component('remaining', event.remainingHealth),
          _component('actorPosition', _vector(event.actorPosition)),
          _component('targetPosition', _vector(event.targetPosition)),
        ]);
      case Phase0aEnemyDefeated():
        values.addAll([
          _component('target', event.target),
          _component('kind', event.defeatKind.name),
          _component('targetPosition', _vector(event.targetPosition)),
        ]);
      case Phase0aBossPhaseChanged():
        values.addAll([
          _component('actor', event.actor),
          _component('phase', event.phaseIndex),
          _listComponent('skills', event.unlockedSkillIds),
        ]);
      case Phase0aBossChargeStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('skill', event.skillId),
          _component('charge', event.chargeTicks),
        ]);
      case Phase0aGuardianCoopStrike():
        values.addAll([
          _component('main', event.mainGuardian),
          _component('partner', event.partner),
          _component('boss', event.boss),
          _component('target', event.target),
          _component('mainDamage', event.mainGuardianDamage),
          _component('mainCritical', event.mainGuardianCritical),
          _component('totalDamage', event.totalDamage),
          _component('mainPosition', _vector(event.mainGuardianPosition)),
          _component('partnerPosition', _vector(event.partnerPosition)),
          _component('bossPosition', _vector(event.bossPosition)),
          _component('targetPosition', _vector(event.targetPosition)),
        ]);
      case Phase0aGuardIntercepted():
        values.addAll([
          _component('actor', event.actor),
          _component('boss', event.boss),
          _component('guardian', event.guardian),
          _component('skill', event.skillId),
          _component('damage', event.resolvedDamage),
          _component('bossPosition', _vector(event.bossPosition)),
          _component('guardianPosition', _vector(event.guardianPosition)),
        ]);
      case Phase0aBossChargeInterrupted():
        values.addAll([
          _component('actor', event.actor),
          _component('target', event.target),
          _component('skill', event.skillId),
          _component('stagger', event.staggerTicks),
        ]);
      case Phase0aEnemySkillStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('skill', event.skillId),
        ]);
      case Phase0aGatherStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('skill', event.skillId),
          _component('actorPosition', _vector(event.actorPosition)),
        ]);
      case Phase0aGatherApplied():
        values.addAll([
          _component('actor', event.actor),
          _outcomesComponent(event.outcomes),
        ]);
      case Phase0aClearStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('skill', event.skillId),
          _component('actorPosition', _vector(event.actorPosition)),
        ]);
      case Phase0aClearApplied():
        values.addAll([
          _component('actor', event.actor),
          _outcomesComponent(event.outcomes),
        ]);
      case Phase0aSkillStarted():
        values.addAll([
          _component('actor', event.actor),
          _component('hotkey', event.hotkey),
          _component('skill', event.skillId),
        ]);
      case Phase0aSkillApplied():
        values.addAll([
          _component('actor', event.actor),
          _component('hotkey', event.hotkey),
          _component('skill', event.skillId),
          _outcomesComponent(event.outcomes),
        ]);
      case Phase0aSkillAvailabilityChanged():
        values.addAll([
          _component('slot', event.slot),
          _component('availability', event.availability.name),
          _component('cooldown', event.cooldownRemaining),
          _component('qi', event.qiCurrent),
          _component('required', event.qiRequired),
        ]);
      case Phase0aWaveStarted():
        values.addAll([
          _component('index', event.waveIndex),
          _component('total', event.waveTotal),
        ]);
      case Phase0aWaveCleared():
        values.add(_component('index', event.waveIndex));
      case Phase0aSpawnWarningStarted():
        values.addAll(
          _spawnComponents(
            entryId: event.entryId,
            enemyId: event.enemyId,
            entryPosition: event.entryPosition,
          ),
        );
      case Phase0aEnemyEntered():
        values.addAll(
          _spawnComponents(
            entryId: event.entryId,
            enemyId: event.enemyId,
            entryPosition: event.entryPosition,
          ),
        );
      case Phase0aSpawnGraceExpired():
        values.addAll(
          _spawnComponents(
            entryId: event.entryId,
            enemyId: event.enemyId,
            entryPosition: event.entryPosition,
          ),
        );
      case Phase0aBattleVictory() || Phase0aBattleDefeat():
        // seq/tick/type are the complete terminal payload.
        break;
    }
    return values.join('|');
  }

  static String _component(String name, Object? value) {
    final item = '$name=${_scalar(value)}';
    return '${item.length}:$item';
  }

  static String _listComponent(String name, List<String> values) {
    final encoded = values.map(_canonicalValue).join();
    final item = '$name=$encoded';
    return '${item.length}:$item';
  }

  static String _canonicalValue(String value) => '${value.length}:$value';

  static String _scalar(Object? value) {
    if (value == null) return 'null';
    if (value is double && value == 0) return '0.0';
    return '$value';
  }

  static String _vector(ArenaVector? value) =>
      value == null ? 'null' : 'x=${_scalar(value.x)},y=${_scalar(value.y)}';

  static List<String> _spawnComponents({
    required String entryId,
    required String enemyId,
    required ArenaVector entryPosition,
  }) => [
    _component('entry', entryId),
    _component('enemy', enemyId),
    _component('entryPosition', _vector(entryPosition)),
  ];

  static String _outcomesComponent(List<Phase0aSkillOutcome> outcomes) {
    final encoded = outcomes.map(_outcome).join();
    final item = 'outcomes=$encoded';
    return '${item.length}:$item';
  }

  static String _outcome(Phase0aSkillOutcome outcome) {
    final fields = [
      _component('target', outcome.target),
      _component('damage', outcome.resolvedDamage),
      _component('critical', outcome.isCritical),
      _component('defeated', outcome.defeated),
      _component('status', outcome.statusApplied.name),
      _component('sourcePosition', _vector(outcome.sourcePosition)),
      _component('targetPosition', _vector(outcome.targetPosition)),
    ].join('|');
    return '${fields.length}:$fields';
  }
}

final class _EventDescriptor {
  const _EventDescriptor(this.type, this.stage);

  final String type;
  final CombatEventStage stage;
}
