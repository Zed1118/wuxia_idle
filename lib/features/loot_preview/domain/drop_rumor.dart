// lib/features/loot_preview/domain/drop_rumor.dart
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
