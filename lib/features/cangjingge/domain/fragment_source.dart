import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../tower/domain/tower_floor_def.dart';

/// 残页来源派生（T7）：从塔层 / 主线章末重打的 `dropSkillFragmentId` 反查。
///
/// 塔优先（残页主来自塔 Boss 层），其次主线章末重打（stages.yaml）。
/// 都无匹配 → null（UI 显示「来源未明」，不臆造来源 · CLAUDE §15.10）。
String? fragmentSourceLabel(
  String skillId, {
  required Iterable<TowerFloorDef> floors,
  required Iterable<StageDef> stages,
}) {
  for (final f in floors) {
    if (f.dropSkillFragmentId == skillId) {
      return UiStrings.cangjingFragmentSourceTower(f.floorIndex);
    }
  }
  for (final s in stages) {
    if (s.dropSkillFragmentId == skillId && s.chapterIndex != null) {
      return UiStrings.cangjingFragmentSourceMainline(s.chapterIndex!);
    }
  }
  return null;
}
