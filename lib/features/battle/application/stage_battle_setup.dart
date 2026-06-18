import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:isar_community/isar.dart';

import '../domain/battle_state.dart';
import '../domain/derived_stats.dart' show RealmUtils;
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/synergy_def.dart';
import '../../tower/domain/tower_floor_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../cultivation/application/skill_loadout_resolver.dart';
import '../../cultivation/application/skill_loadout_service.dart';
import '../../cultivation/application/synergy_service.dart';
import '../../inheritance/application/founder_buff_service.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../sect/domain/sect.dart';

/// 关卡战斗准备（Phase 3 T37，对应 PROGRESS #22 销账）。
///
/// 负责把「持久化角色 + stage.enemyTeam」装配成 (左队, 右队) 两组
/// [BattleCharacter] 快照，可直接喂给 `BattleNotifier.startBattle`。
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
  }) async {
    final left = await _buildPlayerTeam();
    final right = stage.stageType == StageType.innerDemon
        ? InnerDemonService.buildMirrorEnemyTeam(
            playerTeam: left,
            stageId: stage.id,
            innerDemonDef: GameRepository.instance.numbers.innerDemon,
          )
        : buildEnemyTeam(stage.enemyTeam, cycleIndex: cycleIndex, isTower: false);
    return (left, right);
  }

  /// 拼装 (left, right) 战斗双方，准备调 `startBattle`（爬塔版）。
  ///
  /// 左队装配逻辑与 [buildTeams] 完全一致；右队用 [TowerFloorDef.enemyTeam]。
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版完全一致，零回归）。
  Future<(List<BattleCharacter>, List<BattleCharacter>)> buildTeamsForTower(
    TowerFloorDef floor, {
    int cycleIndex = 1,
  }) async {
    final left = await _buildPlayerTeam();
    final right = buildEnemyTeam(floor.enemyTeam, cycleIndex: cycleIndex, isTower: true);
    return (left, right);
  }

  /// 将 [EnemyDef] 列表装配为右队 [BattleCharacter] 列表（最多 3 人）。
  ///
  /// 主线 [buildTeams] 与爬塔 [buildTeamsForTower] 共用，避免重复。纯函数,保持 static。
  /// [cycleIndex] 默认 1（cycle-1 行为与旧版完全一致，零回归）；
  /// [isTower] 决定词条分配表选取（false=主线，true=爬塔）。
  static List<BattleCharacter> buildEnemyTeam(
    List<EnemyDef> enemies, {
    int cycleIndex = 1,
    bool isTower = false,
  }) {
    final right = <BattleCharacter>[];
    for (var i = 0; i < enemies.length && i < 3; i++) {
      right.add(_enemyToBattle(
        enemy: enemies[i],
        slotIndex: i,
        cycleIndex: cycleIndex,
        isTower: isTower,
      ));
    }
    return right;
  }

  /// 群战守城 per-wave 敌队生成。模板 [stage.enemyTeam] (3 templates) 循环填充
  /// 每波 [massBattleEnemyCounts[w]] 人，characterId 从 -10000 递减防撞。
  /// [cycleIndex] 默认 1（零回归）。
  static List<List<BattleCharacter>> buildEnemyTeamsPerWave(
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
            _enemyToBattle(
              enemy: templates[j % templates.length],
              slotIndex: j,
              characterIdOverride: -10000 - (cursor++),
              cycleIndex: cycleIndex,
              isTower: false, // 群战守城属于主线场景，非爬塔
            ),
        ],
    ];
  }

  /// 从 Isar 拉玩家方（左队）：优先 activeCharacterIds，空则兜底 findFirst。
  Future<List<BattleCharacter>> _buildPlayerTeam() async {
    final save = await isar.saveDatas.get(0);
    final ids = save?.activeCharacterIds ?? const [];
    final players = <Character>[];
    for (final cid in ids) {
      final c = await isar.characters.get(cid);
      if (c != null) players.add(c);
    }
    if (players.isEmpty) {
      // 兜底：Phase 2 P1 种子是 id=1 单人，没设 activeCharacterIds
      final fallback = await isar.characters.where().findFirst();
      if (fallback == null) {
        throw StateError('StageBattleSetup: Isar 没有任何 Character（先跑 P1 种子）');
      }
      players.add(fallback);
    }
    // P4.1 1.1 founder_buff cross_sect(spec §3):per-character buff 算法
    // 替换 P1.1 整队同一 bool · 沿 FounderBuffService.isBuffActiveFor API ·
    // playerSectId 从 isar.sects.get(1) 直接拿(Demo 单 sect · sect null →
    // fallback isInSect=false 路径 P1.1 R5 维持)。
    final founderBuffSvc = FounderBuffService(isar);
    final numbers = GameRepository.instance.numbers;
    final sect = await isar.sects.get(1);
    final playerSectId = sect?.id;
    final founderBuffByChar = <int, bool>{};
    for (final c in players) {
      founderBuffByChar[c.id] = await founderBuffSvc.isBuffActiveFor(
        target: c,
        numbers: numbers,
        playerSectId: playerSectId,
      );
    }
    // P1b Task5:进战斗前对每个出战玩家角色调 applyAutoFill，补满空装配槽。
    // 旧存档/未配置角色（5 槽全空）→ autoFill 填主修招，保证走装配路径而非 fallback。
    final loadoutSvc = SkillLoadoutService(isar);
    final resolver = SkillLoadoutResolver(isar: isar);
    final repo = GameRepository.instance;
    for (final c in players) {
      // P1b Task5/Task9 共享 resolver：解析主修招 / 辅修招 / joint 共鸣招。
      final sources = await resolver.resolve(c, repository: repo, numbers: numbers);
      // 第六阶段 Task 6 — 职责软引导：传入角色 lineage 身份，autoFill 按角色倾向填槽。
      await loadoutSvc.applyAutoFill(
        characterId: c.id,
        mainTechniqueSkills: sources.mainTechniqueSkills,
        assistTechniqueSkills: sources.assistTechniqueSkills,
        jointSkill: sources.jointSkill,
        ultimatePowerThreshold: numbers.loadoutUltimatePowerThreshold,
        interruptSkills: sources.interruptSkills,
        lineageRole: c.lineageRole,
        isFounder: c.isFounder,
      );
    }

    final left = <BattleCharacter>[];
    for (var i = 0; i < players.length && i < 3; i++) {
      // autoFill 已落库，重新从 Isar 读取（装配槽已更新的版本）。
      final updated = await isar.characters.get(players[i].id) ?? players[i];
      left.add(
        await _playerToBattle(
          character: updated,
          slotIndex: i,
          founderBuffActive: founderBuffByChar[players[i].id] ?? false,
        ),
      );
    }
    return left;
  }

  Future<BattleCharacter> _playerToBattle({
    required Character character,
    required int slotIndex,
    bool founderBuffActive = false,
  }) async {
    final equipped = <Equipment>[];
    for (final id in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (id == null) continue;
      final e = await isar.equipments.get(id);
      if (e != null) equipped.add(e);
    }

    if (character.mainTechniqueId == null) {
      throw StateError('StageBattleSetup: 角色 ${character.name} 未修主修，无法进入战斗');
    }
    final mainTech = await isar.techniques.get(character.mainTechniqueId!);
    if (mainTech == null) {
      throw StateError(
        'StageBattleSetup: 角色 ${character.name} mainTechniqueId='
        '${character.mainTechniqueId} 在 Isar 中找不到',
      );
    }

    // W18-A1:加载全部辅修(若有)供 SynergyService 检测心法相生。
    // assistTechniqueIds 为空 / Isar 找不到 → ownedTechniques 只含 main,
    // detectActive 因 assist 缺失返 null,正常 fallthrough。
    final ownedTechs = <Technique>[mainTech];
    for (final assistId in character.assistTechniqueIds) {
      final assistTech = await isar.techniques.get(assistId);
      if (assistTech != null) ownedTechs.add(assistTech);
    }

    // M6 Task6：余毒在身 debuff → 战斗输出 ×0.95（§5.6 从 config 读，不写死）。
    final residueMult = character.innerDemonResidueHoursRemaining > 0
        ? GameRepository.instance.numbers.innerDemon.residueDebuff
            .battleOutputMultiplier
        : 1.0;

    final base = BattleCharacter.fromCharacter(
      character: character,
      equipped: equipped,
      mainTechnique: mainTech,
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: slotIndex,
      founderBuffActive: founderBuffActive,
      outputMultiplier: residueMult,
    );

    // W18-A1 心法相生 buff 注入(GDD §4.5)。命中即 copyWith 调整 maxHp/speed/
    // totalEquipmentAttack/maxInternalForce/defenseRate 5 字段(W18-A1.2 补
    // defensePct → defenseRate 加法叠加);internalForceGrowthPct 在
    // [SeclusionService.computeOutputs] 消费(战斗 init 不涉)。
    final synergy = SynergyService.detectActive(
      character: character,
      ownedTechniques: ownedTechs,
      techDefLookup: (defId) => GameRepository.instance.techniqueDefs[defId],
      synergies: GameRepository.instance.synergies,
    );
    return synergy == null ? base : applySynergy(base, synergy.multipliers);
  }

  /// 把 [SynergyMultipliers] 应用到 [BattleCharacter] 4 个标量字段(view layer)。
  ///
  /// 数值红线 cap:
  ///   - maxInternalForce ≤ 15000(§5.4)
  ///   - maxHp ≤ 20000(§5.4,W18-A1.2 hot-loop 升级版加 cap,沿 maxIf cap 体例)
  ///
  /// 装备攻击 ≤ 2000 是 §5.4 单装备红线(equipment.yaml 单件 baseAttack 上限),
  /// 角色 totalEquipmentAttack 是 3 件求和不在 §5.4 红线范畴,applySynergy 不 cap。
  /// multiplier 上限 0.30 在 _enforceSynergyRedLines 保证。currentHp/currentInternalForce
  /// 跟 max 同比例放大(战斗起点保持满血 / 当前内力上限按比例)。
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
    final redLines =
        (numbers ?? GameRepository.instance.numbers).combat.redLines;
    var newMaxHp = (base.maxHp * (1 + m.hpPct)).round();
    // §5.4 玩家血量红线(W18-A1.2 升级版加 · 2026-05-29 消 hardcode 走 config)
    if (newMaxHp > redLines.playerHpMax) newMaxHp = redLines.playerHpMax;
    final newSpeed = (base.speed * (1 + m.speedPct)).round();
    final newAttack = (base.totalEquipmentAttack * (1 + m.attackPct)).round();
    var newMaxIf = (base.maxInternalForce * (1 + m.internalForceMaxPct))
        .round();
    // §5.4 内力红线(2026-05-29 消 hardcode 走 config)
    if (newMaxIf > redLines.internalForceMax) {
      newMaxIf = redLines.internalForceMax;
    }
    // W18-A1.2 加法叠加,clamp ≤ 0.95 防止减伤 100% 极端值
    final newDefenseRate = (base.defenseRate + m.defensePct).clamp(0.0, 0.95);
    // currentHp 起点跟 maxHp 一致(战斗起点满血,fromCharacter 保证)
    final newCurHp = newMaxHp;
    // currentInternalForce 不超新 max(若原 currentInternalForce 已 ≤ maxIf 仍取原值)
    final newCurIf = base.currentInternalForce > newMaxIf
        ? newMaxIf
        : base.currentInternalForce;
    return base.copyWith(
      maxHp: newMaxHp,
      currentHp: newCurHp,
      speed: newSpeed,
      totalEquipmentAttack: newAttack,
      maxInternalForce: newMaxIf,
      currentInternalForce: newCurIf,
      defenseRate: newDefenseRate,
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
    final scaled = (realmInternalForceMax * scale).round();
    return scaled.clamp(0, redLineCap);
  }

  /// EnemyDef → BattleCharacter。
  ///
  /// 敌人不持装备/心法，全靠 yaml `baseHp / baseAttack / baseSpeed`：
  /// - `maxInternalForce / currentInternalForce` 按境界查表 RealmDef.internalForceMax
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
  static BattleCharacter _enemyToBattle({
    required EnemyDef enemy,
    required int slotIndex,
    int? characterIdOverride,
    int cycleIndex = 1,
    bool isTower = false,
  }) {
    final numbers = GameRepository.instance.numbers;
    final skills = enemy.skillIds
        .map((id) => GameRepository.instance.getSkill(id))
        .toList(growable: false);
    final enemyDefaults = numbers.combat.enemyDefaults;
    final realm = GameRepository.instance.getRealm(
      enemy.realmTier,
      enemy.realmLayer,
    );
    final redLineCap = numbers.combat.redLines.internalForceMax;

    // ── 周目缩放系数（cycle 1 = 1.0，零变化）─────────────────────────────
    final ce = numbers.cycleEvolution;
    final scale = 1.0 + ce.scalePerCycle * (cycleIndex - 1);

    // ── hp：baseHp × scale，clamp ≤ Boss HP 红线（§5.4，防终局周目越线）────
    final scaledHp = (enemy.baseHp * scale)
        .toInt()
        .clamp(0, numbers.combat.redLines.bossHpMax);

    // ── attack：baseAttack × scale ────────────────────────────────────────
    final scaledAttack = (enemy.baseAttack * scale).toInt();

    // ── 内力：境界 IF × internalForceScale × scale（真气词条在词条块处理）──
    final baseIf = (realm.internalForceMax * enemyDefaults.internalForceScale * scale).round();

    // ── 词条分配（cycle ≤ 1 时 traitsFor 返回空集）────────────────────────
    final traits = ce.traitsFor(
      cycle: cycleIndex,
      isBoss: enemy.isBoss,
      isTower: isTower,
    );

    // ── 御体词条：defenseRate↑，按周目分档，clamp ≤ defenseRateCap ─────────
    var defenseRate = RealmUtils.defenseRateOf(enemy.realmTier);
    if (traits.contains('yuti')) {
      final yutiBonus = cycleIndex >= 3
          ? ce.traits.yuti.defenseRateBonusC3
          : ce.traits.yuti.defenseRateBonusC2;
      defenseRate = (defenseRate + yutiBonus).clamp(0.0, ce.defenseRateCap);
    }

    // ── 真气词条：内力 ×(1+pct)，clamp 最后执行（§5.4 红线）────────────────
    var resolvedIf = baseIf;
    if (traits.contains('zhenqi')) {
      resolvedIf = (baseIf * (1 + ce.traits.zhenqi.internalForcePct)).round();
    }
    resolvedIf = resolvedIf.clamp(0, redLineCap);

    // ── 识破词条：敌无自带 chargeSkillId 时注入 config 的蓄力技 id ──────────
    // Fix: 同时把该技能追加到 availableSkills，否则 battle_ai._pickSkill 只迭代
    // availableSkills，永远选不到 chargeSkillId，识破机制实质死机制。
    final String? chargeSkillId;
    List<SkillDef> resolvedSkills = skills;
    if (traits.contains('shipo') && enemy.chargeSkillId == null) {
      final shipoSkillId = ce.traits.shipo.chargeSkillId;
      chargeSkillId = shipoSkillId;
      // 若蓄力技不在 skills 列表中，追加一份可增长副本（保持原顺序）。
      if (!skills.any((s) => s.id == shipoSkillId)) {
        final shipoSkill = GameRepository.instance.getSkill(shipoSkillId);
        resolvedSkills = [...skills, shipoSkill];
      }
    } else {
      chargeSkillId = enemy.chargeSkillId; // 保留自带（P0 破招:招牌蓄力技透传）
    }

    // ── 词条标签：凝甲/反震仅携带标签，结算侧（Tasks C1/C2）消费 ───────────
    final activeBuffs = traits.isEmpty
        ? const <String>[]
        : (traits.map((t) => 'cycle_$t').toList()..sort());

    return BattleCharacter(
      characterId: characterIdOverride ?? -(slotIndex + 1),
      name: enemy.name,
      realmTier: enemy.realmTier,
      realmLayer: enemy.realmLayer,
      school: enemy.school,
      maxHp: scaledHp,
      currentHp: scaledHp,
      maxInternalForce: resolvedIf,
      currentInternalForce: resolvedIf,
      speed: enemy.baseSpeed,
      criticalRate: enemyDefaults.criticalRate,
      evasionRate: enemyDefaults.evasionRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: scaledAttack,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: resolvedSkills,
      skillCooldowns: const {},
      activeBuffs: activeBuffs,
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: slotIndex,
      iconPath: enemy.iconPath,
      isBoss: enemy.isBoss,
      chargeSkillId: chargeSkillId,
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
  }) => _enemyToBattle(
      enemy: enemy,
      slotIndex: slotIndex,
      cycleIndex: cycleIndex,
      isTower: isTower,
    );
}
