import '../../core/domain/enums.dart';
import '../defs/codex_category.dart';
import '../defs/codex_entry.dart';
import '../defs/codex_index.dart';
import '../defs/item_def.dart';
import '../defs/shop_item_def.dart';
import '../defs/synergy_def.dart';
import '../defs/taohua_island_config.dart';
import '../defs/technique_def.dart';
import '../numbers_config.dart';

/// 经济/百科/相生域加载期红线(2026-07-18 审查批C 自 GameRepository 抽出)。
///
/// 体例:顶层自由函数 + 显式参数(沿 enforceLineageOnboardingRedLines 先例),
/// 参数名与 GameRepository 字段名一致,方法体自抽出起逐字未改;
/// 越界一律抛 [StateError],启动失败(fail-fast)。

/// P1.z 机制百科红线(GDD §10.2 第 3 方式):
/// - 加载到的 entry id 必须在 [CodexIndex.entries] 登记(graceful loader 已保证)
/// - 机制条目(isMechanic):step ∈ [1, 8]
/// - lore 条目(isLore):step == null
/// - paragraphs 总字数 ∈ [200, 550](放宽 +50,three_styles_detail 543)
/// - paragraphs 非空
///
/// P2 扩段:A 组 4 篇补充阅读挂相同机制 category 与 P1.z 首批共存(同档可多条),
/// 故 step 唯一性已废除;id 唯一性由 [CodexIndex.byId] + Map 加载层保证。
void enforceCodexRedLines({required Map<String, CodexEntry> codexEntries}) {
  if (codexEntries.isEmpty) return; // test fixture 兼容
  for (final e in codexEntries.values) {
    if (CodexIndex.byId(e.id) == null) {
      throw StateError('codex entry ${e.id} 不在 CodexIndex.entries 登记');
    }
    final step = e.step;
    if (e.category.isMechanic) {
      if (step == null || step < 1 || step > 8) {
        throw StateError('codex entry ${e.id} 机制条目 step=$step 应 ∈ [1, 8]');
      }
    } else if (e.category.isLore && step != null) {
      throw StateError('codex entry ${e.id} lore 条目 step=$step 应为 null');
    }
    if (e.paragraphs.isEmpty) {
      throw StateError('codex entry ${e.id} paragraphs 为空');
    }
    final chars = e.totalChars;
    if (chars < 200 || chars > 550) {
      throw StateError(
        'codex entry ${e.id} 字数=$chars,应 ∈ [200, 550](GDD §10.2)',
      );
    }
  }
}

/// 材料经济 P1 商店标价红线（GDD §5.1）：
/// - 固定价商品：price ∈ [1, 100000]（test fixture 不带 yaml 时空 map，跳过）。
/// - 动态价商品（priceLayerFraction != null）：fraction > 0，跳过绝对价格校验。
void enforceShopRedLines({
  required Map<String, ShopItemDef> shopItemDefs,
  required Map<String, ItemDef> itemDefs,
}) {
  if (shopItemDefs.isEmpty) return; // test fixture 兼容
  for (final d in shopItemDefs.values) {
    // F8（2026-06-23 掉落优化）：§5.7「仅掉落不上架」守门。
    //   - 秘籍（techniqueScroll）：GDD §5.7 仅掉落，上架破"先感受问题再给答案"。
    //   - 大还丹（大档经验丹）：仅掉落不上架。档位由稳定 defId 识别，
    //     不与可调的 layerFraction 数值耦合。
    if (d.itemType == ItemType.techniqueScroll) {
      throw StateError('红线:商店 ${d.id} 上架秘籍 ${d.itemDefId}，违反 §5.7（秘籍仅掉落不上架）');
    }
    final item = itemDefs[d.itemDefId];
    if (item != null &&
        item.type == ItemType.jingYanDan &&
        item.defId == 'item_jingyandan_large') {
      throw StateError(
        '红线:商店 ${d.id} 上架大还丹 ${d.itemDefId}，违反 §5.7（大档经验丹仅掉落不上架）',
      );
    }
    if (d.isDynamicPrice) {
      // 动态标价：校验 fraction > 0 即可，绝对价格由 etl 决定
      if (d.priceLayerFraction! <= 0) {
        throw StateError(
          '红线:商店 ${d.id} price_layer_fraction ${d.priceLayerFraction} ≤ 0',
        );
      }
    } else {
      if (d.price! <= 0) {
        throw StateError('红线:商店 ${d.id} 标价 ${d.price} ≤ 0');
      }
      if (d.price! > 100000) {
        throw StateError('红线:商店 ${d.id} 标价 ${d.price} > 100000');
      }
    }
  }
}

/// 材料经济 balance T1：经验丹 layer_fraction 红线（应 ∈ (0.0, 1.0]，防配 0 或超 1 破缩放）。
void enforceItemRedLines({
  required Map<String, ItemDef> itemDefs,
  required NumbersConfig numbers,
}) {
  if (itemDefs.isEmpty) return; // test fixture 兼容
  for (final d in itemDefs.values) {
    final frac = d.layerFraction;
    if (frac != null && (frac <= 0 || frac > 1.0)) {
      throw StateError(
        '红线:道具 ${d.defId} layer_fraction $frac 应 ∈ (0.0, 1.0]',
      );
    }
    if (d.injuryHealHours < 0 || d.residueHealHours < 0) {
      throw StateError(
        '红线:道具 ${d.defId} recovery hours 不可为负 '
        '(injury=${d.injuryHealHours}, residue=${d.residueHealHours})',
      );
    }
  }
  for (final map in numbers.retreat.maps) {
    for (final itemId in map.itemOutputsPerHour.keys) {
      if (!itemDefs.containsKey(itemId)) {
        throw StateError(
          '红线:闭关地图 ${map.mapType.name} item_outputs_per_hour 引用不存在道具 $itemId',
        );
      }
    }
  }
}

/// 桃花岛一期：建筑配置红线。
///
/// itemDefs 为空（test fixture 不带 items.yaml）时跳过，避免误伤 fixture。
/// 非空时收集已知 item defId，调 [TaohuaIslandConfig.validate]。
void enforceTaohuaIslandRedLines({
  required Map<String, ItemDef> itemDefs,
  required NumbersConfig numbers,
}) {
  if (itemDefs.isEmpty) return; // test fixture 兼容
  final knownIds = itemDefs.keys.toSet();
  TaohuaIslandConfig.validate(numbers.taohuaIsland, knownIds);
}

/// W18-A1 心法相生红线(GDD §4.5 + numbers 红线对齐):
/// - id 唯一(由 _parseDefMap 已保证,此处不重校)
/// - multiplier 各项 ≥ 0 ≤ 0.30(防数值膨胀)
/// - schoolPair 类型必须配 mainSchool + assistSchool 且两者不同
/// - sameSchool / sameTier 类型不应配 mainSchool / assistSchool
/// - synergies 非空时 ≥ 5(GDD §4.5 "5-8 个隐藏组合")— test fixture
///   不带 yaml 时 list 为空,跳过下限校验
void enforceSynergyRedLines({
  required List<SynergyDef> synergies,
  required Map<String, TechniqueDef> techniqueDefs,
}) {
  if (synergies.isEmpty) return;
  if (synergies.length < 5) {
    throw StateError(
      'synergies.yaml 至少 5 组合(GDD §4.5),实际 ${synergies.length}',
    );
  }
  final seen = <String>{};
  for (final s in synergies) {
    if (!seen.add(s.id)) {
      throw StateError('synergy id 重复: ${s.id}');
    }
    if (!s.multipliers.isWithinRedLine) {
      throw StateError('synergy ${s.id} multiplier 越界(应各项 ∈ [0, 0.30])');
    }
    switch (s.requirementType) {
      case SynergyRequirementType.specificTechniques:
        if (s.requiredMainTechniqueId == null ||
            s.requiredAssistTechniqueId == null) {
          throw StateError(
            'synergy ${s.id} specificTechniques 必须配 '
            'mainTechniqueId + assistTechniqueId',
          );
        }
        if (s.mainSchool != null || s.assistSchool != null) {
          throw StateError(
            'synergy ${s.id} specificTechniques 不应配 mainSchool/assistSchool',
          );
        }
        if (techniqueDefs.isNotEmpty &&
            !techniqueDefs.containsKey(s.requiredMainTechniqueId)) {
          throw StateError(
            'synergy ${s.id} requiredMainTechniqueId='
            '${s.requiredMainTechniqueId} 不存在于 techniques.yaml',
          );
        }
        if (techniqueDefs.isNotEmpty &&
            !techniqueDefs.containsKey(s.requiredAssistTechniqueId)) {
          throw StateError(
            'synergy ${s.id} requiredAssistTechniqueId='
            '${s.requiredAssistTechniqueId} 不存在于 techniques.yaml',
          );
        }
        break;
      case SynergyRequirementType.schoolPair:
        if (s.mainSchool == null || s.assistSchool == null) {
          throw StateError(
            'synergy ${s.id} schoolPair 必须配 mainSchool + assistSchool',
          );
        }
        if (s.mainSchool == s.assistSchool) {
          throw StateError(
            'synergy ${s.id} schoolPair main/assist 不能相同(同流派走 sameSchool 类型)',
          );
        }
        if (s.requiredMainTechniqueId != null ||
            s.requiredAssistTechniqueId != null) {
          throw StateError(
            'synergy ${s.id} schoolPair 不应配 mainTechniqueId/assistTechniqueId',
          );
        }
        break;
      case SynergyRequirementType.sameSchool:
      case SynergyRequirementType.sameTier:
        if (s.mainSchool != null || s.assistSchool != null) {
          throw StateError(
            'synergy ${s.id} ${s.requirementType.name} 不应配 mainSchool/assistSchool',
          );
        }
        if (s.requiredMainTechniqueId != null ||
            s.requiredAssistTechniqueId != null) {
          throw StateError(
            'synergy ${s.id} ${s.requirementType.name} '
            '不应配 mainTechniqueId/assistTechniqueId',
          );
        }
        break;
    }
  }
}
