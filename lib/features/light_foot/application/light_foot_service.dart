import '../domain/light_foot_def.dart';

/// 轻功对决 application 层(1.0 P3.1 §12.3,Batch B.1)。
///
/// 设计要点(沿 InnerDemonService 体例但简化):
///   - 全部静态方法,无 mutable state(memory `feedback_avoid_over_engineer_abstraction`)
///   - 不直接读 Isar / GameRepository(caller 注入 def + clearedStageIds)
///   - **不接管 wuSheng 突破链**(轻功对决平行支线 · 无 isLayerLocked 路径)
///   - 仅 stage clearance check + unlock chain(三态判断给 LightFootScreen)
class LightFootService {
  LightFootService._();

  /// 单关三态判定:cleared / available / locked。
  ///
  /// 逻辑(沿 inner_demon_screen.dart:212 体例):
  ///   - cleared:[stageId] ∈ [clearedStageIds]
  ///   - available:[stageId] ∉ clearedStageIds + unlock_triggers reverse 链
  ///     找到的 prevStageId ∈ clearedStageIds(或 stageId 是 chain 起点 + 起点
  ///     trigger ∈ clearedStageIds,如 stage_06_05 → light_foot_01)
  ///   - locked:cleared / available 都不命中
  ///
  /// **chain 起点处理**:light_foot_01 的 prev 是 stage_06_05(Ch6 末 Boss),
  /// 玩家通 stage_06_05 → light_foot_01 unlock。chain 起点的 prev 不是 light_foot
  /// stage 而是 mainline / 其他,沿 unlock_triggers map reverse 查即可。
  static LightFootStageStatus statusOf({
    required String stageId,
    required LightFootDef config,
    required Set<String> clearedStageIds,
  }) {
    if (clearedStageIds.contains(stageId)) {
      return LightFootStageStatus.cleared;
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
      return LightFootStageStatus.locked;
    }

    return clearedStageIds.contains(prevStageId)
        ? LightFootStageStatus.available
        : LightFootStageStatus.locked;
  }

  /// 5 关全部 stage_id 顺序(stage_light_foot_01..05)。
  ///
  /// 顺序 = unlock chain 拓扑序(stages.yaml 5 entries 顺序一致)。
  /// chain 起点用 `stage_light_foot_01` 硬编码识别(非 light_foot_xx 的 prev
  /// 在 chain 起点 = mainline stage_06_05)。
  static List<String> orderedStageIds(LightFootDef config) {
    final result = <String>[];
    // chain 起点:non-light_foot stage trigger 的 next
    String? current;
    for (final entry in config.unlockTriggers.entries) {
      if (!entry.key.startsWith('stage_light_foot_')) {
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
}

/// 关卡三态(沿 [StageStatus] 体例但 light_foot 独立 enum 避免跨模块耦合 ·
/// memory `feedback_avoid_over_engineer_abstraction`)。
enum LightFootStageStatus {
  locked,    // 上一关未通(灰色 + 锁)
  available, // 上一关通过 + 本关未通(主色按钮可点)
  cleared,   // 本关已通(绿勾 · 可重玩)
}
