import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';

/// T19b 技术债清账:Sect / SectEvent Isar 真持久化 round-trip 测族。
///
/// 沿 test/data/isar_setup_test.dart 体例(`Isar.initializeIsarCore` + tempDir
/// + close/reopen 验持久化)。**不用 widget test**(memory
/// `feedback_isar_widget_test_deadlock`)— 纯 service 层 writeTxn 联调。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  group('Sect / SectEvent Isar 持久化', () {
    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_sect_persistence_');
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('R4.1 SectSchema/SectEventSchema 加入 _allSchemas → init 不抛',
        () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      // sects + sectEvents collection 都能访问
      expect(IsarSetup.instance.sects, isNotNull);
      expect(IsarSetup.instance.sectEvents, isNotNull);
    });

    test('R4.2 saveVersion 已升当前 0.24.0(M2 范围 B 被动挂机累计字段)', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.saveVersion, '0.24.0');
    });

    test('R4.3 Sect 写入 → close → reopen 读出字段一致', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      final s = Sect()
        ..id = 1
        ..name = '青锋门'
        ..founderId = 7
        ..sectLevel = 3
        ..sectReputation = 75
        ..totalWins = 12
        ..createdAt = DateTime(2026, 5, 1)
        ..lastEventAt = DateTime(2026, 5, 20);
      await isar.writeTxn(() => isar.sects.put(s));

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final reopened = await IsarSetup.instance.sects.get(1);
      expect(reopened, isNotNull);
      expect(reopened!.name, '青锋门');
      expect(reopened.sectLevel, 3);
      expect(reopened.sectReputation, 75);
      expect(reopened.totalWins, 12);
      expect(reopened.lastEventAt, DateTime(2026, 5, 20));
    });

    test('R4.4 SectEvent put 后 filter().statusEqualTo(pending) 查得到',
        () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      final ev = SectEvent()
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = DateTime(2026, 5, 24)
        ..narrativeId = 'tournament_01';
      await isar.writeTxn(() => isar.sectEvents.put(ev));

      final pending = await isar.sectEvents
          .filter()
          .statusEqualTo(SectEventStatus.pending)
          .findAll();
      expect(pending, hasLength(1));
      expect(pending.first.narrativeId, 'tournament_01');
      expect(pending.first.sectId, 1);
    });

    test('R4.5 SectEvent resolve → status=resolved 写库 → historical 查得到',
        () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      final ev = SectEvent()
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = DateTime(2026, 5, 24)
        ..narrativeId = 'tournament_01';
      await isar.writeTxn(() => isar.sectEvents.put(ev));

      // mutate to resolved
      await isar.writeTxn(() async {
        ev
          ..status = SectEventStatus.resolved
          ..resolvedAt = DateTime(2026, 5, 25)
          ..reputationDelta = 10;
        await isar.sectEvents.put(ev);
      });

      final historical = await isar.sectEvents
          .filter()
          .statusEqualTo(SectEventStatus.resolved)
          .or()
          .statusEqualTo(SectEventStatus.expired)
          .findAll();
      expect(historical, hasLength(1));
      expect(historical.first.reputationDelta, 10);
      expect(historical.first.resolvedAt, DateTime(2026, 5, 25));

      final pendingAfter = await isar.sectEvents
          .filter()
          .statusEqualTo(SectEventStatus.pending)
          .findAll();
      expect(pendingAfter, isEmpty);
    });
  });
}
