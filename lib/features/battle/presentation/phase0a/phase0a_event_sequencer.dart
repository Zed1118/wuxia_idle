import '../../domain/phase0a/phase0a_combat_events.dart';

/// Phase 0A 事件排序去重器:把 reducer 发来的乱序/重复事件批
/// 整理为按 seq 升序、跨批无重复的消费序列。
///
/// 纯通道职责,不解读事件语义;同一 seq 一旦接受,之后(含同批)
/// 再次出现一律丢弃。
final class Phase0aEventSequencer {
  final Set<int> _acceptedSeqs = <int>{};

  /// 接收一批事件,返回按 seq 升序的新鲜事件(已消费或重复的丢弃)。
  List<Phase0aEvent> ingest(List<Phase0aEvent> batch) {
    if (batch.isEmpty) return const <Phase0aEvent>[];
    final fresh = <Phase0aEvent>[
      for (final event in batch)
        if (_acceptedSeqs.add(event.seq)) event,
    ];
    fresh.sort((a, b) => a.seq.compareTo(b.seq));
    return fresh;
  }
}
