import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameRepository repository;

  setUpAll(() async {
    repository = await GameRepository.loadAllDefs(
      loader: _fileLoader,
      assetExists: (path) async => File(path).existsSync(),
    );
  });
  tearDownAll(GameRepository.resetForTest);

  test('stage_02_02 is the real Chapter 2 survive-duration stage', () {
    final assignment = repository.combatCatalog!.assignmentForStage(
      'stage_02_02',
    );
    final encounter = repository.combatEncounterForStage('stage_02_02')!;

    expect(assignment?.encounterId, 'ch2_encounter_02_teahouse');
    expect(encounter.objectives.clauses, hasLength(1));
    expect(
      encounter.objectives.clauses.single.primitive,
      isA<CombatSurviveDurationRef>(),
    );
    expect(
      (encounter.objectives.clauses.single.primitive
              as CombatSurviveDurationRef)
          .requiredTicks,
      900,
      reason: '90 seconds is the current TUNING candidate, not a frozen value',
    );
  });

  test('stage_07_04 is the real Chapter 7 pursue-target stage', () {
    final assignment = repository.combatCatalog!.assignmentForStage(
      'stage_07_04',
    );
    final encounter = repository.combatEncounterForStage('stage_07_04');

    expect(assignment?.encounterId, 'ch7_encounter_04_grey_cloak_pursuit');
    expect(encounter, isNotNull);
    expect(encounter!.objectives.clauses, hasLength(1));
    final primitive = encounter.objectives.clauses.single.primitive;
    expect(primitive, isA<CombatPursueTargetRef>());
    expect((primitive as CombatPursueTargetRef).targetId, 'ch7_s04_grey_cloak');
    expect(
      encounter.spawnEntries.map((entry) => entry.entryId),
      contains('ch7_s04_grey_cloak'),
      reason: 'the objective id must resolve to the same production actor',
    );
  });

  test('production catalog closes six executable objective families', () {
    final kinds = <String>{
      for (final encounter in repository.combatCatalog!.encounters)
        for (final clause in encounter.objectives.clauses)
          switch (clause.primitive) {
            CombatDefeatTargetsRef() => 'defeat_targets',
            CombatDestroyAnchorsRef() => 'destroy_anchors',
            CombatDefendEntityRef() => 'defend_entity',
            CombatSurviveDurationRef() => 'survive_duration',
            CombatReachCheckpointRef() => 'reach_checkpoint',
            CombatTouchMarkersRef() => 'touch_markers',
            CombatPursueTargetRef() => 'pursue_target',
            CombatDefeatCommanderRef() => 'defeat_commander',
          },
    };

    expect(kinds, {
      'defeat_targets',
      'destroy_anchors',
      'survive_duration',
      'reach_checkpoint',
      'pursue_target',
      'defeat_commander',
    });
    expect(
      kinds,
      isNot(contains('defend_entity')),
      reason:
          'defend_entity cannot enter production until a durable positioned '
          'objective entity has an authoritative runtime owner',
    );
  });
}
