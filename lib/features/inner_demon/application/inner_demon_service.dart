import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inner_breath_disorder.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/inner_demon_def.dart';

/// 心魔关战败惩罚结果（in-place 改 ch.internalForce + mainTech.cultivationProgress
/// 已发生，此处汇总供 UI 展示 / 测试断言）。与 DispelService.DefeatPenaltyResult
/// 区别：心魔惩罚 layer 不回退（spec「不跌破当前层起点」自动满足）。
class InnerDemonPenaltyResult {
  final int internalForceBefore;
  final int internalForceAfter;
  final int progressBefore;
  final int progressAfter;
  final double residueHoursApplied;
  const InnerDemonPenaltyResult({
    required this.internalForceBefore,
    required this.internalForceAfter,
    required this.progressBefore,
    required this.progressAfter,
    required this.residueHoursApplied,
  });
}

/// 心魔系统 application 层（1.0 P2.2 §12.1）。
///
/// **已实装**：[isLayerLocked] 升层 unlock 拦截（Batch 2.2.A）、
/// [applyFailurePenalty] 战败惩罚 + 余毒（M6，2026-06-16）。
///
/// 设计要点（memory `feedback_avoid_over_engineer_abstraction`）：
///   - 全部静态方法（无 mutable state，无需 Riverpod provider 持有）
///   - 不直接读 Isar / GameRepository（caller 注入 def + clearedStageIds）→
///     test 易，hook closure 易构造
///   - 使用境界枚举顺序比较绝对层，支持同阶与跨阶节点
class InnerDemonService {
  InnerDemonService._();

  /// 玩家升 layer 时心魔关 unlock 拦截判定。
  ///
  /// `required_realm_layer` 记录玩家被拦截时的当前层。
  /// 待进入层的绝对顺序减一命中某节点，且对应关卡未通关时返回 true。
  /// 因此同 tier 进层和 `dengFeng → 下一 tier.qiMeng` 共用同一规则。
  static bool isLayerLocked({
    required RealmTier nextTier,
    required RealmLayer nextLayer,
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    final nextAbsoluteIndex = _absoluteIndex(nextTier, nextLayer);
    if (nextAbsoluteIndex <= 0) return false;

    for (final entry in innerDemonDef.requiredRealmLayer.entries) {
      if (_absoluteIndex(entry.value.tier, entry.value.layer) ==
          nextAbsoluteIndex - 1) {
        return !clearedStageIds.contains(entry.key);
      }
    }

    return false;
  }

  static int _absoluteIndex(RealmTier tier, RealmLayer layer) =>
      tier.index * RealmLayer.values.length + layer.index;

  /// 心魔关战败惩罚（M6）。对单个**有主修**的参战角色调用一次。
  ///
  /// in-place 改：
  ///   - ch.internalForce = max(floor(old × internalForceMultiplier),
  ///                            floor(internalForceMax × internalForceFloorPct))
  ///   - mainTech.cultivationProgress = floor(old × mainCultivationMultiplier)
  ///     （cultivationLayer / cultivationProgressToNext 不动 → 不跌破当前层起点）
  ///   - ch.innerBreathDisorderHoursRemaining 按配置累加并受上限约束
  ///   - 辅修不动（subCultivationMultiplier=1.00，不触碰辅修字段）
  ///
  /// Isar 持久化由 caller 负责（沿 DispelService.applyDefeatPenalty 体例）。
  static InnerDemonPenaltyResult applyFailurePenalty({
    required Character ch,
    required Technique mainTech,
    required InnerDemonFailurePenalty penalty,
    required double residueHours,
    double? disorderMaxHours,
  }) {
    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;

    InnerBreathDisorder.apply(
      character: ch,
      hours: residueHours,
      maxHours: disorderMaxHours ?? residueHours,
    );

    // §5.4 惩罚单向下调：主修系数必 ≤ 1.0（内力侧已有地板兜底，progress 侧无
    // 上限守卫，此 assert 防 numbers.yaml 误配 >1.0 反涨修炼度）。
    assert(
      penalty.mainCultivationMultiplier <= 1.0,
      'mainCultivationMultiplier 必 ≤ 1.0（惩罚不得反涨修炼度）',
    );
    mainTech.cultivationProgress =
        (mainTech.cultivationProgress * penalty.mainCultivationMultiplier)
            .floor();

    return InnerDemonPenaltyResult(
      internalForceBefore: ifBefore,
      internalForceAfter: ch.internalForce,
      progressBefore: progressBefore,
      progressAfter: mainTech.cultivationProgress,
      residueHoursApplied: residueHours,
    );
  }
}
