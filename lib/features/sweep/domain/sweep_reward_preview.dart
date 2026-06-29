import '../../../core/domain/item_source.dart';
import '../../../core/domain/item_usage.dart';
import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../inventory/application/item_usage_lookup_service.dart';
import '../../inventory/application/material_source_lookup_service.dart';
import '../../mainline/domain/mainline_replay_reward_route.dart';

enum SweepProficiencyHint { skillManual, skillFragment, chargeSkill }

class SweepRewardPreview {
  const SweepRewardPreview({
    required this.primaryKinds,
    required this.equipmentDropCount,
    required this.possibleItemNames,
    required this.proficiencyHints,
    required this.materialHits,
  });

  final List<MainlineReplayRewardKind> primaryKinds;
  final int equipmentDropCount;
  final List<String> possibleItemNames;
  final List<SweepProficiencyHint> proficiencyHints;
  final List<SweepMaterialHit> materialHits;

  bool get isEmpty =>
      primaryKinds.isEmpty &&
      equipmentDropCount == 0 &&
      possibleItemNames.isEmpty &&
      proficiencyHints.isEmpty &&
      materialHits.isEmpty;

  factory SweepRewardPreview.fromMainlineStages({
    required Iterable<StageDef> stages,
    required GameRepository repo,
  }) {
    final kindSet = <MainlineReplayRewardKind>{};
    final equipmentIds = <String>{};
    final itemIds = <String>{};
    final hintSet = <SweepProficiencyHint>{};
    final sourceStageIdsByItem = <String, Set<String>>{};

    for (final stage in stages) {
      kindSet.addAll(MainlineReplayRewardRoute.fromStage(stage).kinds);

      for (final entry in stage.dropTable) {
        switch (entry) {
          case EquipmentDrop(:final equipmentDefId):
            equipmentIds.add(equipmentDefId);
          case ItemDrop(:final inventoryItemDefId):
            itemIds.add(inventoryItemDefId);
            sourceStageIdsByItem
                .putIfAbsent(inventoryItemDefId, () => <String>{})
                .add(stage.id);
        }
      }

      if (stage.dropSkillManualId != null) {
        hintSet.add(SweepProficiencyHint.skillManual);
      }
      if (stage.dropSkillFragmentId != null) {
        hintSet.add(SweepProficiencyHint.skillFragment);
      }
      if (stage.enemyTeam.any((enemy) => enemy.chargeSkillId != null)) {
        hintSet.add(SweepProficiencyHint.chargeSkill);
      }
    }

    final usageLookup = ItemUsageLookupService(repo);
    final sourceLookup = MaterialSourceLookupService(repo);
    final materialHits = <SweepMaterialHit>[];

    for (final itemId in itemIds) {
      final usages = usageLookup.usagesFor(itemId);
      if (usages.isEmpty) continue;
      final sourceStageIds = sourceStageIdsByItem[itemId] ?? const <String>{};
      final hasChapterSource = sourceLookup.sourcesFor(itemId).any((source) {
        return source.kind == ItemSourceKind.mainline &&
            source.sourceId != null &&
            sourceStageIds.contains(source.sourceId);
      });
      if (!hasChapterSource) continue;
      materialHits.add(
        SweepMaterialHit(
          itemId: itemId,
          itemName: repo.itemDefs[itemId]?.name ?? itemId,
          usages: usages,
        ),
      );
    }

    materialHits.sort((a, b) => a.itemName.compareTo(b.itemName));

    return SweepRewardPreview(
      primaryKinds: [
        for (final kind in MainlineReplayRewardKind.values)
          if (kindSet.contains(kind)) kind,
      ],
      equipmentDropCount: equipmentIds.length,
      possibleItemNames: [
        for (final itemId in itemIds) repo.itemDefs[itemId]?.name ?? itemId,
      ]..sort(),
      proficiencyHints: [
        for (final hint in SweepProficiencyHint.values)
          if (hintSet.contains(hint)) hint,
      ],
      materialHits: List.unmodifiable(materialHits),
    );
  }
}

class SweepMaterialHit {
  const SweepMaterialHit({
    required this.itemId,
    required this.itemName,
    required this.usages,
  });

  final String itemId;
  final String itemName;
  final List<ItemUsage> usages;
}
