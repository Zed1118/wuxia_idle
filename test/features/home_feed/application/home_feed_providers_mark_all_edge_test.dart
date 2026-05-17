import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';

/// P1 #42 Phase 3 · markAllFeedRead 边界契约。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_mark_all_edge_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('markAllFeedRead 边界', () {
    test('A. Isar null 传入 — graceful no-op 不抛', () async {
      await expectLater(markAllFeedRead(null), completes);
    });

    test('B. 全部已读再 mark — idempotent:字段不变副作用不触发', () async {
      final isar = IsarSetup.instance;
      final base = DateTime(2026, 5, 18, 8);
      const titles = ['甲', '乙', '丙', '丁', '戊'];
      await isar.writeTxn(() async {
        await isar.gameEvents.putAll([
          for (var i = 0; i < titles.length; i++)
            GameEvent()
              ..eventType = GameEventType.retreatCompleted
              ..title = titles[i]
              ..summary = '摘要$i'
              ..occurredAt = base.add(Duration(minutes: i))
              ..isRead = true,
        ]);
      });

      await markAllFeedRead(isar);

      final all = await isar.gameEvents.where().findAll();
      // 集合自洽：全部仍为已读，无条目被意外置为未读
      expect(all.every((e) => e.isRead == true), isTrue);
      // 副作用语义：title/summary/occurredAt 未被修改
      final sortedTitles =
          (all..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)))
              .map((e) => e.title)
              .toList();
      expect(sortedTitles, titles);
    });

    test('C. mark 后 feed 顺序不乱 — occurredAt desc 语义不变', () async {
      final isar = IsarSetup.instance;
      final base = DateTime(2026, 5, 18, 8);
      // 故意乱序写入，模拟真实 insert 顺序
      await isar.writeTxn(() async {
        await isar.gameEvents.putAll([
          GameEvent()
            ..eventType = GameEventType.retreatCompleted
            ..title = '中'
            ..summary = ''
            ..occurredAt = base.add(const Duration(hours: 2))
            ..isRead = false,
          GameEvent()
            ..eventType = GameEventType.bossDefeated
            ..title = '最晚'
            ..summary = ''
            ..occurredAt = base.add(const Duration(hours: 4))
            ..isRead = false,
          GameEvent()
            ..eventType = GameEventType.adventureTriggered
            ..title = '最早'
            ..summary = ''
            ..occurredAt = base
            ..isRead = false,
          GameEvent()
            ..eventType = GameEventType.retreatCompleted
            ..title = '次早'
            ..summary = ''
            ..occurredAt = base.add(const Duration(hours: 1))
            ..isRead = false,
          GameEvent()
            ..eventType = GameEventType.bossDefeated
            ..title = '次晚'
            ..summary = ''
            ..occurredAt = base.add(const Duration(hours: 3))
            ..isRead = false,
        ]);
      });

      await markAllFeedRead(isar);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final feed =
          await container.read(gameEventsFeedProvider(limit: 10).future);

      // 顺序语义：occurredAt desc → 最晚在前
      expect(feed.map((e) => e.title).toList(),
          ['最晚', '次晚', '中', '次早', '最早']);
      // 集合自洽：mark 后所有条目均为已读
      expect(feed.every((e) => e.isRead == true), isTrue);
    });
  });
}
