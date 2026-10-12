import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUp(() async => repo = await loadTestGameRepository());

  Phase0aMainlineEncounterHostBuildRequest request({
    required _UnusedRuntime source,
    CombatCatalogManifestDef? catalog,
    Phase0aMainlineEncounterRouteAuthority? authority,
    String stageId = 'stage_01_03',
  }) => Phase0aMainlineEncounterHostBuildRequest(
    stage: repo.getStage(stageId),
    playerMapping: Phase0aStageContentMapper.mapPlayerOnly(
      contentId: stageId,
      playerSnapshot: testCombatantSnapshot(includeProductionBasicAttack: true),
      numbers: repo.numbers,
    ),
    numbers: repo.numbers,
    cycleIndex: 1,
    rng: Random(22),
    runtimeBindingSource: source,
    catalogOverride: catalog,
    routeAuthority: authority,
  );

  for (final legacy in [false, true]) {
    test(
      'mainline rejects ${legacy ? 'legacy' : 'missing'} assignment before runtime loading',
      () async {
        const stageId = 'stage_01_03';
        final current = repo.combatCatalog!;
        final removedEncounter = current
            .assignmentForStage(stageId)!
            .encounterId;
        final catalog = CombatCatalogManifestDef(
          referenceIndex: current.referenceIndex,
          archetypes: current.archetypes,
          encounters: current.encounters.where((e) => e.id != removedEncounter),
          stageAssignments: [
            for (final assignment in current.stageAssignments)
              if (assignment.stageId != stageId) assignment,
            if (legacy)
              CombatStageEncounterAssignment(
                stageId: stageId,
                migrationState: CombatEncounterMigrationState.legacy,
              ),
          ],
        );
        final source = _UnusedRuntime();
        await expectLater(
          createFreshPhase0aMainlineEncounter(
            request(source: source, catalog: catalog),
          ),
          throwsStateError,
        );
        expect(source.calls, 0);
      },
    );
  }

  test('mainline cannot restore legacy through route authority', () async {
    final source = _UnusedRuntime();
    await expectLater(
      createFreshPhase0aMainlineEncounter(
        request(
          source: source,
          authority: Phase0aMainlineEncounterRouteAuthority(
            loader: ({required stageId}) =>
                Phase0aMainlineEncounterRouteMode.legacy,
          ),
        ),
      ),
      throwsStateError,
    );
    expect(source.calls, 0);
  });

  test(
    'mainline cannot simulate from a fixture repository without catalog',
    () async {
      GameRepository.resetForTest();
      addTearDown(() async {
        GameRepository.resetForTest();
        await loadTestGameRepository();
      });
      await GameRepository.loadAllDefs(
        loader: (path) {
          if (path == 'data/combat/manifest.yaml') {
            throw FileSystemException(
              'missing',
              path,
              const OSError('missing', 2),
            );
          }
          return File(path).readAsString();
        },
      );
      expect(GameRepository.instance.combatCatalog, isNull);
      final source = _UnusedRuntime();
      await expectLater(
        createFreshPhase0aMainlineEncounter(request(source: source)),
        throwsStateError,
      );
      expect(source.calls, 0);
    },
  );

  for (final type in [
    StageType.innerDemon,
    StageType.lightFoot,
    StageType.massBattle,
  ]) {
    test('$type keeps its dedicated special-mode mapping', () async {
      final stage = repo.stageDefs.values.firstWhere(
        (stage) => stage.stageType == type,
      );
      final source = _UnusedRuntime();
      expect(
        await createFreshPhase0aMainlineEncounter(
          request(source: source, stageId: stage.id),
        ),
        isNull,
      );
      expect(source.calls, 0);
    });
  }
}

final class _UnusedRuntime
    implements Phase0aMainlineEncounterRuntimeBindingSource {
  int calls = 0;

  @override
  Future<Phase0aMainlineEncounterRuntimeBindingBundle> load({
    required String stageId,
    required String encounterId,
    required int cycleIndex,
  }) async {
    calls++;
    throw StateError('Invalid route reached the runtime loader');
  }
}
