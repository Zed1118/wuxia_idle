import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// Task 2: BattleCharacter.fromCharacter 烘焙开锋 pierce/lifesteal 派生字段。
///
/// 断言：
/// - 带 pierce20/lifesteal15 槽的武器 → bc.forgingPiercePct=0.20 / bc.forgingLifestealPct=0.15
/// - 裸装（无装备）→ 两字段均为 0.0
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  Equipment mkWeapon(List<ForgingSlot> slots) => Equipment.create(
    defId: 'weapon_zhongqi_test',
    tier: EquipmentTier.zhongQi,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: 500,
    forgingSlots: slots,
  );

  test('fromCharacter 烘焙 pierce/lifesteal 派生字段', () {
    final weapon = mkWeapon([
      ForgingSlot()
        ..slotIndex = 1
        ..type = ForgingSlotType.pierce
        ..unlocked = true
        ..bonusValue = 20,
      ForgingSlot()
        ..slotIndex = 2
        ..type = ForgingSlotType.lifesteal
        ..unlocked = true
        ..bonusValue = 15,
    ]);
    final bc = BattleCharacter.fromCharacter(
      character: _mkChar(),
      equipped: [weapon],
      mainTechnique: _mkTech(),
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );
    expect(bc.forgingPiercePct, closeTo(0.20, 1e-9));
    expect(bc.forgingLifestealPct, closeTo(0.15, 1e-9));
  });

  test('fromCharacter 将开锋三专属技能加入 availableSkills', () {
    const specialSkillId = 'skill_lingqiao_shichuan_skill';
    final weapon = mkWeapon([
      ForgingSlot()..slotIndex = 1,
      ForgingSlot()..slotIndex = 2,
      ForgingSlot()
        ..slotIndex = 3
        ..type = ForgingSlotType.specialSkill
        ..unlocked = true
        ..bonusValue = 1
        ..specialSkillId = specialSkillId,
    ]);
    final bc = BattleCharacter.fromCharacter(
      character: _mkChar(),
      equipped: [weapon],
      mainTechnique: _mkTech(),
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );

    expect(bc.availableSkills.map((s) => s.id), contains(specialSkillId));
  });

  test('fromCharacter 拒绝低境界角色使用高阶装备', () {
    final weapon = Equipment.create(
      defId: 'weapon_shenwu_test',
      tier: EquipmentTier.shenWu,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
      baseAttack: 500,
    );

    expect(
      () => BattleCharacter.fromCharacter(
        character: _mkChar(realmTier: RealmTier.erLiu),
        equipped: [weapon],
        mainTechnique: _mkTech(),
        numbers: GameRepository.instance.numbers,
        teamSide: 0,
        slotIndex: 0,
      ),
      throwsStateError,
    );
  });

  test('裸装 → 0', () {
    final bc = BattleCharacter.fromCharacter(
      character: _mkChar(),
      equipped: const [],
      mainTechnique: _mkTech(),
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );
    expect(bc.forgingPiercePct, 0.0);
    expect(bc.forgingLifestealPct, 0.0);
  });
}

Character _mkChar({RealmTier realmTier = RealmTier.jueDing}) {
  final attrs = Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;
  return Character.create(
    name: '测试侠',
    realmTier: realmTier,
    realmLayer: RealmLayer.ruMen,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 3000,
    school: TechniqueSchool.gangMeng,
    mainTechniqueId: 1,
  );
}

Technique _mkTech() => Technique.create(
  defId: 'tech_gangmeng_jichu',
  ownerCharacterId: 1,
  tier: TechniqueTier.ruMenGong,
  school: TechniqueSchool.gangMeng,
  role: TechniqueRole.main,
  learnedAt: DateTime(2026, 1, 1),
);
