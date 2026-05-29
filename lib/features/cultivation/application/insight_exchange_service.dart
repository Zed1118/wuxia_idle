import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import 'cultivation_service.dart';

/// 凝练领悟结果状态。
enum InsightRefineStatus {
  success,
  noMainTechnique, // 未设主修心法
  insufficientInsight, // 领悟点不足
  invalidAmount, // 消费量 ≤ 0
}

/// 凝练领悟结果（根因A 2026-05-29）。
class InsightRefineResult {
  final InsightRefineStatus status;

  /// 实际增加的修炼度 progress（= floor(insightSpend × ratio)）。
  final int progressGained;
  final bool didLevelUp;
  final int layersGained;

  /// 凝练后剩余的 insightPoints。
  final int remainingInsight;

  const InsightRefineResult({
    required this.status,
    this.progressGained = 0,
    this.didLevelUp = false,
    this.layersGained = 0,
    this.remainingInsight = 0,
  });

  bool get isSuccess => status == InsightRefineStatus.success;
}

/// insightPoints 凝练兑换主修修炼度（根因A 2026-05-29）。
///
/// 闭关挂机 → insightPoints → 玩家凝练 → 主修修炼度 progress。把死钱包
/// 接成 idle→中期成长链路（不开学心法 UI，维持 GDD §7.2 Phase 5+ scoped）。
/// 比率走 `numbers.yaml techniques.cultivation.insight_to_cultivation_ratio`，
/// 升层逻辑复用 [CultivationService.applyProgressDelta]（不计 skillUsageCount）。
class InsightExchangeService {
  final Isar isar;
  const InsightExchangeService(this.isar);

  /// 花 [insightSpend] 点领悟点凝练主修修炼度。
  ///
  /// 校验：消费量 > 0 / 角色有主修 / 领悟点足够。任一不满足返回对应状态，
  /// 不改任何数据。
  Future<InsightRefineResult> refine({
    required int characterId,
    required int insightSpend,
  }) async {
    if (insightSpend <= 0) {
      return const InsightRefineResult(status: InsightRefineStatus.invalidAmount);
    }
    final ch = await isar.characters.get(characterId);
    if (ch == null || ch.mainTechniqueId == null) {
      return InsightRefineResult(
        status: InsightRefineStatus.noMainTechnique,
        remainingInsight: ch?.insightPoints ?? 0,
      );
    }
    if (ch.insightPoints < insightSpend) {
      return InsightRefineResult(
        status: InsightRefineStatus.insufficientInsight,
        remainingInsight: ch.insightPoints,
      );
    }
    final tech = await isar.techniques.get(ch.mainTechniqueId!);
    if (tech == null) {
      return InsightRefineResult(
        status: InsightRefineStatus.noMainTechnique,
        remainingInsight: ch.insightPoints,
      );
    }

    final ratio = GameRepository.instance.numbers.insightToCultivationRatio;
    final delta = (insightSpend * ratio).floor();

    late CultivationProgressResult progress;
    await isar.writeTxn(() async {
      progress = CultivationService.applyProgressDelta(
        tech: tech,
        delta: delta,
        progressToNextMap:
            GameRepository.instance.numbers.cultivationProgressToNext,
      );
      ch.insightPoints -= insightSpend;
      await isar.techniques.put(tech);
      await isar.characters.put(ch);
    });

    return InsightRefineResult(
      status: InsightRefineStatus.success,
      progressGained: delta,
      didLevelUp: progress.didLevelUp,
      layersGained: progress.layersGained,
      remainingInsight: ch.insightPoints,
    );
  }
}
