import '../../../../core/domain/enums.dart';
import '../../../../data/defs/boss_phase_def.dart';
import '../../../../data/defs/light_foot_def.dart';
import '../../../../data/defs/mass_battle_def.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../data/defs/stage_def.dart';
import '../../../../data/defs/stage_win_condition.dart';
import '../../../../data/defs/tower_floor_def.dart';
import '../../../../data/game_repository.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../../shared/battle_shared/combatant_skill_loadout.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/basic_attack_chain.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/defense_resolution.dart';
import '../../domain/phase0a/phase0a_defense_tuning.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../../domain/phase0a/posture.dart';
import '../../../../shared/battle_shared/enemy_combatant_snapshot_assembler.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_basic_attack_geometry_mapper.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_skill_binding.dart';
import 'phase0a_numeric_skill_binding.dart';
import 'phase0a_defense_tuning_mapper.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_tactical_skill_binding.dart';
import 'phase0a_wave_battle_flow.dart';

/// Phase 1 纵切切片 1(spec 2026-08-19 · P1=α 主线 Ch1 · D1=α 机械映射):
/// 把生产关卡内容(StageDef)装配成 [Phase0aProductionFlowAssembler.assemble]
/// 的全套入参。
///
/// 零口径复制原则:
/// - 敌人 neutral snapshot 直接复用 [EnemyCombatantSnapshotAssembler](旧战斗
///   同一口径:境界内力查表/红线 clamp/周目 scale=1 零回归),不重算任何数值;
/// - 空间/能量/动作维度(stages.yaml 没有的 0A 特有轴)全部取
///   [NumbersConfig.phase0aArena] 段,不硬编码;
/// - 敌队→波次为 D1 机械映射:StageDef.enemyTeam 整队一波(主线关 ≤3 敌,
///   无首发/后备之分;远征/塔的续波语义绑内容迁移后续切片)。
final class Phase0aStageMapping {
  const Phase0aStageMapping({
    required this.initialState,
    required this.waves,
    required this.combatants,
    required this.moveBindings,
    required this.playerAdapter,
    required this.enemyAiAdapter,
    this.waveTransitionPolicy,
  });

  final Phase0aArenaState initialState;
  final List<Phase0aWave> waves;
  final List<Phase0aCombatantInput> combatants;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aWaveTransitionPolicy? waveTransitionPolicy;
}

/// Player-only production inputs used before mainline migration routing.
/// This intentionally does not construct legacy waves or enemy payloads.
final class Phase0aPlayerRuntimeMapping {
  const Phase0aPlayerRuntimeMapping({
    required this.snapshot,
    required this.initialPlayer,
    required this.skillSlots,
    required this.moveBindings,
    required this.playerAdapter,
    required this.defenseTuning,
  });

  final Phase0aActor initialPlayer;
  final CombatantSnapshot snapshot;
  final List<Phase0aSkillSlot> skillSlots;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aDefenseTuning? defenseTuning;
}

final class Phase0aStageContentMapper {
  const Phase0aStageContentMapper._();

  /// Builds only the player-side adapter/bindings shared by migrated and
  /// legacy mainline routes. No enemy snapshot, wave or legacy payload is
  /// constructed here.
  static Phase0aPlayerRuntimeMapping mapPlayerOnly({
    required String contentId,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
  }) {
    final arena = numbers.phase0aArena;
    if (arena.isEmpty) {
      throw StateError('Phase0a player mapping $contentId lacks arena config');
    }
    final playerBasicSkill = playerSnapshot.skillLoadout.basicAttack;
    if (playerBasicSkill == null) {
      throw StateError('Phase0a player mapping lacks a real basic skill');
    }
    final numeric = _numericSkillBindings(playerSnapshot, arena);
    final tactical = _tacticalSkillBindings(arena);
    final defenseTuning = Phase0aDefenseTuningMapper.fromNumbers(numbers);
    final player = Phase0aActor(
      id: playerId,
      side: Phase0aSide.player,
      position: ArenaVector(arena.arenaMinX * 0.5, 0),
      facing: const ArenaVector(1, 0),
      maxHealth: playerSnapshot.maxHp,
      currentHealth: playerSnapshot.currentHp,
      moveSpeed: arena.playerMoveSpeed,
      qiCurrent: playerSnapshot.currentQi,
      qiMax: playerSnapshot.maxQi,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );
    return Phase0aPlayerRuntimeMapping(
      snapshot: playerSnapshot,
      initialPlayer: player,
      skillSlots: _skillSlots(numeric, tactical, playerSnapshot.currentQi),
      moveBindings: _moveBindings(playerBasicSkill, numeric, tactical),
      defenseTuning: defenseTuning,
      playerAdapter: _playerAdapter(
        arena: arena,
        playerId: playerId,
        numericSkillBindings: numeric,
        tacticalSkillBindings: tactical,
        attackQiDelta: playerBasicSkill.qiDelta,
        attackPowerMultiplier: playerBasicSkill.powerMultiplier,
        defenseTuning: defenseTuning,
      ),
    );
  }

  /// 装配一关的 0A 战斗输入。[playerSnapshot] 由调用方构造(生产侧走
  /// [PlayerCombatantSnapshotAssembler] Isar 路径,纵切测试显式构造)。
  ///
  /// fail-fast:`numbers.phase0aArena` 缺段(isEmpty)拒绝装配——纵切不得
  /// 静默用零参数竞技场冒充配置;`stage.enemyTeam` 为空拒绝(剧情空关
  /// 不走战斗装配)。
  static Phase0aStageMapping map({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
    int? cycleIndex,
  }) => stage.stageType == StageType.mainline && numbers.mainlineWave.isEnabled
      ? mapMainline(
          stage: stage,
          playerSnapshot: playerSnapshot,
          numbers: numbers,
          playerId: playerId,
          cycleIndex: cycleIndex,
        )
      : _mapContent(
          contentId: stage.id,
          enemyTeam: stage.enemyTeam,
          isTower: false,
          playerSnapshot: playerSnapshot,
          numbers: numbers,
          playerId: playerId,
          cycleIndex: cycleIndex ?? 1,
          advanceRealmPerCycle: false,
          winCondition: _mapWinCondition(stage.winCondition),
        );

  /// 主线生产波次：普通关只生成小怪波；Boss 关把原始 Boss 快照完整放到
  /// 独立终波，前置波只使用显式比例派生的无机制小怪。
  static Phase0aStageMapping mapMainline({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
    int? cycleIndex,
  }) {
    if (stage.stageType != StageType.mainline) {
      throw ArgumentError.value(stage.id, 'stage', 'must be mainline');
    }
    if (stage.enemyTeam.length != 1) {
      throw ArgumentError.value(
        stage.enemyTeam,
        'stage.enemyTeam',
        '主线群怪 profile 要求恰有 1 个原始敌人',
      );
    }
    final cycle = cycleIndex ?? 1;
    final profile = stage.isBossStage
        ? numbers.mainlineWave.boss
        : numbers.mainlineWave.ordinary;
    final source = EnemyCombatantSnapshotAssembler.assembleAll(
      stage.enemyTeam,
      cycleIndex: cycle,
      isTower: false,
      advanceRealmPerCycle: false,
      stageNpcId: stage.npcId,
    ).single;
    final waves = <List<CombatantSnapshot>>[];
    final moveSpeedOverrides = <double?>[];
    var characterId = -20000;
    for (final count in profile.waveEnemyCounts) {
      waves.add([
        for (var slot = 0; slot < count; slot++)
          _asMainlineMob(
            source: source,
            characterId: characterId--,
            hpMultiplier: profile.hpMultiplier,
            attackMultiplier: profile.attackMultiplier,
            outputMultiplier: profile.outputMultiplier,
            speedMultiplier: profile.speedMultiplier,
          ),
      ]);
      moveSpeedOverrides.addAll([
        for (var slot = 0; slot < count; slot++)
          (source.speed * profile.speedMultiplier).toDouble(),
      ]);
    }
    if (stage.isBossStage) {
      if (!source.isBoss) {
        throw StateError('主线 Boss ${stage.id} 原始敌人必须标记 isBoss=true');
      }
      if (profile.bossFinalEnemyCount != 1) {
        throw StateError('主线 Boss ${stage.id} 缺少唯一终波主敌人配置');
      }
      // 终波直接持有原快照，包含 charge/phase/vulnerability/guardian。
      waves.add([source]);
      moveSpeedOverrides.add(null);
    }
    final intermission = numbers.mainlineWave.intermission;
    return _mapContent(
      contentId: stage.id,
      enemyTeam: stage.enemyTeam,
      isTower: false,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
      playerId: playerId,
      cycleIndex: cycle,
      advanceRealmPerCycle: false,
      winCondition: _mapWinCondition(stage.winCondition),
      enemySnapshotWavesOverride: waves,
      enemyMoveSpeedOverrides: moveSpeedOverrides,
      waveTransitionPolicy: Phase0aWaveTransitionPolicy(
        healPlayerToFull: !intermission.preserveHp,
        qiRecoveryPct: intermission.aliveIfRecoveryPct,
        resetAttackCooldown: intermission.resetActionPoint,
        resetSkillCooldowns: !intermission.preserveCooldowns,
        intermissionSeconds: intermission.intermissionSeconds,
      ),
    );
  }

  static CombatantSnapshot _asMainlineMob({
    required CombatantSnapshot source,
    required int characterId,
    required double hpMultiplier,
    required double attackMultiplier,
    required double outputMultiplier,
    required double speedMultiplier,
  }) {
    final mobHp = (source.maxHp * hpMultiplier).round().clamp(1, source.maxHp);
    final mobOutput = source.outputMultiplier * outputMultiplier;
    return CombatantSnapshot(
      characterId: characterId,
      name: source.name,
      realmTier: source.realmTier,
      realmLayer: source.realmLayer,
      school: source.school,
      maxHp: mobHp,
      currentHp: mobHp,
      internalForce: source.internalForce,
      maxQi: source.maxQi,
      currentQi: source.currentQi,
      qiGainMultiplier: source.qiGainMultiplier,
      qiCostReductionPct: source.qiCostReductionPct,
      autoUltimate: source.autoUltimate,
      speed: (source.speed * speedMultiplier).round().clamp(1, source.speed),
      criticalRate: source.criticalRate,
      evasionRate: source.evasionRate,
      defenseRate: source.defenseRate,
      totalEquipmentAttack: (source.totalEquipmentAttack * attackMultiplier)
          .round()
          .clamp(0, source.totalEquipmentAttack),
      mainCultivationLayer: source.mainCultivationLayer,
      skillLoadout: source.skillLoadout,
      availableSkills: source.availableSkills,
      openingSkillCooldowns: const {},
      skillUses: const {},
      activeBuffs: const [],
      swordSongResonanceActive: false,
      iconPath: source.iconPath,
      attackPowerMultiplier: source.attackPowerMultiplier,
      outputMultiplier: mobOutput,
      isBoss: false,
      chargeSkillId: null,
      bossPhases: null,
      bossPhaseUnlockSkills: null,
      schoolDamageTakenMult: source.schoolDamageTakenMult,
      lineageRole: null,
      forgingPiercePct: 0,
      forgingLifestealPct: 0,
      enemyDefId: source.enemyDefId,
      guardianWardMult: null,
      guardianDefIds: const [],
      vulnerabilityMult: null,
      guardInterceptsInterrupt: false,
    );
  }

  /// 心魔关以单主角开战快照生成同源镜像，不消费 YAML 的空 enemyTeam。
  /// 强化、红线、机制化蓄力与脆弱窗口均复用 numbers.innerDemon 口径。
  static Phase0aStageMapping mapInnerDemon({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
    int? cycleIndex,
  }) {
    if (stage.stageType != StageType.innerDemon) {
      throw ArgumentError.value(stage.id, 'stage', 'must be innerDemon');
    }
    final definition = numbers.innerDemon;
    final buff = definition.mirrorBuffPerStage[stage.id] ?? 0.0;
    final caps = definition.mirrorCaps;
    final vulnerability = definition.mirrorVulnerabilityPerStage[stage.id];
    final chargeSkillId = definition.mirrorChargeSkillId;
    final chargeSkill = chargeSkillId == null
        ? null
        : GameRepository.instance.getSkill(chargeSkillId);
    final injectMechanic = vulnerability != null && chargeSkill != null;
    final attackMultiplier = injectMechanic
        ? definition.mechanicMirrorAttackMultiplier
        : 1 + buff;
    final skills =
        injectMechanic &&
            !playerSnapshot.availableSkills.any(
              (skill) => skill.id == chargeSkill.id,
            )
        ? [...playerSnapshot.availableSkills, chargeSkill]
        : playerSnapshot.availableSkills;
    final maxHp = (playerSnapshot.maxHp * (1 + buff)).round().clamp(
      1,
      caps.hpMax,
    );
    final internalForce = (playerSnapshot.internalForce * (1 + buff))
        .round()
        .clamp(1, caps.internalForceMax);
    final attack = (playerSnapshot.totalEquipmentAttack * attackMultiplier)
        .round()
        .clamp(0, caps.attackPowerMax);
    final outputMultiplier = injectMechanic
        ? definition.mechanicMirrorOutputMultiplierPerStage[stage.id] ?? 1.0
        : 1.0;
    final mirror = CombatantSnapshot(
      characterId: -1,
      name: UiStrings.innerDemonMirrorName(playerSnapshot.name),
      realmTier: playerSnapshot.realmTier,
      realmLayer: playerSnapshot.realmLayer,
      school: playerSnapshot.school,
      maxHp: maxHp,
      currentHp: maxHp,
      internalForce: internalForce,
      maxQi: playerSnapshot.maxQi,
      currentQi: playerSnapshot.currentQi,
      qiGainMultiplier: playerSnapshot.qiGainMultiplier,
      qiCostReductionPct: playerSnapshot.qiCostReductionPct,
      autoUltimate: playerSnapshot.autoUltimate,
      speed: playerSnapshot.speed,
      criticalRate: playerSnapshot.criticalRate,
      evasionRate: playerSnapshot.evasionRate,
      defenseRate: playerSnapshot.defenseRate,
      totalEquipmentAttack: attack,
      mainCultivationLayer: playerSnapshot.mainCultivationLayer,
      skillLoadout: playerSnapshot.skillLoadout,
      availableSkills: skills,
      openingSkillCooldowns: const {},
      skillUses: const {},
      activeBuffs: const [],
      swordSongResonanceActive: playerSnapshot.swordSongResonanceActive,
      iconPath: WuxiaUi.battleFounderFallback,
      attackPowerMultiplier: playerSnapshot.attackPowerMultiplier,
      outputMultiplier: playerSnapshot.outputMultiplier * outputMultiplier,
      isBoss: true,
      chargeSkillId: injectMechanic ? chargeSkillId : null,
      bossPhases: null,
      bossPhaseUnlockSkills: null,
      schoolDamageTakenMult: playerSnapshot.schoolDamageTakenMult,
      lineageRole: null,
      forgingPiercePct: playerSnapshot.forgingPiercePct,
      forgingLifestealPct: playerSnapshot.forgingLifestealPct,
      enemyDefId: stage.id,
      guardianWardMult: null,
      guardianDefIds: const [],
      vulnerabilityMult: injectMechanic
          ? vulnerability.outOfWindowDamageMult
          : null,
      guardInterceptsInterrupt: false,
    );
    return _mapContent(
      contentId: stage.id,
      enemyTeam: const [],
      isTower: false,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
      playerId: playerId,
      cycleIndex: cycleIndex ?? 1,
      advanceRealmPerCycle: false,
      winCondition: _mapWinCondition(stage.winCondition),
      enemySnapshotsOverride: [mirror],
      enemyActorIdsOverride: ['${stage.id}_mirror'],
    );
  }

  /// 轻功对决把同一地形修正对称烘焙到主角与全部敌人，再进入标准单波 0A。
  static Phase0aStageMapping mapLightFoot({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
    int? cycleIndex,
  }) {
    if (stage.stageType != StageType.lightFoot || stage.terrainBiome == null) {
      throw ArgumentError.value(
        stage.id,
        'stage',
        'must be lightFoot with terrainBiome',
      );
    }
    final cycle = cycleIndex ?? 1;
    final modifier =
        numbers.lightFoot.terrainModifiers[stage.terrainBiome!] ??
        LightFootTerrainModifier.neutral();
    final rateCap = numbers.combat.redLines.combinedRateCap;
    CombatantSnapshot applyTerrain(CombatantSnapshot snapshot) =>
        snapshot.copyWith(
          criticalRate: (snapshot.criticalRate + modifier.criticalRateDelta)
              .clamp(0.0, rateCap),
          evasionRate: (snapshot.evasionRate + modifier.evasionRateDelta).clamp(
            0.0,
            rateCap,
          ),
          defenseRate: (snapshot.defenseRate + modifier.defenseRateDelta).clamp(
            0.0,
            rateCap,
          ),
          attackPowerMultiplier: modifier.damageMultiplier,
        );
    final enemies = EnemyCombatantSnapshotAssembler.assembleAll(
      stage.enemyTeam,
      cycleIndex: cycle,
      isTower: false,
      advanceRealmPerCycle: true,
    ).map(applyTerrain).toList(growable: false);
    return _mapContent(
      contentId: stage.id,
      enemyTeam: stage.enemyTeam,
      isTower: false,
      playerSnapshot: applyTerrain(playerSnapshot),
      numbers: numbers,
      playerId: playerId,
      cycleIndex: cycle,
      advanceRealmPerCycle: true,
      winCondition: _mapWinCondition(stage.winCondition),
      enemySnapshotsOverride: enemies,
    );
  }

  /// 群战守城：默认/所选阵型仅烘焙到主角，敌人按生产 wave 模板展开；
  /// 波间满血、恢复 25% 气海并重置普攻/技能冷却由 transition policy 执行。
  static Phase0aStageMapping mapMassBattle({
    required StageDef stage,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    Formation? formation,
    String playerId = 'player',
    int? cycleIndex,
  }) {
    if (stage.stageType != StageType.massBattle ||
        stage.massBattleEnemyCounts == null ||
        stage.massBattleEnemyCounts!.isEmpty) {
      throw ArgumentError.value(stage.id, 'stage', 'must be massBattle waves');
    }
    final cycle = cycleIndex ?? 1;
    final selectedFormation =
        formation ??
        numbers.massBattle.stageFormations[stage.id] ??
        Formation.yanXing;
    final modifier =
        numbers.massBattle.formations[selectedFormation] ??
        MassBattleFormationModifier.neutral();
    final rateCap = numbers.combat.redLines.combinedRateCap;
    final formedPlayer = playerSnapshot.copyWith(
      criticalRate: (playerSnapshot.criticalRate + modifier.criticalRateDelta)
          .clamp(0.0, rateCap),
      evasionRate: (playerSnapshot.evasionRate + modifier.evasionRateDelta)
          .clamp(0.0, rateCap),
      defenseRate: (playerSnapshot.defenseRate + modifier.defenseRateDelta)
          .clamp(0.0, rateCap),
      attackPowerMultiplier: modifier.damageMultiplier,
    );
    final enemyWaves = EnemyCombatantSnapshotAssembler.assembleWaves(
      stage,
      cycleIndex: cycle,
    );
    if (enemyWaves.isEmpty) {
      throw ArgumentError.value(stage.id, 'stage', 'massBattle waves empty');
    }
    final intermission = numbers.massBattle.waveIntermission;
    return _mapContent(
      contentId: stage.id,
      enemyTeam: stage.enemyTeam,
      isTower: false,
      playerSnapshot: formedPlayer,
      numbers: numbers,
      playerId: playerId,
      cycleIndex: cycle,
      advanceRealmPerCycle: true,
      winCondition: _mapWinCondition(stage.winCondition),
      enemySnapshotWavesOverride: enemyWaves,
      waveTransitionPolicy: Phase0aWaveTransitionPolicy(
        healPlayerToFull: intermission.aliveHpRecoveryPct >= 1,
        qiRecoveryPct: intermission.aliveIfRecoveryPct,
        resetAttackCooldown: intermission.resetActionPoint,
        resetSkillCooldowns: !intermission.preserveCooldowns,
        intermissionSeconds: intermission.intermissionSeconds,
      ),
    );
  }

  /// 把一层生产塔定义装配到与主线相同的 Phase 0A 输入。这里只做 D1
  /// 敌队机械映射；Boss 阶段/蓄力/破招、周目脆弱窗口与
  /// 护法结界动态 ward 均由 Phase 0A reducer/伤害 resolver 消费。
  static Phase0aStageMapping mapTower({
    required TowerFloorDef floor,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    String playerId = 'player',
    int? cycleIndex,
  }) => _mapContent(
    contentId: 'tower_${floor.floorIndex}',
    enemyTeam: floor.enemyTeam,
    isTower: true,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
    playerId: playerId,
    cycleIndex: cycleIndex ?? 1,
    advanceRealmPerCycle: false,
    winCondition: null,
  );

  /// 远征节点敌队已含深度缩放；这里额外保留远征既有的周目境界段推进。
  static Phase0aStageMapping mapExpedition({
    required String contentId,
    required List<EnemyDef> enemyTeam,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    required int cycleIndex,
    String playerId = 'player',
  }) => _mapContent(
    contentId: contentId,
    enemyTeam: enemyTeam,
    isTower: false,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
    playerId: playerId,
    cycleIndex: cycleIndex,
    advanceRealmPerCycle: true,
    winCondition: null,
  );

  static Phase0aStageMapping _mapContent({
    required String contentId,
    required List<EnemyDef> enemyTeam,
    required bool isTower,
    required CombatantSnapshot playerSnapshot,
    required NumbersConfig numbers,
    required String playerId,
    required int cycleIndex,
    required bool advanceRealmPerCycle,
    required Phase0aWinCondition? winCondition,
    List<CombatantSnapshot>? enemySnapshotsOverride,
    List<String>? enemyActorIdsOverride,
    List<List<CombatantSnapshot>>? enemySnapshotWavesOverride,
    List<double?>? enemyMoveSpeedOverrides,
    Phase0aWaveTransitionPolicy? waveTransitionPolicy,
  }) {
    if (cycleIndex < 1) {
      throw ArgumentError.value(cycleIndex, 'cycleIndex', 'must be >= 1');
    }
    final playerMapping = mapPlayerOnly(
      contentId: contentId,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
      playerId: playerId,
    );
    final arena = numbers.phase0aArena;
    final defenseTuning = playerMapping.defenseTuning;
    final skillSlots = playerMapping.skillSlots;
    final moveBindings = playerMapping.moveBindings;
    if (enemyTeam.isEmpty &&
        (enemySnapshotsOverride?.isEmpty ?? true) &&
        (enemySnapshotWavesOverride?.isEmpty ?? true)) {
      throw ArgumentError.value(contentId, 'content', 'Phase0a 纵切装配拒绝空敌队内容');
    }

    // —— 敌人 neutral snapshot:复用旧战斗同一口径(零数值复制)——
    final enemySnapshotWaves =
        enemySnapshotWavesOverride ??
        [
          enemySnapshotsOverride ??
              EnemyCombatantSnapshotAssembler.assembleAll(
                enemyTeam,
                cycleIndex: cycleIndex,
                isTower: isTower,
                advanceRealmPerCycle: advanceRealmPerCycle,
              ),
        ];
    if (enemySnapshotWaves.any((wave) => wave.isEmpty)) {
      throw ArgumentError.value(contentId, 'content', 'Phase0a 波次不得为空');
    }
    final enemySnapshots = enemySnapshotWaves
        .expand((wave) => wave)
        .toList(growable: false);
    if (enemyMoveSpeedOverrides != null &&
        enemyMoveSpeedOverrides.length != enemySnapshots.length) {
      throw ArgumentError.value(
        enemyMoveSpeedOverrides,
        'enemyMoveSpeedOverrides',
        'must match enemySnapshots length',
      );
    }
    if (enemyActorIdsOverride != null &&
        enemyActorIdsOverride.length != enemySnapshots.length) {
      throw ArgumentError.value(
        enemyActorIdsOverride,
        'enemyActorIdsOverride',
        'must match enemySnapshots length',
      );
    }
    final actorIds =
        enemyActorIdsOverride ??
        [
          for (
            var waveIndex = 0;
            waveIndex < enemySnapshotWaves.length;
            waveIndex++
          )
            for (
              var slot = 0;
              slot < enemySnapshotWaves[waveIndex].length;
              slot++
            )
              if (enemySnapshotWaves.length == 1 && enemyTeam.length == 1)
                enemyTeam.single.id
              else
                '${enemySnapshotWaves[waveIndex][slot].enemyDefId}_w${waveIndex}s$slot',
        ];
    // —— 蓄力/破招预解析(reducer 不回查仓库):顶层 chargeSkillId 招牌 cast +
    // 阶段 chargeCounter 招牌 cast + 踉跄窗口拍数,全部来自 snapshot 已解析
    // SkillDef 与 numbers.combat.bossCharge ——
    final chargeTicks = numbers.combat.bossCharge.defaultChargeTicks;
    final staggerTicksTotal = numbers.combat.bossCharge.defaultStaggerTicks;
    final postureConfig = _postureConfig(numbers.combat.posture);
    final topLevelChargeCasts = <Phase0aChargeCast?>[
      for (final snapshot in enemySnapshots)
        preResolveTopLevelChargeCast(
          snapshot: snapshot,
          arena: arena,
          chargeTicks: chargeTicks,
          defenseFlags: defenseTuning?.skillAttackFlags,
        ),
    ];
    final phaseChargeCastsByEnemy = <List<Phase0aChargeCast?>>[
      for (final snapshot in enemySnapshots)
        preResolvePhaseChargeCasts(
          snapshot: snapshot,
          arena: arena,
          chargeTicks: chargeTicks,
          defenseFlags: defenseTuning?.skillAttackFlags,
        ),
    ];

    // —— 空间排布:确定性,玩家在左,敌人右侧按 slot 均匀散开 ——
    final waveEnemies = <Phase0aActor>[];
    final actorWaves = <List<Phase0aActor>>[];
    var flatIndex = 0;
    for (final snapshotWave in enemySnapshotWaves) {
      final actorWave = <Phase0aActor>[];
      for (var slot = 0; slot < snapshotWave.length; slot++) {
        final snapshot = snapshotWave[slot];
        final actor = _enemyActor(
          arena: arena,
          snapshot: snapshot,
          actorId: actorIds[flatIndex],
          position: _enemyPosition(
            arena: arena,
            slot: slot,
            count: snapshotWave.length,
          ),
          chargeCast: topLevelChargeCasts[flatIndex],
          phaseChargeCasts: phaseChargeCastsByEnemy[flatIndex],
          staggerTicksTotal: staggerTicksTotal,
          postureConfig: postureConfig,
          guardianDefIds: snapshot.guardianDefIds,
          guardianWardMult: snapshot.guardianWardMult,
          guardInterceptsInterrupt: snapshot.guardInterceptsInterrupt,
          vulnerabilityMult: snapshot.vulnerabilityMult,
          moveSpeedOverride: enemyMoveSpeedOverrides?[flatIndex],
        );
        actorWave.add(actor);
        waveEnemies.add(actor);
        flatIndex += 1;
      }
      actorWaves.add(List.unmodifiable(actorWave));
    }

    final playerActor = playerMapping.initialPlayer;

    final enemySkillBindingsByActor = <String, List<Phase0aEnemySkillBinding>>{
      for (var i = 0; i < enemySnapshots.length; i++)
        waveEnemies[i].id: preResolveEnemySkillBindings(
          arena: arena,
          snapshot: enemySnapshots[i],
        ),
    };
    final enemyBasicQiDeltaByActor = <String, int>{
      for (var i = 0; i < enemySnapshots.length; i++)
        waveEnemies[i].id: _requiredBasicSkillOf(
          enemySnapshots[i],
          actorId: waveEnemies[i].id,
        ).qiDelta,
    };
    final enemyBasicPowerMultiplierByActor = <String, int>{
      for (var i = 0; i < enemySnapshots.length; i++)
        waveEnemies[i].id: _requiredBasicSkillOf(
          enemySnapshots[i],
          actorId: waveEnemies[i].id,
        ).powerMultiplier,
    };

    final combatants = <Phase0aCombatantInput>[
      Phase0aCombatantInput(actorId: playerId, snapshot: playerSnapshot),
      for (var i = 0; i < enemySnapshots.length; i++)
        Phase0aCombatantInput(
          actorId: waveEnemies[i].id,
          snapshot: enemySnapshots[i],
        ),
    ];

    return Phase0aStageMapping(
      initialState: Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: playerActor,
        enemies: actorWaves.first,
        skillSlots: skillSlots,
        winCondition: winCondition,
      ),
      waves: [for (final actors in actorWaves) Phase0aWave(enemies: actors)],
      combatants: List.unmodifiable(combatants),
      moveBindings: moveBindings,
      playerAdapter: playerMapping.playerAdapter,
      enemyAiAdapter: Phase0aEnemyAiAdapter(
        attackRange: arena.enemyAttackRange,
        attackHalfArcRadians: arena.enemyAttackHalfArcRadians,
        attackCooldownSeconds: arena.enemyAttackCooldownSeconds,
        skillBindingsByActor: Map.unmodifiable(enemySkillBindingsByActor),
        basicQiDeltaByActor: Map.unmodifiable(enemyBasicQiDeltaByActor),
        basicPowerMultiplierByActor: Map.unmodifiable(
          enemyBasicPowerMultiplierByActor,
        ),
        postureBasicPowerMultiplier: arena.basicPowerMultiplier,
        defenseTuning: defenseTuning,
      ),
      waveTransitionPolicy: waveTransitionPolicy,
    );
  }

  static Phase0aWinCondition? _mapWinCondition(StageWinCondition? condition) {
    if (condition == null) return null;
    return switch (condition.type) {
      StageWinConditionType.defeatAll => const Phase0aWinCondition.defeatAll(),
      StageWinConditionType.surviveTicks => Phase0aWinCondition.surviveTicks(
        condition.surviveTicksRequired!,
      ),
    };
  }

  /// 敌人空间位:右侧纵深固定,纵向按 slot 数均匀展开(确定性,无 RNG)。
  static ArenaVector _enemyPosition({
    required Phase0aArenaConfig arena,
    required int slot,
    required int count,
  }) {
    final x = arena.arenaMaxX * 0.4;
    if (count == 1) return ArenaVector(x, 0);
    final usableHeight = arena.arenaMaxY - arena.arenaMinY;
    final y = arena.arenaMinY + usableHeight * (slot + 0.5) / count;
    return ArenaVector(x, y);
  }

  static Phase0aActor _enemyActor({
    required Phase0aArenaConfig arena,
    required CombatantSnapshot snapshot,
    required String actorId,
    required ArenaVector position,
    required Phase0aChargeCast? chargeCast,
    required List<Phase0aChargeCast?> phaseChargeCasts,
    required int staggerTicksTotal,
    required PostureConfig postureConfig,
    required List<String> guardianDefIds,
    required double? guardianWardMult,
    required bool guardInterceptsInterrupt,
    required double? vulnerabilityMult,
    required double? moveSpeedOverride,
  }) {
    final phases = snapshot.bossPhases;
    final initialUnlocks = phases == null || phases.isEmpty
        ? const <String>[]
        : List<String>.unmodifiable(phases.first.unlockSkillIds);
    final openingCooldowns = <String, double>{
      for (final entry in snapshot.openingSkillCooldowns.entries)
        if (entry.value > 0)
          entry.key: entry.value * arena.enemyAttackCooldownSeconds,
    };
    // 真气/技能 CD 运行态:阶段敌人走 snapshot 口径;无阶段但带顶层蓄力的
    // 敌人同样需要真实真气门槛(否则招牌技永不可选 = 蓄力静默失效)。
    final usesSkillRuntime = phases != null || chargeCast != null;
    return Phase0aActor(
      id: actorId,
      side: Phase0aSide.enemy,
      position: position,
      facing: const ArenaVector(-1, 0),
      maxHealth: snapshot.maxHp,
      currentHealth: snapshot.currentHp,
      // 非主线继续使用 arena 速度；仅主线 mapper 显式传入小怪 override。
      moveSpeed: moveSpeedOverride ?? arena.enemyMoveSpeed,
      qiCurrent: usesSkillRuntime ? snapshot.currentQi : arena.enemyQi,
      qiMax: usesSkillRuntime ? snapshot.maxQi : arena.enemyQi,
      attackCooldownRemaining: arena.enemyInitialAttackCooldown,
      defeatKind: snapshot.isBoss
          ? Phase0aDefeatKind.elite
          : Phase0aDefeatKind.normal,
      isBoss: snapshot.isBoss,
      autoUltimate: snapshot.autoUltimate,
      bossPhases: phases,
      unlockedEnemySkillIds: initialUnlocks,
      enemySkillCooldowns: usesSkillRuntime
          ? Map.unmodifiable(openingCooldowns)
          : const {},
      chargeCast: chargeCast,
      phaseChargeCasts: phaseChargeCasts,
      staggerTicksTotal: staggerTicksTotal,
      guardianDefIds: guardianDefIds,
      guardianWardMult: guardianWardMult,
      guardInterceptsInterrupt: guardInterceptsInterrupt,
      vulnerabilityMult: vulnerabilityMult,
      posture: PostureState.initial(postureConfig),
    );
  }

  /// 顶层蓄力入口(EnemyDef.chargeSkillId):从 snapshot 已解析技能表取招牌技
  /// 并预解析施放参数;配了 chargeSkillId 但技能缺失 → fail-fast(loader
  /// 红线 `_enforceBossChargeRedLines` 已保 ∈ skillIds,此处双保险)。
  static Phase0aChargeCast? preResolveTopLevelChargeCast({
    required CombatantSnapshot snapshot,
    required Phase0aArenaConfig arena,
    required int chargeTicks,
    AttackDefenseFlags? defenseFlags,
  }) {
    final chargeSkillId = snapshot.chargeSkillId;
    if (chargeSkillId == null) return null;
    SkillDef? chargeSkill;
    for (final skill in snapshot.availableSkills) {
      if (skill.id == chargeSkillId) {
        chargeSkill = skill;
        break;
      }
    }
    if (chargeSkill == null) {
      throw StateError(
        'Phase0a 蓄力装配 ${snapshot.enemyDefId}: chargeSkillId '
        '$chargeSkillId 不在 availableSkills,不得静默丢蓄力',
      );
    }
    return _chargeCast(
      skill: chargeSkill,
      arena: arena,
      chargeTicks: chargeTicks,
      defenseFlags: defenseFlags,
    );
  }

  /// 阶段蓄力入口(BossPhaseMechanic.chargeCounter):逐阶段预解析招牌技
  /// (= 该阶段解锁招里 powerMultiplier 最高者,对齐旧引擎;解锁招为空 →
  /// null = no-op)。无阶段 = 空表。
  static List<Phase0aChargeCast?> preResolvePhaseChargeCasts({
    required CombatantSnapshot snapshot,
    required Phase0aArenaConfig arena,
    required int chargeTicks,
    AttackDefenseFlags? defenseFlags,
  }) {
    final phases = snapshot.bossPhases;
    if (phases == null) return const [];
    final unlocks = snapshot.bossPhaseUnlockSkills;
    return List<Phase0aChargeCast?>.unmodifiable([
      for (var i = 0; i < phases.length; i++)
        if (phases[i].onEnterMechanic == BossPhaseMechanic.chargeCounter)
          _phaseSignatureCast(
            unlocks != null && i < unlocks.length
                ? unlocks[i]
                : const <SkillDef>[],
            arena,
            chargeTicks,
            defenseFlags,
          )
        else
          null,
    ]);
  }

  static Phase0aChargeCast? _phaseSignatureCast(
    List<SkillDef> skills,
    Phase0aArenaConfig arena,
    int chargeTicks,
    AttackDefenseFlags? defenseFlags,
  ) {
    SkillDef? signature;
    for (final skill in skills) {
      if (signature == null ||
          skill.powerMultiplier > signature.powerMultiplier) {
        signature = skill;
      }
    }
    return signature == null
        ? null
        : _chargeCast(
            skill: signature,
            arena: arena,
            chargeTicks: chargeTicks,
            defenseFlags: defenseFlags,
          );
  }

  /// 招牌技施放参数:空间值取竞技场敌攻口径(沿阶段技能绑定),CD 取
  /// SkillDef 已物化的敌方实时秒值;伤害仍由 SkillDef 经唯一
  /// DamageCalculator 结算,本对象不复制数值。
  static Phase0aChargeCast _chargeCast({
    required SkillDef skill,
    required Phase0aArenaConfig arena,
    required int chargeTicks,
    AttackDefenseFlags? defenseFlags,
  }) => Phase0aChargeCast(
    skill: skill,
    chargeTicks: chargeTicks,
    attackRange: arena.enemyAttackRange,
    halfArcRadians: arena.enemyAttackHalfArcRadians,
    effectRadius: arena.enemyAttackRange,
    cooldownSeconds: _requiredEnemyCooldownSeconds(skill),
    actionCooldownSeconds: arena.enemyAttackCooldownSeconds,
    postureDamage: addDefenseBreakPostureDamage(
      powerMultiplierToPostureDamage(
        skill.powerMultiplier,
        basicPowerMultiplier: arena.basicPowerMultiplier,
      ),
      defenseBreakPct: skill.defenseBreakPct,
    ),
    postureHitKind: PostureHitKind.heavy,
    defenseFlags: defenseFlags,
  );

  static List<Phase0aEnemySkillBinding> preResolveEnemySkillBindings({
    required Phase0aArenaConfig arena,
    required CombatantSnapshot snapshot,
  }) {
    final byId = <String, SkillDef>{};
    final phaseSkills = snapshot.bossPhaseUnlockSkills;
    if (phaseSkills != null) {
      for (final skills in phaseSkills) {
        for (final skill in skills) {
          byId[skill.id] = skill;
        }
      }
    }
    // 顶层招牌蓄力技也须进 AI 绑定表,否则 BattleAI 永远不会选中它、
    // 起手蓄力入口静默失效(与 preResolveTopLevelChargeCast 同源 fail-fast)。
    final chargeSkillId = snapshot.chargeSkillId;
    if (chargeSkillId != null && !byId.containsKey(chargeSkillId)) {
      for (final skill in snapshot.availableSkills) {
        if (skill.id == chargeSkillId) {
          byId[chargeSkillId] = skill;
          break;
        }
      }
    }
    if (byId.isEmpty) return const [];
    final ids = byId.keys.toList()..sort();
    return List.unmodifiable([
      for (final id in ids)
        Phase0aEnemySkillBinding(
          skill: byId[id]!,
          attackRange: arena.enemyAttackRange,
          halfArcRadians: arena.enemyAttackHalfArcRadians,
          effectRadius: arena.enemyAttackRange,
          cooldownSeconds: _requiredEnemyCooldownSeconds(byId[id]!),
          consumesDefenseBreakAsPostureDamage: true,
          allowQiDrain:
              snapshot.chargeSkillId == id && byId[id]!.qiDrainPct > 0,
        ),
    ]);
  }

  static SkillDef? _basicSkillOf(CombatantSnapshot snapshot) {
    final bound = snapshot.skillLoadout.basicAttack;
    if (bound != null) return bound;
    for (final skill in snapshot.availableSkills) {
      if (skill.type == SkillType.normalAttack) return skill;
    }
    return null;
  }

  static SkillDef _requiredBasicSkillOf(
    CombatantSnapshot snapshot, {
    required String actorId,
  }) {
    final skill = _basicSkillOf(snapshot);
    if (skill == null) {
      throw StateError(
        'Phase0a 纵切装配 $actorId: 敌人快照缺真实 basicAttack，'
        '禁止回退中性 qiDelta',
      );
    }
    return skill;
  }

  static List<Phase0aSkillSlot> _skillSlots(
    Phase0aNumericSkillBindings numericSkills,
    _Phase0aTacticalSkillBindings tacticalSkills,
    int openingQi,
  ) => List.unmodifiable([
    Phase0aSkillSlot(
      slot: tacticalSkills.gather.slot,
      cooldownRemaining: 0,
      qiCost: tacticalSkills.gather.qiCost,
      availability: availabilityOf(
        cooldownRemaining: 0,
        qiCurrent: openingQi,
        qiCost: tacticalSkills.gather.qiCost,
      ),
    ),
    Phase0aSkillSlot(
      slot: tacticalSkills.clear.slot,
      cooldownRemaining: 0,
      qiCost: tacticalSkills.clear.qiCost,
      availability: availabilityOf(
        cooldownRemaining: 0,
        qiCurrent: openingQi,
        qiCost: tacticalSkills.clear.qiCost,
      ),
    ),
    for (final binding in numericSkills.equipped)
      Phase0aSkillSlot(
        slot: binding.slotId,
        cooldownRemaining: 0,
        qiCost: binding.skill.qiCost,
        availability: availabilityOf(
          cooldownRemaining: 0,
          qiCurrent: openingQi,
          qiCost: binding.skill.qiCost,
        ),
      ),
  ]);

  /// 招式绑定:basic/Q/R 均保留仓库真实 SkillDef 身份与效果契约。
  static Map<Phase0aDamageKind, SkillDef?> _moveBindings(
    SkillDef playerBasicSkill,
    Phase0aNumericSkillBindings numericSkills,
    _Phase0aTacticalSkillBindings tacticalSkills,
  ) => Map.unmodifiable({
    Phase0aDamageKind.basic: playerBasicSkill,
    Phase0aDamageKind.gather: tacticalSkills.gather.skill,
    Phase0aDamageKind.clear: tacticalSkills.clear.skill,
    for (final binding in numericSkills.equipped)
      phase0aDamageKindForSkillHotkey(binding.hotkey): binding.skill,
  });

  static Phase0aNumericSkillBindings _numericSkillBindings(
    CombatantSnapshot player,
    Phase0aArenaConfig arena,
  ) {
    Phase0aNumericSkillBinding? binding(int hotkey) {
      final loadoutSlot = CombatantSkillLoadout.numericSlots[hotkey - 1];
      final skill = player.skillLoadout.skillFor(loadoutSlot);
      // 正式控制已拍板「鼠标左键 = 普攻」；autoFill 仍可能把 normalAttack
      // 放进 main1/2（历史技能槽语义），Phase 0A 数字栏必须排除，避免同拍
      // 鼠标 basic + 数字 basic 双入口重复结算。
      if (skill == null || skill.type == SkillType.normalAttack) return null;
      return Phase0aNumericSkillBinding(
        hotkey: hotkey,
        loadoutSlot: loadoutSlot,
        skill: skill,
        visualSchool: skill.style ?? player.school,
        slotId: 'phase0a_skill_$hotkey',
        attackRange: arena.playerAttackRange,
        halfArc: arena.playerAttackHalfArcRadians,
        effectRadius: arena.clearEffectRadius,
        cooldownSeconds: _requiredPlayerCooldownSeconds(skill),
        consumesDefenseBreakAsPostureDamage: true,
      );
    }

    return Phase0aNumericSkillBindings(
      one: binding(1),
      two: binding(2),
      three: binding(3),
      four: binding(4),
      five: binding(5),
      six: binding(6),
    );
  }

  static double _requiredPlayerCooldownSeconds(SkillDef skill) {
    final seconds = skill.cooldownSeconds;
    if (seconds == null || !seconds.isFinite || seconds < 0) {
      throw StateError('Phase0a 玩家技能 ${skill.id}: 缺有限非负 cooldownSeconds');
    }
    return seconds;
  }

  static double _requiredEnemyCooldownSeconds(SkillDef skill) {
    final seconds = skill.phase0aEnemyCooldownSeconds;
    if (seconds == null || !seconds.isFinite || seconds < 0) {
      throw StateError(
        'Phase0a 敌方技能 ${skill.id}: '
        '缺有限非负 phase0aEnemyCooldownSeconds',
      );
    }
    return seconds;
  }

  /// Production and mapper fixtures resolve both Q/R bindings from real
  /// SkillDefs. Missing, partial, or unsupported configuration fails closed;
  /// the retired synthetic-clear mapper path must not be reintroduced.
  static _Phase0aTacticalSkillBindings _tacticalSkillBindings(
    Phase0aArenaConfig arena,
  ) {
    final gatherMissing = arena.gatherSkillId.isEmpty;
    final clearMissing = arena.clearSkillId.isEmpty;
    if (gatherMissing || clearMissing) {
      throw StateError(
        'Phase0a tactical skill ids must be configured together',
      );
    }
    final skills = GameRepository.instance.skillDefs;
    final gatherSkill = skills[arena.gatherSkillId];
    final clearSkill = skills[arena.clearSkillId];
    if (gatherSkill == null || clearSkill == null) {
      throw StateError(
        'Phase0a tactical skill missing: '
        'gather=${arena.gatherSkillId}(${gatherSkill != null}), '
        'clear=${arena.clearSkillId}(${clearSkill != null})',
      );
    }
    return _Phase0aTacticalSkillBindings(
      gather: Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.gather,
        slot: arena.gatherSlot,
        skill: gatherSkill,
      ),
      clear: Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.clear,
        slot: arena.clearSlot,
        skill: clearSkill,
      ),
    );
  }

  static Phase0aPlayerInputAdapter _playerAdapter({
    required Phase0aArenaConfig arena,
    required String playerId,
    required Phase0aNumericSkillBindings numericSkillBindings,
    required _Phase0aTacticalSkillBindings tacticalSkillBindings,
    required int attackQiDelta,
    required int attackPowerMultiplier,
    Phase0aDefenseTuning? defenseTuning,
  }) {
    final gather = tacticalSkillBindings.gather;
    final clear = tacticalSkillBindings.clear;
    return Phase0aPlayerInputAdapter(
      playerId: playerId,
      attackRange: arena.playerAttackRange,
      attackHalfArcRadians: arena.playerAttackHalfArcRadians,
      attackCooldownSeconds: arena.playerAttackCooldownSeconds,
      attackQiDelta: attackQiDelta,
      postureBasicPowerMultiplier: arena.basicPowerMultiplier,
      attackPowerMultiplier: attackPowerMultiplier,
      gatherPowerMultiplier: gather.skill.powerMultiplier,
      clearPowerMultiplier: clear.skill.powerMultiplier,
      gatherSlot: gather.slot,
      gatherRingRadius: gather.destinationRadius!,
      gatherEffectRadius: gather.effectRadius,
      gatherQiCost: gather.qiCost,
      gatherCooldownSeconds: gather.cooldownSeconds,
      clearSlot: clear.slot,
      clearEffectRadius: clear.effectRadius,
      clearQiCost: clear.qiCost,
      clearCooldownSeconds: clear.cooldownSeconds,
      gatherSkillBinding: gather,
      clearSkillBinding: clear,
      numericSkillBindings: numericSkillBindings,
      defenseTuning: defenseTuning,
      basicAttackChain: swordBasicAttackChain,
      basicAttackGeometryRegistry:
          Phase0aBasicAttackGeometryMapper.swordRegistryFromArena(arena),
      basicAttackArenaBounds: Phase0aBasicAttackGeometryMapper.arenaBoundsFrom(
        arena,
      ),
    );
  }

  static PostureConfig _postureConfig(PostureNumbersConfig config) =>
      PostureConfig(
        capacity: config.capacity,
        vulnerabilityTicks: config.vulnerabilityTicks,
        recoveryPolicy:
            config.recoveryPolicy == PostureRecoveryPolicyConfig.reset
            ? PostureRecoveryPolicy.reset
            : PostureRecoveryPolicy.recover,
        postVulnerabilityAccumulated: config.postVulnerabilityAccumulated,
        bossControlConversionFactor: config.bossConversionFactor,
      );
}

final class _Phase0aTacticalSkillBindings {
  const _Phase0aTacticalSkillBindings({
    required this.gather,
    required this.clear,
  });

  final Phase0aTacticalSkillBinding gather;
  final Phase0aTacticalSkillBinding clear;
}
