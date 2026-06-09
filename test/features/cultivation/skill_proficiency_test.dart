import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';

void main() {
  final stages = [
    const SkillProficiencyStageConfig(id: 'chuShi', minUses: 0, damageMult: 1.00),
    const SkillProficiencyStageConfig(id: 'shunShou', minUses: 30, damageMult: 1.05),
    const SkillProficiencyStageConfig(id: 'shuLian', minUses: 100, damageMult: 1.12),
    const SkillProficiencyStageConfig(id: 'jingTong', minUses: 300, damageMult: 1.20),
    const SkillProficiencyStageConfig(id: 'huaJing', minUses: 800, damageMult: 1.30),
  ];
  final cfg = SkillProficiencyConfig(stages: stages);

  test('stageFor 按 uses 落档', () {
    expect(SkillProficiency.stageFor(0, cfg).id, 'chuShi');
    expect(SkillProficiency.stageFor(29, cfg).id, 'chuShi');
    expect(SkillProficiency.stageFor(30, cfg).id, 'shunShou');
    expect(SkillProficiency.stageFor(799, cfg).id, 'jingTong');
    expect(SkillProficiency.stageFor(800, cfg).id, 'huaJing');
    expect(SkillProficiency.stageFor(99999, cfg).id, 'huaJing');
  });

  test('damageMultFor 取对应阶段倍率', () {
    expect(SkillProficiency.damageMultFor(0, cfg), 1.00);
    expect(SkillProficiency.damageMultFor(100, cfg), 1.12);
    expect(SkillProficiency.damageMultFor(800, cfg), 1.30);
  });

  test('combinedMult: 全局×(1+perSkillPct) 封顶 maxDamageMult', () {
    expect(SkillProficiency.combinedMult(800, 0.20, cfg), 1.30);
    expect(SkillProficiency.combinedMult(100, 0.05, cfg), closeTo(1.176, 1e-9));
    expect(SkillProficiency.combinedMult(300, 0.0, cfg), 1.20);
  });
}
