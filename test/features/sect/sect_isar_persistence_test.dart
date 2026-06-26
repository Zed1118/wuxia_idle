import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/sect/application/sect_event_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_monthly_tick_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_reputation_decay.dart';
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

    test('R4.2 saveVersion 已升当前 0.32.0(装备锁定字段)', () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.saveVersion, '0.32.0');
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
        ..lastEventAt = DateTime(2026, 5, 20)
        ..lastTickAt = DateTime(2026, 5, 18); // B1 新字段
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
      expect(reopened.lastTickAt, DateTime(2026, 5, 18),
          reason: 'B1 lastTickAt nullable 新字段持久化 round-trip');
    });

    test('R4.6 B1 月度 tick compute → writeTxn 落库 e2e(真 Isar · 触发+decay)',
        () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final isar = IsarSetup.instance;

      // lastTickAt 35 天前 → 1 月;lastEventAt 远古 → cooldown 已过 + idle decay。
      final now = DateTime(2026, 7, 5);
      final sect = Sect()
        ..id = 1
        ..name = '无名宗'
        ..founderId = 1
        ..sectLevel = 1
        ..sectReputation = 50
        ..totalWins = 0
        ..createdAt = DateTime(2026, 1, 1)
        ..lastEventAt = DateTime(2026, 5, 1)
        ..lastTickAt = DateTime(2026, 6, 1);
      await isar.writeTxn(() => isar.sects.put(sect));

      final numbers = NumbersConfigForTick();
      final svc = SectMonthlyTickService(
        eventSvc: SectEventService(numbers: numbers),
        decaySvc: SectReputationDecayService(numbers: numbers),
        numbers: numbers,
      );
      final result = svc.compute(
        sect: sect,
        activeEvents: const [],
        playerRealm: RealmTier.yiLiu,
        now: now,
        rng: _AlwaysHitRng(),
      );
      // 同 _runSectMonthlyTick 落库
      await isar.writeTxn(() async {
        await isar.sects.put(sect);
        for (final e in result.newEvents) {
          await isar.sectEvents.put(e);
        }
      });

      final pending = await isar.sectEvents
          .filter()
          .statusEqualTo(SectEventStatus.pending)
          .findAll();
      expect(pending, hasLength(1), reason: '1 月命中 → 1 新 pending 落库');
      expect(pending.first.narrativeId, 'tournament_01');
      final reopenSect = await isar.sects.get(1);
      expect(reopenSect!.lastTickAt, DateTime(2026, 7, 1),
          reason: '锚点推进 1×30 天落库');
      expect(reopenSect.sectReputation, 45, reason: 'idle 1 月 decay -5 落库');
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

/// B1 e2e 用 NumbersConfig stub(含 narrative_ids 池)。
class NumbersConfigForTick implements NumbersConfig {
  @override
  SectEventDef get sectEvent => SectEventDef.fromYaml(const {
        'tournament': {
          'trigger_probability': 0.30,
          'cooldown_days': 30,
          'trigger_realm_min': 'yiLiu',
          'expire_days': 7,
          'narrative_ids': ['tournament_01', 'tournament_02'],
        },
        'reputation': {
          'initial': 50,
          'win_delta': 10,
          'loss_delta': -5,
          'decay_per_month_idle': 5,
          'max': 100,
          'min': 0,
        },
        'sect_level': {'max': 7, 'initial': 1, 'promote_wins_threshold': 3},
        'active_events_max': 3,
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 概率必命中(nextDouble 0.0)+ pick 首项(nextInt 0)。
class _AlwaysHitRng implements Random {
  @override
  double nextDouble() => 0.0;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => throw UnimplementedError();
}
