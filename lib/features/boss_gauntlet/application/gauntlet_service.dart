import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../../core/domain/attribute_effect_policy.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/skill_unlock_entry.dart';
import '../../../data/defs/item_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../../battle/application/legacy_3v3_combatant_adapter.dart';
import '../../battle/application/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/battle_state.dart';
import '../../../shared/battle_shared/cycle_realm_gate.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/application/progression_gate_service.dart';
import '../../equipment/application/equipment_factory.dart';
import '../../injury/application/injury_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import 'gauntlet_battle_runner.dart';
import 'gauntlet_controller.dart';
import 'phase0a_gauntlet_stage_runner.dart';

enum GauntletLegacyRetirement {
  none,
  preservedRewardChoice,
  refundedUnstarted,
  settledProgress,
}

/// 断魂庄当前关出战计划：`prepareStage` 事务外纯计算产出，供 live BattleScreen 路
/// （`gauntlet_entry_flow`）与 headless [GauntletService.fightCurrentStage] 共用。
typedef GauntletStagePlan = ({
  List<BattleCharacter> playerTeam,
  List<EnemyDef> enemyDefs,
  int seed,
  bool isBoss,
  int cycleIndex,
});

typedef Phase0aGauntletStagePlan = ({
  CombatantSnapshot playerSnapshot,
  List<EnemyDef> enemyDefs,
  int seed,
  bool isBoss,
  int cycleIndex,
  int stage,
});

/// 断魂庄崩溃恢复结果（C2.3b·§5.6/§10）。
enum GauntletRecoveryOutcome {
  /// 无 active 会话（正常入口）。
  none,

  /// 会话可恢复：caller 按 `run.sessionPhase` 路由（inBattle 重打当前关 / interlude
  /// 整备 / awaitingRewardChoice 奖励页）；本调用不改会话。
  resumed,

  /// 配置损坏且第一关前未开战 → 已退帖 + 返还托管补给 + 删会话。
  refundedTicket,

  /// 配置损坏且已开战 → 需认输结算（信号交 C2.5·本调用不改会话不退帖）。
  concedeRequired,
}

/// 断魂庄失败结算摘要（§6.3 · #1 wiring Task 3）：[GauntletService.settleDefeat] 产出，
/// 供战败屏只读展示（结算即删会话·摘要须随结算带出，不能事后读 run）。含已击败精英经验
/// （各参战成员同额名义值）+ 逐成员战末伤势（倒下→重伤 / 存活→轻伤）。
class GauntletDefeatSummary {
  const GauntletDefeatSummary({
    required this.elitesDefeated,
    required this.eliteExpPerMember,
    required this.members,
  });

  /// 幂等 no-op（无存档 / 会话已结算重入）时的空摘要。
  static const empty = GauntletDefeatSummary(
    elitesDefeated: 0,
    eliteExpPerMember: 0,
    members: [],
  );

  /// 已击败精英关数（战败关之前 role==elite 计数·§6.2 每精英一份）。
  final int elitesDefeated;

  /// 每名参战成员所得精英经验名义值（= elitesDefeated × eliteRewardExp·层锁封顶前）。
  final int eliteExpPerMember;

  /// 逐成员伤势（倒下者重伤·存活者轻伤·§6.3）。
  final List<GauntletDefeatMember> members;
}

/// 断魂庄战败单成员伤势（§6.3 · #1 wiring Task 3）。
class GauntletDefeatMember {
  const GauntletDefeatMember({required this.name, required this.downed});

  final String name;

  /// 战末倒下 → 重伤；存活 → 轻伤。
  final bool downed;
}

/// 断魂庄应用服务（spec §5.1/§9.2）。
///
/// C2.1 入场扣帖 + 补给会话托管；C2.2 整备页用药 + 关闭返还（守恒）。均单 `writeTxn`。
/// 离线恢复、奖励发放见后续切片（C2.3–C2.5）。[itemDefs] 供 [useSupply]/[close]
/// 读补给效果（`gauntletHpHealPct`/`gauntletQiRestorePct`）与库存重建类型，生产由
/// `GameRepository.instance.itemDefs` 注入；[enter] 不需。
class GauntletService {
  const GauntletService(this._isar, {this.itemDefs = const {}});

  final Isar _isar;

  /// 道具效果查表（defId → [ItemDef]）。
  final Map<String, ItemDef> itemDefs;

  /// 副本凭证 defId（断魂帖）。每次入场消耗一张，消耗凭证与建会话同事务（§5.1）。
  static const String ticketDefId = 'item_duanhuntie';

  /// 断魂庄副本标识（`SaveData.clearedGauntletIds` 键·首通判定/防重·§9.2）。
  /// 单副本，无 yaml id；未来多副本时移入配置。
  static const String gauntletId = 'duanhunzhuang';

  /// 入场：单 `writeTxn` 建断魂庄 active 会话，返回落库的 run id。
  ///
  /// [supplies] = defId → 份数（疗伤丹/行囊补给自由混装），总份数 ≤ [supplyCap]。
  /// 断魂庄已全通最高周目（读侧兜底：旧档 cycle1 通关态由
  /// [SaveData.duanhunFirstClearedAt] 派生，`duanhunClearedCyclesMax` 缺失读 0）。
  static int duanhunClearedCyclesMaxOf(SaveData save) => math.max(
    save.duanhunClearedCyclesMax,
    save.duanhunFirstClearedAt != null ? 1 : 0,
  );

  Future<int> enter({
    required List<int> characterIds,
    Map<String, int> supplies = const {},
    required int supplyCap,
    int cycleIndex = 1,
  }) async {
    if (characterIds.isEmpty || characterIds.length > 3) {
      throw StateError('断魂庄入场：队伍须 1-3 人，got ${characterIds.length}');
    }
    if (cycleIndex < 1) {
      throw StateError('断魂庄入场：周目须 ≥1，got $cycleIndex');
    }
    if (characterIds.toSet().length != characterIds.length) {
      throw StateError('断魂庄入场：队伍含重复角色');
    }
    if (supplies.values.any((v) => v <= 0)) {
      throw StateError('断魂庄入场：补给份数须为正');
    }
    final totalSupplies = supplies.values.fold(0, (a, b) => a + b);
    if (totalSupplies > supplyCap) {
      throw StateError('断魂庄入场：补给至多 $supplyCap 份，got $totalSupplies');
    }

    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('断魂庄入场：无存档');

      final runs = await _isar.bossGauntletRuns.where().findAll();
      if (runs.any((r) => r.saveDataId == save.id)) {
        throw StateError('断魂庄入场：已有进行中的断魂庄会话，需先结束');
      }

      final occupancy = await CharacterOccupancyService(_isar).snapshot();
      final members = <ActivityMemberSnapshot>[];
      var entryMaxTier = RealmTier.xueTu;
      for (final cid in characterIds) {
        final c = await _isar.characters.get(cid);
        if (c == null) throw StateError('断魂庄入场：角色 $cid 不存在');
        if (c.realmTier.index > entryMaxTier.index) entryMaxTier = c.realmTier;
        if (c.isFounder) throw StateError('断魂庄入场：祖师不可入场');
        if (occupancy.isCharacterOccupied(cid)) {
          throw StateError('断魂庄入场：角色 $cid 已被其它活动占用');
        }
        final mainTechId = c.mainTechniqueId;
        if (mainTechId == null) {
          throw StateError('断魂庄入场：角色 $cid 未修主修，不可入场');
        }
        members.add(
          ActivityMemberSnapshot()
            ..characterId = cid
            ..reservedEquipmentIds = [
              ?c.equippedWeaponId,
              ?c.equippedArmorId,
              ?c.equippedAccessoryId,
            ]
            ..reservedTechniqueIds = [mainTechId, ...c.assistTechniqueIds]
            ..currentHp = 0
            ..currentQi = 0
            ..isDowned = false,
        );
      }

      // 批 B：周目解锁门槛硬守卫（顺序解锁 + 境界门槛，UI 为第一道拦截）。
      if (cycleIndex > 1) {
        final config = GameRepository.instance.bossGauntletConfig;
        if (config == null) {
          throw StateError('断魂庄入场：无断魂庄配置，不可挑战高周目');
        }
        final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
        final unlocked = CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: duanhunClearedCyclesMaxOf(save),
          playerMaxTier: entryMaxTier,
          baseEnemyMaxTier: CycleRealmGate.maxEnemyTierOf([
            for (final s in config.stages)
              ...config.enemiesForTeam(s.enemyTeamId),
          ]),
          ra: ra,
        );
        if (cycleIndex > unlocked) {
          throw StateError('断魂庄入场：周目 $cycleIndex 未解锁（当前可挑战至 $unlocked）');
        }
      }

      // 扣一张断魂帖（消耗凭证与建会话同事务·§5.1）。
      final ticket = await _isar.inventoryItems.getByDefId(ticketDefId);
      if (ticket == null || ticket.quantity < 1) {
        throw StateError('断魂庄入场：无断魂帖，不可入场');
      }
      ticket.quantity -= 1;
      await _isar.inventoryItems.put(ticket);

      // 补给移入托管栏（平行三列表·扣普通库存·usedQty 全 0）。
      final escrowDefIds = <String>[];
      final escrowLoaded = <int>[];
      final escrowUsed = <int>[];
      for (final entry in supplies.entries) {
        final item = await _isar.inventoryItems.getByDefId(entry.key);
        if (item == null || item.quantity < entry.value) {
          throw StateError('断魂庄入场：补给 ${entry.key} 库存不足');
        }
        item.quantity -= entry.value;
        await _isar.inventoryItems.put(item);
        escrowDefIds.add(entry.key);
        escrowLoaded.add(entry.value);
        escrowUsed.add(0);
      }

      final run = BossGauntletRun()
        ..saveDataId = save.id
        // seed = saveId 派生（无 run serial·异于远征）；每关组合层再混 currentStage。
        ..seed = save.id
        ..currentStage = 1
        ..cycleIndex = cycleIndex
        ..sessionPhase = GauntletPhase.inBattle
        ..members = members
        ..escrowItemDefIds = escrowDefIds
        ..escrowLoadedQty = escrowLoaded
        ..escrowUsedQty = escrowUsed;

      return _isar.bossGauntletRuns.put(run);
    });
  }

  /// 整备页用药：单 `writeTxn` 只减托管 `escrowUsedQty`（**不碰普通库存**·§5.1）。
  ///
  /// [index] 指托管栏条目；疗伤丹恢复 [targetCharacterId]（须存活）`gauntletHpHealPct`
  /// 最大生命，行囊补给恢复全体存活 `gauntletQiRestorePct` 最大真气（均钳到 max·
  /// 不复活倒下者）。仅 [GauntletPhase.interlude]（关次间整备页）可用；战斗中不可用药。
  Future<void> useSupply({required int index, int? targetCharacterId}) async {
    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('断魂庄用药：无存档');
      final run = await _activeRun(save.id);
      if (run == null) throw StateError('断魂庄用药：无进行中会话');
      if (run.sessionPhase != GauntletPhase.interlude) {
        throw StateError('断魂庄用药：仅整备页可用药（当前 ${run.sessionPhase.name}）');
      }
      if (index < 0 || index >= run.escrowItemDefIds.length) {
        throw StateError('断魂庄用药：补给下标越界 $index');
      }
      if (run.escrowUsedQty[index] >= run.escrowLoadedQty[index]) {
        throw StateError('断魂庄用药：该补给已用尽');
      }
      final defId = run.escrowItemDefIds[index];
      final def = itemDefs[defId];
      if (def == null) throw StateError('断魂庄用药：未知补给道具 $defId');

      if (def.gauntletHpHealPct > 0) {
        if (targetCharacterId == null) {
          throw StateError('断魂庄用药：疗伤丹须指定目标角色');
        }
        final m = _memberOf(run, targetCharacterId);
        if (m == null) {
          throw StateError('断魂庄用药：目标 $targetCharacterId 不在队伍');
        }
        if (m.isDowned) throw StateError('断魂庄用药：不可对倒下者用药');
        final heal = (m.maxHp * def.gauntletHpHealPct).round();
        m.currentHp = math.min(m.maxHp, m.currentHp + heal);
      } else if (def.gauntletQiRestorePct > 0) {
        for (final m in run.members) {
          if (m.isDowned) continue;
          final restore = (m.maxQi * def.gauntletQiRestorePct).round();
          m.currentQi = math.min(m.maxQi, m.currentQi + restore);
        }
      } else {
        throw StateError('断魂庄用药：$defId 无断魂庄补给效果');
      }

      run.escrowUsedQty[index] += 1; // 只减托管（增用量）·不碰普通库存
      await _isar.bossGauntletRuns.put(run);
    });
  }

  /// 关闭会话：单 `writeTxn` 把每份托管补给的 `Loaded - Used` 原子**返还**普通库存，
  /// 删除会话（占用随之解除）。无 active 会话时幂等 no-op（供崩溃恢复重入·§5.6）。
  /// 胜利/失败/认输/安全恢复各自的奖励/伤势结算由 caller 先于本调用完成（C2.4/C2.5）。
  Future<void> close() async {
    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) return;
      final run = await _activeRun(save.id);
      if (run == null) return; // 幂等：无 active 会话
      await _returnEscrow(run);
      await _isar.bossGauntletRuns.delete(run.id);
    });
  }

  /// 路线 C 一次性清理历史 2–3 人会话。Boss 已胜的待选奖励保留给玩家；
  /// 未开战全额退帖，已推进会话发已获精英经验并返还剩余托管，但不因系统迁移附伤。
  Future<GauntletLegacyRetirement> retireLegacyMultiplayer({
    required BossGauntletConfig config,
    required NumbersConfig numbers,
  }) async {
    final run = await activeRun();
    if (run == null || run.members.length == 1) {
      return GauntletLegacyRetirement.none;
    }
    if (run.sessionPhase == GauntletPhase.awaitingRewardChoice) {
      return GauntletLegacyRetirement.preservedRewardChoice;
    }
    final hasFought =
        run.currentStage > 1 ||
        run.sessionPhase != GauntletPhase.inBattle ||
        run.members.any((member) => member.maxHp > 0);
    if (!hasFought) {
      await _refundTicketAndClose(run);
      return GauntletLegacyRetirement.refundedUnstarted;
    }
    await settleDefeat(config: config, numbers: numbers, applyInjuries: false);
    return GauntletLegacyRetirement.settledProgress;
  }

  /// 把托管补给的 `Loaded - Used` 返还普通库存（**假定已在 `writeTxn` 内**）。
  /// [close] 与 [recover] 退帖共用。库存行缺失（防御）据 [itemDefs] 重建。
  Future<void> _returnEscrow(BossGauntletRun run) async {
    for (var i = 0; i < run.escrowItemDefIds.length; i++) {
      final remaining = run.escrowLoadedQty[i] - run.escrowUsedQty[i];
      if (remaining <= 0) continue;
      final defId = run.escrowItemDefIds[i];
      final existing = await _isar.inventoryItems.getByDefId(defId);
      if (existing != null) {
        existing.quantity += remaining;
        await _isar.inventoryItems.put(existing);
      } else {
        final def = itemDefs[defId];
        if (def == null) {
          throw StateError('断魂庄返还：补给 $defId 库存行缺失且无 ItemDef 重建');
        }
        final now = DateTime.now();
        await _isar.inventoryItems.put(
          InventoryItem()
            ..defId = defId
            ..itemType = def.type
            ..quantity = remaining
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
    }
  }

  /// 单场战斗驱动：驱动当前关次一场 headless 战斗并原子推进会话（C2.3a·§5.6/§9.2）。
  ///
  /// load run → 从会话成员建满血基准队（`buildExactPlayerTeam` 真生产路径：
  /// autoFill/相生/祖师 buff/伤势）→ `GauntletController.stagePlayerTeam` 按快照装配
  /// （首关满血/关次间继承 生命·真气·冷却·剔阵亡）→ `GauntletBattleRunner.runStage`
  /// （seed 混 currentStage·`Random` 确定性）→ `GauntletController.advance` → 单
  /// `writeTxn` 持久化。**建队/战斗在事务外**（纯计算），仅推进落一个原子事务——
  /// 战斗中崩溃（未落事务）→ 会话留当前关开打前态·重开重打（§5.6）。
  ///
  /// [config]/[numbers] 由 caller 从 `GameRepository.instance` 注入（可测）。
  Future<GauntletStageResult> fightCurrentStage({
    required BossGauntletConfig config,
    required NumbersConfig numbers,
  }) async {
    final plan = await prepareStage(config: config);
    final result = GauntletBattleRunner.runStage(
      playerTeam: plan.playerTeam,
      enemyDefs: plan.enemyDefs,
      numbers: numbers,
      seed: plan.seed,
      cycleIndex: plan.cycleIndex,
    );
    await settleStageResult(finalState: result.finalState, config: config);
    return result;
  }

  Future<Phase0aGauntletStageResult> fightCurrentStagePhase0a({
    required BossGauntletConfig config,
    required NumbersConfig numbers,
  }) async {
    final plan = await preparePhase0aStage(config: config);
    final result = await Phase0aGauntletStageRunner.run(
      contentId: 'gauntlet_${plan.stage}',
      playerSnapshot: plan.playerSnapshot,
      enemyTeam: plan.enemyDefs,
      numbers: numbers,
      seed: plan.seed,
      cycleIndex: plan.cycleIndex,
    );
    await settlePhase0aStageResult(result: result, config: config);
    return result;
  }

  Future<Phase0aGauntletStagePlan> preparePhase0aStage({
    required BossGauntletConfig config,
  }) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) throw StateError('断魂庄开打：无存档');
    final run = await _activeRun(save.id);
    if (run == null) throw StateError('断魂庄开打：无进行中会话');
    if (run.sessionPhase != GauntletPhase.inBattle) {
      throw StateError('断魂庄开打：仅关次开打态可战斗（当前 ${run.sessionPhase.name}）');
    }
    if (run.members.length != 1) {
      throw StateError('Phase0a gauntlet requires exactly one member');
    }
    if (run.currentStage < 1 || run.currentStage > config.stages.length) {
      throw StateError('断魂庄开打：关次越界 ${run.currentStage}');
    }
    final stageCfg = config.stages[run.currentStage - 1];
    final enemyDefs = config.enemiesForTeam(stageCfg.enemyTeamId);
    if (enemyDefs.isEmpty) {
      throw StateError('断魂庄开打：关次 ${run.currentStage} 敌队为空（配置损坏）');
    }
    final member = run.members.single;
    final snapshots = await PlayerCombatantSnapshotAssembler(
      isar: _isar,
    ).loadExactRoster([member.characterId]);
    var player = snapshots.single;
    if (member.maxHp > 0) {
      player = player.copyWith(
        maxHp: member.maxHp,
        currentHp: member.currentHp,
        maxQi: member.maxQi,
        currentQi: member.currentQi,
        openingSkillCooldowns: {
          for (var i = 0; i < member.skillCooldownKeys.length; i++)
            member.skillCooldownKeys[i]: member.skillCooldownTurns[i],
        },
      );
    }
    return (
      playerSnapshot: player,
      enemyDefs: enemyDefs,
      seed: _stageSeed(run.seed, run.currentStage),
      isBoss: stageCfg.role == 'boss',
      cycleIndex: run.cycleIndex,
      stage: run.currentStage,
    );
  }

  Future<void> settlePhase0aStageResult({
    required Phase0aGauntletStageResult result,
    required BossGauntletConfig config,
  }) async {
    await _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) return;
      final fresh = await _activeRun(save.id);
      if (fresh == null) return;
      if (fresh.members.length != 1 ||
          fresh.currentStage < 1 ||
          fresh.currentStage > config.stages.length) {
        return;
      }
      final isBoss = config.stages[fresh.currentStage - 1].role == 'boss';
      GauntletController.advancePhase0a(
        run: fresh,
        checkpoint: result.checkpoint,
        leftWin: result.leftWin,
        isBossStage: isBoss,
      );
      GauntletController.stageBossReward(
        run: fresh,
        config: config,
        alreadyCleared: save.clearedGauntletIds.contains(gauntletId),
      );
      await _isar.bossGauntletRuns.put(fresh);
    });
  }

  /// 事务外纯计算：load run → 校验 → 建当前关出战计划（满血基准队按会话快照继承
  /// 生命·真气·冷却 + 关次敌队 + 混 currentStage 的确定性 seed + isBoss）。live
  /// BattleScreen 路（`gauntlet_entry_flow`）与 headless [fightCurrentStage] 共用此段。
  Future<GauntletStagePlan> prepareStage({
    required BossGauntletConfig config,
  }) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) throw StateError('断魂庄开打：无存档');
    final run = await _activeRun(save.id);
    if (run == null) throw StateError('断魂庄开打：无进行中会话');
    if (run.sessionPhase != GauntletPhase.inBattle) {
      throw StateError('断魂庄开打：仅关次开打态可战斗（当前 ${run.sessionPhase.name}）');
    }
    if (run.currentStage < 1 || run.currentStage > config.stages.length) {
      throw StateError('断魂庄开打：关次越界 ${run.currentStage}');
    }
    final stageCfg = config.stages[run.currentStage - 1];
    final enemyDefs = config.enemiesForTeam(stageCfg.enemyTeamId);
    if (enemyDefs.isEmpty) {
      throw StateError('断魂庄开打：关次 ${run.currentStage} 敌队为空（配置损坏）');
    }
    final memberIds = run.members.map((m) => m.characterId).toList();
    final baseSnapshots = await PlayerCombatantSnapshotAssembler(
      isar: _isar,
    ).loadExactRoster(memberIds);
    final baseTeam = Legacy3v3CombatantAdapter.playerTeam(baseSnapshots);
    final playerTeam = GauntletController.stagePlayerTeam(
      baseTeam: baseTeam,
      members: run.members,
    );
    return (
      playerTeam: playerTeam,
      enemyDefs: enemyDefs,
      seed: _stageSeed(run.seed, run.currentStage),
      isBoss: stageCfg.role == 'boss',
      cycleIndex: run.cycleIndex,
    );
  }

  /// 消费当前关战末态 [finalState]（headless `runStage` 或 live BattleScreen 均可）：
  /// 单 `writeTxn` 原子推进——re-load fresh → `advance`（战末快照继承 + 推进相位）→
  /// `stageBossReward`（Boss 胜利固化三选一候选·非该相位 no-op）→ put。会话已并发
  /// 关闭（fresh null）或关次越界 → 防御 no-op（§9.2 原子性即崩溃安全）。
  Future<void> settleStageResult({
    required BattleState finalState,
    required BossGauntletConfig config,
  }) async {
    await _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) return;
      final fresh = await _activeRun(save.id);
      if (fresh == null) return; // 防御：会话已被并发关闭
      if (fresh.currentStage < 1 || fresh.currentStage > config.stages.length) {
        return; // 防御：关次越界（配置漂移）
      }
      final isBoss = config.stages[fresh.currentStage - 1].role == 'boss';
      GauntletController.advance(
        run: fresh,
        finalState: finalState,
        isBossStage: isBoss,
      );
      GauntletController.stageBossReward(
        run: fresh,
        config: config,
        alreadyCleared: save.clearedGauntletIds.contains(gauntletId),
      );
      await _isar.bossGauntletRuns.put(fresh);
    });
  }

  /// 整备页「继续闯关」：单 `writeTxn` 把 interlude 翻回 inBattle 开打下一关（§7.2）。
  /// 关次由上关 [GauntletController.advance] 已递增，本调用只翻相位。
  Future<void> continueToNextStage() async {
    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('断魂庄续战：无存档');
      final run = await _activeRun(save.id);
      if (run == null) throw StateError('断魂庄续战：无进行中会话');
      if (run.sessionPhase != GauntletPhase.interlude) {
        throw StateError('断魂庄续战：仅整备页可继续闯关（当前 ${run.sessionPhase.name}）');
      }
      run.sessionPhase = GauntletPhase.inBattle;
      await _isar.bossGauntletRuns.put(run);
    });
  }

  /// 断魂庄奖励三选一原子结算（最关键幂等·§6.2/§9.2）。单 `writeTxn`：发
  /// [chosenEquipmentDefId] 命名装备入背包（owner=null）+ 参战全员经验（层锁·同远征/
  /// 闭关口径受发布上限）与领悟点（首通全额 / 重复取半·§6.2）+ 首通解锁秘籍
  /// （[BossGauntletConfig.firstClearRewardSkillId]）+ 记 `clearedGauntletIds` /
  /// `duanhunFirstClearedAt` + 返还托管补给 + 关会话。**只成功一次**：会话已结算（run
  /// 已删）→ 重入 no-op 不重复发（§inv4/5·`clearedGauntletIds` 防重）。[rng] 供命名
  /// 装备属性 roll；[config]/[numbers] 由 caller 从 `GameRepository` 注入。
  Future<void> chooseReward({
    required String chosenEquipmentDefId,
    required BossGauntletConfig config,
    required NumbersConfig numbers,
    required Rng rng,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final save0 = await _isar.saveDatas.get(0);
    if (save0 == null) throw StateError('断魂庄选奖：无存档');
    final run0 = await _activeRun(save0.id);
    if (run0 == null) return; // 幂等：会话已结算关闭·重入 no-op
    if (run0.sessionPhase != GauntletPhase.awaitingRewardChoice) {
      throw StateError('断魂庄选奖：非奖励选择态（当前 ${run0.sessionPhase.name}）');
    }
    if (!run0.rewardCandidateDefIds.contains(chosenEquipmentDefId)) {
      throw StateError('断魂庄选奖：$chosenEquipmentDefId 不在三选一候选');
    }

    final repo = GameRepository.instance;
    final eqDef = repo.getEquipment(chosenEquipmentDefId);
    final isFirstClear = run0.isFirstClearPending;
    final memberIds = run0.members.map((m) => m.characterId).toList();
    // §6.2：首通全额，重复通关取半。批 B：高周目奖励乘数
    // ×(1+bonus×(cycle-1))（用户拍板 2026-08-04·打更强的敌奖励随之抬）。
    final cycleRewardMult = numbers.cycleEvolution.realmAdvance.rewardMultFor(
      run0.cycleIndex,
    );
    final rewardExp =
        ((isFirstClear
                    ? config.firstClearRewardExp
                    : config.firstClearRewardExp ~/ 2) *
                cycleRewardMult)
            .round();
    final rewardInsight =
        ((isFirstClear
                    ? config.firstClearRewardInsight
                    : config.firstClearRewardInsight ~/ 2) *
                cycleRewardMult)
            .round();

    await _isar.writeTxn(() async {
      final run = await _activeRun(save0.id);
      if (run == null) return; // 幂等
      if (run.sessionPhase != GauntletPhase.awaitingRewardChoice) return;
      final save = (await _isar.saveDatas.get(0))!;
      final alreadyCleared = save.clearedGauntletIds.contains(gauntletId);

      // ① 选中命名装备入背包（owner=null·走标准 roll 路径）。
      final eq = EquipmentFactory.fromDef(
        eqDef,
        rng: rng,
        obtainedAt: at,
        obtainedFrom: UiStrings.gauntletName,
      );
      await _isar.equipments.put(eq);

      // ② 参战全员经验（层锁受发布上限·同远征/闭关口径）+ 领悟点。
      if (rewardExp > 0 || rewardInsight > 0) {
        // 主线进度行以槽号（IsarSetup.currentSlotId）为 saveDataId，
        // SaveData 单例 id=0 永查不到（07-21 审查 P1-5.5）。
        final progress = await _isar.mainlineProgress
            .filter()
            .saveDataIdEqualTo(IsarSetup.currentSlotId)
            .findFirst();
        final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
        for (final id in memberIds) {
          final ch = await _isar.characters.get(id);
          if (ch == null) continue; // §10：找不到角色仍安全结算
          if (rewardExp > 0) {
            CharacterAdvancementService.applyExperience(
              ch,
              rewardExp,
              realmLookup: repo.getRealm,
              isLayerLocked: (tier, layer) =>
                  ProgressionGateService.isLayerLocked(
                    nextTier: tier,
                    nextLayer: layer,
                    releaseCap: numbers.progressionReleaseCap,
                    realmLookup: repo.getRealm,
                    innerDemonDef: numbers.innerDemon,
                    clearedStageIds: clearedSet,
                  ),
            );
          }
          if (rewardInsight > 0) ch.insightPoints += rewardInsight;
          await _isar.characters.put(ch);
        }
      }

      // ③ 首通：解锁秘籍（inline markUnlocked·避嵌套 writeTxn）+ 记首通时间。
      if (isFirstClear && !alreadyCleared) {
        save.skillUnlockProgress = List.of(save.skillUnlockProgress);
        if (!save.skillUnlockProgress.isUnlocked(
          config.firstClearRewardSkillId,
        )) {
          save.skillUnlockProgress.markUnlocked(config.firstClearRewardSkillId);
        }
        save.duanhunFirstClearedAt = at;
      }
      // ④ 记通关（防重键·首通秘籍不重复掉落靠此·§inv5）。
      if (!alreadyCleared) {
        save.clearedGauntletIds = [...save.clearedGauntletIds, gauntletId];
      }
      // ④b 批 B：记已全通最高周目（周目解锁判定读侧·旧档缺失 cycleIndex 读 0 不写）。
      if (run.cycleIndex > save.duanhunClearedCyclesMax) {
        save.duanhunClearedCyclesMax = run.cycleIndex;
      }
      await _isar.saveDatas.put(save);

      // ⑤ 返还托管补给 + 关会话。
      await _returnEscrow(run);
      await _isar.bossGauntletRuns.delete(run.id);
    });
  }

  /// 断魂庄失败结算（§6.3）：战败 / 认输离庄统一入口。单 `writeTxn`——只发「已击败
  /// 精英经验」给全体参战角色（含途中倒下者·层锁受发布上限·同远征/闭关口径）+ 按战末
  /// 快照结算轻/重伤（倒下者重伤·存活者轻伤·不扣永久内力）+ 返还托管补给
  /// （`Loaded-Used`·已用不返）+ 关会话。**不发**装备/秘籍/领悟点/最终奖励、不记
  /// `clearedGauntletIds`、不设保底/每日首胜/登录补偿（§6.3）。幂等：无 active 会话
  /// （已结算）→ no-op。仅 [GauntletPhase.inBattle]（战败）/ [GauntletPhase.interlude]
  /// （认输）可结算；[GauntletPhase.awaitingRewardChoice]（Boss 已胜）应走 [chooseReward]。
  /// [config]/[numbers] 由 caller 从 `GameRepository` 注入。返回失败结算摘要
  /// （[GauntletDefeatSummary]·供 live 战败屏只读展示；结算即删会话故须随带出）。
  /// 幂等 no-op（无存档 / 已结算）→ [GauntletDefeatSummary.empty]。
  Future<GauntletDefeatSummary> settleDefeat({
    required BossGauntletConfig config,
    required NumbersConfig numbers,
    DateTime? now,
    bool applyInjuries = true,
  }) async {
    final save0 = await _isar.saveDatas.get(0);
    if (save0 == null) return GauntletDefeatSummary.empty; // 幂等：无存档
    final run0 = await _activeRun(save0.id);
    if (run0 == null) return GauntletDefeatSummary.empty; // 幂等：已结算·重入 no-op
    if (run0.sessionPhase == GauntletPhase.awaitingRewardChoice) {
      throw StateError(
        '断魂庄失败结算：Boss 已胜（应走 chooseReward·当前 awaitingRewardChoice）',
      );
    }

    // 已击败精英数 = 当前关之前已通关次中 role==elite 计数。inBattle（战败当前关，未
    // 推进·currentStage 指向失败关）与 interlude（认输·currentStage 已指向下一未战关）
    // 两态统一 = `stages.take(currentStage-1)` 中的精英数（§6.2 每精英一份）。
    final elitesDefeated = config.stages
        .take(run0.currentStage - 1)
        .where((s) => s.role == 'elite')
        .length;
    final eliteExp = elitesDefeated * config.eliteRewardExp;
    final memberIds = run0.members.map((m) => m.characterId).toList();
    // 战末快照倒下判定（伤势按此结：倒下者重伤·存活者轻伤·§6.3）。
    final downedById = {
      for (final m in run0.members) m.characterId: m.isDowned,
    };
    // 战败屏摘要成员（名 + 伤势·会话即将删故先建）；名沿整备屏 fallback 口径。
    final summaryMembers = <GauntletDefeatMember>[];
    for (final m in run0.members) {
      final ch = await _isar.characters.get(m.characterId);
      summaryMembers.add(
        GauntletDefeatMember(
          name: ch?.name ?? UiStrings.gauntletMemberFallbackName,
          downed: m.isDowned,
        ),
      );
    }
    final repo = GameRepository.instance;
    final injuryPolicy = AttributeEffectPolicy(numbers.attributeEffects);

    await _isar.writeTxn(() async {
      final run = await _activeRun(save0.id);
      if (run == null) return; // 幂等

      // 精英经验层锁需 cleared 集（仅 eliteExp>0 时查）。
      // 主线进度行以槽号（IsarSetup.currentSlotId）为 saveDataId（P1-5.5）。
      var clearedSet = const <String>{};
      if (eliteExp > 0) {
        final progress = await _isar.mainlineProgress
            .filter()
            .saveDataIdEqualTo(IsarSetup.currentSlotId)
            .findFirst();
        clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
      }

      for (final id in memberIds) {
        final ch = await _isar.characters.get(id);
        if (ch == null) continue; // §10：找不到角色仍安全结算
        // ① 已击败精英经验（含倒下者·层锁·同远征口径）。领悟点/装备/秘籍/最终奖励全失。
        if (eliteExp > 0) {
          CharacterAdvancementService.applyExperience(
            ch,
            eliteExp,
            realmLookup: repo.getRealm,
            isLayerLocked: (tier, layer) =>
                ProgressionGateService.isLayerLocked(
                  nextTier: tier,
                  nextLayer: layer,
                  releaseCap: numbers.progressionReleaseCap,
                  realmLookup: repo.getRealm,
                  innerDemonDef: numbers.innerDemon,
                  clearedStageIds: clearedSet,
                ),
          );
        }
        // ② 正常战败附伤；系统迁移清场显式关闭，避免非玩家失败造成惩罚。
        if (applyInjuries) {
          if (downedById[id] == true) {
            final hours = injuryPolicy.heavyInjuryHours(
              baseHours: numbers.injury.heavyRecoveryHours,
              constitution: ch.attributes.constitution,
            );
            InjuryService.applyHeavyInjury(ch, recoveryHours: hours);
          } else {
            InjuryService.accumulateLightInjury(
              ch,
              maxStacks: numbers.injury.lightMaxStacks,
            );
          }
        }
        await _isar.characters.put(ch);
      }

      // ③ 返还托管补给（已用不返·§6.3）+ 关会话。
      await _returnEscrow(run);
      await _isar.bossGauntletRuns.delete(run.id);
    });

    return GauntletDefeatSummary(
      elitesDefeated: elitesDefeated,
      eliteExpPerMember: eliteExp,
      members: summaryMembers,
    );
  }

  /// 崩溃/重开恢复关次边界（§5.6/§10）。检查点已随会话持久、驱动已原子（C2.3a），
  /// 本方法只判「配置损坏」边界：
  /// - 无 active 会话 → [GauntletRecoveryOutcome.none]；
  /// - 配置对当前关可用 → [GauntletRecoveryOutcome.resumed]（caller 按 `sessionPhase`
  ///   路由；不改会话·断魂帖不重扣·已用补给不返·检查点原值不回满·同流不重抽）；
  /// - 配置损坏（[config] 为空 / 关次越界 / 敌队解析空）+ 第一关前未开战 →
  ///   [GauntletRecoveryOutcome.refundedTicket]（退帖 + 返还托管 + 删会话）；
  /// - 配置损坏 + 已开战 → [GauntletRecoveryOutcome.concedeRequired]（交 C2.5 认输
  ///   结算·保已结算经验不复制补给·本调用不改会话不退帖）。
  Future<GauntletRecoveryOutcome> recover({
    required BossGauntletConfig? config,
  }) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) return GauntletRecoveryOutcome.none;
    final run = await _activeRun(save.id);
    if (run == null) return GauntletRecoveryOutcome.none;
    if (_configUsableForStage(config, run.currentStage)) {
      return GauntletRecoveryOutcome.resumed;
    }
    // 配置损坏：区分「第一关前未开战」（战末快照 maxHp 恒 0·未推进·未离 inBattle）
    // 与「已开战」。
    final hasFought =
        run.currentStage > 1 ||
        run.sessionPhase != GauntletPhase.inBattle ||
        run.members.any((m) => m.maxHp > 0);
    if (hasFought) return GauntletRecoveryOutcome.concedeRequired;
    await _refundTicketAndClose(run);
    return GauntletRecoveryOutcome.refundedTicket;
  }

  /// 配置对指定关次是否可用（非空 / 关次在界 / 敌队解析非空）。
  bool _configUsableForStage(BossGauntletConfig? config, int stage) {
    if (config == null) return false;
    if (stage < 1 || stage > config.stages.length) return false;
    return config
        .enemiesForTeam(config.stages[stage - 1].enemyTeamId)
        .isNotEmpty;
  }

  /// 退帖关会话（§10）：单 `writeTxn` 退回一张断魂帖 + 返还托管补给 + 删会话。
  Future<void> _refundTicketAndClose(BossGauntletRun run) async {
    return _isar.writeTxn(() async {
      final ticket = await _isar.inventoryItems.getByDefId(ticketDefId);
      if (ticket != null) {
        ticket.quantity += 1;
        await _isar.inventoryItems.put(ticket);
      } else {
        final now = DateTime.now();
        await _isar.inventoryItems.put(
          InventoryItem()
            ..defId = ticketDefId
            ..itemType = ItemType.ticket
            ..quantity = 1
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
      await _returnEscrow(run);
      await _isar.bossGauntletRuns.delete(run.id);
    });
  }

  /// 关次稳定种子：会话 [baseSeed] 混当前 [stage]（§5.6·重打同关不重抽·跨关不同流）。
  static int _stageSeed(int baseSeed, int stage) => baseSeed * 31 + stage;

  /// 当前存档的 active 断魂庄会话（provider/UI watch·总览断魂庄卡/整备屏据此路由）。
  /// 无存档/无会话 → null。写路径（enter/fight/choose/settle/close）后由 caller
  /// `ref.invalidate(activeGauntletProvider)` 统一失效。
  Future<BossGauntletRun?> activeRun() async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) return null;
    return _activeRun(save.id);
  }

  /// 当前存档的 active 断魂庄会话（每存档 ≤1，§8.3）；无则 null。
  Future<BossGauntletRun?> _activeRun(int saveId) async {
    final runs = await _isar.bossGauntletRuns.where().findAll();
    for (final r in runs) {
      if (r.saveDataId == saveId) return r;
    }
    return null;
  }

  ActivityMemberSnapshot? _memberOf(BossGauntletRun run, int characterId) {
    for (final m in run.members) {
      if (m.characterId == characterId) return m;
    }
    return null;
  }
}
