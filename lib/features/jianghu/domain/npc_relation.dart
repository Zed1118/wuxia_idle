import 'package:isar_community/isar.dart';

part 'npc_relation.g.dart';

/// NPC 关系稀疏表(P1.2 §2 · spec Q2=B 稀疏)。
///
/// 体例(沿 phase0 §12.4 草案):
/// - [type] 字符串枚举:friend / foe / master / disciple / owed
/// - [level] ∈ [-100, +100]:enmity = (type=foe && level ≤ -50)
/// - 单向 source→target:互害需双写(NpcRelationService.upsert 双向 caller 端负责)
/// - sparse:仅在有显式关系时写入(不预填全 N×N 矩阵)
@collection
class NpcRelation {
  Id id = Isar.autoIncrement;
  @Index() late int sourceCharacterId;
  @Index() late int targetCharacterId;
  late String type;
  late int level;
  late DateTime updatedAt;
}
