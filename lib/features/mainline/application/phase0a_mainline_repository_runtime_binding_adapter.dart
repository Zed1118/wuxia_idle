import '../../../core/domain/enums.dart';
import '../../../data/defs/combat_encounter_def.dart';
import '../../../data/defs/combat_enemy_archetype_def.dart';
import '../../../data/defs/combat_runtime_binding_def.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combatant_skill_loadout.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/enemy_combatant_snapshot_assembler.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/arena_vector.dart';
import '../../battle/domain/phase0a/attack_token_director.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import '../../battle/domain/phase0a/posture.dart';
import 'phase0a_mainline_encounter_host.dart';

Phase0aMainlineEncounterRuntimeBindingBundle
loadPhase0aMainlineRuntimeBindingBundleFromRepository({
  required String stageId,
  required String encounterId,
  required int cycleIndex,
}) => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
  stageId: stageId,
  encounterId: encounterId,
  cycleIndex: cycleIndex,
);

/// Resolves the typed production catalog/runtime closure into the encounter
/// host's content-neutral runtime bundle.
///
/// This is the only production bridge between [GameRepository] and the
/// migrated Phase0A host. It never parses YAML and never falls back to the
/// legacy stage mapper when a migrated binding is incomplete.
Phase0aMainlineEncounterRuntimeBindingBundle
buildPhase0aMainlineRuntimeBindingBundleFromRepository({
  required String stageId,
  required String encounterId,
  required int cycleIndex,
  GameRepository? repository,
}) {
  if (cycleIndex < 1) {
    throw ArgumentError.value(cycleIndex, 'cycleIndex', 'must be positive');
  }
  final repo = repository ?? GameRepository.instance;
  final runtime = repo.combatRuntimeBindingForStage(stageId);
  if (runtime == null) {
    throw StateError('migrated runtime binding is missing for $stageId');
  }
  if (runtime.stageId != stageId || runtime.encounterId != encounterId) {
    throw StateError(
      'migrated runtime route mismatch: '
      '${runtime.stageId}/${runtime.encounterId} != $stageId/$encounterId',
    );
  }
  final encounter = repo.combatEncounterForStage(stageId);
  if (encounter == null || encounter.id != encounterId) {
    throw StateError('migrated combat encounter is missing for $stageId');
  }
  final stage = repo.getStage(stageId);
  if (stage.enemyTeam.length != 1) {
    throw StateError('$stageId must declare exactly one base enemy template');
  }
  final baseEnemy = stage.enemyTeam.single;
  if (runtime.baseEnemyId != baseEnemy.id) {
    throw StateError(
      '$stageId runtime base enemy ${runtime.baseEnemyId} '
      'does not match ${baseEnemy.id}',
    );
  }
  if (runtime.enemyBindings.length != encounter.spawnEntries.length) {
    throw StateError('$stageId runtime binding does not cover the encounter');
  }

  final commanderEntryIds = <String>{
    for (final clause in encounter.objectives.clauses)
      if (clause.primitive case CombatDefeatCommanderRef(:final commanderId))
        commanderId,
  };
  final actorBindings = <String, Phase0aEncounterActorRuntimeBinding>{};
  for (var ordinal = 0; ordinal < encounter.spawnEntries.length; ordinal++) {
    final entry = encounter.spawnEntries[ordinal];
    final baseSnapshot = EnemyCombatantSnapshotAssembler.assembleOne(
      enemy: baseEnemy,
      slotIndex: ordinal,
      cycleIndex: cycleIndex,
      isTower: false,
    );
    final binding = runtime.bindingForEntry(entry.entryId);
    if (binding == null) {
      throw StateError('$stageId runtime entry is missing: ${entry.entryId}');
    }
    if (binding.archetypeId != entry.archetypeId ||
        binding.roleId != entry.roleId ||
        binding.entranceId != entry.entranceId ||
        binding.positionId != entry.positionId ||
        binding.behavior.id != entry.behaviorId) {
      throw StateError('$stageId runtime entry mismatch: ${entry.entryId}');
    }
    final archetype = repo.combatArchetypeById(binding.archetypeId);
    final variant = archetype?.variantByRole(binding.roleId);
    if (variant == null) {
      throw StateError(
        '$stageId runtime role is unresolved: '
        '${binding.archetypeId}/${binding.roleId}',
      );
    }
    if (variant.attackSetId != binding.attackSet.id) {
      throw StateError(
        '$stageId runtime attack set mismatch: ${entry.entryId}',
      );
    }
    final visualIds = variant.visualVariantIds;
    if (!visualIds.contains(binding.visualVariant.id)) {
      throw StateError(
        '$stageId runtime visual variant mismatch: ${entry.entryId}',
      );
    }
    _requireMatchingTokenPolicy(variant, binding.behavior);

    final preserveBaseBossIdentity =
        baseSnapshot.isBoss && commanderEntryIds.contains(entry.entryId);
    final snapshot = _applyVariant(
      base: baseSnapshot,
      variant: variant,
      skills: binding.attackSet.skills,
      repository: repo,
      visualAssetPath: binding.visualVariant.assetPath,
      preserveBaseBossIdentity: preserveBaseBossIdentity,
    );
    final basicSkill = _requiredBasicSkill(
      snapshot.availableSkills,
      stageId: stageId,
      entryId: entry.entryId,
    );
    final enemySkills = preserveBaseBossIdentity
        ? Phase0aStageContentMapper.preResolveEnemySkillBindings(
            arena: repo.numbers.phase0aArena,
            snapshot: snapshot,
          )
        : _enemySkillBindings(
            snapshot.availableSkills,
            repository: repo,
            stageId: stageId,
            entryId: entry.entryId,
          );
    final token = _tokenBinding(variant, binding.behavior);
    final position = ArenaVector(binding.position.x, binding.position.y);
    final chargeCast = preserveBaseBossIdentity
        ? Phase0aStageContentMapper.preResolveTopLevelChargeCast(
            snapshot: snapshot,
            arena: repo.numbers.phase0aArena,
            chargeTicks: repo.numbers.combat.bossCharge.defaultChargeTicks,
          )
        : null;
    final phaseChargeCasts = preserveBaseBossIdentity
        ? Phase0aStageContentMapper.preResolvePhaseChargeCasts(
            snapshot: snapshot,
            arena: repo.numbers.phase0aArena,
            chargeTicks: repo.numbers.combat.bossCharge.defaultChargeTicks,
          )
        : const <Phase0aChargeCast?>[];
    final unlockedSkillIds = preserveBaseBossIdentity
        ? List<String>.unmodifiable(
            snapshot.bossPhases == null || snapshot.bossPhases!.isEmpty
                ? const <String>[]
                : snapshot.bossPhases!.first.unlockSkillIds,
          )
        : List<String>.unmodifiable(enemySkills.map((item) => item.skill.id));
    final visualAssetPath = preserveBaseBossIdentity
        ? snapshot.iconPath ?? binding.visualVariant.assetPath
        : binding.visualVariant.assetPath;

    actorBindings[entry.entryId] = Phase0aEncounterActorRuntimeBinding(
      createActor: (runtimeEnemyId) => Phase0aActor(
        id: runtimeEnemyId,
        side: Phase0aSide.enemy,
        position: position,
        facing: const ArenaVector(-1, 0),
        maxHealth: snapshot.maxHp,
        currentHealth: snapshot.currentHp,
        moveSpeed: snapshot.speed.toDouble(),
        qiCurrent: snapshot.currentQi,
        qiMax: snapshot.maxQi,
        attackCooldownRemaining:
            repo.numbers.phase0aArena.enemyInitialAttackCooldown,
        defeatKind: snapshot.isBoss
            ? Phase0aDefeatKind.elite
            : Phase0aDefeatKind.normal,
        isBoss: snapshot.isBoss,
        autoUltimate: snapshot.autoUltimate,
        bossPhases: snapshot.bossPhases,
        unlockedEnemySkillIds: unlockedSkillIds,
        enemySkillCooldowns: _openingCooldownSeconds(
          snapshot,
          repo.numbers.phase0aArena.enemyAttackCooldownSeconds,
        ),
        chargeCast: chargeCast,
        phaseChargeCasts: phaseChargeCasts,
        staggerTicksTotal: preserveBaseBossIdentity
            ? repo.numbers.combat.bossCharge.defaultStaggerTicks
            : 0,
        guardianDefIds: snapshot.guardianDefIds,
        guardianWardMult: snapshot.guardianWardMult,
        guardInterceptsInterrupt: snapshot.guardInterceptsInterrupt,
        vulnerabilityMult: snapshot.vulnerabilityMult,
        posture: PostureState.initial(
          PostureConfig(
            capacity: repo.numbers.combat.posture.capacity,
            vulnerabilityTicks: repo.numbers.combat.posture.vulnerabilityTicks,
            recoveryPolicy:
                repo.numbers.combat.posture.recoveryPolicy ==
                    PostureRecoveryPolicyConfig.reset
                ? PostureRecoveryPolicy.reset
                : PostureRecoveryPolicy.recover,
            postVulnerabilityAccumulated:
                repo.numbers.combat.posture.postVulnerabilityAccumulated,
            bossControlConversionFactor:
                repo.numbers.combat.posture.bossConversionFactor,
          ),
        ),
      ),
      combatant: snapshot,
      token: token,
      enemySkillBindings: enemySkills,
      basicQiDelta: basicSkill.qiDelta,
      basicPowerMultiplier: basicSkill.powerMultiplier,
      entrance: binding.entranceId,
      behaviorAiProfile: binding.behavior.aiProfile.id,
      behaviorProfile: _behaviorProfile(binding.behavior.aiProfile),
      attackSet: binding.attackSet.id,
      visualVariant: binding.visualVariant.id,
      visualAssetPath: visualAssetPath,
    );
  }

  final fixedDelta = repo.numbers.phase0aArena.fixedDeltaSeconds;
  final tickDuration = Duration(
    microseconds: (fixedDelta * Duration.microsecondsPerSecond).round(),
  );
  if (tickDuration <= Duration.zero) {
    throw StateError('Phase0A fixed delta must resolve to a positive duration');
  }
  return Phase0aMainlineEncounterRuntimeBindingBundle(
    stageId: stageId,
    encounterId: encounterId,
    tickDuration: tickDuration,
    actorBindingsByEntryId: Map.unmodifiable(actorBindings),
  );
}

Phase0aEnemyBehaviorProfile _behaviorProfile(CombatRuntimeAiProfile profile) {
  final movementPolicy = switch (profile.movementPolicy) {
    CombatRuntimeMovementPolicy.directAdvance =>
      Phase0aEnemyMovementPolicy.directAdvance,
    CombatRuntimeMovementPolicy.holdDistance =>
      Phase0aEnemyMovementPolicy.holdDistance,
    CombatRuntimeMovementPolicy.lateralFlank =>
      Phase0aEnemyMovementPolicy.lateralFlank,
    CombatRuntimeMovementPolicy.guardedPosition =>
      Phase0aEnemyMovementPolicy.guardedPosition,
  };
  final attackPolicy = switch (profile.attackPolicy) {
    CombatRuntimeAttackPolicy.closeRange => Phase0aEnemyAttackPolicy.closeRange,
    CombatRuntimeAttackPolicy.rangedPressure =>
      Phase0aEnemyAttackPolicy.rangedPressure,
    CombatRuntimeAttackPolicy.chargeAndReposition =>
      Phase0aEnemyAttackPolicy.chargeAndReposition,
    CombatRuntimeAttackPolicy.supportPulse =>
      Phase0aEnemyAttackPolicy.supportPulse,
  };
  return Phase0aEnemyBehaviorProfile(
    id: profile.id,
    movementPolicy: movementPolicy,
    attackPolicy: attackPolicy,
  );
}

CombatantSnapshot _applyVariant({
  required CombatantSnapshot base,
  required CombatArchetypeVariant variant,
  required List<SkillDef> skills,
  required GameRepository repository,
  required String visualAssetPath,
  required bool preserveBaseBossIdentity,
}) {
  final resolvedSkills = preserveBaseBossIdentity
      ? base.availableSkills
      : skills;
  final basic = _requiredBasicSkill(
    resolvedSkills,
    stageId: 'runtime',
    entryId: variant.roleId,
  );
  final maxHp = (base.maxHp * variant.hpMultiplier)
      .round()
      .clamp(1, repository.numbers.combat.redLines.bossHpMax)
      .toInt();
  final attack = (base.totalEquipmentAttack * variant.attackMultiplier).round();
  final defense = (base.defenseRate * variant.defenseMultiplier)
      .clamp(0.0, repository.numbers.cycleEvolution.defenseRateCap)
      .toDouble();
  final speed = (base.speed * variant.speedMultiplier).round();
  final stripBossIdentity = base.isBoss && !preserveBaseBossIdentity;
  return CombatantSnapshot(
    characterId: base.characterId,
    name: preserveBaseBossIdentity ? base.name : variant.displayName,
    realmTier: base.realmTier,
    realmLayer: base.realmLayer,
    school: base.school,
    maxHp: maxHp,
    currentHp: maxHp,
    internalForce: base.internalForce,
    maxQi: base.maxQi,
    currentQi: base.currentQi,
    qiGainMultiplier: base.qiGainMultiplier,
    qiCostReductionPct: base.qiCostReductionPct,
    autoUltimate: preserveBaseBossIdentity && base.autoUltimate,
    speed: speed,
    criticalRate: base.criticalRate,
    evasionRate: base.evasionRate,
    defenseRate: defense,
    totalEquipmentAttack: attack,
    mainCultivationLayer: base.mainCultivationLayer,
    skillLoadout: preserveBaseBossIdentity
        ? base.skillLoadout
        : CombatantSkillLoadout(basicAttack: basic),
    availableSkills: List<SkillDef>.unmodifiable(resolvedSkills),
    openingSkillCooldowns: preserveBaseBossIdentity
        ? base.openingSkillCooldowns
        : const {},
    skillUses: preserveBaseBossIdentity ? base.skillUses : const {},
    activeBuffs: preserveBaseBossIdentity ? base.activeBuffs : const [],
    swordSongResonanceActive:
        preserveBaseBossIdentity && base.swordSongResonanceActive,
    iconPath: preserveBaseBossIdentity ? base.iconPath : visualAssetPath,
    attackPowerMultiplier: base.attackPowerMultiplier,
    outputMultiplier: base.outputMultiplier,
    isBoss: preserveBaseBossIdentity,
    chargeSkillId: preserveBaseBossIdentity ? base.chargeSkillId : null,
    bossPhases: preserveBaseBossIdentity ? base.bossPhases : null,
    bossPhaseUnlockSkills: preserveBaseBossIdentity
        ? base.bossPhaseUnlockSkills
        : null,
    schoolDamageTakenMult: base.schoolDamageTakenMult,
    lineageRole: stripBossIdentity ? null : base.lineageRole,
    forgingPiercePct: base.forgingPiercePct,
    forgingLifestealPct: base.forgingLifestealPct,
    enemyDefId: stripBossIdentity ? null : base.enemyDefId,
    guardianWardMult: preserveBaseBossIdentity ? base.guardianWardMult : null,
    guardianDefIds: preserveBaseBossIdentity ? base.guardianDefIds : const [],
    vulnerabilityMult: preserveBaseBossIdentity ? base.vulnerabilityMult : null,
    guardInterceptsInterrupt:
        preserveBaseBossIdentity && base.guardInterceptsInterrupt,
  );
}

SkillDef _requiredBasicSkill(
  List<SkillDef> skills, {
  required String stageId,
  required String entryId,
}) {
  final normalAttacks = skills
      .where((skill) => skill.type == SkillType.normalAttack)
      .toList(growable: false);
  if (normalAttacks.length != 1) {
    throw StateError(
      '$stageId/$entryId must resolve exactly one normal attack',
    );
  }
  return normalAttacks.single;
}

List<Phase0aEnemySkillBinding> _enemySkillBindings(
  List<SkillDef> skills, {
  required GameRepository repository,
  required String stageId,
  required String entryId,
}) {
  final arena = repository.numbers.phase0aArena;
  final bindings = <Phase0aEnemySkillBinding>[];
  for (final skill in skills) {
    if (skill.type == SkillType.normalAttack) continue;
    if (skill.type == SkillType.jointSkill || skill.requiresManualTrigger) {
      throw StateError(
        '$stageId/$entryId has unsupported enemy skill ${skill.id}',
      );
    }
    final cooldown = skill.phase0aEnemyCooldownSeconds;
    if (cooldown == null) {
      throw StateError(
        '$stageId/$entryId enemy skill ${skill.id} has no Phase0A cooldown',
      );
    }
    bindings.add(
      Phase0aEnemySkillBinding(
        skill: skill,
        attackRange: arena.enemyAttackRange,
        halfArcRadians: arena.enemyAttackHalfArcRadians,
        effectRadius: arena.enemyAttackRange,
        cooldownSeconds: cooldown,
      ),
    );
  }
  return List.unmodifiable(bindings);
}

Map<String, double> _openingCooldownSeconds(
  CombatantSnapshot snapshot,
  double actionCooldownSeconds,
) => Map.unmodifiable({
  for (final entry in snapshot.openingSkillCooldowns.entries)
    if (entry.value > 0) entry.key: entry.value * actionCooldownSeconds,
});

Phase0aEncounterTokenBinding _tokenBinding(
  CombatArchetypeVariant variant,
  CombatRuntimeBehaviorBinding behavior,
) {
  final tags = variant.attackTagIds.toList()..sort();
  return Phase0aEncounterTokenBinding(
    kind: _attackTokenKind(behavior.tokenPolicy),
    priority: behavior.priority,
    tag: tags.first,
    visibility: behavior.isOffscreen ? 'off_screen' : 'on_screen',
    isOffscreen: behavior.isOffscreen,
    isHighImpact: behavior.isHighImpact,
    isUnblockableArea: behavior.isUnblockableArea,
    spawnGraceTicksRemaining: behavior.spawnGraceTicksRemaining,
    telegraphReady: behavior.telegraphReady,
  );
}

void _requireMatchingTokenPolicy(
  CombatArchetypeVariant variant,
  CombatRuntimeBehaviorBinding behavior,
) {
  final roleKind = switch (variant.attackTokenKind) {
    CombatAttackTokenKind.melee => CombatRuntimeTokenPolicy.melee,
    CombatAttackTokenKind.ranged => CombatRuntimeTokenPolicy.ranged,
    CombatAttackTokenKind.charge => CombatRuntimeTokenPolicy.charge,
    CombatAttackTokenKind.support => CombatRuntimeTokenPolicy.support,
  };
  if (roleKind != behavior.tokenPolicy) {
    throw StateError('${variant.roleId} token policy mismatch');
  }
}

AttackTokenKind _attackTokenKind(CombatRuntimeTokenPolicy policy) =>
    switch (policy) {
      CombatRuntimeTokenPolicy.melee => AttackTokenKind.melee,
      CombatRuntimeTokenPolicy.ranged => AttackTokenKind.ranged,
      CombatRuntimeTokenPolicy.charge => AttackTokenKind.charge,
      CombatRuntimeTokenPolicy.support => AttackTokenKind.support,
    };
