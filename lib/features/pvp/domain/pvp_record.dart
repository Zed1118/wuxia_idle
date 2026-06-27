import 'package:isar_community/isar.dart';

part 'pvp_record.g.dart';

/// Legacy PVP 战例记录 schema。
///
/// PVP 玩法已切除;本 collection 仅保留在 Isar schema 中，避免旧存档里曾
/// 创建过 PVP collection 时无法打开。生产路径不再读写。
///
/// 一行 = 一场 PVP 完整结算。`(playerId, timestamp)` composite index 曾用于
/// 按玩家倒序拉历史。
///
/// 关键字段语义:
///   - [matchId]:application 层生成的 uuid v4,跨 leftSnapshot/opponentSnapshot 唯一索引
///   - [winnerId]:null = draw,与 inner_demon 体例一致
///   - [eloDelta]:±单场 ELO 变化,显式存储(派生 = playerEloAfter - playerEloBefore
///     但 K factor 调参时回溯需要原值)
///   - [leftSnapshotId] / [opponentSnapshotId]:都指向 [PvpSnapshot.id],
///     leftSnapshot 是玩家出战阵容快照(应战时已固定,防强化后回放数值漂移)
///
@collection
class PvpRecord {
  Id id = Isar.autoIncrement;

  /// 战例唯一 id(application 层 uuid v4)。
  late String matchId;

  /// 本地玩家 character id(composite index 主键)。
  @Index(composite: [CompositeIndex('timestamp')])
  late int playerId;

  /// 对手快照 id → [PvpSnapshot.id]。
  late int opponentSnapshotId;

  /// 玩家阵容快照 id → [PvpSnapshot.id]。
  late int leftSnapshotId;

  /// 胜方角色 id(玩家 leader 或 opponent leader);null = draw。
  int? winnerId;

  /// 战前玩家 ELO。
  late int playerEloBefore;

  /// 战后玩家 ELO。
  late int playerEloAfter;

  /// ±单场积分变化(冗余存储,防 K factor 调参后回溯失真)。
  late int eloDelta;

  /// 战例发生时间。
  late DateTime timestamp;
}
