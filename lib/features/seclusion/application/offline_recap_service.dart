import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';
import 'seclusion_service.dart';
import 'retreat_settlement_calculator.dart';

enum OfflineRecapLimitReason { inProgress, plannedDuration, systemCap }

/// M2 离线收益汇总「欢迎回来」卡的展示数据。
///
/// 由 [OfflineRecapService.buildRecap] 纯函数产出,供启动后 recap 卡渲染。
typedef OfflineRecap = ({
  /// 距开始闭关的真实流逝小时数（= now - startedAt）。
  double awayHours,

  double retreatHours,

  double passiveHours,

  int passiveMojianshi,

  int passiveExperience,

  int equipmentRollCount,

  double? nextEquipmentNodeHours,

  bool fullRateComplete,

  /// 闭关地图显示名（如「山林」）。
  String mapName,

  /// 闭关是否已挂满前 72 小时地图收益。
  bool isComplete,

  /// 进度比例 [0, 1]，用于「进行中 P%」展示。
  double progressPct,

  /// 预计可收磨剑石（与 [SeclusionService.computeOutputs] 口径一致）。
  int estimatedMojianshi,

  /// 预计可收经验。
  int estimatedExperience,

  /// 预计可收通用材料（defId → quantity）。
  Map<String, int> estimatedItemRewards,

  /// 预计可收心法领悟点。
  int estimatedTechniqueLearnPoints,

  /// 预计可收银两。
  int estimatedSilver,

  /// 本次按公式实际参与结算的小时数。
  double settledHours,

  /// 结算上限/截断原因。
  OfflineRecapLimitReason limitReason,
});

/// M2 离线收益汇总（范围 A）计算服务。
///
/// 纯函数,不碰 Isar、不发放资源、不新增挂机机制。仅把「已发生的闭关产出」
/// 在重开时可见化 + 给收功入口（GDD §5.5 红线无关：闭关本就按时长结算）。
/// 预估产出复用 [SeclusionService.computeOutputs]，与实际收功口径一致。
class OfflineRecapService {
  OfflineRecapService._();

  /// 根据 active [session] 构造「欢迎回来」卡数据。
  ///
  /// 返回 null（不弹卡）当：
  ///   - 无 active session（[session] == null）；
  ///   - 离开时长不足 [minAwayHours]（默认 1h，避免短暂切出也弹卡）。
  static OfflineRecap? buildRecap({
    required RetreatSession? session,
    required RealmTier charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    double minAwayHours = 1.0,
    TechniqueSchool? charSchool,
  }) {
    if (session == null) return null;

    final elapsed = now.difference(session.startedAt).inSeconds / 3600.0;
    if (elapsed < minAwayHours) return null;

    final settlement = SeclusionService.computeSettlement(
      session: session,
      config: config,
      passiveConfig: GameRepository.instance.numbers.passiveIdle,
      maps: maps,
      now: now,
      legacyRealmTier: charRealmTier,
      charSchool: charSchool,
    );

    final cap = config.capHours.toDouble();
    final isComplete = settlement.retreatHours >= cap;
    final progressPct = cap <= 0
        ? 1.0
        : (settlement.retreatHours / cap).clamp(0.0, 1.0).toDouble();
    final def = maps.firstWhere((m) => m.mapType == session.mapType);
    final rollCount = RetreatSettlementCalculator.equipmentRollCount(
      retreatHours: settlement.retreatHours,
      intervalHours: config.equipmentRollIntervalHours,
      maxCount: config.equipmentRollMaxCount,
    );
    final nextNodeHours = rollCount >= config.equipmentRollMaxCount
        ? null
        : config.equipmentRollIntervalHours * (rollCount + 1) -
              settlement.retreatHours;
    final outputs = settlement.retreat;

    return (
      awayHours: elapsed,
      retreatHours: settlement.retreatHours,
      passiveHours: settlement.passiveHours,
      passiveMojianshi: settlement.passive.mojianshi,
      passiveExperience: settlement.passive.experience,
      equipmentRollCount: rollCount,
      nextEquipmentNodeHours: nextNodeHours,
      fullRateComplete: isComplete,
      mapName: def.mapName,
      isComplete: isComplete,
      progressPct: progressPct,
      estimatedMojianshi: outputs.mojianshi + settlement.passive.mojianshi,
      estimatedExperience:
          outputs.experiencePoints + settlement.passive.experience,
      estimatedItemRewards: outputs.itemRewards,
      estimatedTechniqueLearnPoints: outputs.techniqueLearnPoints,
      estimatedSilver: outputs.silver,
      settledHours: settlement.elapsedHours,
      limitReason: isComplete
          ? OfflineRecapLimitReason.systemCap
          : OfflineRecapLimitReason.inProgress,
    );
  }
}
