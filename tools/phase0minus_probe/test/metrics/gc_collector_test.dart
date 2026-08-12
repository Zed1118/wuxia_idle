import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/metrics/gc_collector.dart';

void main() {
  test('GC event serialization keeps type and isolate identity', () {
    const sample = GcEventSample(
      timestampMs: 123,
      gcType: 'Scavenge',
      isolateId: 'isolates/1',
      isolateGroupId: 'isolateGroups/1',
    );

    expect(sample.toJson(), {
      'record_type': 'gc_event',
      'timestamp_ms': 123,
      'gc_type': 'Scavenge',
      'isolate_id': 'isolates/1',
      'isolate_group_id': 'isolateGroups/1',
    });
  });
}
