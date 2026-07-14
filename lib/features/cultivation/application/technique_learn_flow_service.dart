import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../event/application/game_event_service.dart';
import 'technique_learning.dart';

/// 研习新心法的落库编排结果（2026-07-14 心法学习闭环）。
enum TechniqueLearnFlowStatus {
  success,
  characterMissing, // 角色不存在
  techniqueDefMissing, // 心法 def 不存在
  alreadyOwned, // 该心法已在角色名下（不可重复学）
  techniqueTierTooHigh, // 境界不足（§5.3 三系锁死）
  mainTechniqueAlreadyExists, // 主修已存在（换主修走散功）
  assistSlotsFull, // 辅修槽满 3
  insufficientInsightPoints, // 领悟点不足
}

/// 研习结果。成功时 [learnedTechniqueId] 非 null、[pointsSpent] = 实际扣减、
/// [remainingInsightPoints] = 扣后余额。失败态零副作用。
class TechniqueLearnFlowResult {
  final TechniqueLearnFlowStatus status;
  final int? learnedTechniqueId;
  final int pointsSpent;
  final int remainingInsightPoints;

  const TechniqueLearnFlowResult({
    required this.status,
    this.learnedTechniqueId,
    this.pointsSpent = 0,
    this.remainingInsightPoints = 0,
  });

  bool get isSuccess => status == TechniqueLearnFlowStatus.success;
}

/// 研习新心法落库编排（技能面板「研习新心法」入口消费）。
///
/// 校验（纯规则）委托 [TechniqueLearningService.learn]（§5.3 tier 锁死、主修占位、
/// 辅修槽满、领悟点不足四态），本服务在其之上补「角色/def 存在」「未持有」两道前置，
/// 成功则**单事务**落库：Technique put + 扣 insightPoints + 写
/// mainTechniqueId/assistTechniqueIds + 记 techniqueLearned 事件。
///
/// 体例对齐 [InsightExchangeService]：自持 Isar、自开 writeTxn、返回结果对象；
/// 失败态在写事务外返回，零副作用。领悟点来源见 SeclusionService（在线=离线，
/// 本服务只加消费）。
class TechniqueLearnFlowService {
  final Isar isar;
  const TechniqueLearnFlowService(this.isar);

  Future<TechniqueLearnFlowResult> learn({
    required int characterId,
    required String techniqueDefId,
    required TechniqueRole role,
  }) async {
    final repo = GameRepository.instance;
    final def = repo.techniqueDefs[techniqueDefId];
    if (def == null) {
      return const TechniqueLearnFlowResult(
        status: TechniqueLearnFlowStatus.techniqueDefMissing,
      );
    }

    final ch = await isar.characters.get(characterId);
    if (ch == null) {
      return const TechniqueLearnFlowResult(
        status: TechniqueLearnFlowStatus.characterMissing,
      );
    }

    // 未持有校验：同 defId 已在名下（主修或辅修）则拒绝，不重复学。
    final owned = await isar.techniques
        .filter()
        .ownerCharacterIdEqualTo(characterId)
        .defIdEqualTo(techniqueDefId)
        .findFirst();
    if (owned != null) {
      return TechniqueLearnFlowResult(
        status: TechniqueLearnFlowStatus.alreadyOwned,
        remainingInsightPoints: ch.insightPoints,
      );
    }

    final result = TechniqueLearningService.learn(
      ch: ch,
      def: def,
      role: role,
      currentInsightPoints: ch.insightPoints,
      costConfig: repo.numbers.learningCost,
      learnedAt: DateTime.now(),
    );
    if (!result.success) {
      return TechniqueLearnFlowResult(
        status: _mapOutcome(result.outcome),
        remainingInsightPoints: ch.insightPoints,
      );
    }

    final tech = result.technique!;
    final events = GameEventService(isar);
    await isar.writeTxn(() async {
      final techId = await isar.techniques.put(tech);
      ch.insightPoints -= result.pointsSpent;
      if (role == TechniqueRole.main) {
        ch.mainTechniqueId = techId;
      } else {
        ch.assistTechniqueIds = [...ch.assistTechniqueIds, techId];
      }
      await isar.characters.put(ch);
      await events.recordTechniqueLearned(
        characterId: characterId,
        techniqueDefId: techniqueDefId,
        techniqueName: def.name,
      );
    });

    return TechniqueLearnFlowResult(
      status: TechniqueLearnFlowStatus.success,
      learnedTechniqueId: tech.id,
      pointsSpent: result.pointsSpent,
      remainingInsightPoints: ch.insightPoints,
    );
  }

  static TechniqueLearnFlowStatus _mapOutcome(LearnOutcome outcome) {
    switch (outcome) {
      case LearnOutcome.techniqueTierTooHigh:
        return TechniqueLearnFlowStatus.techniqueTierTooHigh;
      case LearnOutcome.mainTechniqueAlreadyExists:
        return TechniqueLearnFlowStatus.mainTechniqueAlreadyExists;
      case LearnOutcome.assistSlotsFull:
        return TechniqueLearnFlowStatus.assistSlotsFull;
      case LearnOutcome.insufficientInsightPoints:
        return TechniqueLearnFlowStatus.insufficientInsightPoints;
      case LearnOutcome.success:
        return TechniqueLearnFlowStatus.success;
    }
  }
}
