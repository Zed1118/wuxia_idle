import '../../features/battle/domain/phase0a/encounter_enemy_roster.dart';
import '../../features/battle/domain/phase0a/phase0a_combat_model.dart';
import '../../features/battle/domain/phase0a/spawn_director.dart';
import '../defs/combat_encounter_def.dart';

/// Constructs one complete runtime actor for a content spawn entry.
///
/// [enemyId] is the authoritative runtime instance id from the exact
/// [SpawnDirector]. The mapper never derives an actor id from the content
/// entry id and supplies no actor defaults.
typedef CombatEncounterActorFactory =
    Phase0aActor Function(CombatEncounterSpawnEntry entry, String enemyId);

/// Maps one content definition and its exact spawn director to a fresh roster.
///
/// Before invoking [createActor], the mapper verifies that the definition and
/// director contain exactly the same entry ids. It then invokes the factory
/// once per entry in content order, passing the director snapshot's runtime
/// enemy id. Actor identity, side, liveness and player-id constraints remain
/// owned by [Phase0aEncounterRoster].
///
/// This function does not advance [director], retain [createActor], provide
/// actor defaults or connect a production host.
Phase0aEncounterRoster mapCombatEncounterRoster(
  CombatEncounterDef definition,
  SpawnDirector director, {
  required String playerId,
  required CombatEncounterActorFactory createActor,
}) {
  final unitsByEntryId = <String, SpawnUnitSnapshot>{
    for (final unit in director.state.units) unit.entryId: unit,
  };
  final definitionEntryIds = {
    for (final entry in definition.spawnEntries) entry.entryId,
  };

  if (definitionEntryIds.length != unitsByEntryId.length ||
      !definitionEntryIds.every(unitsByEntryId.containsKey)) {
    final missingFromDirector =
        definitionEntryIds
            .where((entryId) => !unitsByEntryId.containsKey(entryId))
            .toList()
          ..sort();
    final extraInDirector =
        unitsByEntryId.keys
            .where((entryId) => !definitionEntryIds.contains(entryId))
            .toList()
          ..sort();
    throw ArgumentError.value(
      {
        'missingFromDirector': missingFromDirector,
        'extraInDirector': extraInDirector,
      },
      'director',
      'entry ids must exactly match definition.spawnEntries',
    );
  }

  final bindings = <Phase0aEncounterRosterBinding>[
    for (final entry in definition.spawnEntries)
      Phase0aEncounterRosterBinding(
        entryId: entry.entryId,
        actor: createActor(entry, unitsByEntryId[entry.entryId]!.enemyId),
      ),
  ];

  return Phase0aEncounterRoster(
    director: director,
    playerId: playerId,
    bindings: bindings,
  );
}
