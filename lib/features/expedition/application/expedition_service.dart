import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:isar_community/isar.dart';

import '../../../core/domain/attribute_effect_policy.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/reward_entry.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../../../shared/battle_shared/cycle_realm_gate.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/application/progression_gate_service.dart';
import '../../injury/application/injury_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../../data/defs/expedition_config.dart';
import '../domain/expedition_rules.dart';
import '../domain/expedition_seed.dart';
import '../domain/expedition_run.dart';
import 'expedition_combat.dart';

/// 百草岭远征应用服务（§4.1/§9.1）。
///
/// A1 冻结 `ExpeditionRun`/`ActivityMemberSnapshot`/`SaveData.expeditionRunSerial`；
/// 本服务负责派遣入场事务（B2.1）。离线分批结算/召回战败见 B2.2/B2.3。
class ExpeditionService {
  const ExpeditionService(this._isar);

  final Isar _isar;

  /// 派遣入场：单 `writeTxn` 校验占用 → 建 [ExpeditionRun] 快照 → `serial++` → put。
  /// 返回落库的 run id；任一校验不过抛 [StateError]，事务回滚。
  ///
  /// 校验（路线 C）：恰好 1 人、不含祖师、成员未被其它活动占用、成员已修
  /// 主修；每存档最多一条 active 远征（§8.3）。成员生命/真气不在派遣期计算——
  /// `currentNode==0` 即「未开战」，B2.2 首战按 `BattleCharacter.fromCharacter`
  /// 满血起，之后写回快照 HP/qi（跨节点继承）。
  ///
  /// `run.seed` 存新 serial（run 稳定标识，B2.2 用作 `ExpeditionRules.generateNode`
  /// 的 runSerial，与 saveDataId + 节点号混合出稳定节点 seed）。
  Future<int> dispatch({
    required List<int> characterIds,
    required ExpeditionPolicy policy,
    int cycleIndex = 1,
    DateTime? now,
  }) async {
    if (characterIds.length != 1) {
      throw StateError('远征派遣：路线 C 只允许单人，got ${characterIds.length}');
    }
    if (characterIds.toSet().length != characterIds.length) {
      throw StateError('远征派遣：队伍含重复角色');
    }
    if (cycleIndex < 1) {
      throw StateError('远征派遣：周目须 ≥1，got $cycleIndex');
    }

    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('远征派遣：无存档');

      final runs = await _isar.expeditionRuns.where().findAll();
      if (runs.any((r) => r.saveDataId == save.id)) {
        throw StateError('远征派遣：已有进行中的远征，需先召回/结束');
      }

      final occupancy = await CharacterOccupancyService(_isar).snapshot();
      final members = <ActivityMemberSnapshot>[];
      var entryMaxTier = RealmTier.xueTu;
      for (final cid in characterIds) {
        final c = await _isar.characters.get(cid);
        if (c == null) throw StateError('远征派遣：角色 $cid 不存在');
        if (!c.isAlive) {
          throw StateError('expedition_dispatch_character_dead:$cid');
        }
        if (c.isFounder) throw StateError('远征派遣：祖师不可派遣');
        if (c.realmTier.index > entryMaxTier.index) entryMaxTier = c.realmTier;
        if (occupancy.isCharacterOccupied(cid)) {
          throw StateError('远征派遣：角色 $cid 已被其它活动占用');
        }
        final mainTechId = c.mainTechniqueId;
        if (mainTechId == null) {
          throw StateError('远征派遣：角色 $cid 未修主修，不可派遣');
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

      // 批 B：周目解锁门槛硬守卫（深度里程碑折算「已通」+ 境界门槛，
      // 2026-08-04 拍板：远征无终点，解锁改绑历史最深 baicaoMaxDepth）。
      if (cycleIndex > 1) {
        final config = GameRepository.instance.expeditionConfig;
        if (config == null) {
          throw StateError('远征派遣：无远行配置，不可挑战高周目');
        }
        final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
        final unlocked = CycleRealmGate.unlockedCycleCap(
          clearedCyclesMax: CycleRealmGate.expeditionClearedEquivalent(
            maxDepth: save.baicaoMaxDepth,
            milestones: ra.expeditionDepthMilestones,
          ),
          playerMaxTier: entryMaxTier,
          baseEnemyMaxTier: CycleRealmGate.maxEnemyTierOf([
            for (final t in config.normalEnemyTeams) ...t.enemies,
            for (final t in config.eliteEnemyTeams) ...t.enemies,
          ]),
          ra: ra,
        );
        if (cycleIndex > unlocked) {
          throw StateError('远征派遣：周目 $cycleIndex 未解锁（当前可挑战至 $unlocked）');
        }
      }

      final newSerial = save.expeditionRunSerial + 1;
      save.expeditionRunSerial = newSerial;

      final run = ExpeditionRun()
        ..saveDataId = save.id
        ..policy = policy
        ..seed = newSerial
        ..departedAt = now ?? DateTime.now()
        ..lastSettledAt = null
        ..currentNode = 0
        ..cycleIndex = cycleIndex
        ..members = members
        ..stagedRewards = [];

      await _isar.saveDatas.put(save);
      return _isar.expeditionRuns.put(run);
    });
  }

  /// 单批离线结算允许的最大节点数（禁数十节点一事务，§4.4）。
  // TODO(batch3-probe): 探针定案后可下沉 expeditions.yaml。
  static const int defaultMaxNodesPerBatch = 24;

  /// 批 B：高周目奖励乘数（×(1+bonus×(cycle-1))，用户拍板 2026-08-04）。
  /// cycle≤1 恒等短路且**不读全局配置**——轻量 fake-combat 结算测不加载
  /// GameRepository，结算路径读 config 会崩（memory
  /// feedback_battle_result_path_config_read_crashes_light_test 同模式）。
  /// 2026-08-05 拍板候选 a:exp/internal_force 是连续量按比例 round;其余
  /// rewardKey 为整件发放的物品/装备 defId,round 会把小数量吞成零增益
  /// (帖/药草 1×1.25→1,cycle2 白打),改 ceil 保证周目加成对整数件永不空转。
  @visibleForTesting
  static List<RewardEntry> scaleRewardsForCycle(
    List<RewardEntry> rewards,
    int cycleIndex,
  ) {
    if (cycleIndex <= 1) return rewards;
    final mult = GameRepository.instance.numbers.cycleEvolution.realmAdvance
        .rewardMultFor(cycleIndex);
    if (mult == 1.0) return rewards;
    return [
      for (final r in rewards)
        RewardEntry()
          ..rewardKey = r.rewardKey
          ..quantity = _isContinuousReward(r.rewardKey)
              ? (r.quantity * mult).round()
              : (r.quantity * mult).ceil(),
    ];
  }

  /// exp/内力是连续量;其余 rewardKey(item/equipment defId)按整件发放。
  static bool _isContinuousReward(String rewardKey) =>
      rewardKey == 'exp' || rewardKey == 'internal_force';

  /// 离线分批幂等结算（§4.4/§9.1，本 feature 最难点）。
  ///
  /// 节点完成时刻按 `departedAt + 累计节点时长` 绝对锚定，故推进是
  /// `(run 状态, now)` 的确定函数：**在线分段 == 一次性离线**、重复调用**幂等**
  /// （已完成节点不再兑现）自然成立。单批最多 [maxNodesPerBatch] 个节点一事务；
  /// 战败即停；系统时间回拨以 `max(lastSettledAt, now)` 处理不产生负进度。
  Future<ExpeditionSettlementResult> settle({
    required ExpeditionCombat combat,
    required ExpeditionConfig config,
    DateTime? now,
    int maxNodesPerBatch = defaultMaxNodesPerBatch,
    @visibleForTesting Future<void> Function()? beforeCommitForTest,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final run = await _activeRun();
    if (run == null) {
      return const ExpeditionSettlementResult(
        nodesSettled: 0,
        currentNode: 0,
        caughtUp: true,
        defeated: false,
      );
    }

    final startNode = run.currentNode;
    // 战败持久态（§4.2 战败即停，07-22 审查 P1-5.2）：已战败 run 不再
    // 推进/重战，停留待召回；recall 凭落库的 defeated 兑现战败伤势，
    // 不依赖跨启动后确定性重战碰巧复现同一败局。
    if (run.defeated) {
      return ExpeditionSettlementResult(
        nodesSettled: 0,
        currentNode: startNode,
        caughtUp: true,
        defeated: true,
      );
    }
    final anchor = run.lastSettledAt ?? run.departedAt;
    final clampedNow = effectiveNow.isBefore(anchor) ? anchor : effectiveNow;
    final elapsed = clampedNow.difference(run.departedAt).inMinutes;
    final targetNode = _completedNodesBy(elapsed, config);
    if (targetNode <= startNode) {
      return ExpeditionSettlementResult(
        nodesSettled: 0,
        currentNode: startNode,
        caughtUp: true,
        defeated: false,
      );
    }

    // 成员工作副本（fresh: currentNode==0 → 满血起）。
    final caps = await combat.memberCaps(
      run.members.map((m) => m.characterId).toList(),
    );
    final fresh = startNode == 0;
    final vitals = <int, ExpeditionMemberVital>{};
    final downed = <int, bool>{};
    for (final m in run.members) {
      final cap = caps[m.characterId];
      vitals[m.characterId] = ExpeditionMemberVital(
        hp: fresh ? (cap?.maxHp ?? 0) : m.currentHp,
        qi: fresh ? (cap?.maxQi ?? 0) : m.currentQi,
      );
      downed[m.characterId] = fresh ? false : m.isDowned;
    }

    // 单批上限：本次最多结算 maxNodesPerBatch 个节点，余下 elapsed 留下批。
    final batchEnd = (startNode + maxNodesPerBatch < targetNode)
        ? startNode + maxNodesPerBatch
        : targetNode;

    // txn 外逐节点跑规则 + 战斗，攒本批增量。
    final newRewards = <RewardEntry>[];
    var node = startNode;
    var defeated = false;
    while (node < batchEnd) {
      final index = node + 1;
      final genNode = ExpeditionRules.generateNode(
        saveId: run.saveDataId,
        runSerial: run.seed,
        node: index,
        policy: run.policy,
        normalMinutes: config.normalNodeMinutes,
        eliteMinutes: config.eliteNodeMinutes,
      );
      if (genNode.isBattle) {
        final alive = <int, ExpeditionMemberVital>{
          for (final e in vitals.entries)
            if (!(downed[e.key] ?? false)) e.key: e.value,
        };
        final outcome = await combat.fight(
          node: genNode,
          memberStates: alive,
          nodeSeed: ExpeditionSeed.forNode(
            saveId: run.saveDataId,
            runSerial: run.seed,
            node: index,
          ),
          cycleIndex: run.cycleIndex,
        );
        outcome.survivorHp.forEach((id, hp) {
          vitals[id] = ExpeditionMemberVital(
            hp: hp,
            qi: outcome.survivorQi[id] ?? vitals[id]?.qi ?? 0,
          );
          if (hp <= 0) downed[id] = true;
        });
        if (!outcome.leftWin) {
          // 战败即停（§4.2）：失败节点无奖励、不计入 currentNode，停止后续节点。
          defeated = true;
          break;
        }
      }
      _applyRecovery(vitals, downed, caps, config, deepestCompletedNode: index);
      _mergeRewards(
        newRewards,
        scaleRewardsForCycle(
          ExpeditionRules.rewardsForNode(
            node: genNode,
            saveId: run.saveDataId,
            runSerial: run.seed,
            baseExpPerBattle: config.baseExpPerBattle,
          ),
          run.cycleIndex,
        ),
      );
      node = index;
    }

    final settledCount = node - startNode;

    // 测试钩子：模拟提交前的并发推进（生产恒 null）。
    await beforeCommitForTest?.call();

    var committed = false;
    await _isar.writeTxn(() async {
      final row = await _isar.expeditionRuns.get(run.id);
      if (row == null) return;
      // cursor 守卫（§4.4.3）：提交前校验 run 未被并发推进；被改则弃本批，
      // 交外层重试，避免把过期批结果覆盖到更新状态上（重复发奖/回退进度）。
      if (row.currentNode != startNode ||
          row.lastSettledAt != run.lastSettledAt) {
        return;
      }
      row.currentNode = node;
      row.lastSettledAt = clampedNow;
      if (defeated) row.defeated = true; // 战败即停落库（P1-5.2）
      for (final m in row.members) {
        final v = vitals[m.characterId];
        if (v != null) {
          m.currentHp = v.hp;
          m.currentQi = v.qi;
          m.isDowned = downed[m.characterId] ?? m.isDowned;
        }
      }
      // Isar 读回的 list 为 fixed-length，合并须走 growable 副本再回写。
      final mergedRewards = List<RewardEntry>.from(row.stagedRewards);
      _mergeRewards(mergedRewards, newRewards);
      row.stagedRewards = mergedRewards;
      await _isar.expeditionRuns.put(row);
      committed = true;
    });

    if (!committed) {
      return ExpeditionSettlementResult(
        nodesSettled: 0,
        currentNode: startNode,
        caughtUp: false,
        defeated: false,
      );
    }

    return ExpeditionSettlementResult(
      nodesSettled: settledCount,
      currentNode: node,
      caughtUp: defeated || node >= targetNode,
      defeated: defeated,
    );
  }

  /// 循环分批结算追平到 [now]（每批一事务、分帧让出的批间由 caller 控）。
  ///
  /// 单次 [settle] 最多推进 `maxNodesPerBatch` 个节点；本方法循环驱动至追平或
  /// 战败，返回聚合结果（`nodesSettled` 为累计）。[maxBatches] 兜底防病态自旋。
  Future<ExpeditionSettlementResult> settleToNow({
    required ExpeditionCombat combat,
    required ExpeditionConfig config,
    DateTime? now,
    int maxNodesPerBatch = defaultMaxNodesPerBatch,
    int maxBatches = 4096,
  }) async {
    var total = 0;
    var last = const ExpeditionSettlementResult(
      nodesSettled: 0,
      currentNode: 0,
      caughtUp: true,
      defeated: false,
    );
    for (var i = 0; i < maxBatches; i++) {
      final r = await settle(
        combat: combat,
        config: config,
        now: now,
        maxNodesPerBatch: maxNodesPerBatch,
      );
      total += r.nodesSettled;
      last = r;
      if (r.caughtUp) break;
      if (r.nodesSettled == 0) break; // 无进展（并发弃批）→ 不空转
    }
    return ExpeditionSettlementResult(
      nodesSettled: total,
      currentNode: last.currentNode,
      caughtUp: last.caughtUp,
      defeated: last.defeated,
    );
  }

  /// 召回 / 战败返程单事务（§4.6/§9.1）。
  ///
  /// 同一 `writeTxn`：发 `stagedRewards`（全员含途中倒下者得完成节点经验 §4.6）+
  /// 结算伤势（战败时倒下者重伤、其余轻伤；召回不附伤）+ 删 `ExpeditionRun`
  /// 关闭会话（占用由 active run 派生 → 自动解除、角色释放）。失败节点不在
  /// `stagedRewards`（settle 战败即停未暂存），故「失败节点无奖励」自然成立。
  /// 经验受发布上限层锁门禁（同闭关口径），超阶留账不消费。
  ///
  /// 战败判定 = 传入 [defeated]（同会话 settle 刚报败）∨ run 落库的
  /// `defeated`（P1-5.2 持久态，跨启动不丢）；二者任一即按战败返程。
  ///
  /// 并发守卫（07-21 审查 P1-5.4）：事务内重读 run 并校验 cursor
  /// （`currentNode`/`lastSettledAt` 与事务外快照一致）。run 已被并发召回删除
  /// → 放弃本次调用（不重复发奖）；被并发 settle 推进 → 同样放弃（避免按过期
  /// 快照发奖后把新暂存随 run 一并删掉）。放弃时返回 `returned:false`，
  /// 调用方（UI 已防重）可安全重试。
  Future<ExpeditionReturnResult> recall({
    bool defeated = false,
    DateTime? now,
    @visibleForTesting Future<void> Function()? beforeCommitForTest,
  }) async {
    final run = await _activeRun();
    if (run == null) {
      return const ExpeditionReturnResult(
        returned: false,
        deepestNode: 0,
        grantedRewards: [],
        downedCount: 0,
        defeated: false,
      );
    }

    final at = now ?? DateTime.now();
    final deepest = run.currentNode;
    // 战败 = 调用方传入 ∨ 落库持久态（P1-5.2：settle 战败已写 run.defeated，
    // 跨启动召回不再依赖调用方记得传参）。
    final isDefeated = defeated || run.defeated;
    final memberIds = run.members.map((m) => m.characterId).toList();
    final downedIds = run.members
        .where((m) => m.isDowned)
        .map((m) => m.characterId)
        .toSet();
    // 快照暂存奖励（脱离 Isar fixed-length list）。
    final granted = <RewardEntry>[
      for (final e in run.stagedRewards)
        RewardEntry()
          ..rewardKey = e.rewardKey
          ..quantity = e.quantity,
    ];

    final numbers = GameRepository.instance.numbers;
    final stagedExp = granted.quantityOf('exp');

    // 测试钩子：模拟事务提交前的并发召回/推进（生产恒 null）。
    await beforeCommitForTest?.call();

    var raced = false;
    await _isar.writeTxn(() async {
      // 并发重读 + cursor 守卫：不一致即弃，事务回滚零副作用。
      final row = await _isar.expeditionRuns.get(run.id);
      if (row == null ||
          row.currentNode != run.currentNode ||
          row.lastSettledAt != run.lastSettledAt) {
        raced = true;
        return;
      }
      // 1. 全员发经验（含途中倒下者）+ 战败伤势。
      // 主线进度行以槽号（IsarSetup.currentSlotId，1-3）为 saveDataId
      // （mainline_providers/stage_entry_flow 口径）；run.saveDataId 是
      // SaveData 单例 id=0，仅作 run 归属与种子用，二者不可混查
      // （07-21 审查 P1-5.5：误用 run.saveDataId 导致生产永远查空、
      // 层锁门禁按未通关误判）。
      final progress = await _isar.mainlineProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
      for (final id in memberIds) {
        final ch = await _isar.characters.get(id);
        if (ch == null) continue; // §10：找不到角色仍安全结算，不悬挂会话
        if (stagedExp > 0) {
          CharacterAdvancementService.applyExperience(
            ch,
            stagedExp,
            realmLookup: GameRepository.instance.getRealm,
            isLayerLocked: (tier, layer) =>
                ProgressionGateService.isLayerLocked(
                  nextTier: tier,
                  nextLayer: layer,
                  releaseCap: numbers.progressionReleaseCap,
                  realmLookup: GameRepository.instance.getRealm,
                  innerDemonDef: numbers.innerDemon,
                  clearedStageIds: clearedSet,
                ),
          );
        }
        if (isDefeated) {
          // §4.6：倒下者重伤、其余轻伤；召回不进此分支（不附伤）。
          if (downedIds.contains(id)) {
            final hours = AttributeEffectPolicy(numbers.attributeEffects)
                .heavyInjuryHours(
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

      // 2. 发暂存物品到背包（exp 已发，跳过）。
      for (final r in granted) {
        if (r.rewardKey == 'exp' || r.quantity <= 0) continue;
        final existing = await _isar.inventoryItems.getByDefId(r.rewardKey);
        if (existing != null) {
          existing.quantity += r.quantity;
          existing.lastObtainedAt = at;
          await _isar.inventoryItems.put(existing);
        } else {
          await _isar.inventoryItems.put(
            InventoryItem()
              ..defId = r.rewardKey
              ..itemType = ItemType.fromDefId(r.rewardKey)
              ..quantity = r.quantity
              ..firstObtainedAt = at
              ..lastObtainedAt = at,
          );
        }
      }

      // 3. 关闭会话：删 run → 占用自动解除（占用由 active run 派生）。
      await _isar.expeditionRuns.delete(run.id);

      // 4. 永久进度：百草岭历史最深节点（展示用 §3.3，07-21 审查 P1-5.7；
      // max 单调不回退）。
      final save = await _isar.saveDatas.get(0);
      if (save != null && deepest > save.baicaoMaxDepth) {
        save.baicaoMaxDepth = deepest;
        await _isar.saveDatas.put(save);
      }
    });

    if (raced) {
      // 并发冲突：未发任何奖励、run 未动；调用方可重试。
      return const ExpeditionReturnResult(
        returned: false,
        deepestNode: 0,
        grantedRewards: [],
        downedCount: 0,
        defeated: false,
      );
    }

    return ExpeditionReturnResult(
      returned: true,
      deepestNode: deepest,
      grantedRewards: granted,
      downedCount: downedIds.length,
      defeated: isDefeated,
    );
  }

  /// 当前 active 远征（供 provider/UI 读；无 → null）。
  Future<ExpeditionRun?> activeRun() => _activeRun();

  /// active 远征（每存档最多一条）。
  Future<ExpeditionRun?> _activeRun() async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) return null;
    final runs = await _isar.expeditionRuns.where().findAll();
    for (final r in runs) {
      if (r.saveDataId == save.id) return r;
    }
    return null;
  }

  /// `departedAt → clampedNow` 已完成节点数：累计节点时长 ≤ elapsed 的最大节点。
  static int _completedNodesBy(int elapsedMinutes, ExpeditionConfig config) {
    if (elapsedMinutes <= 0) return 0;
    var cumulative = 0;
    var node = 0;
    while (true) {
      final next = node + 1;
      final dur = ExpeditionRules.nodeDurationMinutes(
        next,
        normalMinutes: config.normalNodeMinutes,
        eliteMinutes: config.eliteNodeMinutes,
      );
      if (cumulative + dur > elapsedMinutes) break;
      cumulative += dur;
      node = next;
    }
    return node;
  }

  /// 节点完成后存活成员恢复（§4.5），瘴蚀按最深节点递减恢复效果。
  static void _applyRecovery(
    Map<int, ExpeditionMemberVital> vitals,
    Map<int, bool> downed,
    Map<int, ExpeditionMemberCaps> caps,
    ExpeditionConfig config, {
    required int deepestCompletedNode,
  }) {
    final layers = ExpeditionRules.zhangshiLayers(deepestCompletedNode);
    final mult = ExpeditionRules.recoveryMultiplier(
      layers,
      perLayer: config.zhangshiPctPerLayer,
    );
    for (final id in vitals.keys.toList()) {
      if (downed[id] ?? false) continue; // 倒下者不恢复
      final cap = caps[id];
      if (cap == null) continue;
      final v = vitals[id]!;
      final hp = (v.hp + cap.maxHp * config.hpRecoverPctPerNode * mult)
          .round()
          .clamp(0, cap.maxHp);
      final qi = (v.qi + cap.maxQi * config.qiRecoverPctPerNode * mult)
          .round()
          .clamp(0, cap.maxQi);
      vitals[id] = ExpeditionMemberVital(hp: hp, qi: qi);
    }
  }

  /// 按 rewardKey 累加合并到 [into]。
  static void _mergeRewards(List<RewardEntry> into, List<RewardEntry> add) {
    for (final r in add) {
      final existing = into.firstWhere(
        (e) => e.rewardKey == r.rewardKey,
        orElse: () {
          final n = RewardEntry()
            ..rewardKey = r.rewardKey
            ..quantity = 0;
          into.add(n);
          return n;
        },
      );
      existing.quantity += r.quantity;
    }
  }
}

/// 单批离线结算结果（B2.2）。
class ExpeditionSettlementResult {
  const ExpeditionSettlementResult({
    required this.nodesSettled,
    required this.currentNode,
    required this.caughtUp,
    required this.defeated,
  });

  /// 本批完成节点数。
  final int nodesSettled;

  /// 结算后已完成节点数（= `ExpeditionRun.currentNode`）。
  final int currentNode;

  /// 已追平 `now`（无更多可结算节点）或已战败 → 外层循环可停。
  final bool caughtUp;

  /// 战败即停（§4.2）。
  final bool defeated;
}

/// 召回 / 战败返程结果（B2.3）。
class ExpeditionReturnResult {
  const ExpeditionReturnResult({
    required this.returned,
    required this.deepestNode,
    required this.grantedRewards,
    required this.downedCount,
    required this.defeated,
  });

  /// 有 active 远征被返程关闭；false = 无远征、无操作。
  final bool returned;

  /// 最深完成节点（= 返程时 `currentNode`）。
  final int deepestNode;

  /// 本次发放的暂存奖励（完成节点累计）。
  final List<RewardEntry> grantedRewards;

  /// 倒下成员数（战败伤势结算依据）。
  final int downedCount;

  /// 是否战败返程（true）或主动召回（false）。
  final bool defeated;
}
