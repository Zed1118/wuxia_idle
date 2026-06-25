import '../../../core/domain/enums.dart';

/// 第八阶段 B · 关卡/Boss 推荐境界难度判语。
///
/// 玩家当前境界 tier 与关卡推荐境界(StageDef/TowerFloorDef `requiredRealm`)
/// 的差档,对齐 GDD §5.5 境界差修正:
/// - 玩家高于推荐(差 ≤ -1)→ [comfortable] 碾压
/// - 同阶(差 0)→ [suitable] 适中
/// - 低 1 阶(差 1)→ [risky] 偏高(§5.5 守方 ×0.7,能打但吃力)
/// - 低 2+ 阶(差 ≥ 2)→ [deadly] 送死(§5.5 守方 ×0.3 / ×0.05 近免疫)
enum DifficultyVerdict { comfortable, suitable, risky, deadly }

/// 纯函数难度评估(不查 Isar / 不读 config)。
class StageDifficultyAssessor {
  StageDifficultyAssessor._();

  static DifficultyVerdict assess({
    required RealmTier recommended,
    required RealmTier playerTier,
  }) {
    final diff = recommended.index - playerTier.index; // >0 = 玩家低于推荐
    if (diff <= -1) return DifficultyVerdict.comfortable;
    if (diff == 0) return DifficultyVerdict.suitable;
    if (diff == 1) return DifficultyVerdict.risky;
    return DifficultyVerdict.deadly;
  }
}
