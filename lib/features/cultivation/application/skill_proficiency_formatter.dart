import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/strings.dart';

class SkillProficiencySummary {
  final SkillDef skill;
  final int uses;
  final String stageName;
  final double ratio;
  final String currentEffect;
  final String? nextEffect;
  final String progressText;

  const SkillProficiencySummary({
    required this.skill,
    required this.uses,
    required this.stageName,
    required this.ratio,
    required this.currentEffect,
    required this.nextEffect,
    required this.progressText,
  });
}

class SkillProficiencyFormatter {
  const SkillProficiencyFormatter._();

  static SkillProficiencySummary summarize({
    required SkillDef skill,
    required int uses,
    required SkillProficiencyConfig cfg,
  }) {
    final stages = cfg.stages;
    final stage = SkillProficiency.stageFor(uses, cfg);
    final stageIdx = stages.indexWhere((s) => s.id == stage.id);
    final isMax = stageIdx == stages.length - 1;

    final double ratio;
    final String progressText;
    if (isMax) {
      ratio = 1.0;
      progressText = UiStrings.cangjingProficiencySourceCombat;
    } else {
      final nextStage = stages[stageIdx + 1];
      final rangeStart = stage.minUses;
      final rangeEnd = nextStage.minUses;
      ratio = ((uses - rangeStart) / (rangeEnd - rangeStart)).clamp(0.0, 1.0);
      progressText = UiStrings.cangjingProficiencyNeedWithSource(
        nextStage.minUses - uses,
      );
    }

    return SkillProficiencySummary(
      skill: skill,
      uses: uses,
      stageName: UiStrings.cangjingProficiencyStageName(stage.id),
      ratio: ratio,
      currentEffect: UiStrings.cangjingProficiencyCurrent(
        _effectTextForStage(skill: skill, stage: stage, cfg: cfg),
      ),
      nextEffect: isMax
          ? UiStrings.cangjingProficiencyMaxStage
          : UiStrings.cangjingProficiencyNext(
              _effectTextForStage(
                skill: skill,
                stage: stages[stageIdx + 1],
                cfg: cfg,
              ),
            ),
      progressText: progressText,
    );
  }

  static String compactEffect({
    required SkillDef skill,
    required int uses,
    required SkillProficiencyConfig cfg,
  }) {
    final summary = summarize(skill: skill, uses: uses, cfg: cfg);
    return UiStrings.skillProficiencyCompact(
      summary.stageName,
      _effectTextForStage(
        skill: skill,
        stage: SkillProficiency.stageFor(uses, cfg),
        cfg: cfg,
      ),
    );
  }

  static SkillProficiencySummary? bestSkillSummaryForTechnique({
    required Iterable<SkillDef> skills,
    required Map<String, int> usage,
    required SkillProficiencyConfig cfg,
  }) {
    SkillDef? bestSkill;
    var bestUses = -1;
    for (final skill in skills) {
      final uses = usage[skill.id] ?? 0;
      if (uses > bestUses) {
        bestSkill = skill;
        bestUses = uses;
      }
    }
    if (bestSkill == null) return null;
    return summarize(skill: bestSkill, uses: bestUses, cfg: cfg);
  }

  static String _effectTextForStage({
    required SkillDef skill,
    required SkillProficiencyStageConfig stage,
    required SkillProficiencyConfig cfg,
  }) {
    final effects = <String>[
      UiStrings.cangjingProficiencyDamageBonus(
        _damageBonusPct(skill, stage, cfg),
      ),
    ];

    final cooldownReduction = _cooldownReduction(skill, stage.id);
    if (cooldownReduction > 0) {
      effects.add(
        UiStrings.cangjingProficiencyCooldownReduction(cooldownReduction),
      );
    }

    final interruptPowerPct =
        skill.proficiency?.interruptPowerPctAt(stage.id) ?? 0.0;
    if (interruptPowerPct > 0) {
      effects.add(
        UiStrings.cangjingProficiencyInterruptPower(
          (interruptPowerPct * 100).round(),
        ),
      );
    }

    final interruptWindow =
        skill.proficiency?.interruptWindowBonusAt(stage.id) ?? 0;
    if (interruptWindow > 0) {
      effects.add(
        UiStrings.cangjingProficiencyInterruptWindow(interruptWindow),
      );
    }

    return UiStrings.cangjingProficiencyEffectList(effects);
  }

  static int _damageBonusPct(
    SkillDef skill,
    SkillProficiencyStageConfig stage,
    SkillProficiencyConfig cfg,
  ) {
    final perSkillPct = skill.proficiency?.damagePctAt(stage.id) ?? 0.0;
    final raw = stage.damageMult * (1.0 + perSkillPct);
    final combined = raw > cfg.maxDamageMult ? cfg.maxDamageMult : raw;
    return ((combined - 1.0) * 100).round();
  }

  static int _cooldownReduction(SkillDef skill, String stageId) {
    final base = skill.cooldownTurns;
    if (base <= 0) return 0;
    final delta = skill.proficiency?.cooldownDeltaAt(stageId) ?? 0;
    final effective = (base + delta).clamp(0, base);
    return base - effective;
  }
}
