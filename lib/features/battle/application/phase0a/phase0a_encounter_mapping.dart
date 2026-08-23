import '../../../../data/defs/skill_def.dart';
import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_damage_kind.dart';
import '../../domain/phase0a/spawn_director.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_player_input_adapter.dart';

/// Frozen-input carrier for Phase 0A dynamic encounters (D09 dispatch).
///
/// Holds every runtime input already frozen by
/// [Phase0aProductionFlowAssembler.assembleEncounter]: the initial arena
/// state, spawn director, roster, combatant inputs, move bindings and both
/// input adapters. Lists and maps are defensively copied to unmodifiable
/// views, so external mutation after construction cannot pollute the frozen
/// mapping (same defensive-copy discipline as the snapshot bundle / roster).
///
/// This class copies no damage, AI, movement, spawn, terminal or RNG rules.
/// [NumbersConfig] and the single caller [Random] stay explicit at assembly
/// time (the typed bridge) so tuning and RNG ownership never enter the
/// mapping; an observe-only observer is likewise passed at assembly time.
///
/// Construction validates exactly three structural facts (zero RNG
/// consumption): director/roster identity, roster player id consistency
/// against the initial state player id, and duplicate combatant actor ids.
/// Full actor coverage, player adapter id and move-binding validation remain
/// the existing assembler's fail-closed responsibility to avoid behavior
/// drift.
final class Phase0aEncounterMapping {
  Phase0aEncounterMapping({
    required this.initialState,
    required this.director,
    required this.roster,
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required this.playerAdapter,
    required this.enemyAiAdapter,
  }) : _combatants = _freezeCombatants(combatants),
       _moveBindings = Map.unmodifiable(moveBindings) {
    _checkDirectorIdentity(roster, director);
    _checkPlayerId(roster, initialState);
  }

  final Phase0aArenaState initialState;
  final SpawnDirector director;
  final Phase0aEncounterRoster roster;
  final List<Phase0aCombatantInput> _combatants;
  final Map<Phase0aDamageKind, SkillDef?> _moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;

  /// Frozen combatant inputs; unmodifiable, safe to hand to the assembler.
  List<Phase0aCombatantInput> get combatants => _combatants;

  /// Frozen move bindings (null value = control-only); unmodifiable, safe to
  /// hand to the assembler.
  Map<Phase0aDamageKind, SkillDef?> get moveBindings => _moveBindings;

  /// Defensive copy plus duplicate actor id check. The copy is taken from a
  /// fresh unmodifiable list, so later mutation of the caller's list cannot
  /// leak into the mapping.
  static List<Phase0aCombatantInput> _freezeCombatants(
    List<Phase0aCombatantInput> combatants,
  ) {
    final seen = <String>{};
    final duplicates = <String>[];
    for (final combatant in combatants) {
      if (!seen.add(combatant.actorId)) {
        duplicates.add(combatant.actorId);
      }
    }
    if (duplicates.isNotEmpty) {
      final sorted = duplicates.toSet().toList()..sort();
      throw ArgumentError.value(
        combatants,
        'combatants',
        'duplicate Phase0a actor ids: $sorted',
      );
    }
    return List.unmodifiable(combatants);
  }

  /// The roster must be bound to the very same director instance carried by
  /// the mapping (mirrors the runtime flow construction check).
  static void _checkDirectorIdentity(
    Phase0aEncounterRoster roster,
    SpawnDirector director,
  ) {
    if (!identical(roster.director, director)) {
      throw ArgumentError.value(roster, 'roster', 'director identity mismatch');
    }
  }

  /// The roster player id must equal the initial state player id; the
  /// player-adapter id check stays with the assembler.
  static void _checkPlayerId(
    Phase0aEncounterRoster roster,
    Phase0aArenaState initialState,
  ) {
    final playerId = roster.playerId;
    final initialPlayerId = initialState.player.id;
    if (playerId != initialPlayerId) {
      throw ArgumentError.value(
        playerId,
        'roster',
        'playerId must match initial state player id($initialPlayerId)',
      );
    }
  }
}
