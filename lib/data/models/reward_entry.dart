import 'package:isar/isar.dart';

part 'reward_entry.g.dart';

/// 奖励条目（data_schema.md §3.5）。
///
/// 嵌入在 `RetreatSession.estimatedRewards` / `actualRewards` 中。
/// rewardKey 可为 `exp` / `internal_force` / item defId / equipment defId。
@embedded
class RewardEntry {
  String rewardKey = '';
  int quantity = 0;
}

/// 在 `List<RewardEntry>` 上模拟 Map 语义（data_schema.md §3.6）。
extension MapLikeOnRewards on List<RewardEntry> {
  int quantityOf(String rewardKey) =>
      firstWhere((e) => e.rewardKey == rewardKey, orElse: () => RewardEntry())
          .quantity;
}
