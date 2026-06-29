import '../../../core/domain/enums.dart'
    show StageStatus, isTechniqueScrollDefId;
import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/stage_def.dart';

enum MainlineReplayRewardKind { equipment, material, proficiency }

class MainlineReplayRewardRoute {
  const MainlineReplayRewardRoute._(this.kinds);

  final List<MainlineReplayRewardKind> kinds;

  bool get isEmpty => kinds.isEmpty;

  factory MainlineReplayRewardRoute.fromStage(StageDef stage) {
    var hasEquipment = false;
    var hasMaterial = false;
    var hasProficiency = false;

    for (final entry in stage.dropTable) {
      switch (entry) {
        case EquipmentDrop():
          hasEquipment = true;
        case ItemDrop(:final inventoryItemDefId):
          if (!isTechniqueScrollDefId(inventoryItemDefId)) {
            hasMaterial = true;
          }
      }
    }

    if (stage.dropSkillManualId != null || stage.dropSkillFragmentId != null) {
      hasProficiency = true;
    }
    if (stage.enemyTeam.any((enemy) => enemy.chargeSkillId != null)) {
      hasProficiency = true;
    }

    return MainlineReplayRewardRoute._([
      if (hasEquipment) MainlineReplayRewardKind.equipment,
      if (hasMaterial) MainlineReplayRewardKind.material,
      if (hasProficiency) MainlineReplayRewardKind.proficiency,
    ]);
  }
}

typedef MainlineChapterFarmStageEntry = ({StageDef def, StageStatus status});

class MainlineChapterFarmSpot {
  const MainlineChapterFarmSpot({
    required this.stageIndex,
    required this.stage,
    required this.route,
  });

  final int stageIndex;
  final StageDef stage;
  final MainlineReplayRewardRoute route;
}

class MainlineChapterFarmSpotSelector {
  const MainlineChapterFarmSpotSelector._();

  static List<MainlineChapterFarmSpot> fromEntries(
    List<MainlineChapterFarmStageEntry> entries, {
    int limit = 2,
  }) {
    if (limit <= 0 || entries.isEmpty) return const [];
    if (entries.any((entry) => entry.status != StageStatus.cleared)) {
      return const [];
    }

    final candidates = <({MainlineChapterFarmSpot spot, int score})>[];
    for (var i = 0; i < entries.length; i++) {
      final stage = entries[i].def;
      final route = MainlineReplayRewardRoute.fromStage(stage);
      if (route.isEmpty) continue;
      final spot = MainlineChapterFarmSpot(
        stageIndex: i + 1,
        stage: stage,
        route: route,
      );
      candidates.add((spot: spot, score: _score(spot)));
    }

    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.spot.stageIndex.compareTo(b.spot.stageIndex);
    });

    return [for (final candidate in candidates.take(limit)) candidate.spot];
  }

  static int _score(MainlineChapterFarmSpot spot) {
    final kinds = spot.route.kinds;
    return kinds.length * 100 +
        (spot.stage.isBossStage ? 24 : 0) +
        (kinds.contains(MainlineReplayRewardKind.proficiency) ? 14 : 0) +
        (kinds.contains(MainlineReplayRewardKind.equipment) ? 8 : 0) +
        (kinds.contains(MainlineReplayRewardKind.material) ? 6 : 0);
  }
}
