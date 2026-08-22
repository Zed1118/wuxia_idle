import '../../../data/defs/inner_demon_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../shared/strings.dart';
import '../domain/battle_state.dart';

/// Legacy 3v3 mirror-team builder retained only until the Route C delete gate.
/// Production inner-demon combat is mapped directly to Phase 0A snapshots.
class LegacyInnerDemonMirrorBuilder {
  LegacyInnerDemonMirrorBuilder._();

  static List<BattleCharacter> build({
    required List<BattleCharacter> playerTeam,
    required String stageId,
    required InnerDemonDef innerDemonDef,
    SkillDef? mirrorChargeSkill,
  }) {
    final buff = innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0;
    final caps = innerDemonDef.mirrorCaps;
    final vuln = innerDemonDef.mirrorVulnerabilityPerStage[stageId];
    final injectMechanic = vuln != null && mirrorChargeSkill != null;

    return [
      for (var i = 0; i < playerTeam.length && i < 3; i++)
        _mirror(
          playerTeam[i],
          buff: buff,
          caps: caps,
          slotIndex: i,
          vulnerabilityMult: injectMechanic ? vuln.outOfWindowDamageMult : null,
          chargeSkill: injectMechanic ? mirrorChargeSkill : null,
          attackMultiplier: injectMechanic
              ? innerDemonDef.mechanicMirrorAttackMultiplier
              : 1 + buff,
          outputMultiplier: injectMechanic
              ? innerDemonDef.mechanicMirrorOutputMultiplierPerStage[stageId] ??
                    1.0
              : 1.0,
          startActionPoint: injectMechanic
              ? innerDemonDef.mechanicMirrorStartActionPoint
              : 0,
        ),
    ];
  }

  static BattleCharacter _mirror(
    BattleCharacter src, {
    required double buff,
    required InnerDemonMirrorCaps caps,
    required int slotIndex,
    double? vulnerabilityMult,
    SkillDef? chargeSkill,
    required double attackMultiplier,
    required double outputMultiplier,
    required int startActionPoint,
  }) {
    final maxHp = (src.maxHp * (1 + buff)).round().clamp(1, caps.hpMax);
    final internalForce = (src.internalForce * (1 + buff)).round().clamp(
      1,
      caps.internalForceMax,
    );
    final attack = (src.totalEquipmentAttack * attackMultiplier).round().clamp(
      0,
      caps.attackPowerMax,
    );
    final skills =
        chargeSkill != null &&
            !src.availableSkills.any((s) => s.id == chargeSkill.id)
        ? [...src.availableSkills, chargeSkill]
        : src.availableSkills;

    return src.copyWith(
      characterId: -(slotIndex + 1),
      name: UiStrings.innerDemonMirrorName(src.name),
      maxHp: maxHp,
      currentHp: maxHp,
      internalForce: internalForce,
      totalEquipmentAttack: attack,
      outputMultiplier: src.outputMultiplier * outputMultiplier,
      availableSkills: skills,
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: startActionPoint,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
      internalInjury: null,
      iconPath: null,
      vulnerabilityMult: vulnerabilityMult,
      chargeSkillId: chargeSkill?.id,
    );
  }
}
