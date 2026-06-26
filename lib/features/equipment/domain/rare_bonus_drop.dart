import '../../../core/domain/enums.dart';
import '../../../shared/utils/rng.dart';

/// 第八阶段 E·稀有彩头掉落配置(numbers.yaml `rare_bonus_drop`)。
///
/// 全局机制:每场战斗除本关固定掉落外,按 [tiers] 各档独立 roll,小概率额外掉
/// 「高于本关 N 阶」的随机装备。概率随阶差递减但不为零(用户拍板)。守 §5.3:
/// 高阶装备可拿不可装,由境界锁兜底;守 §5.1:低概率非每日/抽卡机制。
class RareBonusDropConfig {
  final bool enabled;

  /// 各阶差档(offset≥1)+ 命中概率。建议按 offset 升序(取最高命中靠覆盖)。
  final List<RareBonusTier> tiers;

  const RareBonusDropConfig({required this.enabled, required this.tiers});

  static const empty = RareBonusDropConfig(enabled: false, tiers: []);

  factory RareBonusDropConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    final rawTiers = (y['tiers'] as List?) ?? const [];
    return RareBonusDropConfig(
      enabled: y['enabled'] as bool? ?? false,
      tiers: rawTiers
          .map((e) => RareBonusTier.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}

class RareBonusTier {
  /// 高于本关装备阶的阶数(1=高 1 阶,2=高 2 阶)。
  final int offset;

  /// 该档命中概率 [0,1]。
  final double chance;

  const RareBonusTier({required this.offset, required this.chance});

  factory RareBonusTier.fromYaml(Map<String, dynamic> y) => RareBonusTier(
        offset: (y['offset'] as num).toInt(),
        chance: (y['chance'] as num).toDouble(),
      );
}

/// 稀有彩头阶选择(纯函数)。各档独立 roll,命中则记该阶,**取命中的最高阶**
/// (更稀有优先);全不命中 / disabled / 越界(超神物)→ null。
EquipmentTier? selectRareBonusTier(
  EquipmentTier baseTier,
  RareBonusDropConfig config,
  Rng rng,
) {
  if (!config.enabled) return null;
  const tiers = EquipmentTier.values;
  EquipmentTier? hit;
  for (final t in config.tiers) {
    final idx = baseTier.index + t.offset;
    if (idx >= tiers.length) continue; // 越界(超神物)不掉
    if (rng.nextDouble() < t.chance) hit = tiers[idx]; // 升序覆盖 → 取最高
  }
  return hit;
}
