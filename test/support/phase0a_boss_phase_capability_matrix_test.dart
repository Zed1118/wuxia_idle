import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';

import 'phase0a_production_preflight_manifest.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('production boss phase capability matrix is derived from manifest', () {
    final stages = repo.stageDefs.values
        .where(
          (stage) =>
              stage.stageType == StageType.mainline &&
              (stage.chapterIndex ?? 0) >= 2,
        )
        .toList();
    final towers = repo.towerFloors;
    expect(stages, hasLength(100));
    expect(towers, hasLength(49));

    final entries = [
      ...stages.map(Phase0aProductionPreflightManifest.classifyStage),
      ...towers.map(Phase0aProductionPreflightManifest.classifyTower),
    ];
    expect(entries, hasLength(149));
    expect(entries.map((entry) => entry.key).toSet(), hasLength(149));

    final bossPhaseEntries = entries
        .where(
          (entry) =>
              entry.skipReason == 'unsupported_boss_phase_or_charge_semantics',
        )
        .toList();
    expect(bossPhaseEntries, hasLength(24));
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'stage'),
      hasLength(19),
    );
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'tower'),
      hasLength(5),
    );

    for (final entry in bossPhaseEntries) {
      final phases = switch (entry.kind) {
        Phase0aPreflightContentKind.stage =>
          repo.stageDefs[entry.id]!.enemyTeam.expand(
            (enemy) => enemy.bossPhases ?? const <BossPhaseDef>[],
          ),
        Phase0aPreflightContentKind.tower =>
          repo.towerFloors
              .firstWhere((floor) => 'tower_${floor.floorIndex}' == entry.id)
              .enemyTeam
              .expand((enemy) => enemy.bossPhases ?? const <BossPhaseDef>[]),
      };
      expect(
        phases,
        contains(
          predicate<BossPhaseDef>(
            (phase) => phase.onEnterMechanic == BossPhaseMechanic.chargeCounter,
          ),
        ),
        reason: '${entry.key} must expose a chargeCounter phase',
      );
    }

    final stageBossPhaseEntries = bossPhaseEntries.where(
      (entry) => entry.kind == Phase0aPreflightContentKind.stage,
    );
    for (final entry in stageBossPhaseEntries) {
      final hasTopLevelCharge = repo.stageDefs[entry.id]!.enemyTeam.any(
        (enemy) => enemy.chargeSkillId != null,
      );
      expect(hasTopLevelCharge, isTrue, reason: entry.key);
    }
    final towerBossPhaseEntries = bossPhaseEntries.where(
      (entry) => entry.kind == Phase0aPreflightContentKind.tower,
    );
    for (final entry in towerBossPhaseEntries) {
      final hasTopLevelCharge = repo.towerFloors
          .firstWhere((floor) => 'tower_${floor.floorIndex}' == entry.id)
          .enemyTeam
          .any((enemy) => enemy.chargeSkillId != null);
      expect(hasTopLevelCharge, isFalse, reason: entry.key);
    }

    final dynamicEntries = entries
        .where(
          (entry) =>
              entry.skipReason == 'unsupported_vulnerability_window' ||
              entry.skipReason == 'unsupported_guardian_ward',
        )
        .toList();
    expect(dynamicEntries, isNotEmpty);
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_32').skipReason,
      'unsupported_vulnerability_window',
    );
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_42').skipReason,
      'unsupported_guardian_ward',
    );
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_49').skipReason,
      'unsupported_guardian_ward',
    );
    expect(
      dynamicEntries
          .map((entry) => entry.key)
          .toSet()
          .intersection(bossPhaseEntries.map((entry) => entry.key).toSet()),
      isEmpty,
      reason: 'guardian/vulnerability precedence must hide phase reason',
    );
  });
}
