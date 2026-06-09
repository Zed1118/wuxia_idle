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
}
