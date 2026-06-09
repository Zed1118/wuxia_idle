import 'package:isar_community/isar.dart';

part 'skill_unlock_entry.g.dart';

/// 技能解锁进度(可玩性 P1a · spec §一,账号级 B2 轻量)。
///
/// 嵌入在 `SaveData.skillUnlockProgress`,模拟
/// `Map<String, {fragmentCount, unlocked}>`。真解首通直接 markUnlocked;
/// 爬塔残页 addFragment 累加,达阈值自动 markUnlocked。
@embedded
class SkillUnlockEntry {
  String skillId = '';
  int fragmentCount = 0;
  bool unlocked = false;
}

/// 在 `List<SkillUnlockEntry>` 上模拟 Map 语义(spec §一)。
///
/// 全部用 `indexWhere` 回写原元素,避免 firstWhere orElse 新建对象不回写的坑。
extension MapLikeOnSkillUnlock on List<SkillUnlockEntry> {
  SkillUnlockEntry? _find(String skillId) {
    final idx = indexWhere((e) => e.skillId == skillId);
    return idx >= 0 ? this[idx] : null;
  }

  bool isUnlocked(String skillId) => _find(skillId)?.unlocked ?? false;
  int fragmentCountOf(String skillId) => _find(skillId)?.fragmentCount ?? 0;

  void addFragment(String skillId, [int delta = 1]) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].fragmentCount += delta;
    } else {
      add(SkillUnlockEntry()
        ..skillId = skillId
        ..fragmentCount = delta);
    }
  }

  void markUnlocked(String skillId) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].unlocked = true;
    } else {
      add(SkillUnlockEntry()
        ..skillId = skillId
        ..unlocked = true);
    }
  }
}
