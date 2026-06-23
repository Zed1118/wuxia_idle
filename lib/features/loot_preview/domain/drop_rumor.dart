// lib/features/loot_preview/domain/drop_rumor.dart
import '../../../core/domain/enums.dart' show isTechniqueScrollDefId;
import '../../../data/defs/drop_entry.dart';

/// 首通门控策略（F2/2026-06-23 续48）。
///
/// 此前 `fromDropTable` 用「整表单布尔」铺给每一条，表达不了「同表内秘籍门控、
/// 装备不门控」——主线秘籍(item_scroll_*)被错归常可得。改为逐条策略：
/// - [scrollOnly]   主线：仅秘籍 first-clear-gated（镜像 runtime `shouldSkipScrollDrop`），
///   其余每次胜利可掉。
/// - [wholeChannel] 爬塔：整渠道 first-clear-gated，全表条目均首通必得。
enum FirstClearGating { scrollOnly, wholeChannel }

/// 玩家侧掉落「传闻」稀有度桶（GDD §2.1 反主流：不用传奇/SSR 等网游词）。
/// 纯由 dropChance + 是否首通门控派生，不引入 DropEntry schema 字段。
enum DropRumorBucket {
  shouTongBiDe, // 首通必得（仅首通门控上下文 + dropChance==1.0）
  changKeDe,    // 常可得（非门控 + dropChance==1.0）
  ouKeDe,       // 偶可得（>=0.30）
  shaoYouRenDe, // 少有人得（>=0.08）
  jiangHuChuanWen, // 江湖传闻（<0.08）
}

/// 桶映射规则。判定顺序：首条命中即返回。
/// 入参 dropChance 恒 ∈ [0.0, 1.0]（上游 DropEntry.fromYaml 已硬校验）；>1 同 1.0、<0 归江湖传闻。
DropRumorBucket bucketOf(double dropChance, {required bool isFirstClearGated}) {
  if (dropChance >= 1.0) {
    return isFirstClearGated
        ? DropRumorBucket.shouTongBiDe
        : DropRumorBucket.changKeDe;
  }
  if (dropChance >= 0.30) return DropRumorBucket.ouKeDe;
  if (dropChance >= 0.08) return DropRumorBucket.shaoYouRenDe;
  return DropRumorBucket.jiangHuChuanWen;
}

/// 桶展示优先级（高 → 低）：grouped 与 topRepresentatives 共用。
const List<DropRumorBucket> _bucketDisplayOrder = [
  DropRumorBucket.shouTongBiDe,
  DropRumorBucket.changKeDe,
  DropRumorBucket.ouKeDe,
  DropRumorBucket.shaoYouRenDe,
  DropRumorBucket.jiangHuChuanWen,
];

class DropRumorEntry {
  final String defId;
  final bool isEquipment;
  final DropRumorBucket bucket;

  const DropRumorEntry({
    required this.defId,
    required this.isEquipment,
    required this.bucket,
  });
}

/// 单条 [DropEntry] 在给定门控策略下是否首通必得。
/// scrollOnly 仅秘籍门控（与 runtime `shouldSkipScrollDrop` 同一谓词），
/// wholeChannel 全条目门控。
bool _entryFirstClearGated(String defId, FirstClearGating gating) =>
    switch (gating) {
      FirstClearGating.scrollOnly => isTechniqueScrollDefId(defId),
      FirstClearGating.wholeChannel => true,
    };

class DropRumorTable {
  final List<DropRumorEntry> entries;
  final FirstClearGating gating;

  const DropRumorTable({
    required this.entries,
    required this.gating,
  });

  bool get isEmpty => entries.isEmpty;

  /// 表内是否存在首通必得条目（dropChance==1.0 且该条门控）。
  /// 主线脚注由此驱动：含秘籍才提示「重打不补」，否则不显。
  bool get hasFirstClearGatedEntry =>
      entries.any((e) => e.bucket == DropRumorBucket.shouTongBiDe);

  factory DropRumorTable.fromDropTable(
    List<DropEntry> table, {
    required FirstClearGating gating,
  }) {
    final entries = <DropRumorEntry>[];
    for (final e in table) {
      final defId = switch (e) {
        EquipmentDrop(:final equipmentDefId) => equipmentDefId,
        ItemDrop(:final inventoryItemDefId) => inventoryItemDefId,
      };
      final bucket = bucketOf(
        e.dropChance,
        isFirstClearGated: _entryFirstClearGated(defId, gating),
      );
      switch (e) {
        case EquipmentDrop():
          entries.add(DropRumorEntry(
            defId: defId,
            isEquipment: true,
            bucket: bucket,
          ));
        case ItemDrop():
          entries.add(DropRumorEntry(
            defId: defId,
            isEquipment: false,
            bucket: bucket,
          ));
      }
    }
    return DropRumorTable(entries: entries, gating: gating);
  }

  /// 按桶分组，桶顺序固定为展示优先级；空桶不出现。entry 原序保留。
  Map<DropRumorBucket, List<DropRumorEntry>> grouped() {
    final map = <DropRumorBucket, List<DropRumorEntry>>{};
    for (final bucket in _bucketDisplayOrder) {
      final hits = entries.where((e) => e.bucket == bucket).toList();
      if (hits.isNotEmpty) map[bucket] = hits;
    }
    return map;
  }

  /// 简版代表：按桶优先级展平，取前 n（默认 3）。
  List<DropRumorEntry> topRepresentatives(int n) {
    final flat = <DropRumorEntry>[];
    for (final bucket in _bucketDisplayOrder) {
      flat.addAll(entries.where((e) => e.bucket == bucket));
    }
    return flat.take(n).toList();
  }
}
