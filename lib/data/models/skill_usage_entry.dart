import 'package:isar/isar.dart';

part 'skill_usage_entry.g.dart';

/// 招式使用次数（data_schema.md §3.4）。
///
/// 嵌入在 `Technique.skillUsageCount` 中模拟 `Map<String, int>`，
/// 用于累积心法修炼度（GDD §4.3）以及相生 buff 判定时按 key 查询。
@embedded
class SkillUsageEntry {
  String skillId = '';
  int count = 0;
}

/// 在 `List<SkillUsageEntry>` 上模拟 Map 语义（data_schema.md §3.6）。
///
/// `increment` 用 `indexWhere` + 直接修改原元素或追加，避免 firstWhere 的
/// orElse 创建新对象后不回写到原 List 的坑（phase1_tasks.md T03 提示）。
extension MapLikeOnSkillUsage on List<SkillUsageEntry> {
  int countOf(String skillId) =>
      firstWhere((e) => e.skillId == skillId, orElse: () => SkillUsageEntry())
          .count;

  void increment(String skillId, [int delta = 1]) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].count += delta;
    } else {
      add(SkillUsageEntry()
        ..skillId = skillId
        ..count = delta);
    }
  }
}
