import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// 招式熟练度纯域(可玩性 P1a · spec §三)。
/// 从招式被使用次数派生当前阶段与伤害倍率。计数源 = Technique.skillUsageCount。
class SkillProficiency {
  const SkillProficiency._();

  static SkillProficiencyStageConfig stageFor(
      int uses, SkillProficiencyConfig cfg) {
    var stage = cfg.stages.first;
    for (final s in cfg.stages) {
      if (uses >= s.minUses) stage = s;
    }
    return stage;
  }

  static double damageMultFor(int uses, SkillProficiencyConfig cfg) =>
      stageFor(uses, cfg).damageMult;

  /// 全局阶段倍率 × (1 + per-skill damage_pct),综合封顶 maxDamageMult(§2.5 130% cap)。
  static double combinedMult(
      int uses, double perSkillDamagePct, SkillProficiencyConfig cfg) {
    final raw = damageMultFor(uses, cfg) * (1.0 + perSkillDamagePct);
    final cap = cfg.maxDamageMult;
    return raw > cap ? cap : raw;
  }

  /// per-skill 熟练度有效冷却(可玩性 P1a · C6)。
  /// 当前阶若配 cooldown_delta 则 base+delta,下限 0、上限 base(不被拉长)。
  /// 原 CD 为 0 的招恒 0(无 CD 概念,delta 不生效)。
  static int effectiveCooldown(
      SkillDef skill, int uses, SkillProficiencyConfig cfg) {
    final base = skill.cooldownTurns;
    if (base <= 0) return base;
    final delta =
        skill.proficiency?.cooldownDeltaAt(stageFor(uses, cfg).id) ?? 0;
    return (base + delta).clamp(0, base);
  }

  /// per-skill 破招窗口加成 tick(可玩性 P1a · C6)。破招技达阶后延长目标踉跄时长。
  static int interruptWindowBonus(
      SkillDef skill, int uses, SkillProficiencyConfig cfg) =>
      skill.proficiency?.interruptWindowBonusAt(stageFor(uses, cfg).id) ?? 0;

  /// 波A interrupt_power_pct(方向 b):该破招技当阶的减防加深比例(0 = 无加成)。
  /// 消费方算有效减防 = base × (1 + 此值),并 clamp 到 interruptPowerCap。
  static double interruptPowerPct(
      SkillDef skill, int uses, SkillProficiencyConfig cfg) =>
      skill.proficiency?.interruptPowerPctAt(stageFor(uses, cfg).id) ?? 0.0;
}
