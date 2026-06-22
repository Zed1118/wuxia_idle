import '../../../core/domain/enums.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';

/// 武学图鉴 5 来源分组(方案 A)。
enum MartialGroupKind { heartArt, trueSolution, fragment, interrupt, encounter }

/// 是否纳入武学典籍收录池(205招)。
/// source∈{technique,mainlineDrop,fragment,encounter} 或 破招(special∩canInterrupt)。
/// 排除 special 非破招(轻功对决18 + joint共鸣1)。
bool isMartialCodexSkill(SkillDef d) {
  switch (d.source) {
    case SkillSource.technique:
    case SkillSource.mainlineDrop:
    case SkillSource.fragment:
    case SkillSource.encounter:
      return true;
    case SkillSource.special:
      return d.canInterrupt; // 破招收,轻功/joint 不收
    case null:
      return false;
  }
}

/// 来源归类(破招优先于 special 兜底)。归类与段标共用,防双份漂移。
/// 前置:仅对收录池(isMartialCodexSkill==true)调用。
MartialGroupKind martialSourceKindOf(SkillDef d) {
  if (d.source == SkillSource.special && d.canInterrupt) {
    return MartialGroupKind.interrupt;
  }
  switch (d.source) {
    case SkillSource.technique:
      return MartialGroupKind.heartArt;
    case SkillSource.mainlineDrop:
      return MartialGroupKind.trueSolution;
    case SkillSource.fragment:
      return MartialGroupKind.fragment;
    case SkillSource.encounter:
      return MartialGroupKind.encounter;
    case SkillSource.special:
    case null:
      throw StateError('非武学典籍招进入归类(应先经 isMartialCodexSkill): ${d.id}');
  }
}

/// 三套点亮口径(2026-06-22 spec)。pool 须已过滤为收录池。
/// - 心法招(heartArt): id ∈ learnedHeartArtSkillIds(active角色学过的心法招并集)
/// - 稀有招(trueSolution/fragment/encounter): id ∈ unlockedIds(unlockedSkillIdSet)
/// - 破招(interrupt): style ∈ activeSchools(active角色 school 集)
Set<String> litSkillIds({
  required Iterable<SkillDef> pool,
  required Set<String> unlockedIds,
  required Set<String> learnedHeartArtSkillIds,
  required Set<TechniqueSchool> activeSchools,
}) {
  final lit = <String>{};
  for (final d in pool) {
    switch (martialSourceKindOf(d)) {
      case MartialGroupKind.heartArt:
        if (learnedHeartArtSkillIds.contains(d.id)) lit.add(d.id);
      case MartialGroupKind.interrupt:
        if (d.style != null && activeSchools.contains(d.style)) lit.add(d.id);
      case MartialGroupKind.trueSolution:
      case MartialGroupKind.fragment:
      case MartialGroupKind.encounter:
        if (unlockedIds.contains(d.id)) lit.add(d.id);
    }
  }
  return lit;
}

/// active 角色学过的心法招并集(正向:由 techDef.skillIds 取,对称 1.0 武学库)。
Set<String> learnedHeartArtSkillIds(
  List<Technique> techniques,
  Map<String, dynamic> techDefsById,
) {
  final s = <String>{};
  for (final t in techniques) {
    final def = techDefsById[t.defId];
    if (def != null) s.addAll((def.skillIds as List).cast<String>());
  }
  return s;
}

/// 全队该招最高使用次数(剪影/未练=0)。
int maxUsesOf(String skillId, List<Technique> techniques) {
  var max = 0;
  for (final t in techniques) {
    final c = t.skillUsageCount.countOf(skillId);
    if (c > max) max = c;
  }
  return max;
}
