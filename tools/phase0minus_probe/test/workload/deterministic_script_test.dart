import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/workload/deterministic_script.dart';

void main() {
  test('fixed seed and interval produce stable events and checksum', () {
    final first = DeterministicScript(seed: 20260812, burstIntervalSeconds: 10);
    final second = DeterministicScript(
      seed: 20260812,
      burstIntervalSeconds: 10,
    );
    final events = first.eventsForDuration(60);
    expect(events, hasLength(6));
    expect(events.first.timeUs, 10000000);
    expect(events.last.timeUs, 60000000);
    expect(first.checksumForDuration(60), second.checksumForDuration(60));
  });

  test('seed participates in checksum', () {
    final first = DeterministicScript(seed: 1, burstIntervalSeconds: 10);
    final second = DeterministicScript(seed: 2, burstIntervalSeconds: 10);
    expect(
      first.checksumForDuration(60),
      isNot(second.checksumForDuration(60)),
    );
  });
}
