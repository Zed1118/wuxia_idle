import '../../../core/domain/enums.dart';
import '../domain/mass_battle_def.dart';

/// 群战守城 application 层(1.0 P3.2 §12.3,GDD v1.13,Batch 2.3)。
///
/// 设计要点(沿 LightFootService 体例):
///   - 全部静态方法,无 mutable state(memory `feedback_avoid_over_engineer_abstraction`)
///   - 不直接读 Isar / GameRepository(caller 注入 def + clearedStageIds)
///   - **不接管 wuSheng 突破链**(群战守城平行支线 · 无 isLayerLocked 路径)
///   - 仅 stage clearance check + unlock chain + default formation 查询
///     (三态判断给 MassBattleScreen · 默认阵型给阵型选择 dialog · UI 走 Batch 2.4)
///
/// **与 LightFootService 关键差异**:多 [formationFor] 方法,因为 mass_battle 还
/// 有玩家战略选择维度(LightFoot 地形是 stages.yaml `terrainBiome` 直接读)。
class MassBattleService {
  MassBattleService._();

  /// 单关三态判定:cleared / available / locked。
  ///
  /// 逻辑(沿 LightFootService.statusOf 体例):
  ///   - cleared:[stageId] ∈ [clearedStageIds]
  ///   - available:[stageId] ∉ clearedStageIds + unlock_triggers reverse 链
  ///     找到的 prevStageId ∈ clearedStageIds(chain 起点 stage_06_05 在主线 Ch6 末)
  ///   - locked:cleared / available 都不命中
  ///
  /// **chain 起点处理**:mass_battle_01 的 prev 是 stage_06_05(Ch6 末 Boss),
  /// 玩家通 stage_06_05 → mass_battle_01 unlock(沿 LightFoot 体例)。
  static MassBattleStageStatus statusOf({
    required String stageId,
    required MassBattleDef config,
    required Set<String> clearedStageIds,
  }) {
    if (clearedStageIds.contains(stageId)) {
      return MassBattleStageStatus.cleared;
    }

    // unlock_triggers 是 prev → next,reverse 找 prevStageId for 本 stageId
    String? prevStageId;
    for (final entry in config.unlockTriggers.entries) {
      if (entry.value == stageId) {
        prevStageId = entry.key;
        break;
      }
    }

    if (prevStageId == null) {
      // 未配置 unlock trigger(配置不全 / fixture 兼容)→ locked
      return MassBattleStageStatus.locked;
    }

    return clearedStageIds.contains(prevStageId)
        ? MassBattleStageStatus.available
        : MassBattleStageStatus.locked;
  }

  /// 5 关全部 stage_id 顺序(stage_mass_battle_01..05)。
  ///
  /// 顺序 = unlock chain 拓扑序(stages.yaml 5 entries 顺序一致)。
  /// chain 起点用 `stage_mass_battle_` prefix 识别(沿 LightFootService 体例)。
  static List<String> orderedStageIds(MassBattleDef config) {
    final result = <String>[];
    // chain 起点:non-mass_battle stage trigger 的 next
    String? current;
    for (final entry in config.unlockTriggers.entries) {
      if (!entry.key.startsWith('stage_mass_battle_')) {
        current = entry.value;
        break;
      }
    }
    while (current != null) {
      result.add(current);
      current = config.unlockTriggers[current];
    }
    return result;
  }

  /// 取 [stageId] 的默认阵型(玩家未选时 fallback)。
  ///
  /// 优先从 `config.stageFormations[stageId]` 取;若未配置 → [Formation.yanXing]
  /// 兜底(攻势启,沿 Batch 2.1 numbers.yaml 默认决议)。
  ///
  /// Batch 2.4 UI 阵型选择 dialog 用此值预选项,玩家可改选 baGua / fengShi。
  static Formation formationFor({
    required String stageId,
    required MassBattleDef config,
  }) {
    return config.stageFormations[stageId] ?? Formation.yanXing;
  }
}

/// 关卡三态(沿 [LightFootStageStatus] 体例但 mass_battle 独立 enum 避免跨模块
/// 耦合 · memory `feedback_avoid_over_engineer_abstraction`)。
enum MassBattleStageStatus {
  locked,    // 上一关未通(灰色 + 锁)
  available, // 上一关通过 + 本关未通(主色按钮可点)
  cleared,   // 本关已通(绿勾 · 可重玩)
}
