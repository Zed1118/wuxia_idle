import 'package:isar_community/isar.dart';

/// 活动会话（远征/断魂庄）内单个角色的关次/节点边界快照。
///
/// 保留字段 [reservedEquipmentIds]/[reservedTechniqueIds] 是占用契约的真相来源：
/// [CharacterOccupancyService] 聚合各 active 会话成员的这两列，供装备/心法/战斗入口
/// 统一查询（companion Q5/§3.5）。生命/真气/阵亡供 Phase B/C 的跨战继承。
@embedded
class ActivityMemberSnapshot {
  int characterId = 0;

  /// 出发/入场时冻结的装备 Isar id（`Character.equipped*Id` 快照）。
  List<int> reservedEquipmentIds = [];

  /// 出发/入场时冻结的心法 Isar id（`Character.mainTechniqueId` 及装配槽快照）。
  List<int> reservedTechniqueIds = [];

  int currentHp = 0;
  int currentQi = 0;
  bool isDowned = false;
}
