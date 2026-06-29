import 'dart:math' as math;

import '../domain/island_building_state.dart';
import '../domain/island_building_type.dart';
import '../domain/taohua_island_config.dart';

/// 桃花岛产出累积核心逻辑（纯函数 · 无 Isar/无副作用）。
///
/// 离线 = 在线由 [settle] 单一函数构造性保证：无论分几段调用、
/// 还是一次性结算整段时间，只要落在「源料充裕 + 成品仓未满」的线性区，
/// 累积结果一致（见测试用例 4）。`capHours` 封顶防无限堆积（红线）。
class IslandProductionService {
  IslandProductionService._();

  /// 结算 [elapsedHours] 小时内的产出累积。
  ///
  /// 纯函数：深拷贝输入 [states]，全程只改副本并返回副本，绝不改原对象。
  ///
  /// 处理顺序：先全部跑完 source（原料滴落），再跑 processor（加工消费），
  /// 保证 processor 消费的是本窗口已累积的源料。
  static List<IslandBuildingState> settle({
    required List<IslandBuildingState> states,
    required TaohuaIslandConfig config,
    required double elapsedHours,
    required int founderRealmIndex,
  }) {
    // 步骤 1:深拷贝输入(保证纯函数)
    final result = states.map((s) => s.copy()).toList();

    // capHours 封顶 = 防无限堆积红线
    final t = elapsedHours.clamp(0.0, config.capHours.toDouble());
    if (t <= 0) return result;

    // 步骤 2：原料建筑滴落（已按境界解锁的才产）
    for (final s in result) {
      final cfg = config.buildingOf(s.type);
      if (cfg.kind != BuildingKind.source) continue;
      if (cfg.realmUnlockIndex > founderRealmIndex) continue; // 未解锁不产
      final cap = cfg.capFor(s.level).toDouble();
      final produced = cfg.baseRatePerHour * s.level * t;
      s.stored = math.min(cap, s.stored + produced);
    }

    // 步骤 3：加工建筑消费源料、产成品
    for (final s in result) {
      final cfg = config.buildingOf(s.type);
      if (cfg.kind != BuildingKind.processor) continue;

      final recipeId = s.activeRecipeId;
      if (recipeId == null) continue; // 未选配方 → 不产不耗

      final recipe = cfg.recipeById(recipeId);
      if (recipe == null) continue; // 配方失联 → 暂停
      if (recipe.realmUnlockIndex > founderRealmIndex) continue; // 配方未达境界 → 暂停

      // 找源建筑：其 outputItem == 本 processor 的 inputItem 的那个 source
      final inputItem = cfg.inputItem;
      if (inputItem == null) continue;
      IslandBuildingState? sourceState;
      for (final candidate in result) {
        final cCfg = config.buildingOf(candidate.type);
        if (cCfg.kind == BuildingKind.source && cCfg.outputItem == inputItem) {
          sourceState = candidate;
          break; // 供应自洽校验保证最多一个 source 产此 item,取首个即可
        }
      }
      if (sourceState == null) continue; // 找不到源 → 跳过

      // 双输入配方：额外找次要源建筑（如丹房疗伤丹的灵泉水）。
      // 校验层保证 secondary_input_per_output>0 ⇒ 建筑配了 secondary_input_item 且有 source 供应。
      IslandBuildingState? secondarySource;
      if (recipe.secondaryInputPerOutput > 0) {
        final secItem = cfg.secondaryInputItem;
        for (final candidate in result) {
          final cCfg = config.buildingOf(candidate.type);
          if (cCfg.kind == BuildingKind.source && cCfg.outputItem == secItem) {
            secondarySource = candidate;
            break;
          }
        }
        if (secondarySource == null) continue; // 次要源缺失（防御）→ 跳过
      }

      final cap = cfg.capFor(s.level).toDouble();
      final synergyMultiplier = config.synergies.rateMultiplierFor(
        target: s.type,
        buildingLevels: result.map(
          (b) => IslandBuildingLevel(type: b.type, level: b.level),
        ),
        founderRealmIndex: founderRealmIndex,
        buildings: config.buildings,
      );
      final want = recipe.ratePerHour * synergyMultiplier * s.level * t;
      final effectiveInputPerOutput = recipe.inputPerOutput / synergyMultiplier;
      final byMaterial = sourceState.stored / effectiveInputPerOutput;
      var made = math.min(want, byMaterial);
      var effectiveSecondaryInputPerOutput = recipe.secondaryInputPerOutput;
      if (secondarySource != null) {
        effectiveSecondaryInputPerOutput =
            recipe.secondaryInputPerOutput / synergyMultiplier;
        // 次要原料也限产，取更紧的约束（离线=在线：所有 min 可交换，与分段无关）
        final bySecondary =
            secondarySource.stored / effectiveSecondaryInputPerOutput;
        made = math.min(made, bySecondary);
      }
      made = math.min(made, cap - s.stored); // 成品仓 cap 限
      made = math.max(0.0, made); // 浮点负兜底:也覆盖 stored > cap 的历史存量(cap 调低后存量合法超限)

      sourceState.stored -= made * effectiveInputPerOutput; // 扣源料
      if (secondarySource != null) {
        secondarySource.stored -=
            made * effectiveSecondaryInputPerOutput; // 扣次要源料
      }
      s.stored += made; // 产成品
    }

    return result;
  }
}
