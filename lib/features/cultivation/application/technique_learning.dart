import '../../battle/domain/derived_stats.dart';
import '../../../data/defs/technique_def.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/numbers_config.dart';

/// 心法学习结果（phase2_tasks T23）。
///
/// `outcome` 区分成败语义：
///   - [LearnOutcome.success]：[technique] 非 null，[pointsSpent] = 实际扣减
///   - 其余 4 类失败：[technique] = null，[pointsSpent] = 0
///
/// 服务**只构造 [Technique] 实例**，不写 Isar、不改 [Character.mainTechniqueId]
/// / [Character.assistTechniqueIds]。副作用归调用方（与 [EnhancementService]
/// 一致）。
class TechniqueLearningResult {
  final LearnOutcome outcome;
  final Technique? technique;
  final int pointsSpent;

  const TechniqueLearningResult({
    required this.outcome,
    this.technique,
    this.pointsSpent = 0,
  });

  bool get success => outcome == LearnOutcome.success;
}

enum LearnOutcome {
  success,
  techniqueTierTooHigh,        // tier 超过角色境界对应阶（GDD §5.3 三系锁死）
  mainTechniqueAlreadyExists,  // 主修已存在（必须先散功）
  assistSlotsFull,             // 辅修槽满 3（GDD §4.2）
  insufficientInsightPoints,   // 领悟点不足
}

/// 心法学习服务（phase2_tasks T23 §244-265 / GDD §5.3 / §4.2 / §7.2）。
///
/// 校验顺序（fail-fast，越根本性的错误越先返回）：
///   1. tier 上限（设计层硬约束）
///   2. 主修已存在（状态约束）
///   3. 辅修槽满 3（物理约束）
///   4. 领悟点不足（经济约束）
///
/// Demo 阶段领悟点由测试场景手动塞 1000 给玩家（GDD §7.2 武学领悟系统未实装）。
class TechniqueLearningService {
  TechniqueLearningService._();

  static TechniqueLearningResult learn({
    required Character ch,
    required TechniqueDef def,
    required TechniqueRole role,
    required int currentInsightPoints,
    required LearningCostConfig costConfig,
    required DateTime learnedAt,
  }) {
    final cap = RealmUtils.techniqueTierCapOf(ch.realmTier);
    if (def.tier.index > cap.index) {
      return const TechniqueLearningResult(
        outcome: LearnOutcome.techniqueTierTooHigh,
      );
    }

    if (role == TechniqueRole.main && ch.mainTechniqueId != null) {
      return const TechniqueLearningResult(
        outcome: LearnOutcome.mainTechniqueAlreadyExists,
      );
    }

    if (role == TechniqueRole.assist && ch.assistTechniqueIds.length >= 3) {
      return const TechniqueLearningResult(
        outcome: LearnOutcome.assistSlotsFull,
      );
    }

    final cost = costConfig.costFor(role);
    if (currentInsightPoints < cost) {
      return const TechniqueLearningResult(
        outcome: LearnOutcome.insufficientInsightPoints,
      );
    }

    final tech = Technique.create(
      defId: def.id,
      ownerCharacterId: ch.id,
      tier: def.tier,
      school: def.school,
      role: role,
      learnedAt: learnedAt,
    );

    return TechniqueLearningResult(
      outcome: LearnOutcome.success,
      technique: tech,
      pointsSpent: cost,
    );
  }
}
