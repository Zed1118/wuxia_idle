import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';

/// P1 #42 Phase 3 · HomeFeed providers 红线契约。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_home_feed_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('gameEventsFeed 空表返回空 list', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final feed = await container.read(gameEventsFeedProvider().future);
    expect(feed, isEmpty);
  });

  test('gameEventsFeed 按 occurredAt desc 排序', () async {
    final isar = IsarSetup.instance;
    final base = DateTime(2026, 5, 17, 10);
    await isar.writeTxn(() async {
      await isar.gameEvents.putAll([
        GameEvent()
          ..eventType = GameEventType.retreatCompleted
          ..title = '一'
          ..summary = '最早'
          ..occurredAt = base
          ..isRead = false,
        GameEvent()
          ..eventType = GameEventType.bossDefeated
          ..title = '三'
          ..summary = '最晚'
          ..occurredAt = base.add(const Duration(hours: 2))
          ..isRead = false,
        GameEvent()
          ..eventType = GameEventType.adventureTriggered
          ..title = '二'
          ..summary = '中间'
          ..occurredAt = base.add(const Duration(hours: 1))
          ..isRead = false,
      ]);
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final feed = await container.read(gameEventsFeedProvider().future);
    expect(feed.map((e) => e.title).toList(), ['三', '二', '一']);
  });

  test('gameEventsFeed limit 截断', () async {
    final isar = IsarSetup.instance;
    final base = DateTime(2026, 5, 17, 10);
    await isar.writeTxn(() async {
      for (var i = 0; i < 25; i++) {
        await isar.gameEvents.put(GameEvent()
          ..eventType = GameEventType.retreatCompleted
          ..title = '事件$i'
          ..summary = '正文$i'
          ..occurredAt = base.add(Duration(minutes: i))
          ..isRead = false);
      }
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final feed5 = await container.read(gameEventsFeedProvider(limit: 5).future);
    expect(feed5, hasLength(5));
    final feedDefault = await container.read(gameEventsFeedProvider().future);
    expect(feedDefault, hasLength(20));
  });

  test('markAllFeedRead 批量 mark isRead=true', () async {
    final isar = IsarSetup.instance;
    final base = DateTime(2026, 5, 17, 10);
    await isar.writeTxn(() async {
      await isar.gameEvents.putAll([
        GameEvent()
          ..eventType = GameEventType.retreatCompleted
          ..title = '未读 1'
          ..summary = '正文'
          ..occurredAt = base
          ..isRead = false,
        GameEvent()
          ..eventType = GameEventType.bossDefeated
          ..title = '未读 2'
          ..summary = '正文'
          ..occurredAt = base
          ..isRead = false,
      ]);
    });

    await markAllFeedRead(isar);
    final all = await isar.gameEvents.where().findAll();
    expect(all.every((e) => e.isRead == true), isTrue);
  });
}
