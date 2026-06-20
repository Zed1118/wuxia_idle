import 'package:isar_community/isar.dart';

part 'equipment_catalog_entry.g.dart';

/// 兵器谱图鉴条目:玩家曾获得过的某件装备 def 的留档。
///
/// 「曾获得即永久点亮」:一旦建档不删,卖掉/分解不影响。
/// 回填档(isPreRecord=true)= 本功能上线前已持有,来历不详。
@collection
class EquipmentCatalogEntry {
  Id id = Isar.autoIncrement;
  late int saveDataId;

  /// 装备 def 唯一键(= EquipmentDef.id)。同档唯一。
  @Index()
  late String defId;

  /// 首次获得时间;回填档为 null。
  DateTime? firstObtainedAt;

  /// 首次获得来源(如关卡名/「宝塔第N层」/奇遇名);回填档=「来历不详」。
  late String firstObtainedFrom;

  /// 历史累计获得次数(重得 ++)。
  late int obtainedCount;

  /// 回填骨架标记(true=上线前已持有)。
  late bool isPreRecord;
}
