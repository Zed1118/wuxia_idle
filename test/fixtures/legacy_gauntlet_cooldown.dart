import 'package:isar_community/isar.dart';

part 'legacy_gauntlet_cooldown.g.dart';

/// 冻结 0f2b85b2075661146c628aaf60ad5a033101f1d4 的完整断魂庄持久 schema。
/// 仅 Dart 类型名不同；磁盘上确实缺少三个 Phase 0A 秒制字段，
/// 两个嵌入 schema 及所有旧字段均保持原样。
enum LegacyGauntletCooldownPhase {
  inBattle,
  interlude,
  awaitingRewardChoice,
  settled,
}

@collection
@Name('BossGauntletRun')
class LegacyGauntletCooldownRun {
  Id id = Isar.autoIncrement;
  late int saveDataId;
  late int seed;
  bool cycleSeedEnabled = false;
  int currentStage = 1;
  int cycleIndex = 1;
  @enumerated
  LegacyGauntletCooldownPhase sessionPhase =
      LegacyGauntletCooldownPhase.inBattle;
  List<LegacyGauntletCooldownMember> members = [];
  List<String> escrowItemDefIds = [];
  List<int> escrowLoadedQty = [];
  List<int> escrowUsedQty = [];
  List<String> rewardCandidateDefIds = [];
  bool isFirstClearPending = false;
  List<LegacyGauntletCooldownReward> stagedRewards = [];
}

@embedded
@Name('ActivityMemberSnapshot')
class LegacyGauntletCooldownMember {
  int characterId = 0;
  List<int> reservedEquipmentIds = [];
  List<int> reservedTechniqueIds = [];
  int currentHp = 0;
  int currentQi = 0;
  bool isDowned = false;
  int maxHp = 0;
  int maxQi = 0;
  List<String> skillCooldownKeys = [];
  List<int> skillCooldownTurns = [];
}

@embedded
@Name('RewardEntry')
class LegacyGauntletCooldownReward {
  String rewardKey = '';
  int quantity = 0;
}
