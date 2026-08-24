import '../../core/domain/enums.dart';
import '../../data/defs/boss_phase_def.dart';
import '../../data/defs/skill_def.dart';
import '../../data/defs/stage_def.dart';
import '../../data/game_repository.dart';
import 'combatant_snapshot.dart';
import 'derived_stats.dart' show RealmUtils;
import 'enmity_target_id.dart';
import 'qi_cycle.dart';

/// EnemyDef → [CombatantSnapshot] 的深 Module。
///
/// Interface 只暴露「装配全部敌人」与「群战逐波装配」；周目缩放、境界推进、
/// 词条、Boss phase、guardian/vulnerability、真气和首通可读调节全部隐藏在
/// implementation 内。调用方决定 roster policy；Phase 0A 保留全部敌人，
/// 展示层容量不得污染此 seam。
final class EnemyCombatantSnapshotAssembler {
  const EnemyCombatantSnapshotAssembler._();

  /// StageDef 系里仅轻功/群战按周目推进境界段。
  static const Set<StageType> realmAdvanceStageTypes = {
    StageType.lightFoot,
    StageType.massBattle,
  };

  static List<CombatantSnapshot> assembleAll(
    List<EnemyDef> enemies, {
    int cycleIndex = 1,
    bool isTower = false,
    bool advanceRealmPerCycle = false,
    String? stageNpcId,
    bool readableFirstClearTuning = false,
  }) => [
    for (var i = 0; i < enemies.length; i++)
      _assembleOne(
        enemy: enemies[i],
        slotIndex: i,
        characterIdOverride: i == 0 && stageNpcId != null
            ? EnmityTargetId.targetIdForNpcId(stageNpcId)
            : null,
        cycleIndex: cycleIndex,
        isTower: isTower,
        advanceRealmPerCycle: advanceRealmPerCycle,
        readableFirstClearTuning: readableFirstClearTuning,
      ),
  ];

  /// 群战守城 per-wave 敌队生成。模板循环填充每波人数，id 从 -10000 递减。
  static List<List<CombatantSnapshot>> assembleWaves(
    StageDef stage, {
    int cycleIndex = 1,
  }) {
    final counts = stage.massBattleEnemyCounts;
    if (counts == null || counts.isEmpty) return const [];
    final templates = stage.enemyTeam;
    if (templates.isEmpty) return const [];
    var cursor = 0;
    return [
      for (final count in counts)
        [
          for (var j = 0; j < count; j++)
            _assembleOne(
              enemy: templates[j % templates.length],
              slotIndex: j,
              characterIdOverride: -10000 - (cursor++),
              cycleIndex: cycleIndex,
              isTower: false,
              advanceRealmPerCycle: realmAdvanceStageTypes.contains(
                stage.stageType,
              ),
            ),
        ],
    ];
  }

  /// P5.2 敌人内力对称化：境界内力 × scale，clamp 红线。
  static int resolveInternalForce(
    int realmInternalForceMax,
    double scale,
    int redLineCap,
  ) {
    final scaled = (realmInternalForceMax * scale).round();
    return scaled.clamp(0, redLineCap);
  }

  static CombatantSnapshot assembleOne({
    required EnemyDef enemy,
    required int slotIndex,
    int cycleIndex = 1,
    bool isTower = false,
    bool readableFirstClearTuning = false,
  }) => _assembleOne(
    enemy: enemy,
    slotIndex: slotIndex,
    cycleIndex: cycleIndex,
    isTower: isTower,
    readableFirstClearTuning: readableFirstClearTuning,
  );

  static CombatantSnapshot _assembleOne({
    required EnemyDef enemy,
    required int slotIndex,
    int? characterIdOverride,
    int cycleIndex = 1,
    bool isTower = false,
    bool advanceRealmPerCycle = false,
    bool readableFirstClearTuning = false,
  }) {
    final numbers = GameRepository.instance.numbers;
    final skills = enemy.skillIds
        .map((id) => GameRepository.instance.getSkill(id))
        .toList(growable: false);
    final enemyDefaults = numbers.combat.enemyDefaults;

    final advTiers = advanceRealmPerCycle
        ? numbers.cycleEvolution.realmAdvance.tiersFor(cycleIndex)
        : 0;
    final advancedIndex = enemy.realmTier.index + advTiers;
    final effTier = advancedIndex >= RealmTier.wuSheng.index
        ? RealmTier.wuSheng
        : RealmTier.values[advancedIndex];

    final realm = GameRepository.instance.getRealm(effTier, enemy.realmLayer);
    final redLineCap = numbers.combat.redLines.internalForceMax;
    final ce = numbers.cycleEvolution;
    final scale = 1.0 + ce.scalePerCycle * (cycleIndex - 1);
    final readable = numbers.combat.readableFirstClear;
    final readableHpMult = readableFirstClearTuning
        ? readable.hpMultiplierFor(isBoss: enemy.isBoss)
        : 1.0;
    final readableAttackMult = readableFirstClearTuning
        ? readable.enemyAttackMultiplier
        : 1.0;

    final scaledHp = (enemy.baseHp * scale * readableHpMult).toInt().clamp(
      0,
      numbers.combat.redLines.bossHpMax,
    );
    final scaledAttack = (enemy.baseAttack * scale * readableAttackMult)
        .toInt();
    final baseIf =
        (realm.internalForceMax * enemyDefaults.internalForceScale * scale)
            .round();
    final traits = ce.traitsFor(
      cycle: cycleIndex,
      isBoss: enemy.isBoss,
      isTower: isTower,
    );

    var defenseRate = RealmUtils.defenseRateOf(effTier);
    if (traits.contains('yuti')) {
      final yutiBonus = cycleIndex >= 3
          ? ce.traits.yuti.defenseRateBonusC3
          : ce.traits.yuti.defenseRateBonusC2;
      defenseRate = (defenseRate + yutiBonus).clamp(0.0, ce.defenseRateCap);
    }

    var resolvedIf = baseIf;
    if (traits.contains('zhenqi')) {
      resolvedIf = (baseIf * (1 + ce.traits.zhenqi.internalForcePct)).round();
    }
    resolvedIf = resolvedIf.clamp(0, redLineCap);

    final String? chargeSkillId;
    List<SkillDef> resolvedSkills = skills;
    if (traits.contains('shipo') && enemy.chargeSkillId == null) {
      final shipoSkillId = ce.traits.shipo.chargeSkillId;
      chargeSkillId = shipoSkillId;
      if (!skills.any((skill) => skill.id == shipoSkillId)) {
        resolvedSkills = [
          ...skills,
          GameRepository.instance.getSkill(shipoSkillId),
        ];
      }
    } else {
      chargeSkillId = enemy.chargeSkillId;
    }

    final activeBuffs = traits.isEmpty
        ? const <String>[]
        : (traits.map((trait) => 'cycle_$trait').toList()..sort());
    final List<BossPhaseDef>? bossPhases = enemy.bossPhasesForCycle(cycleIndex);
    final List<List<SkillDef>>? bossPhaseUnlockSkills = bossPhases == null
        ? null
        : [
            for (final phase in bossPhases)
              [
                for (final skillId in phase.unlockSkillIds)
                  GameRepository.instance.getSkill(skillId),
              ],
          ];

    final snapshot = CombatantSnapshot(
      characterId: characterIdOverride ?? -(slotIndex + 1),
      name: enemy.name,
      realmTier: effTier,
      realmLayer: enemy.realmLayer,
      school: enemy.school,
      maxHp: scaledHp,
      currentHp: scaledHp,
      internalForce: resolvedIf,
      maxQi: numbers.combat.qi.baseMax,
      currentQi: QiCycle.openingQi(
        maxQi: numbers.combat.qi.baseMax,
        openingQi:
            numbers.combat.qi.enemyOpeningQi +
            (enemy.isBoss
                ? (isTower
                      ? numbers.combat.qi.towerBossOpeningBonus
                      : numbers.combat.qi.bossOpeningBonus)
                : 0),
        openingCap: numbers.combat.qi.openingCap,
      ),
      qiGainMultiplier: 1,
      qiCostReductionPct: 0,
      autoUltimate: true,
      speed: enemy.baseSpeed,
      criticalRate: enemyDefaults.criticalRate,
      evasionRate: enemyDefaults.evasionRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: scaledAttack,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: resolvedSkills,
      openingSkillCooldowns: const {},
      skillUses: const {},
      activeBuffs: activeBuffs,
      swordSongResonanceActive: false,
      iconPath: enemy.iconPath,
      attackPowerMultiplier: 1,
      outputMultiplier: 1,
      isBoss: enemy.isBoss,
      chargeSkillId: chargeSkillId,
      bossPhases: bossPhases,
      bossPhaseUnlockSkills: bossPhaseUnlockSkills,
      schoolDamageTakenMult: enemy.schoolDamageTakenMult ?? const {},
      lineageRole: null,
      forgingPiercePct: 0,
      forgingLifestealPct: 0,
      enemyDefId: enemy.id,
      guardianWardMult: enemy.guardianWard?.damageTakenMult,
      guardianDefIds: enemy.guardianWard?.guardianIds ?? const [],
      vulnerabilityMult: enemy
          .vulnerabilityForCycle(cycleIndex)
          ?.outOfWindowDamageMult,
      guardInterceptsInterrupt: enemy.guardInterceptsInterrupt,
    );
    return readableFirstClearTuning
        ? _applyReadableFirstClearOpeningCooldownToOne(snapshot)
        : snapshot;
  }

  static CombatantSnapshot _applyReadableFirstClearOpeningCooldownToOne(
    CombatantSnapshot character,
  ) {
    final config = GameRepository.instance.numbers.combat.readableFirstClear;
    final tunedSkills = [
      for (final skill in character.availableSkills)
        _tuneReadableFirstClearSkill(skill, config.autoSkillPowerMultiplier),
    ];
    final tuned = character.copyWith(availableSkills: tunedSkills);
    final turns = config.openingAutoSkillCooldownTurns;
    if (turns <= 0) return tuned;
    final ticksPerAction = (1000 / character.speed).ceil();
    final cooldownTicks = turns * ticksPerAction + 1;
    final cooldowns = Map<String, int>.from(tuned.openingSkillCooldowns);
    for (final skill in tuned.availableSkills) {
      if (skill.requiresManualTrigger || skill.type == SkillType.normalAttack) {
        continue;
      }
      final existing = cooldowns[skill.id] ?? 0;
      if (existing < cooldownTicks) cooldowns[skill.id] = cooldownTicks;
    }
    return cooldowns.isEmpty
        ? tuned
        : tuned.copyWith(openingSkillCooldowns: Map.unmodifiable(cooldowns));
  }

  static SkillDef _tuneReadableFirstClearSkill(
    SkillDef skill,
    double autoSkillPowerMultiplier,
  ) {
    if (autoSkillPowerMultiplier >= 1 ||
        skill.requiresManualTrigger ||
        skill.type == SkillType.normalAttack) {
      return skill;
    }
    final tunedPower = (skill.powerMultiplier * autoSkillPowerMultiplier)
        .round()
        .clamp(1, skill.powerMultiplier)
        .toInt();
    return SkillDef(
      id: skill.id,
      name: skill.name,
      description: skill.description,
      type: skill.type,
      powerMultiplier: tunedPower,
      qiDelta: skill.qiDelta,
      cooldownSeconds: skill.cooldownSeconds,
      phase0aEnemyCooldownSeconds: skill.phase0aEnemyCooldownSeconds,
      cooldownTurns: skill.cooldownTurns,
      requiresManualTrigger: skill.requiresManualTrigger,
      parentTechniqueDefId: skill.parentTechniqueDefId,
      visualEffect: skill.visualEffect,
      tier: skill.tier,
      narrativeInsightId: skill.narrativeInsightId,
      imagePath: skill.imagePath,
      canInterrupt: skill.canInterrupt,
      aiUsePolicy: skill.aiUsePolicy,
      style: skill.style,
      source: skill.source,
      proficiency: skill.proficiency,
      targetType: skill.targetType,
      defenseBreakPct: skill.defenseBreakPct,
    );
  }
}
