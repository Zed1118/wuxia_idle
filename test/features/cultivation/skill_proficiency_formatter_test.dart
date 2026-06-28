import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_proficiency_formatter.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  final cfg = const SkillProficiencyConfig(
    stages: [
      SkillProficiencyStageConfig(id: 'chuShi', minUses: 0, damageMult: 1.00),
      SkillProficiencyStageConfig(
        id: 'shunShou',
        minUses: 30,
        damageMult: 1.05,
      ),
      SkillProficiencyStageConfig(
        id: 'shuLian',
        minUses: 100,
        damageMult: 1.12,
      ),
      SkillProficiencyStageConfig(
        id: 'jingTong',
        minUses: 300,
        damageMult: 1.20,
      ),
      SkillProficiencyStageConfig(
        id: 'huaJing',
        minUses: 800,
        damageMult: 1.30,
      ),
    ],
  );

  SkillDef skill({SkillProficiencyEffects? proficiency, int cooldown = 4}) =>
      SkillDef(
        id: 'skill_test',
        name: '试招',
        description: 'd',
        type: SkillType.powerSkill,
        powerMultiplier: 1200,
        internalForceCost: 100,
        cooldownTurns: cooldown,
        requiresManualTrigger: false,
        visualEffect: 'v',
        proficiency: proficiency,
      );

  test('summarize shows current stage, next stage, progress and source', () {
    final summary = SkillProficiencyFormatter.summarize(
      skill: skill(),
      uses: 50,
      cfg: cfg,
    );

    expect(
      summary.stageName,
      UiStrings.cangjingProficiencyStageName('shunShou'),
    );
    expect(summary.ratio, closeTo(20 / 70, 1e-9));
    expect(
      summary.currentEffect,
      UiStrings.cangjingProficiencyCurrent(
        UiStrings.cangjingProficiencyDamageBonus(5),
      ),
    );
    expect(
      summary.nextEffect,
      UiStrings.cangjingProficiencyNext(
        UiStrings.cangjingProficiencyDamageBonus(12),
      ),
    );
    expect(
      summary.progressText,
      contains(UiStrings.cangjingProficiencyNeed(50)),
    );
    expect(
      summary.progressText,
      contains(UiStrings.cangjingProficiencySourceCombat),
    );
  });

  test('summarize includes per-skill effects at current and next stage', () {
    final s = skill(
      proficiency: SkillProficiencyEffects.fromYaml({
        'effects': {
          'jingTong': {
            'damage_pct': 0.05,
            'cooldown_delta': -1,
            'interrupt_power_pct': 0.12,
          },
          'huaJing': {
            'damage_pct': 0.20,
            'cooldown_delta': -6,
            'interrupt_window_bonus_ticks': 2,
          },
        },
      }),
    );

    final summary = SkillProficiencyFormatter.summarize(
      skill: s,
      uses: 300,
      cfg: cfg,
    );

    expect(
      summary.currentEffect,
      contains(UiStrings.cangjingProficiencyDamageBonus(26)),
    );
    expect(
      summary.currentEffect,
      contains(UiStrings.cangjingProficiencyCooldownReduction(1)),
    );
    expect(
      summary.currentEffect,
      contains(UiStrings.cangjingProficiencyInterruptPower(12)),
    );
    expect(
      summary.nextEffect,
      contains(UiStrings.cangjingProficiencyDamageBonus(30)),
    );
    expect(
      summary.nextEffect,
      contains(UiStrings.cangjingProficiencyCooldownReduction(4)),
    );
    expect(
      summary.nextEffect,
      contains(UiStrings.cangjingProficiencyInterruptWindow(2)),
    );
  });

  test('summarize at max stage keeps source visible', () {
    final summary = SkillProficiencyFormatter.summarize(
      skill: skill(),
      uses: 900,
      cfg: cfg,
    );

    expect(summary.ratio, 1.0);
    expect(summary.nextEffect, UiStrings.cangjingProficiencyMaxStage);
    expect(summary.progressText, UiStrings.cangjingProficiencySourceCombat);
  });
}
