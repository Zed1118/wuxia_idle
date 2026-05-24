import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_outcome.dart';
import 'sect_event_service.dart';
import 'sect_reputation_decay.dart';

/// 门派系统 Riverpod wire(1.0 P3.4 §12.1,Batch 2.3 nightshift T16)。
///
/// **Demo 内存 state 体例**(挂账留 Phase 4):
/// - `SectSchema` / `SectEventSchema` 尚未加入 `IsarSetup._allSchemas`,真持久化
///   writeTxn 验收留挂账。Demo 走 [SectStateNotifier] 内存 state 单 sect 单玩家路径
///   即可联调 UI + service + battle。
/// - Phase 4 wire 真 Isar 时:① schema 加入 `_allSchemas` 并升 saveVersion;②
///   [currentSectProvider] / [activeSectEventsProvider] / [historicalSectEventsProvider]
///   切到 StreamProvider 读 Isar collection;③ [SectStateNotifier.resolve] 内 writeTxn 落库。

final sectEventServiceProvider = Provider<SectEventService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectEventService(numbers: numbers);
});

final sectReputationDecayServiceProvider =
    Provider<SectReputationDecayService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectReputationDecayService(numbers: numbers);
});

/// Demo 内存 state(Phase 4 wire 真 Isar 时换 StreamProvider 读 collection)。
///
/// 初态:无名宗 sectLevel=1 / sectReputation=50 / totalWins=0 / lastEventAt=null。
class SectStateNotifier extends Notifier<SectState> {
  static Sect _initialSect() => Sect()
    ..id = 1
    ..name = '无名宗'
    ..founderId = 1
    ..sectLevel = 1
    ..sectReputation = 50
    ..totalWins = 0
    ..createdAt = DateTime.now()
    ..lastEventAt = null;

  @override
  SectState build() => SectState(
        sect: _initialSect(),
        activeEvents: const [],
        historicalEvents: const [],
      );

  /// 注入 active event(测试 / debug / monthly tick callback 用)。
  void seedActiveEvent(SectEvent event) {
    state = state.copyWith(
      activeEvents: [...state.activeEvents, event],
    );
  }

  /// resolve 链路(spec §4):service mutation 后内存 commit。
  ///
  /// Phase 4 wire 真 Isar 时,此处加 `await isar.writeTxn(() async {
  /// await isar.sects.put(sect); await isar.sectEvents.put(event); })`。
  void resolve({required SectEvent event, required SectOutcome outcome}) {
    final svc = ref.read(sectEventServiceProvider);
    final (newSect, newEvent) = svc.resolve(
      sect: state.sect,
      event: event,
      outcome: outcome,
      now: DateTime.now(),
    );
    state = state.copyWith(
      sect: newSect,
      activeEvents:
          state.activeEvents.where((e) => e.id != event.id).toList(),
      historicalEvents: [newEvent, ...state.historicalEvents],
    );
  }
}

class SectState {
  const SectState({
    required this.sect,
    required this.activeEvents,
    required this.historicalEvents,
  });

  final Sect sect;
  final List<SectEvent> activeEvents;
  final List<SectEvent> historicalEvents;

  SectState copyWith({
    Sect? sect,
    List<SectEvent>? activeEvents,
    List<SectEvent>? historicalEvents,
  }) =>
      SectState(
        sect: sect ?? this.sect,
        activeEvents: activeEvents ?? this.activeEvents,
        historicalEvents: historicalEvents ?? this.historicalEvents,
      );
}

final sectStateProvider =
    NotifierProvider<SectStateNotifier, SectState>(SectStateNotifier.new);
