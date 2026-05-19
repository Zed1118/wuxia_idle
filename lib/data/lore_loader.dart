import 'package:flutter/services.dart' show rootBundle;

import 'yaml_loader.dart';

/// 装备典故文案 `data/lore/<id>.yaml`(DeepSeek 维护)按需加载器
/// (Phase 4 W15 #35 + LoreLoader 接入)。
///
/// schema:
/// ```yaml
/// id: weapon_xunchang_ruan_bian      # 必须与文件名一致
/// name: 软鞭
/// default_lore:                       # preset 典故(已有)
///   - text: |
///       鞭身是熟牛皮绞成的 ...
///   - text: |                         # 像样货 / 利器 = 2 段
///       (略)
/// continued_lore_obtained:            # P1 #44 · 首次获得装备触发池
///   - text: |
///       于「{source}」初见此鞭,初见锋芒。
/// continued_lore_boss_defeated:       # P1 #44 · 击败 Boss 装备见证池
///   - text: |
///       于「{stage_name}」一战胜 {boss_name},此鞭沾血未崩。
/// ```
///
/// 与 [Lore] (`lib/core/domain/lore.dart`,Isar @embedded) 区别:
/// - [LoreContent]/[LoreSegment]:**纯 Dart 文件加载层**,按需 read yaml,
///   不入库,供装备详情页 / 江湖见闻录等 UI 实时渲染
/// - [Lore]:**Isar @embedded 持久层**,留给"延续典故"(战斗事件动态追加,
///   入装备实例)。preset 典故不写 [Equipment.lores],保持纯素材库语义
///
/// 缺文件 / 解析失败:返回 [LoreContent.placeholder](沿用 narrative /
/// encounter_event 体例,运行期不抛)。GameRepository 启动期做 fail-fast
/// 校验所有 [EquipmentDef.presetLoreIds] 引用必须能加载到非 placeholder。
///
/// continued_lore 池为空 / placeholder 时,caller(GameEventService)
/// fallback 到 [UiStrings.continuedLore*] Dart 模板兜底(渐进式迁移,
/// 挂账 #44 Phase 2 DeepSeek 全 35 件 yaml 补齐后再删 Dart fallback)。
class LoreSegment {
  final String text;

  const LoreSegment({required this.text});

  factory LoreSegment.fromYaml(Map<String, dynamic> y) =>
      LoreSegment(text: (y['text'] as String? ?? '').trim());
}

class LoreContent {
  final String id;
  final String name;
  final List<LoreSegment> defaultLore;

  /// P1 #44 · 首次获得装备触发池(equipmentObtained)。
  /// 占位符:`{equip_name}` / `{source}`。
  final List<LoreSegment> continuedLoreObtainedPool;

  /// P1 #44 · 击败 Boss 装备见证池(bossDefeated)。
  /// 占位符:`{equip_name}` / `{boss_name}` / `{stage_name}`。
  final List<LoreSegment> continuedLoreBossDefeatedPool;

  final bool isPlaceholder;

  const LoreContent({
    required this.id,
    required this.name,
    required this.defaultLore,
    this.continuedLoreObtainedPool = const [],
    this.continuedLoreBossDefeatedPool = const [],
    required this.isPlaceholder,
  });

  factory LoreContent.placeholder(String id) => LoreContent(
        id: id,
        name: '',
        defaultLore: const [],
        continuedLoreObtainedPool: const [],
        continuedLoreBossDefeatedPool: const [],
        isPlaceholder: true,
      );

  factory LoreContent.fromYaml(Map<String, dynamic> y) {
    List<LoreSegment> parsePool(String key) =>
        ((y[key] as List?) ?? const [])
            .map((e) =>
                LoreSegment.fromYaml(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false);
    return LoreContent(
      id: y['id'] as String,
      name: (y['name'] as String? ?? '').trim(),
      defaultLore: parsePool('default_lore'),
      continuedLoreObtainedPool: parsePool('continued_lore_obtained'),
      continuedLoreBossDefeatedPool: parsePool('continued_lore_boss_defeated'),
      isPlaceholder: false,
    );
  }
}

/// 按需加载器,沿用 [NarrativeLoader] / [EncounterEventLoader] 体例:
/// 单一路径 + placeholder 兜底,运行期不抛。
class LoreLoader {
  LoreLoader._();

  static Future<LoreContent> load(
    String loreId, {
    Future<String> Function(String)? loader,
  }) async {
    final fn = loader ?? rootBundle.loadString;
    try {
      final raw = await fn('data/lore/$loreId.yaml');
      final y = parseYamlMap(raw);
      return LoreContent.fromYaml(y);
    } catch (_) {
      return LoreContent.placeholder(loreId);
    }
  }
}
