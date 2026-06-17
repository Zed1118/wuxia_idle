// lib/features/loot_preview/domain/drop_rumor.dart
import '../../../data/defs/drop_entry.dart';
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

class DropRumorTable {
  final List<DropRumorEntry> entries;
  final bool isFirstClearGated;

  const DropRumorTable({
    required this.entries,
    required this.isFirstClearGated,
  });

  bool get isEmpty => entries.isEmpty;

  factory DropRumorTable.fromDropTable(
    List<DropEntry> table, {
    required bool isFirstClearGated,
  }) {
    final entries = <DropRumorEntry>[];
    for (final e in table) {
      final bucket = bucketOf(e.dropChance, isFirstClearGated: isFirstClearGated);
      switch (e) {
        case EquipmentDrop(:final equipmentDefId):
          entries.add(DropRumorEntry(
            defId: equipmentDefId,
            isEquipment: true,
            bucket: bucket,
          ));
        case ItemDrop(:final inventoryItemDefId):
          entries.add(DropRumorEntry(
            defId: inventoryItemDefId,
            isEquipment: false,
            bucket: bucket,
          ));
      }
    }
    return DropRumorTable(entries: entries, isFirstClearGated: isFirstClearGated);
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
