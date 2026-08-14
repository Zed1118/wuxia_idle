import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

void main() {
  test('feed is bounded, ordered, and sequences monotonically', () {
    final feed = LootFeed(capacity: 3);
    for (var index = 1; index <= 5; index++) {
      feed.add(label: 'drop $index', kind: LootKind.material);
    }
    final entries = feed.entries;
    expect(entries.length, 3);
    expect(entries.map((entry) => entry.label), ['drop 3', 'drop 4', 'drop 5']);
    expect(entries.map((entry) => entry.sequence), [3, 4, 5]);
  });

  test('feed rejects a non-positive capacity', () {
    expect(() => LootFeed(capacity: 0), throwsArgumentError);
  });

  test('clear empties the feed and restarts sequencing', () {
    final feed = LootFeed();
    feed.add(label: 'a', kind: LootKind.currency);
    feed.add(label: 'b', kind: LootKind.gear);
    feed.clear();
    expect(feed.entries, isEmpty);
    expect(feed.add(label: 'c', kind: LootKind.gear).sequence, 1);
  });

  test('entries list is unmodifiable', () {
    final feed = LootFeed();
    feed.add(label: 'a', kind: LootKind.currency);
    expect(() => feed.entries.add(feed.entries.first), throwsUnsupportedError);
  });

  test('controller surfaces loot in-memory and reset clears it', () {
    final controller = FeedbackHudController(lootCapacity: 2);
    controller.apply(const LootPresented(label: 'one', kind: LootKind.gear));
    controller.apply(
      const LootPresented(label: 'two', kind: LootKind.material),
    );
    controller.apply(
      const LootPresented(label: 'three', kind: LootKind.currency),
    );

    final shown = controller.value.loot;
    expect(shown.map((entry) => entry.label), ['two', 'three']);

    controller.apply(const BattleReset());
    expect(controller.value.loot, isEmpty);

    // Nothing survived the reset: a fresh drop starts from sequence 1,
    // proving no history is retained anywhere.
    controller.apply(const LootPresented(label: 'four', kind: LootKind.gear));
    expect(controller.value.loot.single.sequence, 1);
    controller.dispose();
  });
}
