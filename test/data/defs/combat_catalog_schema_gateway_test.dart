import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';

CombatCatalogReferenceIndex _references({
  Iterable<String> entranceIds = const ['entrance_left'],
  Iterable<String> positionIds = const ['position_left_low'],
  Iterable<String> behaviorIds = const ['behavior_press_forward'],
  Iterable<String> attackSetIds = const ['attack_set_bandit_blade'],
  Iterable<String> attackTagIds = const ['attack_tag_melee'],
  Iterable<String> postureProfileIds = const ['posture_bandit_light'],
  Iterable<String> dropGroupIds = const ['drop_group_bandit'],
  Iterable<String> sfxGroupIds = const ['sfx_group_bandit_blade'],
  Iterable<String> visualVariantIds = const ['visual_bandit_blade_a'],
  Iterable<String> objectiveTargetIds = const ['bandit_blade_01'],
  Iterable<String> objectiveAnchorIds = const ['ward_anchor'],
  Iterable<String> objectiveEntityIds = const ['escort_cart'],
  Iterable<String> objectiveCheckpointIds = const ['checkpoint_exit'],
  Iterable<String> objectiveMarkerIds = const ['route_marker'],
}) => CombatCatalogReferenceIndex(
  entranceIds: entranceIds,
  positionIds: positionIds,
  behaviorIds: behaviorIds,
  attackSetIds: attackSetIds,
  attackTagIds: attackTagIds,
  postureProfileIds: postureProfileIds,
  dropGroupIds: dropGroupIds,
  sfxGroupIds: sfxGroupIds,
  visualVariantIds: visualVariantIds,
  objectiveTargetIds: objectiveTargetIds,
  objectiveAnchorIds: objectiveAnchorIds,
  objectiveEntityIds: objectiveEntityIds,
  objectiveCheckpointIds: objectiveCheckpointIds,
  objectiveMarkerIds: objectiveMarkerIds,
);

CombatArchetypeVariant _variant({
  String attackSetId = 'attack_set_bandit_blade',
  Iterable<String> attackTagIds = const ['attack_tag_melee'],
  String postureProfileId = 'posture_bandit_light',
  String dropGroupId = 'drop_group_bandit',
  String sfxGroupId = 'sfx_group_bandit_blade',
  Iterable<String> visualVariantIds = const ['visual_bandit_blade_a'],
}) => CombatArchetypeVariant(
  roleId: 'blade',
  displayName: '刀手',
  attackTokenKind: CombatAttackTokenKind.melee,
  hpMultiplier: 1,
  attackMultiplier: 1,
  defenseMultiplier: 1,
  speedMultiplier: 1,
  attackSetId: attackSetId,
  attackTagIds: attackTagIds,
  postureProfileId: postureProfileId,
  dropGroupId: dropGroupId,
  sfxGroupId: sfxGroupId,
  visualVariantIds: visualVariantIds,
);

CombatEncounterSpawnEntry _spawn({
  String entranceId = 'entrance_left',
  String positionId = 'position_left_low',
  String behaviorId = 'behavior_press_forward',
}) => CombatEncounterSpawnEntry(
  entryId: 'bandit_blade_01',
  archetypeId: 'bandit',
  roleId: 'blade',
  entranceId: entranceId,
  positionId: positionId,
  behaviorId: behaviorId,
);

CombatObjectiveCompositionRef _objectives({
  CombatObjectiveCompletionRule rule = CombatObjectiveCompletionRule.all,
}) => CombatObjectiveCompositionRef(
  completionRule: rule,
  clauses: [
    CombatObjectiveClauseRef(
      id: 'clear_blockers',
      primitive: CombatDefeatTargetsRef(const ['bandit_blade_01']),
    ),
    CombatObjectiveClauseRef(
      id: 'reach_exit',
      primitive: CombatReachCheckpointRef(const ['checkpoint_exit']),
    ),
  ],
);

CombatEncounterDef _encounter({
  CombatEncounterSpawnEntry? spawn,
  CombatObjectiveCompositionRef? objectives,
}) => CombatEncounterDef(
  id: 'encounter_roadbreak',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 1,
    reinforcementThreshold: 0,
    entryWarningTicks: 1,
    attackGraceTicks: 1,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 1,
    ranged: 0,
    charge: 0,
    support: 0,
  ),
  spawnEntries: [spawn ?? _spawn()],
  objectives: objectives ?? _objectives(),
);

CombatCatalogManifestDef _manifest({
  CombatCatalogReferenceIndex? references,
  CombatArchetypeVariant? variant,
  CombatEncounterSpawnEntry? spawn,
  CombatObjectiveCompositionRef? objectives,
}) => CombatCatalogManifestDef(
  referenceIndex: references ?? _references(),
  archetypes: [
    CombatEnemyArchetypeDef(id: 'bandit', variants: [variant ?? _variant()]),
  ],
  encounters: [_encounter(spawn: spawn, objectives: objectives)],
  stageAssignments: [
    CombatStageEncounterAssignment(
      stageId: 'stage_01_01',
      migrationState: CombatEncounterMigrationState.migrated,
      encounterId: 'encounter_roadbreak',
    ),
  ],
);

void main() {
  group('M2 catalog schema gateway', () {
    test(
      'keeps every spawn and archetype reference explicit and immutable',
      () {
        final tags = <String>['attack_tag_melee'];
        final visuals = <String>['visual_bandit_blade_a'];
        final variant = _variant(attackTagIds: tags, visualVariantIds: visuals);
        final spawn = _spawn();

        tags.add('attack_tag_mutated');
        visuals.clear();

        expect(variant.attackSetId, 'attack_set_bandit_blade');
        expect(variant.attackTagIds, {'attack_tag_melee'});
        expect(variant.postureProfileId, 'posture_bandit_light');
        expect(variant.dropGroupId, 'drop_group_bandit');
        expect(variant.sfxGroupId, 'sfx_group_bandit_blade');
        expect(variant.visualVariantIds, {'visual_bandit_blade_a'});
        expect(spawn.entranceId, 'entrance_left');
        expect(spawn.positionId, 'position_left_low');
        expect(spawn.behaviorId, 'behavior_press_forward');
        expect(
          () => variant.attackTagIds.add('attack_tag_other'),
          throwsUnsupportedError,
        );
        expect(
          () => variant.visualVariantIds.add('visual_other'),
          throwsUnsupportedError,
        );
      },
    );

    test('rejects empty duplicate or whitespace reference ids', () {
      expect(() => _variant(attackTagIds: const []), throwsArgumentError);
      expect(
        () => _variant(visualVariantIds: const ['v', 'v']),
        throwsArgumentError,
      );
      expect(() => _variant(attackSetId: 'attack set'), throwsArgumentError);
      expect(() => _spawn(entranceId: ''), throwsArgumentError);
      expect(() => _spawn(positionId: 'bad position'), throwsArgumentError);
      expect(() => _spawn(behaviorId: '  '), throwsArgumentError);
      expect(
        () => _references(behaviorIds: const ['behavior_a', 'behavior_a']),
        throwsArgumentError,
      );
      expect(
        () => _references(objectiveTargetIds: const ['target', 'target']),
        throwsArgumentError,
      );
      expect(
        () => _references(objectiveAnchorIds: const ['bad anchor']),
        throwsArgumentError,
      );
      expect(
        () => _references(objectiveEntityIds: const ['']),
        throwsArgumentError,
      );
      expect(
        () => _references(
          objectiveCheckpointIds: const ['checkpoint', 'checkpoint'],
        ),
        throwsArgumentError,
      );
      expect(
        () => _references(objectiveMarkerIds: const ['bad\nmarker']),
        throwsArgumentError,
      );
    });

    test('reference index snapshots caller sets and exposes no mutation', () {
      final entrances = <String>['entrance_left'];
      final targets = <String>['bandit_blade_01'];
      final references = _references(
        entranceIds: entrances,
        objectiveTargetIds: targets,
      );
      entrances
        ..clear()
        ..add('entrance_mutated');
      targets
        ..clear()
        ..add('target_mutated');

      expect(references.entranceIds, {'entrance_left'});
      expect(references.objectiveTargetIds, {'bandit_blade_01'});
      expect(
        () => references.entranceIds.add('entrance_other'),
        throwsUnsupportedError,
      );
      expect(
        () => references.objectiveTargetIds.add('target_other'),
        throwsUnsupportedError,
      );
    });

    test('expresses flat all and any objective compositions explicitly', () {
      final all = _objectives();
      final any = _objectives(rule: CombatObjectiveCompletionRule.any);

      expect(all.completionRule, CombatObjectiveCompletionRule.all);
      expect(any.completionRule, CombatObjectiveCompletionRule.any);
      expect(all.clauses.map((clause) => clause.id), [
        'clear_blockers',
        'reach_exit',
      ]);
      expect(all.clauses.first.primitive, isA<CombatDefeatTargetsRef>());
      expect(all.clauses.last.primitive, isA<CombatReachCheckpointRef>());
      expect(() => all.clauses.clear(), throwsUnsupportedError);
    });

    test('objective compositions reject empty and duplicate clause ids', () {
      expect(
        () => CombatObjectiveCompositionRef(
          completionRule: CombatObjectiveCompletionRule.all,
          clauses: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => CombatObjectiveCompositionRef(
          completionRule: CombatObjectiveCompletionRule.any,
          clauses: [
            CombatObjectiveClauseRef(
              id: 'same',
              primitive: CombatSurviveDurationRef(requiredTicks: 1),
            ),
            CombatObjectiveClauseRef(
              id: 'same',
              primitive: CombatDefeatCommanderRef(commanderId: 'chief'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test(
      'typed manifest fails closed on every external reference namespace',
      () {
        final cases = <CombatCatalogManifestDef Function()>[
          () => _manifest(spawn: _spawn(entranceId: 'unknown_entrance')),
          () => _manifest(spawn: _spawn(positionId: 'unknown_position')),
          () => _manifest(spawn: _spawn(behaviorId: 'unknown_behavior')),
          () => _manifest(variant: _variant(attackSetId: 'unknown_attack_set')),
          () => _manifest(
            variant: _variant(attackTagIds: const ['unknown_attack_tag']),
          ),
          () =>
              _manifest(variant: _variant(postureProfileId: 'unknown_posture')),
          () => _manifest(variant: _variant(dropGroupId: 'unknown_drop_group')),
          () => _manifest(variant: _variant(sfxGroupId: 'unknown_sfx_group')),
          () => _manifest(
            variant: _variant(visualVariantIds: const ['unknown_visual']),
          ),
        ];

        for (final build in cases) {
          expect(build, throwsArgumentError);
        }
      },
    );

    test('typed manifest validates every id-bearing objective primitive', () {
      final cases = <CombatObjectivePrimitiveRef>[
        CombatDefeatTargetsRef(const ['unknown_target']),
        CombatDestroyAnchorsRef(const ['unknown_anchor']),
        CombatDefendEntityRef(entityId: 'unknown_entity', requiredTicks: 1),
        CombatReachCheckpointRef(const ['unknown_checkpoint']),
        CombatTouchMarkersRef(const ['unknown_marker']),
        CombatPursueTargetRef(targetId: 'unknown_target'),
        CombatDefeatCommanderRef(commanderId: 'unknown_target'),
      ];

      for (final primitive in cases) {
        expect(
          () => _manifest(
            objectives: CombatObjectiveCompositionRef(
              completionRule: CombatObjectiveCompletionRule.all,
              clauses: [
                CombatObjectiveClauseRef(id: 'objective', primitive: primitive),
              ],
            ),
          ),
          throwsArgumentError,
        );
      }
    });

    test('typed manifest accepts known objective refs under all and any', () {
      expect(_manifest, returnsNormally);
      expect(
        () => _manifest(
          objectives: _objectives(rule: CombatObjectiveCompletionRule.any),
        ),
        returnsNormally,
      );
    });
  });
}
