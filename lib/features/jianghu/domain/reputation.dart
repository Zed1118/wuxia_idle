import 'package:isar_community/isar.dart';

part 'reputation.g.dart';

/// 玩家对各门派的声望(P1.2 §2 · GDD §12.2)。
///
/// 不变量:
/// - [value] clamp [-100, +100] 入仓(ReputationService.applyDelta 强制)
/// - tier 映射走 `ReputationService.tierOf`(查 numbers.yaml.jianghu.reputation_tiers)
/// - 多 save 隔离 by [playerId](Demo 单 save · schema 预留多槽语义)
/// - 同 (playerId, factionId) 唯一:复合 unique index 防重复行
///   (沿 SectEvent.sectId composite index 体例)
@collection
class Reputation {
  Id id = Isar.autoIncrement;

  /// 与 [factionId] 组合 unique composite index,防同 (player, faction) 多行重复。
  @Index(composite: [CompositeIndex('factionId')], unique: true)
  late int playerId;

  late String factionId;
  late int value;
  late DateTime updatedAt;
}
