import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

Character _mkChar() {
  final attrs = Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 0
    ..fortune = 5;
  return Character.create(
    name: '测试',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 1000,
    school: TechniqueSchool.gangMeng,
  );
}

Technique _mkTech() => Technique.create(
      defId: 'test_tech',
      ownerCharacterId: 1,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 1, 1),
      cultivationLayer: CultivationLayer.chuKui,
    );

Equipment _mkEquip(int baseAttack) => Equipment.create(
      defId: 'test',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
      baseAttack: baseAttack,
    );

SkillDef _mkSkill() => const SkillDef(
      id: 's',
      name: 'x',
      description: 'd',
      type: SkillType.normalAttack,
      powerMultiplier: 500,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'v',
    );

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  AttackResult calc({required int uses}) {
    final tech = _mkTech();
    if (uses > 0) tech.skillUsageCount.increment('s', uses);
    final ctx = AttackContext(
      attacker: _mkChar(),
      attackerEquipped: [_mkEquip(100)],
      attackerMainTech: tech,
      skill: _mkSkill(),
      defender: _mkChar(),
      defenderEquipped: const [],
      defenderMainTech: _mkTech(),
      rng: Random(99),
    );
    return DamageCalculator.calculate(ctx, GameRepository.instance.numbers);
  }

  test('calculate(ctx) 按 attackerMainTech.skillUsageCount 应用熟练度倍率', () {
    final baseline = calc(uses: 0); // (1000*0.4+100+500)*0.95 = 950
    final huaJing = calc(uses: 800); // ×1.30 = 1235
    expect(baseline.mainDamage, 950);
    expect(huaJing.mainDamage, 1235);
  });

  test('uses=29 仍 chuShi(1.0),uses=100 shuLian(1.12)', () {
    expect(calc(uses: 29).mainDamage, 950);
    expect(calc(uses: 100).mainDamage, (950 * 1.12).toInt()); // 1064
  });
}
