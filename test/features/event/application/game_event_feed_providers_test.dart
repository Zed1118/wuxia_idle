import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/event/application/game_event_feed_providers.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_event_feed_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('空表返回空 list', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final feed = await container.read(gameEventsFeedProvider().future);

    expect(feed, isEmpty);
  });

  test('按 occurredAt desc 排序', () async {
    final isar = IsarSetup.instance;
    final base = DateTime(2026, 5, 17, 10);
    await isar.writeTxn(() async {
      await isar.gameEvents.putAll([
        _event('一', base),
        _event('三', base.add(const Duration(hours: 2))),
        _event('二', base.add(const Duration(hours: 1))),
      ]);
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final feed = await container.read(gameEventsFeedProvider().future);

    expect(feed.map((e) => e.title).toList(), ['三', '二', '一']);
  });

  test('limit 截断且默认取 20 条', () async {
    final isar = IsarSetup.instance;
    final base = DateTime(2026, 5, 17, 10);
    await isar.writeTxn(() async {
      await isar.gameEvents.putAll([
        for (var i = 0; i < 25; i++)
          _event('事件$i', base.add(Duration(minutes: i))),
      ]);
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final feed5 = await container.read(gameEventsFeedProvider(limit: 5).future);
    final feedDefault = await container.read(gameEventsFeedProvider().future);

    expect(feed5, hasLength(5));
    expect(feedDefault, hasLength(20));
  });
}

GameEvent _event(String title, DateTime occurredAt) => GameEvent()
  ..eventType = GameEventType.retreatCompleted
  ..title = title
  ..summary = title
  ..occurredAt = occurredAt
  ..isRead = false;
