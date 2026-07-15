import 'package:isar_community/isar.dart';

import '../../../core/domain/reward_entry.dart';
import '../../activity/domain/activity_member_snapshot.dart';

part 'boss_gauntlet_run.g.dart';

/// 断魂庄会话阶段（§9.2）。`awaitingRewardChoice` = Boss 已胜、待玩家三选一，
/// 崩溃/关闭重进强制恢复到奖励选择页，不再战斗或重抽候选（Q4）。
enum GauntletPhase { inBattle, interlude, awaitingRewardChoice, settled }

/// 断魂庄三连战 active 会话（每存档最多一条，§8.3）。检查点粒度 = 关次边界 + 整备页
/// （v1 不序列化战斗内逐动作，§5.6）。
@collection
class BossGauntletRun {
  Id id = Isar.autoIncrement;

  late int saveDataId;

  /// 稳定随机种子（= 存档标识 + 会话 + 关次派生，§5.6）。
  late int seed;

  /// 当前关次 1..3（1 苏无咎 / 2 石镇岳 / 3 闻九针）。
  int currentStage = 1;

  @enumerated
  GauntletPhase sessionPhase = GauntletPhase.inBattle;

  /// 玩家队伍关次边界快照（生命/真气/阵亡；跨战继承，§5.5）。
  List<ActivityMemberSnapshot> members = [];

  // --- 补给托管栏（Q2 会话托管，三列表平行；不碰普通库存）---
  /// 托管补给 defId（疗伤丹/行囊补给，最多合计 3 份）。
  List<String> escrowItemDefIds = [];

  /// 对应装入数量。
  List<int> escrowLoadedQty = [];

  /// 对应已用数量（≤ 装入数；关闭会话时 装入−已用 原子返还普通库存）。
  List<int> escrowUsedQty = [];

  // --- 最终奖励（Q4）---
  /// 三件命名装备候选 defId；胜利时原子固化，选择前不可重抽。
  List<String> rewardCandidateDefIds = [];

  /// 首通判定快照（胜利时固化，供一次性首通奖励发放）。
  bool isFirstClearPending = false;

  /// 暂存奖励（选定后一次性发放，§9.2）。
  List<RewardEntry> stagedRewards = [];
}
