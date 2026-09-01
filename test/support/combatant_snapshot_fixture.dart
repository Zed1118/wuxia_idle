import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

/// Engine-neutral combat fixture for Phase 0A and shared settlement tests.
///
/// Keep this builder independent from the retired team-battle runtime so tests
/// that protect the production ARPG path survive its atomic deletion.
CombatantSnapshot testCombatantSnapshot({
  int characterId = 1,
  String name = 'test combatant',
  RealmTier realmTier = RealmTier.xueTu,
  RealmLayer realmLayer = RealmLayer.ruMen,
  TechniqueSchool school = TechniqueSchool.gangMeng,
  int maxHp = 1000,
  int? currentHp,
  int internalForce = 600,
  int maxQi = 100,
  int? currentQi,
  double qiGainMultiplier = 1,
  double qiCostReductionPct = 0,
  bool autoUltimate = false,
  int speed = 100,
  double criticalRate = 0,
  double evasionRate = 0,
  double defenseRate = 0.05,
  int totalEquipmentAttack = 130,
  CultivationLayer mainCultivationLayer = CultivationLayer.chuKui,
  WeaponArchetype? weaponArchetype,
  CombatantSkillLoadout skillLoadout = const CombatantSkillLoadout.empty(),
  bool includeProductionBasicAttack = false,
  List<SkillDef> availableSkills = const [],
  Map<String, int> openingSkillCooldowns = const {},
  Map<String, int> skillUses = const {},
  List<String> activeBuffs = const [],
  bool swordSongResonanceActive = false,
  String? iconPath,
  double attackPowerMultiplier = 1,
  double outputMultiplier = 1,
  bool isBoss = false,
  String? chargeSkillId,
  List<BossPhaseDef>? bossPhases,
  List<List<SkillDef>>? bossPhaseUnlockSkills,
  Map<TechniqueSchool, double> schoolDamageTakenMult = const {},
  LineageRole? lineageRole,
  double forgingPiercePct = 0,
  double forgingLifestealPct = 0,
  String? enemyDefId,
  double? guardianWardMult,
  List<String> guardianDefIds = const [],
  double? vulnerabilityMult,
  bool guardInterceptsInterrupt = false,
}) {
  if (includeProductionBasicAttack && skillLoadout.basicAttack != null) {
    throw ArgumentError(
      'includeProductionBasicAttack cannot override an explicit basicAttack',
    );
  }
  final resolvedLoadout = includeProductionBasicAttack
      ? CombatantSkillLoadout(
          basicAttack: GameRepository.instance.getSkill(switch (school) {
            TechniqueSchool.gangMeng => 'skill_gangmeng_jichu_basic',
            TechniqueSchool.lingQiao => 'skill_lingqiao_jichu_basic',
            TechniqueSchool.yinRou => 'skill_yinrou_jichu_basic',
          }),
          main1: skillLoadout.main1,
          main2: skillLoadout.main2,
          assist: skillLoadout.assist,
          resonance: skillLoadout.resonance,
          ultimate: skillLoadout.ultimate,
          encounter: skillLoadout.encounter,
          key: skillLoadout.key,
        )
      : skillLoadout;
  return CombatantSnapshot(
    characterId: characterId,
    name: name,
    realmTier: realmTier,
    realmLayer: realmLayer,
    school: school,
    maxHp: maxHp,
    currentHp: currentHp ?? maxHp,
    internalForce: internalForce,
    maxQi: maxQi,
    currentQi: currentQi ?? maxQi,
    qiGainMultiplier: qiGainMultiplier,
    qiCostReductionPct: qiCostReductionPct,
    autoUltimate: autoUltimate,
    speed: speed,
    criticalRate: criticalRate,
    evasionRate: evasionRate,
    defenseRate: defenseRate,
    totalEquipmentAttack: totalEquipmentAttack,
    mainCultivationLayer: mainCultivationLayer,
    weaponArchetype: weaponArchetype,
    skillLoadout: resolvedLoadout,
    availableSkills: availableSkills,
    openingSkillCooldowns: openingSkillCooldowns,
    skillUses: skillUses,
    activeBuffs: activeBuffs,
    swordSongResonanceActive: swordSongResonanceActive,
    iconPath: iconPath,
    attackPowerMultiplier: attackPowerMultiplier,
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
    guardianDefIds: guardianDefIds,
    vulnerabilityMult: vulnerabilityMult,
    guardInterceptsInterrupt: guardInterceptsInterrupt,
  );
}
