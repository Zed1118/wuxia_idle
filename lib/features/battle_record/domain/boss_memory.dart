import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart';
import 'boss_memory_source.dart';

part 'boss_memory.g.dart';

/// 一档一 Boss 一条「首胜纪念」。Boss-only，~27 封顶。纯展示数据，无数值语义。
@collection
class BossMemory {
  Id id = Isar.autoIncrement;
  late int saveDataId;

  /// 稳定键：主线=stageId / 爬塔=`tower_floor_<N>`。同档唯一。
  @Index()
  late String bossKey;

  @Enumerated(EnumType.name)
  late BossMemorySource source;

  /// 分组排序序号：主线由 stageId 派生 section 序（Ch1-6 前，心魔/轻功/群战各成 section 其后）
  /// / 爬塔=层号。
  late int groupIndex;

  late String bossName;

  DateTime? firstClearedAt;

  /// 回填骨架标记（true=本功能上线前击败，战绩不详）。
  late bool isPreRecord;

  int? totalDamage;
  int? critCount;
  int? totalTicks;
  String? topContributorName;
  int? topContributorDamage;
  String? treasureName;

  @Enumerated(EnumType.name)
  EquipmentTier? treasureTier;

  List<String> rosterNames = [];
  List<String> rosterPortraits = [];

  /// 击败次数（重打累加，不覆盖首胜快照）。
  late int defeatCount;
}
