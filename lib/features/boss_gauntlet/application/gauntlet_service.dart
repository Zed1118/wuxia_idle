import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/item_def.dart';
import '../../../data/numbers_config.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../domain/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import 'gauntlet_battle_runner.dart';
import 'gauntlet_controller.dart';

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

  /// 入场：单 `writeTxn` 建断魂庄 active 会话，返回落库的 run id。
  ///
  /// [supplies] = defId → 份数（疗伤丹/行囊补给自由混装），总份数 ≤ [supplyCap]。
  Future<int> enter({
    required List<int> characterIds,
    Map<String, int> supplies = const {},
    required int supplyCap,
  }) async {
    if (characterIds.isEmpty || characterIds.length > 3) {
      throw StateError('断魂庄入场：队伍须 1-3 人，got ${characterIds.length}');
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
      for (final cid in characterIds) {
        final c = await _isar.characters.get(cid);
        if (c == null) throw StateError('断魂庄入场：角色 $cid 不存在');
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
      for (var i = 0; i < run.escrowItemDefIds.length; i++) {
        final remaining = run.escrowLoadedQty[i] - run.escrowUsedQty[i];
        if (remaining <= 0) continue;
        final defId = run.escrowItemDefIds[i];
        final existing = await _isar.inventoryItems.getByDefId(defId);
        if (existing != null) {
          existing.quantity += remaining;
          await _isar.inventoryItems.put(existing);
        } else {
          // 防御：入场保留了库存行（可能 qty=0）；若缺则据 ItemDef 重建。
          final def = itemDefs[defId];
          if (def == null) {
            throw StateError('断魂庄关闭：补给 $defId 库存行缺失且无 ItemDef 重建');
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
      await _isar.bossGauntletRuns.delete(run.id);
    });
  }

  /// 单场战斗驱动：驱动当前关次一场 headless 战斗并原子推进会话（C2.3a·§5.6/§9.2）。
  ///
  /// load run → 从会话成员建满血基准队（`buildPlayerTeamForCharacters` 真生产路径：
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

    // 满血基准队（真生产路径）→ 按会话快照装配本关出战队（事务外·纯计算）。
    final memberIds = run.members.map((m) => m.characterId).toList();
    final baseTeam = await StageBattleSetup(
      isar: _isar,
    ).buildPlayerTeamForCharacters(memberIds);
    final playerTeam = GauntletController.stagePlayerTeam(
      baseTeam: baseTeam,
      members: run.members,
    );
    final result = GauntletBattleRunner.runStage(
      playerTeam: playerTeam,
      enemyDefs: enemyDefs,
      numbers: numbers,
      seed: _stageSeed(run.seed, run.currentStage),
    );
    final isBoss = stageCfg.role == 'boss';

    // 单事务原子推进：re-load fresh → advance → put（战斗结果一次落地）。
    await _isar.writeTxn(() async {
      final fresh = await _activeRun(save.id);
      if (fresh == null) return; // 防御：会话已被并发关闭
      GauntletController.advance(
        run: fresh,
        finalState: result.finalState,
        isBossStage: isBoss,
      );
      await _isar.bossGauntletRuns.put(fresh);
    });
    return result;
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

  /// 关次稳定种子：会话 [baseSeed] 混当前 [stage]（§5.6·重打同关不重抽·跨关不同流）。
  static int _stageSeed(int baseSeed, int stage) => baseSeed * 31 + stage;

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
