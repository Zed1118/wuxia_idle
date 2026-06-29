import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_replay_reward_route.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_reward_preview.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('aggregates primary kinds, possible drops and proficiency direction', () {
    final repo = GameRepository.instance;
    final stages = [
      repo.getStage('stage_01_01'),
      repo.getStage('stage_01_05'),
    ];

    final preview = SweepRewardPreview.fromMainlineStages(
      stages: stages,
      repo: repo,
    );

    expect(
      preview.primaryKinds,
      containsAllInOrder(const [
        MainlineReplayRewardKind.equipment,
        MainlineReplayRewardKind.material,
        MainlineReplayRewardKind.proficiency,
      ]),
    );
    expect(preview.equipmentDropCount, greaterThan(0));
    expect(preview.possibleItemNames, isNotEmpty);
    expect(
      preview.proficiencyHints,
      contains(SweepProficiencyHint.chargeSkill),
    );
  });

  test('material hits only include chapter drops with existing usage routes', () {
    final repo = GameRepository.instance;
    final stage = repo.stageDefs.values.firstWhere((stage) {
      return stage.dropTable.any(
        (entry) =>
            entry is ItemDrop && entry.inventoryItemDefId == 'item_mojianshi',
      );
    });

    final preview = SweepRewardPreview.fromMainlineStages(
      stages: [stage],
      repo: repo,
    );

    final mojianshi = preview.materialHits.firstWhere(
      (hit) => hit.itemId == 'item_mojianshi',
    );

    expect(mojianshi.itemName, '磨剑石');
    expect(
      mojianshi.usages.map((usage) => usage.kind),
      contains(ItemUsageKind.equipmentEnhancement),
    );
  });
}
