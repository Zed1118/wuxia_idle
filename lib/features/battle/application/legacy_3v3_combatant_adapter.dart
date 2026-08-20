import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../domain/battle_state.dart';

/// Boundary between neutral assembled facts and the legacy 3v3 runtime.
final class Legacy3v3CombatantAdapter {
  const Legacy3v3CombatantAdapter._();

  static const _playerSide = 0;
  static const _enemySide = 1;
  static const _legacyTeamCapacity = 3;

  static List<BattleCharacter> playerTeam(
    Iterable<CombatantSnapshot> snapshots,
  ) => _team(snapshots, teamSide: _playerSide, maxSize: _legacyTeamCapacity);

  static List<BattleCharacter> enemyTeam(
    Iterable<CombatantSnapshot> snapshots,
  ) => _team(snapshots, teamSide: _enemySide, maxSize: _legacyTeamCapacity);

  static List<BattleCharacter> enemyWave(
    Iterable<CombatantSnapshot> snapshots,
  ) => _team(snapshots, teamSide: _enemySide);

  static List<BattleCharacter> _team(
    Iterable<CombatantSnapshot> snapshots, {
    required int teamSide,
    int? maxSize,
  }) {
    final selected = maxSize == null ? snapshots : snapshots.take(maxSize);
    return [
      for (final (index, snapshot) in selected.indexed)
        fromSnapshot(snapshot, teamSide: teamSide, slotIndex: index),
    ];
  }

  static CombatantSnapshot toSnapshot(BattleCharacter c) {
    if (c.actionPoint != 0) {
      throw StateError('Legacy3v3 adapter: actionPoint 是战中动态状态');
    }
    if (!c.isAlive || c.internalInjury != null) {
      throw StateError('Legacy3v3 adapter: 存活/内伤是战中动态状态');
    }
    if (c.chargingSkill != null || c.chargeTicksRemaining != 0) {
      throw StateError('Legacy3v3 adapter: 蓄力是战中动态状态');
    }
    if (c.staggerTicksRemaining != 0 || c.staggerDefenseDownOverride != null) {
      throw StateError('Legacy3v3 adapter: 踉跄是战中动态状态');
    }
    if (c.bossPhaseIndex != 0) {
      throw StateError('Legacy3v3 adapter: Boss phase index 是战中动态状态');
    }
    if (c.coopStrikeUsedInCharge || c.coopStrikeConsumedAtTick != null) {
      throw StateError('Legacy3v3 adapter: 合击消费标记是战中动态状态');
    }
    if (c.attackPowerMultiplierSource != null) {
      throw StateError(
        'Legacy3v3 adapter: 旧战报 multiplier source 不属 neutral seam',
      );
    }
    return CombatantSnapshot(
      characterId: c.characterId,
      name: c.name,
      realmTier: c.realmTier,
      realmLayer: c.realmLayer,
      school: c.school,
      maxHp: c.maxHp,
      currentHp: c.currentHp,
      internalForce: c.internalForce,
      maxQi: c.maxQi,
      currentQi: c.currentQi,
      qiGainMultiplier: c.qiGainMultiplier,
      qiCostReductionPct: c.qiCostReductionPct,
      autoUltimate: c.autoUltimate,
      speed: c.speed,
      criticalRate: c.criticalRate,
      evasionRate: c.evasionRate,
      defenseRate: c.defenseRate,
      totalEquipmentAttack: c.totalEquipmentAttack,
      mainCultivationLayer: c.mainCultivationLayer,
      availableSkills: c.availableSkills,
      openingSkillCooldowns: c.skillCooldowns,
      skillUses: c.skillUses,
      activeBuffs: c.activeBuffs,
      swordSongResonanceActive: c.swordSongResonanceActive,
      iconPath: c.iconPath,
      attackPowerMultiplier: c.attackPowerMultiplier,
      outputMultiplier: c.outputMultiplier,
      isBoss: c.isBoss,
      chargeSkillId: c.chargeSkillId,
      bossPhases: c.bossPhases,
      bossPhaseUnlockSkills: c.bossPhaseUnlockSkills,
      schoolDamageTakenMult: c.schoolDamageTakenMult,
      lineageRole: c.lineageRole,
      forgingPiercePct: c.forgingPiercePct,
      forgingLifestealPct: c.forgingLifestealPct,
      enemyDefId: c.enemyDefId,
      guardianWardMult: c.guardianWardMult,
      guardianDefIds: c.guardianDefIds,
      vulnerabilityMult: c.vulnerabilityMult,
      guardInterceptsInterrupt: c.guardInterceptsInterrupt,
    );
  }

  static BattleCharacter fromSnapshot(
    CombatantSnapshot s, {
    required int teamSide,
    required int slotIndex,
  }) {
    return BattleCharacter(
      characterId: s.characterId,
      name: s.name,
      realmTier: s.realmTier,
      realmLayer: s.realmLayer,
      school: s.school,
      maxHp: s.maxHp,
      currentHp: s.currentHp,
      internalForce: s.internalForce,
      maxQi: s.maxQi,
      currentQi: s.currentQi,
      qiGainMultiplier: s.qiGainMultiplier,
      qiCostReductionPct: s.qiCostReductionPct,
      autoUltimate: s.autoUltimate,
      speed: s.speed,
      criticalRate: s.criticalRate,
      evasionRate: s.evasionRate,
      defenseRate: s.defenseRate,
      totalEquipmentAttack: s.totalEquipmentAttack,
      mainCultivationLayer: s.mainCultivationLayer,
      availableSkills: s.availableSkills,
      skillCooldowns: s.openingSkillCooldowns,
      skillUses: s.skillUses,
      activeBuffs: s.activeBuffs,
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
      swordSongResonanceActive: s.swordSongResonanceActive,
      iconPath: s.iconPath,
      attackPowerMultiplier: s.attackPowerMultiplier,
      outputMultiplier: s.outputMultiplier,
      isBoss: s.isBoss,
      chargeSkillId: s.chargeSkillId,
      bossPhases: s.bossPhases,
      bossPhaseUnlockSkills: s.bossPhaseUnlockSkills,
      schoolDamageTakenMult: s.schoolDamageTakenMult,
      lineageRole: s.lineageRole,
      forgingPiercePct: s.forgingPiercePct,
      forgingLifestealPct: s.forgingLifestealPct,
      enemyDefId: s.enemyDefId,
      guardianWardMult: s.guardianWardMult,
      guardianDefIds: s.guardianDefIds,
      vulnerabilityMult: s.vulnerabilityMult,
      guardInterceptsInterrupt: s.guardInterceptsInterrupt,
    );
  }
}
