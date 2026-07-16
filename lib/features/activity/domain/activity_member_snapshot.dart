import 'package:isar_community/isar.dart';

part 'activity_member_snapshot.g.dart';

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

  /// 关次边界的战斗最大生命/最大真气（= 产出 [currentHp]/[currentQi] 那场战斗的
  /// `BattleCharacter.maxHp`/`maxQi`）。断魂庄整备页用药按「% 最大值」恢复需此上界
  /// （design §5.1）；远征逐节点独立战斗不写入，留 0（可加性列·无 saveVer 迁移）。
  int maxHp = 0;
  int maxQi = 0;

  /// 关次边界技能冷却快照键（Isar @embedded 无 Map，与 [skillCooldownTurns] 平行同序，
  /// 只存 CD>0 项）。断魂庄三关之间继承冷却（design §5.5，避免连关刷新绝招）；远征
  /// 逐节点独立战斗不写入，留空。
  List<String> skillCooldownKeys = [];

  /// 对应剩余冷却回合数（与 [skillCooldownKeys] 平行同序）。
  List<int> skillCooldownTurns = [];
}
