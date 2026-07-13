import '../../../core/domain/enums.dart';
import '../../../data/defs/technique_def.dart';

/// 一条可研习心法候选（纯展示模型 · 学习闭环 2026-07-14）。
///
/// [learnable] = 当前境界是否够阶（§5.3 三系锁死）；不够阶仍列出但灰显，
/// 承 GDD §5.3「可观摩不可修」体例。
class LearnableTechnique {
  final TechniqueDef def;
  final bool learnable;

  const LearnableTechnique({required this.def, required this.learnable});

  TechniqueTier get tier => def.tier;
  TechniqueSchool get school => def.school;
}

/// 由全量心法 def、已持有 defId 集与境界 cap 派生「可研习列表」。
///
/// 规则（拍板 A：境界内全部可学）：
///   - 排除已持有的 defId（不重复学）
///   - 保留其余全部，按 `tier ≤ realmTierCap` 标记 [LearnableTechnique.learnable]
///   - 排序：tier 低→高，同 tier 按流派枚举序（展示稳定）
///
/// 纯函数，不读 Isar/GameRepository 单例，便于单测。
List<LearnableTechnique> computeLearnableTechniques({
  required Iterable<TechniqueDef> allDefs,
  required Set<String> ownedDefIds,
  required TechniqueTier realmTierCap,
}) {
  final candidates = <LearnableTechnique>[
    for (final def in allDefs)
      if (!ownedDefIds.contains(def.id))
        LearnableTechnique(
          def: def,
          learnable: def.tier.index <= realmTierCap.index,
        ),
  ];
  candidates.sort((a, b) {
    final byTier = a.tier.index.compareTo(b.tier.index);
    if (byTier != 0) return byTier;
    return a.school.index.compareTo(b.school.index);
  });
  return candidates;
}
