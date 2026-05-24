import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_record.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_snapshot.dart';

/// P3.3 PVP Phase 2 schema 红线测族(spec p3_3_pvp_spec_2026-05-24 §7 R1 部分)。
///
/// 只测 class 实例化 + 字段赋值 + enum 长度。不测 Isar IO(避免
/// autoIncrement test id 冲突 · memory feedback_isar_autoincrement_test_id_collision)。
void main() {
  group('P3.3 PVP schema 红线', () {
    test('R1.1 StageType.pvp 第 6 枚存在', () {
      expect(StageType.values.length, 6);
      expect(StageType.values.contains(StageType.pvp), true);
    });

    test('R1.2 PvpRecord 字段冻结(spec §2)', () {
      final r = PvpRecord()
        ..matchId = 'm1'
        ..playerId = 1
        ..opponentSnapshotId = 2
        ..leftSnapshotId = 3
        ..winnerId = null
        ..playerEloBefore = 1200
        ..playerEloAfter = 1232
        ..eloDelta = 32
        ..timestamp = DateTime(2026, 5, 24);
      expect(r.matchId, 'm1');
      expect(r.playerId, 1);
      expect(r.opponentSnapshotId, 2);
      expect(r.leftSnapshotId, 3);
      expect(r.winnerId, null);           // draw 体例(沿 inner_demon)
      expect(r.playerEloBefore, 1200);
      expect(r.playerEloAfter, 1232);
      expect(r.eloDelta, 32);
    });

    test('R1.3 PvpRecord winnerId 可设为正负 id(玩家胜 / 对手胜)', () {
      final win = PvpRecord()
        ..matchId = 'm2'
        ..playerId = 1
        ..opponentSnapshotId = 2
        ..leftSnapshotId = 3
        ..winnerId = 1                    // 玩家 leader id
        ..playerEloBefore = 1200
        ..playerEloAfter = 1216
        ..eloDelta = 16
        ..timestamp = DateTime(2026, 5, 24);
      expect(win.winnerId, 1);
    });

    test('R1.4 PvpSnapshot 字段冻结', () {
      final s = PvpSnapshot()
        ..snapshotJson = '{"chars":[]}'
        ..snapshotElo = 1200
        ..takenAt = DateTime(2026, 5, 24);
      expect(s.snapshotJson, '{"chars":[]}');
      expect(s.snapshotElo, 1200);
      expect(s.takenAt, DateTime(2026, 5, 24));
    });

    test('R1.5 PvpRecord/PvpSnapshot 默认 id = Isar.autoIncrement(未持久前可不设)',
        () {
      // 红线:Collection 默认 id 应可用,不强制 application 层先 set id。
      final r = PvpRecord()
        ..matchId = 'm3'
        ..playerId = 1
        ..opponentSnapshotId = 2
        ..leftSnapshotId = 3
        ..playerEloBefore = 1200
        ..playerEloAfter = 1200
        ..eloDelta = 0
        ..timestamp = DateTime(2026, 5, 24);
      expect(r.id, isA<int>());
      final s = PvpSnapshot()
        ..snapshotJson = '{}'
        ..snapshotElo = 1200
        ..takenAt = DateTime(2026, 5, 24);
      expect(s.id, isA<int>());
    });
  });
}
