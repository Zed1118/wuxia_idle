import '../../activity/domain/activity_member_snapshot.dart';
import '../../battle/domain/battle_state.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';

/// 断魂庄三关编排控制器（design §5.2-5.5）。
///
/// C1.2：关次边界白名单快照。一场战斗结束后，把玩家队伍战末态并入成员快照供下一关
/// 重建；**白名单只继承** 当前生命/当前真气/阵亡/技能冷却（§5.5）。行动条、临时
/// buff/debuff、护盾、召唤、内伤槽、敌方状态等**不进快照**——下一关按快照重建战斗时
/// 自然清空（§4.2）。reserved 装备/心法为入场占用冻结，从上一关 [before] 原样保留
/// （战斗态不含这两列）。
class GauntletController {
  const GauntletController._();

  /// 按 characterId 把 [finalState] 左队战末态并入 [before]，返回下一关边界快照。
  ///
  /// 白名单：`currentHp` / `currentQi` / `isDowned` / 技能冷却（仅 CD>0 项）。
  static List<ActivityMemberSnapshot> snapshotAfterStage({
    required List<ActivityMemberSnapshot> before,
    required BattleState finalState,
  }) {
    return [
      for (final prior in before)
        _mergeMember(prior, finalState.characterById(prior.characterId)),
    ];
  }

  /// 关次快照 → 本关玩家出战队（C2.3a·[snapshotAfterStage] 的逆向）。
  ///
  /// [baseTeam] = `StageBattleSetup.buildExactPlayerTeam` 满血基准队；按会话
  /// [members] 快照装配本关出战队：
  /// - `member.maxHp==0`（enter 占位·首关无检查点）→ 保满血基准，不覆盖；
  /// - `maxHp>0`（关次间有战末检查点）→ `copyWith` 覆盖当前生命/真气/技能冷却；
  /// - 阵亡（`isDowned`）或血尽（`currentHp<=0`）→ 剔除（残阵只带存活者·§5.5，
  ///   镜像 `ExpeditionCombatRunner.fight`）。
  /// 迭代以 [baseTeam] 为准；无对应 member 的角色跳过（防御）。纯函数。
  static List<BattleCharacter> stagePlayerTeam({
    required List<BattleCharacter> baseTeam,
    required List<ActivityMemberSnapshot> members,
  }) {
    final byId = {for (final m in members) m.characterId: m};
    final team = <BattleCharacter>[];
    for (final c in baseTeam) {
      final m = byId[c.characterId];
      if (m == null) continue; // 非会话成员（防御）
      if (m.maxHp == 0) {
        team.add(c); // 首关无检查点·满血基准
        continue;
      }
      if (m.isDowned || m.currentHp <= 0) continue; // 残阵只带存活者
      team.add(
        c.copyWith(
          currentHp: m.currentHp,
          currentQi: m.currentQi,
          skillCooldowns: _cooldownMap(m),
        ),
      );
    }
    return team;
  }

  static Map<String, int> _cooldownMap(ActivityMemberSnapshot m) {
    final map = <String, int>{};
    for (var i = 0; i < m.skillCooldownKeys.length; i++) {
      map[m.skillCooldownKeys[i]] = m.skillCooldownTurns[i];
    }
    return map;
  }

  /// 消费当前关战末态 [finalState]：关次边界快照继承 + 推进一关（§9.2）。
  ///
  /// 胜利非终关 → [GauntletPhase.interlude] 停整备 + `currentStage++`（不自动连打，
  /// 玩家在整备页点「继续闯关」才由 service 开下一关）；胜利终关（[isBossStage]）→
  /// [GauntletPhase.awaitingRewardChoice]（待三选一，Q4）；败/平 → 不推进、停当前关
  /// （`sessionPhase`/`currentStage` 不变），失败结算归 C2.5，但仍写战末快照供结伤/给经验。
  ///
  /// [isBossStage] 由 caller 从 `BossGauntletConfig.stages[currentStage-1].role == 'boss'`
  /// 判定（保持本编排纯 + 与配置解耦）。Isar 持久化归 caller 事务（§9.2）。
  static void advance({
    required BossGauntletRun run,
    required BattleState finalState,
    required bool isBossStage,
  }) {
    // 无论胜负都记战末快照（失败结算据此结伤/给经验）。
    run.members = snapshotAfterStage(
      before: run.members,
      finalState: finalState,
    );
    if (finalState.result != BattleResult.leftWin) {
      // 败/平：不推进，停当前关（sessionPhase 留 inBattle），失败结算归 C2.5。
      return;
    }
    if (isBossStage) {
      run.sessionPhase = GauntletPhase.awaitingRewardChoice;
    } else {
      run.currentStage += 1;
      run.sessionPhase = GauntletPhase.interlude;
    }
  }

  /// Phase 0A 单角色终态检查点推进。会话/奖励相位语义与 [advance] 完全一致，
  /// 仅把引擎专属终态换成已归一化的生命/真气检查点。
  static void advancePhase0a({
    required BossGauntletRun run,
    required GauntletMemberCheckpoint checkpoint,
    required bool leftWin,
    required bool isBossStage,
  }) {
    run.members = [_mergeCheckpoint(run.members.single, checkpoint)];
    if (!leftWin) return;
    if (isBossStage) {
      run.sessionPhase = GauntletPhase.awaitingRewardChoice;
    } else {
      run.currentStage += 1;
      run.sessionPhase = GauntletPhase.interlude;
    }
  }

  /// Boss 胜利固化奖励（C2.4b·§9.2）：进入 [GauntletPhase.awaitingRewardChoice] 时把
  /// [config] 三选一命名装备候选固化进 [run]（选择前不可重抽）+ 记首通判定
  /// （[alreadyCleared]＝`SaveData.clearedGauntletIds` 是否已含本副本）。非该相位 no-op。
  /// caller（`GauntletService.fightCurrentStage`）在 advance 之后于同一事务内调用。
  static void stageBossReward({
    required BossGauntletRun run,
    required BossGauntletConfig config,
    required bool alreadyCleared,
  }) {
    if (run.sessionPhase != GauntletPhase.awaitingRewardChoice) return;
    run.rewardCandidateDefIds = List<String>.from(
      config.rewardCandidateEquipmentIds,
    );
    run.isFirstClearPending = !alreadyCleared;
  }

  static ActivityMemberSnapshot _mergeMember(
    ActivityMemberSnapshot prior,
    BattleCharacter? combatant,
  ) {
    final next = ActivityMemberSnapshot()
      ..characterId = prior.characterId
      // 占用冻结：reserved 从入场保留，战斗 finalState 不含这两列。
      ..reservedEquipmentIds = List<int>.from(prior.reservedEquipmentIds)
      ..reservedTechniqueIds = List<int>.from(prior.reservedTechniqueIds);

    if (combatant == null) {
      // 防御：finalState 缺该角色 → 保留上一关关次边界值，不凭空回满/清零。
      return next
        ..currentHp = prior.currentHp
        ..currentQi = prior.currentQi
        ..maxHp = prior.maxHp
        ..maxQi = prior.maxQi
        ..isDowned = prior.isDowned
        ..skillCooldownKeys = List<String>.from(prior.skillCooldownKeys)
        ..skillCooldownTurns = List<int>.from(prior.skillCooldownTurns);
    }

    final keys = <String>[];
    final turns = <int>[];
    combatant.skillCooldowns.forEach((skillId, cd) {
      if (cd > 0) {
        keys.add(skillId);
        turns.add(cd);
      }
    });

    return next
      ..currentHp = combatant.currentHp
      ..currentQi = combatant.currentQi
      ..maxHp = combatant.maxHp
      ..maxQi = combatant.maxQi
      ..isDowned = !combatant.isAlive
      ..skillCooldownKeys = keys
      ..skillCooldownTurns = turns;
  }

  static ActivityMemberSnapshot _mergeCheckpoint(
    ActivityMemberSnapshot prior,
    GauntletMemberCheckpoint checkpoint,
  ) => ActivityMemberSnapshot()
    ..characterId = prior.characterId
    ..reservedEquipmentIds = List<int>.from(prior.reservedEquipmentIds)
    ..reservedTechniqueIds = List<int>.from(prior.reservedTechniqueIds)
    ..currentHp = checkpoint.currentHp
    ..currentQi = checkpoint.currentQi
    ..maxHp = checkpoint.maxHp
    ..maxQi = checkpoint.maxQi
    ..isDowned = checkpoint.currentHp <= 0
    ..skillCooldownKeys = List<String>.from(prior.skillCooldownKeys)
    ..skillCooldownTurns = List<int>.from(prior.skillCooldownTurns);
}

/// Phase 0A 与断魂庄会话之间的最小关次边界事实。
final class GauntletMemberCheckpoint {
  const GauntletMemberCheckpoint({
    required this.characterId,
    required this.currentHp,
    required this.currentQi,
    required this.maxHp,
    required this.maxQi,
  });

  final int characterId;
  final int currentHp;
  final int currentQi;
  final int maxHp;
  final int maxQi;
}
