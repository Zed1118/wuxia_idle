import 'package:isar_community/isar.dart';

part 'pvp_snapshot.g.dart';

/// 异步 PVP 阵容快照(1.0 P3.3 §12.3,spec p3_3_pvp_spec_2026-05-24 §2)。
///
/// 一份快照 = 玩家或对手某时刻的 3 人阵容定格(BattleCharacter[3] JSON 序列化)。
/// 异步 PVP 不联机,玩家"应战"时拉对手快照,本地用 BattleEngine 跑出胜负。
///
/// `snapshotJson` 序列化体例 Phase 3 落 codec 时确定(候选:
/// `{"chars": [{"name":..., "atk":..., "hp":..., ...}]}`)。
///
/// `snapshotTtlHours` 由 `numbers.yaml pvp.sync.snapshot_ttl_hours=168` 控制
/// (7 天过期),application 层定期清理。
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
