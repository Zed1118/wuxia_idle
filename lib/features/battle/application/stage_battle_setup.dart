import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:isar_community/isar.dart';

import '../domain/battle_state.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/synergy_def.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../jianghu/application/enmity_battle_modifier.dart';
import '../../jianghu/application/npc_relation_service.dart';
import '../../../shared/battle_shared/enemy_combatant_snapshot_assembler.dart';
import 'legacy_3v3_combatant_adapter.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';

/// 关卡战斗准备（Phase 3 T37，对应 PROGRESS #22 销账）。
///
/// 负责主线/塔/心魔/恩怨 orchestration；玩家与敌人快照分别委托
/// [PlayerCombatantSnapshotAssembler]/[EnemyCombatantSnapshotAssembler]，
/// 本类通过 [Legacy3v3CombatantAdapter] 保留旧 3v3 roster policy 与兼容
/// interface。
///
/// - 左队（玩家）：从 Isar 拉 [SaveData.activeCharacterIds]，每个角色用
///   [BattleCharacter.fromCharacter] 接装备 + 主修；最少 1 人。
/// - 右队（敌人）：[StageDef.enemyTeam] 每个 [EnemyDef] 用 [_enemyToBattle]
///   构造（不接 yaml 装备/心法，纯走 EnemyDef.base* 数值）。
///
/// **negative id 约定**：敌人 [BattleCharacter.characterId] 用 `-(slotIndex+1)`，
/// 避免与玩家 Isar autoIncrement id 冲突。
class StageBattleSetup {
  const StageBattleSetup({required this.isar});

  final Isar isar;

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`（主线 / 心魔版）。
  ///
  /// **心魔关分支**（1.0 P2.2 §12.1，Batch 2.2.B）：stageType == innerDemon
  /// 时右队走 [InnerDemonService.buildMirrorEnemyTeam] 镜像左队 +10-20% 强化
  /// （§5.4 cap），不走 yaml `enemyTeam`（心魔关 yaml `enemyTeam: []`）。
  ///
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版完全一致，零回归）。
  Future<(List<BattleCharacter>, List<BattleCharacter>)> buildTeams(
    StageDef stage, {
    int cycleIndex = 1,
    bool readableFirstClearTuning = false,
  }) async {
    var left = await buildActivePlayerTeam();
    if (readableFirstClearTuning) {
      left = _applyReadableFirstClearOpeningCooldown(left);
    }
    final right = stage.stageType == StageType.innerDemon
        ? InnerDemonService.buildMirrorEnemyTeam(
            playerTeam: left,
            stageId: stage.id,
            innerDemonDef: GameRepository.instance.numbers.innerDemon,
            mirrorChargeSkill: _resolveInnerDemonChargeSkill(),
          )
        : buildEnemyTeam(
            stage.enemyTeam,
            cycleIndex: cycleIndex,
            isTower: false,
            advanceRealmPerCycle: realmAdvanceStageTypes.contains(
              stage.stageType,
            ),
            stageNpcId: stage.isBossStage ? stage.npcId : null,
            readableFirstClearTuning: readableFirstClearTuning,
          );
    if (!stage.isBossStage || stage.npcId == null) return (left, right);
    return EnmityBattleModifier.bakeMultipliers(
      npcService: NpcRelationService(isar, GameRepository.instance.numbers),
      leftTeam: left,
      rightTeam: right,
    );
  }

  /// 心魔关脆弱窗口蓄力技解析（05/06 机制化心魔）。config 配了
  /// `mirror_charge_skill_id` 时从 GameRepository 取 SkillDef 注入镜像；未配
  /// （旧配置 / 无机制关）→ null。[InnerDemonService] 是纯函数不读 Isar，故在
  /// 此 caller 侧解析后传入。
  static SkillDef? _resolveInnerDemonChargeSkill() {
    final id = GameRepository.instance.numbers.innerDemon.mirrorChargeSkillId;
    return id != null ? GameRepository.instance.getSkill(id) : null;
  }

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`（爬塔版）。
  ///
  /// 左队装配逻辑与 [buildTeams] 完全一致；右队用 [TowerFloorDef.enemyTeam]。
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版完全一致，零回归）。
  Future<(List<BattleCharacter>, List<BattleCharacter>)> buildTeamsForTower(
    TowerFloorDef floor, {
    int cycleIndex = 1,
  }) async {
    final left = await buildActivePlayerTeam();
    final right = buildEnemyTeam(
      floor.enemyTeam,
      cycleIndex: cycleIndex,
      isTower: true,
    );
    return (left, right);
  }

  /// 将 [EnemyDef] 列表装配为右队 [BattleCharacter] 列表（最多 3 人）。
  ///
  /// 批 B 境界段推进入口白名单（spec 2026-08-01 拍板 #5）：StageDef 系里仅
  /// 轻功对决 / 群战守城两个支线推进；主线 / 心魔不推进，爬塔走扩层（拍板 #3）。
  /// 断魂庄 / 远征不走 StageDef 路径，由各自 runner 显式传
  /// [buildEnemyTeam] 的 `advanceRealmPerCycle: true`。
  static const Set<StageType> realmAdvanceStageTypes =
      EnemyCombatantSnapshotAssembler.realmAdvanceStageTypes;

  /// 主线 [buildTeams] 与爬塔 [buildTeamsForTower] 共用，避免重复。纯函数,保持 static。
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版完全一致，零回归）；
  /// [isTower] 决定词条分配表选取（false=主线，true=爬塔）；
  /// [advanceRealmPerCycle] 开启批 B 周目境界段推进（默认 false 零回归）。
  static List<BattleCharacter> buildEnemyTeam(
    List<EnemyDef> enemies, {
    int cycleIndex = 1,
    bool isTower = false,
    bool advanceRealmPerCycle = false,
    String? stageNpcId,
    bool readableFirstClearTuning = false,
  }) {
    return Legacy3v3CombatantAdapter.enemyTeam(
      EnemyCombatantSnapshotAssembler.assembleAll(
        enemies,
        cycleIndex: cycleIndex,
        isTower: isTower,
        advanceRealmPerCycle: advanceRealmPerCycle,
        stageNpcId: stageNpcId,
        readableFirstClearTuning: readableFirstClearTuning,
      ),
    );
  }

  /// 群战守城 per-wave 敌队生成。模板 [stage.enemyTeam] (3 templates) 循环填充
  /// 每波 [massBattleEnemyCounts[w]] 人，characterId 从 -10000 递减防撞。
  /// [cycleIndex] 默认 1（零回归）。
  static List<List<BattleCharacter>> buildEnemyTeamsPerWave(
    StageDef stage, {
    int cycleIndex = 1,
  }) {
    final waves = EnemyCombatantSnapshotAssembler.assembleWaves(
      stage,
      cycleIndex: cycleIndex,
    );
    return [
      for (final wave in waves) Legacy3v3CombatantAdapter.enemyWave(wave),
    ];
  }

  /// 当前出战阵容 interface：读取 activeCharacterIds，过滤活动占用；旧 seed
  /// 未写 active 列表时允许 fallback 首个可用角色。
  Future<List<BattleCharacter>> buildActivePlayerTeam() async {
    final snapshots = await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadActiveRoster();
    return Legacy3v3CombatantAdapter.playerTeam(snapshots);
  }

  /// 指定阵容 interface：严格保序装配传入 ids。空/重复/缺失一律 fail-fast，
  /// 绝不 fallback 任意角色，避免远征/断魂庄/0A 坏会话静默换人。
  Future<List<BattleCharacter>> buildExactPlayerTeam(
    List<int> characterIds,
  ) async {
    final snapshots = await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadExactRoster(characterIds);
    return Legacy3v3CombatantAdapter.playerTeam(snapshots);
  }

  /// 把 [SynergyMultipliers] 应用到 [BattleCharacter] 4 个标量字段(view layer)。
  ///
  /// 数值红线 cap:
  ///   - internalForce ≤ 15000(§5.4)
  ///   - maxHp ≤ 20000(§5.4,W18-A1.2 hot-loop 升级版加 cap,沿 maxIf cap 体例)
  ///
  /// 装备攻击 ≤ 2000 是 §5.4 单装备红线(equipment.yaml 单件 baseAttack 上限),
  /// 角色 totalEquipmentAttack 是 3 件求和不在 §5.4 红线范畴,applySynergy 不 cap。
  /// multiplier 上限 0.30 在 _enforceSynergyRedLines 保证。currentHp 跟
  /// maxHp 同比例放大；内力加成只放大永久内力快照，不改真气。
  ///
  /// W18-A1.2 补 [SynergyMultipliers.defensePct] → defenseRate 加法叠加
  /// (realm max 0.35 + synergy 0.30 = 0.65 ≤ §5.5 红线安全)。
  /// [SynergyMultipliers.internalForceGrowthPct] 在 [SeclusionService.computeOutputs]
  /// 消费(战斗 init 不影响)。
  ///
  /// **@visibleForTesting**:测试矩阵 7 tier × 5 synergy 极端 base 派生压测
  /// 需要直接调用本静态方法绕过 Isar,沿 [TowerEntryFlow.runTowerFlow] /
  /// [StageEntryFlow.runStageFlow] battleRunnerForTest 体例。
  ///
  /// [numbers] 注入红线 cap(单一真相源 numbers.yaml combat.red_lines);省略时
  /// 回落 `GameRepository.instance.numbers`(生产路径,与本类既有 instance 用法一致)。
  /// 测试需先 loadAllDefs(Isar-free),或显式传 fixture numbers。
  @visibleForTesting
  static BattleCharacter applySynergy(
    BattleCharacter base,
    SynergyMultipliers m, {
    NumbersConfig? numbers,
  }) {
    final snapshot = Legacy3v3CombatantAdapter.toSnapshot(base);
    final tuned = PlayerCombatantSnapshotAssembler.applySynergy(
      snapshot,
      m,
      numbers: numbers,
    );
    return Legacy3v3CombatantAdapter.fromSnapshot(
      tuned,
      teamSide: base.teamSide,
      slotIndex: base.slotIndex,
    );
  }

  /// P5.2 敌人内力对称化：按境界 internalForceMax × 全局 scale，clamp ≤ 红线。
  /// 抽纯函数便于单测 scale/clamp，不依赖 GameRepository 单例。
  @visibleForTesting
  static int resolveEnemyInternalForce(
    int realmInternalForceMax,
    double scale,
    int redLineCap,
  ) {
    return EnemyCombatantSnapshotAssembler.resolveInternalForce(
      realmInternalForceMax,
      scale,
      redLineCap,
    );
  }

  /// EnemyDef → BattleCharacter。
  ///
  /// 敌人不持装备/心法，全靠 yaml `baseHp / baseAttack / baseSpeed`：
  /// - `internalForce` 按境界查表 RealmDef.internalForceMax
  ///   × `enemy_defaults.internal_force_scale`（P5.2 对称化，满开局，clamp≤红线）；
  ///   `criticalRate / evasionRate` 取 `numbers.yaml combat.enemy_defaults`
  /// - `mainCultivationLayer` 默认 [CultivationLayer.daCheng]（中等加成）
  /// - `totalEquipmentAttack` = `baseAttack`（直接当装备攻击灌入伤害公式）
  /// - `characterId` 用 `-(slotIndex+1)` 避免与玩家 Isar id 冲突
  ///
  /// **周目进化**（P1 cycle_evolution · B2）：
  /// - [cycleIndex] ≥ 2 时按 `cycleEvolution.scalePerCycle` 缩放 hp/attack/IF；
  /// - 词条注入：御体→defenseRate↑（clamp≤cap）；真气→IF×(1+pct)（clamp最后）；
  ///   识破→chargeSkillId（仅敌无自带时）；凝甲/反震→仅透传 activeBuffs 标签（结算侧消费）。
  /// - [cycleIndex]=1（默认）行为与旧版完全一致（零回归）。
  static List<BattleCharacter> _applyReadableFirstClearOpeningCooldown(
    List<BattleCharacter> team,
  ) {
    return [
      for (final character in team)
        _applyReadableFirstClearOpeningCooldownToOne(character),
    ];
  }

  @visibleForTesting
  static BattleCharacter debugApplyReadableFirstClearTuning(
    BattleCharacter character,
  ) => _applyReadableFirstClearOpeningCooldownToOne(character);

  static BattleCharacter _applyReadableFirstClearOpeningCooldownToOne(
    BattleCharacter character,
  ) {
    final turns = GameRepository
        .instance
        .numbers
        .combat
        .readableFirstClear
        .openingAutoSkillCooldownTurns;
    final autoSkillPowerMultiplier = GameRepository
        .instance
        .numbers
        .combat
        .readableFirstClear
        .autoSkillPowerMultiplier;
    final tunedSkills = [
      for (final skill in character.availableSkills)
        _tuneReadableFirstClearSkill(skill, autoSkillPowerMultiplier),
    ];
    final tuned = character.copyWith(availableSkills: tunedSkills);
    if (turns <= 0) return tuned;
    final ticksPerAction = (1000 / character.speed).ceil();
    final cooldownTicks = turns * ticksPerAction + 1;

    final cooldowns = Map<String, int>.from(tuned.skillCooldowns);
    for (final skill in tuned.availableSkills) {
      if (skill.requiresManualTrigger || skill.type == SkillType.normalAttack) {
        continue;
      }
      final existing = cooldowns[skill.id] ?? 0;
      if (existing < cooldownTicks) cooldowns[skill.id] = cooldownTicks;
    }
    if (cooldowns.isEmpty) return tuned;
    return tuned.copyWith(skillCooldowns: Map.unmodifiable(cooldowns));
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

  /// @visibleForTesting:暴露 [_enemyToBattle] 供单测(private static 不可直测)。
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版一致）；[isTower] 默认 false。
  @visibleForTesting
  static BattleCharacter debugEnemyToBattle({
    required EnemyDef enemy,
    required int slotIndex,
    int cycleIndex = 1,
    bool isTower = false,
    bool readableFirstClearTuning = false,
  }) => Legacy3v3CombatantAdapter.fromSnapshot(
    EnemyCombatantSnapshotAssembler.assembleOne(
      enemy: enemy,
      slotIndex: slotIndex,
      cycleIndex: cycleIndex,
      isTower: isTower,
      readableFirstClearTuning: readableFirstClearTuning,
    ),
    teamSide: 1,
    slotIndex: slotIndex,
  );
}
