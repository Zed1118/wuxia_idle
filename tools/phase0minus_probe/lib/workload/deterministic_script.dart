import 'dart:convert';

import 'package:crypto/crypto.dart';

final class ProbeEvent {
  const ProbeEvent({
    required this.timeUs,
    required this.kind,
    required this.id,
  });

  final int timeUs;
  final String kind;
  final int id;

  Map<String, Object> toJson() => {'time_us': timeUs, 'kind': kind, 'id': id};
}

final class DeterministicScript {
  DeterministicScript({required this.seed, required this.burstIntervalSeconds});

  final int seed;
  final double burstIntervalSeconds;

  List<ProbeEvent> eventsForDuration(double seconds) {
    final intervalUs = (burstIntervalSeconds * 1000000).round();
    final durationUs = (seconds * 1000000).round();
    final events = <ProbeEvent>[];
    var id = 0;
    for (var timeUs = intervalUs; timeUs <= durationUs; timeUs += intervalUs) {
      events.add(ProbeEvent(timeUs: timeUs, kind: 'clear_burst', id: id++));
    }
    return events;
  }

  String checksumForDuration(double seconds) {
    final payload = jsonEncode({
      'seed': seed,
      'events': eventsForDuration(
        seconds,
      ).map((event) => event.toJson()).toList(),
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
