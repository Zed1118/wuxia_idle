import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

void main() {
  const source = BattleCharacter(
    characterId: 7,
    name: 'round-trip',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.ruMen,
    school: TechniqueSchool.gangMeng,
    maxHp: 1200,
    currentHp: 900,
    internalForce: 600,
    maxQi: 100,
    currentQi: 37,
    speed: 101,
    criticalRate: .12,
    evasionRate: .03,
    defenseRate: .08,
    totalEquipmentAttack: 130,
    mainCultivationLayer: CultivationLayer.chuKui,
    availableSkills: [],
    skillCooldowns: {'opening': 2},
    skillUses: {'opening': 19},
    activeBuffs: ['cycle_ningjia'],
    actionPoint: 0,
    isAlive: true,
    teamSide: 1,
    slotIndex: 2,
    attackPowerMultiplier: 1.1,
    outputMultiplier: 1.0,
    isBoss: true,
    bossPhaseUnlockSkills: [<SkillDef>[]],
  );

  test(
    'initial BattleCharacter → neutral → BattleCharacter preserves stable fields',
    () {
      final snapshot = Legacy3v3CombatantAdapter.toSnapshot(source);
      final restored = Legacy3v3CombatantAdapter.fromSnapshot(
        snapshot,
        teamSide: source.teamSide,
        slotIndex: source.slotIndex,
      );
      expect(restored.characterId, source.characterId);
      expect(restored.name, source.name);
      expect(restored.maxHp, source.maxHp);
      expect(restored.currentHp, source.currentHp);
      expect(restored.internalForce, source.internalForce);
      expect(restored.currentQi, source.currentQi);
      expect(restored.speed, source.speed);
      expect(restored.criticalRate, source.criticalRate);
      expect(restored.evasionRate, source.evasionRate);
      expect(restored.defenseRate, source.defenseRate);
      expect(restored.totalEquipmentAttack, source.totalEquipmentAttack);
      expect(restored.activeBuffs, source.activeBuffs);
      expect(restored.availableSkills, source.availableSkills);
      expect(restored.skillCooldowns, source.skillCooldowns);
      expect(restored.skillUses, source.skillUses);
      expect(restored.qiGainMultiplier, source.qiGainMultiplier);
      expect(restored.qiCostReductionPct, source.qiCostReductionPct);
      expect(restored.autoUltimate, source.autoUltimate);
      expect(
        restored.swordSongResonanceActive,
        source.swordSongResonanceActive,
      );
      expect(restored.iconPath, source.iconPath);
      expect(restored.attackPowerMultiplier, source.attackPowerMultiplier);
      expect(restored.outputMultiplier, source.outputMultiplier);
      expect(restored.isBoss, source.isBoss);
      expect(restored.chargeSkillId, source.chargeSkillId);
      expect(restored.bossPhases, source.bossPhases);
      expect(restored.bossPhaseUnlockSkills, source.bossPhaseUnlockSkills);
      expect(restored.schoolDamageTakenMult, source.schoolDamageTakenMult);
      expect(restored.lineageRole, source.lineageRole);
      expect(restored.forgingPiercePct, source.forgingPiercePct);
      expect(restored.forgingLifestealPct, source.forgingLifestealPct);
      expect(restored.enemyDefId, source.enemyDefId);
      expect(restored.guardianWardMult, source.guardianWardMult);
      expect(restored.guardianDefIds, source.guardianDefIds);
      expect(restored.vulnerabilityMult, source.vulnerabilityMult);
      expect(
        restored.guardInterceptsInterrupt,
        source.guardInterceptsInterrupt,
      );
      expect(restored.teamSide, source.teamSide);
      expect(restored.slotIndex, source.slotIndex);
      expect(restored.actionPoint, 0);
    },
  );

  test(
    '动态运行态或 multiplier source 的 BattleCharacter 转 snapshot 必须 fail-fast',
    () {
      expect(
        () => Legacy3v3CombatantAdapter.toSnapshot(
          source.copyWith(actionPoint: 1),
        ),
        throwsStateError,
      );
      expect(
        () => Legacy3v3CombatantAdapter.toSnapshot(
          source.copyWith(staggerTicksRemaining: 1),
        ),
        throwsStateError,
      );
    },
  );
}
