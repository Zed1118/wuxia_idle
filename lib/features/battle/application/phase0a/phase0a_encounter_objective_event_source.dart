import '../../../../data/defs/boss_phase_def.dart';
import '../../domain/phase0a/encounter_objective.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/spawn_director.dart';

/// Immutable facts produced by exactly one dynamic encounter advance.
///
/// This frame deliberately carries no objective identities or policy. A caller
/// may inspect the explicit before/after arena and spawn snapshots, the exact
/// director/spawn/combat event batches, and the supplied combat delta. It must
/// map target, commander, checkpoint, marker, role, ID, and time semantics
/// itself through [Phase0aEncounterObjectiveEventSource].
final class Phase0aEncounterObjectiveFrame {
  Phase0aEncounterObjectiveFrame({
    required Phase0aArenaState beforeArena,
    required Phase0aArenaState afterArena,
    required this.beforeSpawn,
    required this.afterSpawn,
    required Iterable<SpawnDirectorEvent> directorEvents,
    required Iterable<Phase0aEvent> spawnEvents,
    required Iterable<Phase0aEvent> combatEvents,
    required this.deltaSeconds,
  }) : beforeArena = _snapshotArena(beforeArena),
       afterArena = _snapshotArena(afterArena),
       directorEvents = List<SpawnDirectorEvent>.unmodifiable(directorEvents),
       spawnEvents = List<Phase0aEvent>.unmodifiable(spawnEvents),
       combatEvents = List<Phase0aEvent>.unmodifiable(combatEvents);

  final Phase0aArenaState beforeArena;
  final Phase0aArenaState afterArena;
  final SpawnDirectorState beforeSpawn;
  final SpawnDirectorState afterSpawn;
  final List<SpawnDirectorEvent> directorEvents;
  final List<Phase0aEvent> spawnEvents;
  final List<Phase0aEvent> combatEvents;
  final double deltaSeconds;
}

/// Explicit caller policy for projecting one encounter frame into an ordered
/// objective event batch.
///
/// Implementations may return a lazy iterable. The encounter flow snapshots
/// and prepares the entire batch before committing either objective progress
/// or flow state.
abstract interface class Phase0aEncounterObjectiveEventSource {
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  );
}

Phase0aArenaState _snapshotArena(Phase0aArenaState state) => Phase0aArenaState(
  tick: state.tick,
  nextSeq: state.nextSeq,
  player: _snapshotActor(state.player),
  enemies: List<Phase0aActor>.unmodifiable(state.enemies.map(_snapshotActor)),
  skillSlots: List<Phase0aSkillSlot>.unmodifiable(state.skillSlots),
  winCondition: state.winCondition,
);

Phase0aActor _snapshotActor(Phase0aActor actor) => Phase0aActor(
  id: actor.id,
  side: actor.side,
  position: actor.position,
  facing: actor.facing,
  maxHealth: actor.maxHealth,
  currentHealth: actor.currentHealth,
  moveSpeed: actor.moveSpeed,
  qiCurrent: actor.qiCurrent,
  qiMax: actor.qiMax,
  attackCooldownRemaining: actor.attackCooldownRemaining,
  defeatKind: actor.defeatKind,
  isBoss: actor.isBoss,
  autoUltimate: actor.autoUltimate,
  bossPhases: _snapshotBossPhases(actor.bossPhases),
  bossPhaseIndex: actor.bossPhaseIndex,
  unlockedEnemySkillIds: List<String>.unmodifiable(actor.unlockedEnemySkillIds),
  enemySkillCooldowns: Map<String, double>.unmodifiable(
    actor.enemySkillCooldowns,
  ),
  chargeCast: actor.chargeCast,
  phaseChargeCasts: List<Phase0aChargeCast?>.unmodifiable(
    actor.phaseChargeCasts,
  ),
  staggerTicksTotal: actor.staggerTicksTotal,
  guardianDefIds: List<String>.unmodifiable(actor.guardianDefIds),
  guardianWardMult: actor.guardianWardMult,
  guardInterceptsInterrupt: actor.guardInterceptsInterrupt,
  guardianCoopUsedInCharge: actor.guardianCoopUsedInCharge,
  vulnerabilityMult: actor.vulnerabilityMult,
  chargingCast: actor.chargingCast,
  chargeTicksRemaining: actor.chargeTicksRemaining,
  staggerTicksRemaining: actor.staggerTicksRemaining,
  posture: actor.posture,
);

List<BossPhaseDef>? _snapshotBossPhases(List<BossPhaseDef>? phases) =>
    phases == null
    ? null
    : List<BossPhaseDef>.unmodifiable(
        phases.map(
          (phase) => BossPhaseDef(
            hpThresholdPct: phase.hpThresholdPct,
            unlockSkillIds: List<String>.unmodifiable(phase.unlockSkillIds),
            aiMode: phase.aiMode,
            onEnterMechanic: phase.onEnterMechanic,
            titleKey: phase.titleKey,
          ),
        ),
      );
