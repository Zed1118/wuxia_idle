import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';

CombatEventRecord event(
  String id,
  CombatEventStage stage, {
  int tick = 0,
  int tieBreak = 0,
  String? aggregateKey,
  int? priority,
  CombatFeedKind feedKind = CombatFeedKind.none,
}) => CombatEventRecord(
  eventId: id,
  tick: tick,
  stage: stage,
  tieBreak: tieBreak,
  aggregateKey: aggregateKey,
  priority: priority,
  feedKind: feedKind,
);

void main() {
  test('同拍严格按领域阶段顺序排序', () {
    final ordered = CombatEventOrder.order([
      event('presentation', CombatEventStage.presentation),
      event('damage', CombatEventStage.damageAndPosture),
      event('legality', CombatEventStage.legalityAndResources),
      event('hit', CombatEventStage.hitFreeze),
      event('status', CombatEventStage.status),
      event('startup', CombatEventStage.startup),
      event('selection', CombatEventStage.displacementAndSelection),
      event('defense', CombatEventStage.defense),
      event('kill', CombatEventStage.killAndResources),
    ]);

    expect(ordered.map((item) => item.eventId), [
      'legality',
      'startup',
      'selection',
      'hit',
      'defense',
      'damage',
      'status',
      'kill',
      'presentation',
    ]);
  });

  test('跨 tick 优先 tick，同拍按 tie-break 再按 event id 稳定排序', () {
    final ordered = CombatEventOrder.order([
      event('z', CombatEventStage.status, tick: 1, tieBreak: 2),
      event('b', CombatEventStage.status, tick: 1, tieBreak: 1),
      event('a', CombatEventStage.status, tick: 1, tieBreak: 1),
      event('early', CombatEventStage.presentation, tick: 0),
    ]);

    expect(ordered.map((item) => item.eventId), ['early', 'a', 'b', 'z']);
  });

  test('表现 feed 只投影表现事件且不可修改领域结果', () {
    final ordered = CombatEventOrder.order([
      event(
        'impact',
        CombatEventStage.presentation,
        aggregateKey: 'impact-group',
        priority: 2,
        feedKind: CombatFeedKind.impact,
      ),
      event('damage', CombatEventStage.damageAndPosture),
    ]);

    final feed = CombatPresentationFeed.fromOrderedEvents(ordered);

    expect(feed.entries, [
      const CombatPresentationFeedEntry(
        eventId: 'impact',
        tick: 0,
        aggregateKey: 'impact-group',
        priority: 2,
        kind: CombatFeedKind.impact,
      ),
    ]);
    expect(() => feed.entries.add(feed.entries.single), throwsUnsupportedError);
    expect(ordered.first.eventId, 'damage');
  });

  test('拒绝重复 ID、负序号与错误阶段的表现 feed', () {
    expect(
      () => CombatEventOrder.order([
        event('duplicate', CombatEventStage.startup),
        event('duplicate', CombatEventStage.status),
      ]),
      throwsArgumentError,
    );
    expect(
      () => event('negative', CombatEventStage.startup, tick: -1),
      throwsArgumentError,
    );
    expect(
      () => event(
        'wrong-stage',
        CombatEventStage.status,
        feedKind: CombatFeedKind.status,
      ),
      throwsArgumentError,
    );
  });

  test('feed 对未排序输入和重复 ID fail closed，非表现事件不携带 feed 字段', () {
    final presentation = event(
      'presentation',
      CombatEventStage.presentation,
      aggregateKey: 'impact',
      priority: 1,
      feedKind: CombatFeedKind.impact,
    );
    final damage = event('damage', CombatEventStage.damageAndPosture);
    expect(
      () => CombatPresentationFeed.fromOrderedEvents([presentation, damage]),
      throwsArgumentError,
    );
    expect(
      () => CombatPresentationFeed.fromOrderedEvents([damage, damage]),
      throwsArgumentError,
    );
    expect(
      () => event(
        'domain-with-feed-fields',
        CombatEventStage.damageAndPosture,
        aggregateKey: 'not-needed',
        priority: 1,
      ),
      throwsArgumentError,
    );
  });
}
