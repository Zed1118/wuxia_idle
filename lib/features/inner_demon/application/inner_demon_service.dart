import '../../../core/domain/enums.dart';
import '../domain/inner_demon_def.dart';

/// 心魔系统 application 层（1.0 P2.2 §12.1，Batch 2.2.A vertical slice）。
///
/// **Batch 2.2.A 范围**：仅 [isLayerLocked] 静态判定（unlock 拦截）。
/// 镜像 enemy 构造 / victory 记录 / 失败惩罚等留 Batch 2.2.B。
///
/// 设计要点（memory `feedback_avoid_over_engineer_abstraction`）：
///   - 全部静态方法（无 mutable state，无需 Riverpod provider 持有）
///   - 不直接读 Isar / GameRepository（caller 注入 def + clearedStageIds）→
///     test 易，hook closure 易构造
///   - 非 wuSheng tier 短路 → 不影响 Demo + Ch4-6 主线升层路径
class InnerDemonService {
  InnerDemonService._();

  /// 玩家升 layer 时心魔关 unlock 拦截判定。
  ///
  /// **拦截规则**：
  ///   1. [nextTier] 非 [RealmTier.wuSheng] → false（不影响 Demo 7 阶 + Ch4-6
  ///      主线，Ch6 mainline_06_05 victory 跨 tier 升 wuSheng·qiMeng 自动通过）
  ///   2. [nextLayer] == [RealmLayer.qiMeng]（跨 tier 升 wuSheng 起步层） → false
  ///   3. wuSheng 内 layer N→N+1（N ∈ qiMeng..huaJing）：找 innerDemonDef
  ///      `required_realm_layer` 中 `(wuSheng, prevLayer=N)` 对应的拦截关 →
  ///      该 stage_id ∉ [clearedStageIds] → true（拦截）
  ///   4. 无对应拦截关配置（fixture 不带 inner_demon 段 / 配置不全） → false
  ///
  /// **不处理 wuSheng·dengFeng → 飞升**（next == null 时 advancement_service
  /// 直接 break，本 hook 不被调用；飞升前置 inner_demon_07 留 P2.3 spec 接管）。
  static bool isLayerLocked({
    required RealmTier nextTier,
    required RealmLayer nextLayer,
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    if (nextTier != RealmTier.wuSheng) return false;

    final layers = RealmLayer.values;
    final nextIdx = layers.indexOf(nextLayer);
    if (nextIdx <= 0) return false; // qiMeng 是 wuSheng 起步层（跨 tier 升入）

    final prevLayer = layers[nextIdx - 1];

    for (final entry in innerDemonDef.requiredRealmLayer.entries) {
      if (entry.value.tier == RealmTier.wuSheng &&
          entry.value.layer == prevLayer) {
        return !clearedStageIds.contains(entry.key);
      }
    }

    return false;
  }
}
