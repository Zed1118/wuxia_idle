import 'package:isar_community/isar.dart';

part 'pvp_snapshot.g.dart';

/// Legacy PVP 阵容快照 schema。
///
/// PVP 玩法已切除;本 collection 仅保留在 Isar schema 中，避免旧存档里曾
/// 创建过 PVP collection 时无法打开。生产路径不再读写。
///
/// 一份快照 = 玩家或对手某时刻的 3 人阵容定格。字段保留给旧 collection
/// 反序列化，不再有 application 层定期清理或匹配流程。
@collection
class PvpSnapshot {
  Id id = Isar.autoIncrement;

  /// 阵容 JSON 序列化(BattleCharacter[3])。Phase 3 落 codec。
  late String snapshotJson;

  /// 拍快照时该玩家段位(显示 + 匹配窗口校验)。
  late int snapshotElo;

  /// 拍快照时刻(TTL 起点)。
  late DateTime takenAt;
}
