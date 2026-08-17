import 'dart:async';
import 'dart:developer' as developer;

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

final class GcEventSample {
  const GcEventSample({
    required this.timestampMs,
    required this.gcType,
    required this.isolateId,
    required this.isolateGroupId,
  });

  final int? timestampMs;
  final String? gcType;
  final String? isolateId;
  final String? isolateGroupId;

  Map<String, Object?> toJson() => {
    'record_type': 'gc_event',
    'timestamp_ms': timestampMs,
    'gc_type': gcType,
    'isolate_id': isolateId,
    'isolate_group_id': isolateGroupId,
  };
}

final class GcCollector {
  final List<GcEventSample> events = [];
  VmService? _service;
  StreamSubscription<Event>? _subscription;
  String status = 'GC_TELEMETRY_NOT_STARTED';
  String? error;
  bool _closed = false;

  bool get available => status == 'GC_TELEMETRY_COLLECTED';

  Future<void> connect() async {
    try {
      final info = await developer.Service.getInfo();
      final uri = info.serverWebSocketUri;
      if (uri == null) {
        status = 'GC_TELEMETRY_MISSING';
        error = 'Dart VM service URI is unavailable.';
        return;
      }
      final service = await vmServiceConnectUri(uri.toString());
      await service.streamListen(EventStreams.kGC);
      _service = service;
      _subscription = service.onGCEvent.listen((event) {
        events.add(
          GcEventSample(
            timestampMs: event.timestamp,
            gcType: event.gcType,
            isolateId: event.isolate?.id,
            isolateGroupId: event.isolateGroup?.id,
          ),
        );
      });
      status = 'GC_TELEMETRY_COLLECTED';
    } on Object catch (exception) {
      status = 'GC_TELEMETRY_MISSING';
      error = exception.toString();
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _service?.dispose();
    _service = null;
  }
}
