import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';

void main() {
  final cfg = const SkillProficiencyConfig(stages: [
    SkillProficiencyStageConfig(id: 'chuShi', minUses: 0, damageMult: 1.00),
    SkillProficiencyStageConfig(id: 'shunShou', minUses: 30, damageMult: 1.05),
    SkillProficiencyStageConfig(id: 'shuLian', minUses: 100, damageMult: 1.12),
    SkillProficiencyStageConfig(id: 'jingTong', minUses: 300, damageMult: 1.20),
    SkillProficiencyStageConfig(id: 'huaJing', minUses: 800, damageMult: 1.30),
  ]);

  SkillDef mk({SkillProficiencyEffects? prof, int cd = 4}) => SkillDef(
        id: 's',
        name: 'x',
        description: 'd',
        type: SkillType.powerSkill,
        powerMultiplier: 1200,
        internalForceCost: 100,
        cooldownTurns: cd,
        requiresManualTrigger: false,
        visualEffect: 'v',
        proficiency: prof,
      );

  test('effectiveCooldown: 无 proficiency → 原 CD', () {
    final s = mk();
    expect(SkillProficiency.effectiveCooldown(s, 800, cfg), 4);
  });

  test('effectiveCooldown: 达阶起减 CD,下限 0', () {
    final s = mk(prof: SkillProficiencyEffects.fromYaml({
      'effects': {
        'shunShou': {'cooldown_delta': -1},
        'huaJing': {'cooldown_delta': -6},
      }
    }));
    expect(SkillProficiency.effectiveCooldown(s, 0, cfg), 4); // chuShi 未配
    expect(SkillProficiency.effectiveCooldown(s, 30, cfg), 3); // shunShou -1
    expect(SkillProficiency.effectiveCooldown(s, 800, cfg), 0); // huaJing -6 clamp 0
  });

  test('effectiveCooldown: 原 CD 0 → 恒 0(不被 delta 拉负/拉正)', () {
    final s = mk(cd: 0, prof: SkillProficiencyEffects.fromYaml({
      'effects': {'huaJing': {'cooldown_delta': -1}}
    }));
    expect(SkillProficiency.effectiveCooldown(s, 800, cfg), 0);
  });

  test('interruptWindowBonus: 按阶取破招窗口加成 tick', () {
    final s = mk(prof: SkillProficiencyEffects.fromYaml({
      'effects': {'huaJing': {'interrupt_window_bonus_ticks': 2}}
    }));
    expect(SkillProficiency.interruptWindowBonus(s, 0, cfg), 0);
    expect(SkillProficiency.interruptWindowBonus(s, 800, cfg), 2);
  });
}
