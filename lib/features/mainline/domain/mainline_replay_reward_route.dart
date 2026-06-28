import '../../../core/domain/enums.dart' show isTechniqueScrollDefId;
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
