import '../../activity/domain/activity_member_snapshot.dart';
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

  /// Phase 0A 单角色终态检查点推进。只消费已归一化的生命/真气事实，
  /// 不让战斗引擎状态进入会话事务层。
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
  /// caller 在关次推进之后于同一事务内调用。
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
