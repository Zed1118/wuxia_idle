import '../../../core/domain/enums.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';

/// 修炼度累积结果（phase2_tasks T24）。
///
/// `didLevelUp` 区分本次调用是否触发升层（含多层连升）。
/// `layersGained` 记录跨越的层数（一次塞 5000 progress 可能 +N 层）。
/// `oldLayer` / `newLayer` 反映调用前后状态，便于 UI 展示「初窥 → 圆满」字样。
class CultivationProgressResult {
  final bool didLevelUp;
  final CultivationLayer oldLayer;
  final CultivationLayer newLayer;
  final int layersGained;

  /// 调用结束时 [Technique.cultivationProgress] 的最新值（已 in-place 写回 tech）。
  final int currentProgress;

  /// 调用结束时 [Technique.cultivationProgressToNext] 的最新值（jiJing 时保留升上来时的值）。
  final int currentProgressToNext;

  const CultivationProgressResult({
    required this.didLevelUp,
    required this.oldLayer,
    required this.newLayer,
    required this.layersGained,
    required this.currentProgress,
    required this.currentProgressToNext,
  });
}

/// 修炼度服务（GDD §4.3，phase2_tasks T24 §269-293）。
///
/// 设计原则：
///   - **in-place 修改 [Technique]**：与 EnhancementService / TechniqueDispersion
///     extension 风格一致（Technique 是 Isar @collection，本就 mutable）
///   - **接收 progressToNextMap** 而非整个 NumbersConfig，最小依赖
///   - **多层连升**：while 循环消耗 progress（不是一次跳到位）
///   - **极境封顶**：到 jiJing 后 progress ≤ progressToNext（不再涨）
class CultivationService {
  CultivationService._();

  /// 招式使用一次（或 [delta] 次）：累计 [Technique.skillUsageCount] +
  /// [Technique.cultivationProgress]，触发升层时按 [progressToNextMap] 切换
  /// 当前层 + 重置 progressToNext。
  ///
  /// **副作用全部写到 [tech]**（in-place），返回 [CultivationProgressResult]
  /// 供 UI 展示升层提示。调用方负责 Isar 写回。
  static CultivationProgressResult recordSkillUsage({
    required Technique tech,
    required String skillId,
    required Map<CultivationLayer, int> progressToNextMap,
    int delta = 1,
  }) {
    tech.skillUsageCount.increment(skillId, delta);
    return applyProgressDelta(
      tech: tech,
      delta: delta,
      progressToNextMap: progressToNextMap,
    );
  }

  /// 直接给 [Technique.cultivationProgress] 累加 [delta] 并按 [progressToNextMap]
  /// 处理升层，**不**触碰 [Technique.skillUsageCount]。
  ///
  /// 根因A(2026-05-29):insightPoints 凝练 sink 走此路径（玩家闭关攒的领悟点
  /// 兑换主修修炼度，非实战招式使用，故不计 skillUsageCount）。
  /// [recordSkillUsage] 自增 usageCount 后委派本方法,公用升层逻辑单一真相源。
  static CultivationProgressResult applyProgressDelta({
    required Technique tech,
    required int delta,
    required Map<CultivationLayer, int> progressToNextMap,
  }) {
    final oldLayer = tech.cultivationLayer;
    tech.cultivationProgress += delta;

    var layersGained = 0;
    while (tech.cultivationLayer != CultivationLayer.jiJing &&
        tech.cultivationProgress >= tech.cultivationProgressToNext) {
      tech.cultivationProgress -= tech.cultivationProgressToNext;
      tech.cultivationLayer =
          CultivationLayer.values[tech.cultivationLayer.index + 1];
      layersGained += 1;

      if (tech.cultivationLayer != CultivationLayer.jiJing) {
        final next = progressToNextMap[tech.cultivationLayer];
        if (next == null) {
          throw StateError(
            'cultivationProgressToNext 缺 ${tech.cultivationLayer.name} 的 progress_required',
          );
        }
        tech.cultivationProgressToNext = next;
      }
      // jiJing：progressToNext 保留升上来时的值（即 wuXia → jiJing 的 6500），
      // 用作封顶上限。
    }

    if (tech.cultivationLayer == CultivationLayer.jiJing &&
        tech.cultivationProgress > tech.cultivationProgressToNext) {
      tech.cultivationProgress = tech.cultivationProgressToNext;
    }

    return CultivationProgressResult(
      didLevelUp: layersGained > 0,
      oldLayer: oldLayer,
      newLayer: tech.cultivationLayer,
      layersGained: layersGained,
      currentProgress: tech.cultivationProgress,
      currentProgressToNext: tech.cultivationProgressToNext,
    );
  }
}
