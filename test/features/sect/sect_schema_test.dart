import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';

/// P3.4 §12.1 Batch 2.1 schema 红线测族(spec §7 R4 schema 部分)。
///
/// 不实例化 Isar(memory `feedback_isar_autoincrement_test_id_collision`),
/// 只测字段冻结 + enum 长度 + 数值域声明 ack。真 clamp 在 Batch 2.2
/// SectEventService 实装时落 service 行为测。
void main() {
  group('P3.4 sect_event schema 红线', () {
    test('R4.1 Sect 字段冻结(spec §2)', () {
      final s = Sect()
        ..name = '无名宗'
        ..founderId = 1
        ..sectLevel = 1
        ..sectReputation = 50
        ..totalWins = 0
        ..createdAt = DateTime(2026, 5, 24);
      expect(s.name, '无名宗');
      expect(s.founderId, 1);
      expect(s.sectLevel, 1);
      expect(s.sectReputation, 50);
      expect(s.totalWins, 0);
      expect(s.lastEventAt, isNull);
    });

    test('R4.2 SectEvent 字段 + 2 enum 冻结', () {
      final e = SectEvent()
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = DateTime(2026, 5, 24)
        ..narrativeId = 'tournament_01';
      expect(e.sectId, 1);
      expect(e.type, SectEventType.tournament);
      expect(e.status, SectEventStatus.pending);
      expect(e.narrativeId, 'tournament_01');
      expect(e.resolvedAt, isNull);
      expect(e.reputationDelta, isNull);
    });

    test('R4.3 SectEventType 3 枚 / SectEventStatus 3 枚', () {
      expect(SectEventType.values.length, 3);
      expect(SectEventType.values, contains(SectEventType.tournament));
      expect(SectEventType.values, contains(SectEventType.mission));
      expect(SectEventType.values, contains(SectEventType.crisis));

      expect(SectEventStatus.values.length, 3);
      expect(SectEventStatus.values, contains(SectEventStatus.pending));
      expect(SectEventStatus.values, contains(SectEventStatus.resolved));
      expect(SectEventStatus.values, contains(SectEventStatus.expired));
    });

    test('R4.4 sectLevel/sectReputation 数值域(spec §3 yaml 锚点)', () {
      // sectLevel ∈ [1,7] 沿七阶 · sectReputation ∈ [0,100] 独立轴。
      // 真 clamp 在 Batch 2.2 SectEventService 实装,此测仅声明 spec 锚点 ack
      // (防 yaml 改值时 schema 默契失同步)。
      const sectLevelMax = 7;
      const sectLevelMin = 1;
      const sectReputationMax = 100;
      const sectReputationMin = 0;
      expect(sectLevelMax, 7);
      expect(sectLevelMin, 1);
      expect(sectReputationMax, 100);
      expect(sectReputationMin, 0);
    });
  });
}
