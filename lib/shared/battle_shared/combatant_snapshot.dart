import '../../core/domain/enums.dart';
import '../../data/defs/boss_phase_def.dart';
import '../../data/defs/skill_def.dart';
import 'combatant_skill_loadout.dart';

/// Engine-neutral, pre-battle facts for one combatant.
final class CombatantSnapshot {
  CombatantSnapshot({
    required this.characterId,
    required this.name,
    required this.realmTier,
    required this.realmLayer,
    required this.school,
    required this.maxHp,
    required this.currentHp,
    required this.internalForce,
    required this.maxQi,
    required this.currentQi,
    required this.qiGainMultiplier,
    required this.qiCostReductionPct,
    required this.autoUltimate,
    required this.speed,
    required this.criticalRate,
    required this.evasionRate,
    required this.defenseRate,
    required this.totalEquipmentAttack,
    required this.mainCultivationLayer,
    this.weaponArchetype,
    this.skillLoadout = const CombatantSkillLoadout.empty(),
    required List<SkillDef> availableSkills,
    required Map<String, int> openingSkillCooldowns,
    required Map<String, int> skillUses,
    required List<String> activeBuffs,
    required this.swordSongResonanceActive,
    required this.iconPath,
    required this.attackPowerMultiplier,
    required this.outputMultiplier,
    required this.isBoss,
    required this.chargeSkillId,
    required List<BossPhaseDef>? bossPhases,
    required List<List<SkillDef>>? bossPhaseUnlockSkills,
    required Map<TechniqueSchool, double> schoolDamageTakenMult,
    required this.lineageRole,
    required this.forgingPiercePct,
    required this.forgingLifestealPct,
    required this.enemyDefId,
    required this.guardianWardMult,
    required List<String> guardianDefIds,
    required this.vulnerabilityMult,
    required this.guardInterceptsInterrupt,
  }) : availableSkills = List.unmodifiable(availableSkills),
       openingSkillCooldowns = Map.unmodifiable(openingSkillCooldowns),
       skillUses = Map.unmodifiable(skillUses),
       activeBuffs = List.unmodifiable(activeBuffs),
       bossPhases = bossPhases == null
           ? null
           : List<BossPhaseDef>.unmodifiable(
               bossPhases.map(
                 (phase) => BossPhaseDef(
                   hpThresholdPct: phase.hpThresholdPct,
                   unlockSkillIds: List<String>.unmodifiable(
                     phase.unlockSkillIds,
                   ),
                   aiMode: phase.aiMode,
                   onEnterMechanic: phase.onEnterMechanic,
                   titleKey: phase.titleKey,
                 ),
               ),
             ),
       bossPhaseUnlockSkills = bossPhaseUnlockSkills == null
           ? null
           : List<List<SkillDef>>.unmodifiable(
               bossPhaseUnlockSkills.map(
                 (skills) => List<SkillDef>.unmodifiable(<SkillDef>[...skills]),
               ),
             ),
       schoolDamageTakenMult = Map.unmodifiable(schoolDamageTakenMult),
       guardianDefIds = List.unmodifiable(guardianDefIds);

  final int characterId;
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final TechniqueSchool school;
  final int maxHp, currentHp, internalForce, maxQi, currentQi;
  final double qiGainMultiplier, qiCostReductionPct;
  final bool autoUltimate;
  final int speed;
  final double criticalRate, evasionRate, defenseRate;
  final int totalEquipmentAttack;
  final CultivationLayer mainCultivationLayer;
  final WeaponArchetype? weaponArchetype;
  final CombatantSkillLoadout skillLoadout;
  final List<SkillDef> availableSkills;
  final Map<String, int> openingSkillCooldowns, skillUses;
  final List<String> activeBuffs;
  final bool swordSongResonanceActive;
  final String? iconPath;
  final double attackPowerMultiplier, outputMultiplier;
  final bool isBoss;
  final String? chargeSkillId;
  final List<BossPhaseDef>? bossPhases;
  final List<List<SkillDef>>? bossPhaseUnlockSkills;
  final Map<TechniqueSchool, double> schoolDamageTakenMult;
  final LineageRole? lineageRole;
  final double forgingPiercePct, forgingLifestealPct;
  final String? enemyDefId;
  final double? guardianWardMult;
  final List<String> guardianDefIds;
  final double? vulnerabilityMult;
  final bool guardInterceptsInterrupt;

  CombatantSnapshot copyWith({
    int? maxHp,
    int? currentHp,
    int? internalForce,
    int? maxQi,
    int? currentQi,
    int? speed,
    double? criticalRate,
    double? evasionRate,
    double? defenseRate,
    int? totalEquipmentAttack,
    double? attackPowerMultiplier,
    CombatantSkillLoadout? skillLoadout,
    Map<String, int>? skillUses,
    List<SkillDef>? availableSkills,
    Map<String, int>? openingSkillCooldowns,
    List<String>? guardianDefIds,
  }) => CombatantSnapshot(
    characterId: characterId,
    name: name,
    realmTier: realmTier,
    realmLayer: realmLayer,
    school: school,
    maxHp: maxHp ?? this.maxHp,
    currentHp: currentHp ?? this.currentHp,
    internalForce: internalForce ?? this.internalForce,
    maxQi: maxQi ?? this.maxQi,
    currentQi: currentQi ?? this.currentQi,
    qiGainMultiplier: qiGainMultiplier,
    qiCostReductionPct: qiCostReductionPct,
    autoUltimate: autoUltimate,
    speed: speed ?? this.speed,
    criticalRate: criticalRate ?? this.criticalRate,
    evasionRate: evasionRate ?? this.evasionRate,
    defenseRate: defenseRate ?? this.defenseRate,
    totalEquipmentAttack: totalEquipmentAttack ?? this.totalEquipmentAttack,
    mainCultivationLayer: mainCultivationLayer,
    weaponArchetype: weaponArchetype,
    skillLoadout: skillLoadout ?? this.skillLoadout,
    availableSkills: availableSkills ?? this.availableSkills,
    openingSkillCooldowns: openingSkillCooldowns ?? this.openingSkillCooldowns,
    skillUses: skillUses ?? this.skillUses,
    activeBuffs: activeBuffs,
    swordSongResonanceActive: swordSongResonanceActive,
    iconPath: iconPath,
    attackPowerMultiplier: attackPowerMultiplier ?? this.attackPowerMultiplier,
    outputMultiplier: outputMultiplier,
    isBoss: isBoss,
    chargeSkillId: chargeSkillId,
    bossPhases: bossPhases,
    bossPhaseUnlockSkills: bossPhaseUnlockSkills,
    schoolDamageTakenMult: schoolDamageTakenMult,
    lineageRole: lineageRole,
    forgingPiercePct: forgingPiercePct,
    forgingLifestealPct: forgingLifestealPct,
    enemyDefId: enemyDefId,
    guardianWardMult: guardianWardMult,
    guardianDefIds: guardianDefIds ?? this.guardianDefIds,
    vulnerabilityMult: vulnerabilityMult,
    guardInterceptsInterrupt: guardInterceptsInterrupt,
  );
}
