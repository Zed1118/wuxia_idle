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
