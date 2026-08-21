import '../../../core/domain/attribute_effect_policy.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/derived_stats.dart';
import 'qi_cycle.dart';

const _shengShuFallback = ResonanceStageConfig(
  stage: ResonanceStage.shengShu,
  minBattleCount: 0,
  maxBattleCount: 0,
  bonusMultiplier: 1.0,
);

Iterable<SkillDef>? _matchingInterruptSkill(
  GameRepository repository,
  TechniqueSchool? school,
) {
  if (school == null) return null;
  for (final skill in repository.skillDefs.values) {
    if (skill.canInterrupt && skill.style == school) return [skill];
  }
  return null;
}

/// Builds the engine-neutral, pre-battle facts for one persistent player.
///
/// Roster policy, persistence reads, auto-fill, synergy and legacy team slots
/// deliberately remain outside this pure derivation boundary.
final class PlayerCombatantSnapshotBuilder {
  const PlayerCombatantSnapshotBuilder._();

  static CombatantSnapshot build({
    required Character character,
    required List<Equipment> equipped,
    required Technique mainTechnique,
    required NumbersConfig numbers,
    bool founderBuffActive = false,
    double outputMultiplier = 1.0,
    int lightInjuryStacks = 0,
    bool includeLegacyPlayerInterruptFallback = true,
  }) {
    final school = character.school;
    if (school == null) {
      throw StateError(
        'PlayerCombatantSnapshotBuilder: ${character.name} 主修流派为空，'
        '不应进入战斗',
      );
    }
    if (mainTechnique.role != TechniqueRole.main) {
      throw StateError(
        'PlayerCombatantSnapshotBuilder: ${character.name} 传入的 Technique '
        '(defId=${mainTechnique.defId}) role=${mainTechnique.role.name}，'
        '不是 main',
      );
    }
    for (final equipment in equipped) {
      if (!equipment.isEquippableAtRealm(character.realmTier)) {
        throw StateError(
          'PlayerCombatantSnapshotBuilder: ${character.name} 境界 '
          '${character.realmTier.name} 不能装备 '
          '${equipment.defId}(${equipment.tier.name})',
        );
      }
    }

    final repository = GameRepository.instance;
    final techniqueDef = repository.getTechnique(mainTechnique.defId);
    final qiConfig = numbers.combat.qi;
    final profile = techniqueDef.qiProfile;
    final disorder = numbers.innerBreathDisorder;
    final openingPenalty = QiCycle.disorderOpeningQiPenalty(
      disorderHours: character.innerBreathDisorderHoursRemaining,
      disorderMaxHours: disorder.maxHours,
      maxPenalty: disorder.maxOpeningQiPenalty,
    );
    final maxQi = (qiConfig.baseMax + profile.maxBonus).clamp(
      qiConfig.minMax,
      qiConfig.maxCap,
    );
    final openingQi = QiCycle.openingQi(
      maxQi: maxQi,
      openingQi: qiConfig.openingQi + profile.openingBonus - openingPenalty,
      openingCap: qiConfig.openingCap,
    );
    final qiGainMultiplier = (1 + profile.gainPct).clamp(
      1.0,
      qiConfig.gainMultiplierCap,
    );
    final qiCostReductionPct = profile.costReductionPct.clamp(
      0.0,
      qiConfig.costReductionCap,
    );
    final maxHp = CharacterDerivedStats.maxHp(
      character,
      equipped,
      numbers,
      founderBuffActive: founderBuffActive,
    );
    final speed = CharacterDerivedStats.speed(
      character,
      equipped,
      mainTechnique,
      numbers,
      lightInjuryStacks: lightInjuryStacks,
    );
    final criticalRate = CharacterDerivedStats.criticalRate(
      character,
      numbers,
      founderBuffActive: founderBuffActive,
    );
    final evasionRate = CharacterDerivedStats.evasionRate(character, numbers);
    final defenseRate = RealmUtils.defenseRateOf(character.realmTier);
    final totalEquipmentAttack = equipped.fold<int>(
      0,
      (sum, equipment) =>
          sum +
          CharacterDerivedStats.effectiveEquipmentAttack(equipment, numbers),
    );
    final forgingPiercePct = CharacterDerivedStats.forgingAggregatePct(
      equipped,
      ForgingSlotType.pierce,
    );
    final forgingLifestealPct = CharacterDerivedStats.forgingAggregatePct(
      equipped,
      ForgingSlotType.lifesteal,
    );

    final loadoutIds = <String?>[
      character.mainSkillId1,
      character.mainSkillId2,
      character.assistSkillId,
      character.resonanceSkillId,
      character.ultimateSkillId,
      character.equippedEncounterSkillId,
      character.keySkillId,
    ];
    var skills = <SkillDef>[
      for (final id in loadoutIds)
        if (id != null && repository.skillDefs.containsKey(id))
          repository.getSkill(id),
    ];
    final allTechniqueSlotsEmpty =
        character.mainSkillId1 == null &&
        character.mainSkillId2 == null &&
        character.assistSkillId == null &&
        character.resonanceSkillId == null &&
        character.ultimateSkillId == null;
    if (allTechniqueSlotsEmpty) {
      skills = <SkillDef>[
        ...techniqueDef.skillIds.map(repository.getSkill),
        if (character.equippedEncounterSkillId != null &&
            repository.skillDefs.containsKey(
              character.equippedEncounterSkillId!,
            ))
          repository.getSkill(character.equippedEncounterSkillId!),
        if (includeLegacyPlayerInterruptFallback &&
            character.keySkillId == null)
          ...?_matchingInterruptSkill(repository, school),
      ];
    }
    final skillIds = <String>{for (final skill in skills) skill.id};
    for (final equipment in equipped) {
      for (final slot in equipment.forgingSlots) {
        if (!slot.unlocked ||
            slot.type != ForgingSlotType.specialSkill ||
            slot.specialSkillId == null) {
          continue;
        }
        final skill = repository.skillDefs[slot.specialSkillId!];
        if (skill == null ||
            !skill.canEquipAtRealm(character.realmTier) ||
            skillIds.contains(skill.id)) {
          continue;
        }
        skills.add(skill);
        skillIds.add(skill.id);
      }
    }

    var swordSongResonanceActive = false;
    for (final equipment in equipped) {
      if (equipment.slot != EquipmentSlot.weapon) continue;
      final stage = equipment.resonanceStage(numbers);
      final config = numbers.resonanceStages.firstWhere(
        (candidate) => candidate.stage == stage,
        orElse: () => _shengShuFallback,
      );
      if (config.hasSwordSongEffect) swordSongResonanceActive = true;
    }

    return CombatantSnapshot(
      characterId: character.id,
      name: character.name,
      realmTier: character.realmTier,
      realmLayer: character.realmLayer,
      school: school,
      maxHp: maxHp,
      currentHp: maxHp,
      internalForce: QiCycle.effectiveInnerForce(
        actualInnerForce: character.internalForce,
        disorderHours: character.innerBreathDisorderHoursRemaining,
        disorderMaxHours: disorder.maxHours,
        maxPenaltyPct: disorder.maxInnerForcePenaltyPct,
      ),
      maxQi: maxQi,
      currentQi: openingQi,
      qiGainMultiplier: qiGainMultiplier,
      qiCostReductionPct: qiCostReductionPct,
      autoUltimate: false,
      speed: speed,
      criticalRate: criticalRate,
      evasionRate: evasionRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: totalEquipmentAttack,
      mainCultivationLayer: mainTechnique.cultivationLayer,
      availableSkills: skills,
      openingSkillCooldowns: const {},
      skillUses: {
        for (final skill in skills)
          skill.id: AttributeEffectPolicy(numbers.attributeEffects)
              .effectiveUsageCount(
                rawUses: mainTechnique.skillUsageCount.countOf(skill.id),
                enlightenment: character.attributes.enlightenment,
              ),
      },
      activeBuffs: const [],
      swordSongResonanceActive: swordSongResonanceActive,
      iconPath: character.portraitPath,
      attackPowerMultiplier: 1.0,
      outputMultiplier: outputMultiplier,
      isBoss: false,
      chargeSkillId: null,
      bossPhases: null,
      bossPhaseUnlockSkills: null,
      schoolDamageTakenMult: const {},
      lineageRole: character.lineageRole,
      forgingPiercePct: forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct,
      enemyDefId: null,
      guardianWardMult: null,
      guardianDefIds: const [],
      vulnerabilityMult: null,
      guardInterceptsInterrupt: false,
    );
  }
}
