import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/application/system_clock_provider.dart';
import '../../../data/isar_provider.dart';
import '../domain/sect.dart';
import '../domain/sect_event.dart';
import '../domain/sect_outcome.dart';
import 'sect_event_service.dart';
import 'sect_reputation_decay.dart';

/// 门派系统 Riverpod wire(1.0 P3.4 §12.1 · T19b 技术债清账)。
///
/// **T19b 升级**(原 Batch 2.3 内存 state → 真 Isar 持久化):
/// - `SectSchema` / `SectEventSchema` 已加入 `IsarSetup._allSchemas`(0.13.0)。
/// - [currentSectProvider] StreamProvider 读 `isar.sects` watchObject(1)。
/// - [activeSectEventsProvider] / [historicalSectEventsProvider] StreamProvider
///   走 status filter 查询 watch。
/// - [resolveSectEventProvider] 写库走 [SectEventService.resolve] 算 delta 后
///   `isar.writeTxn` put sect + event。
/// - Isar 未 init 时(widget test 不 init 路径)StreamProvider 退兜底空 stream,
///   resolve no-op,沿 [isarProvider] nullable propagation 体例。

final sectEventServiceProvider = Provider<SectEventService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectEventService(numbers: numbers);
});

final sectReputationDecayServiceProvider =
    Provider<SectReputationDecayService>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  return SectReputationDecayService(numbers: numbers);
});

/// 默认无名宗 Sect 实例(P3.4 spec 初态)。
Sect _defaultSect(DateTime now) => Sect()
  ..id = 1
  ..name = '无名宗'
  ..founderId = 1
  ..sectLevel = 1
  ..sectReputation = 50
  ..totalWins = 0
  ..createdAt = now
  ..lastEventAt = null;

/// Demo 单 sect(id=1)Stream watch。Isar 未 init → 退 [Stream.value] 默认 sect。
final currentSectProvider = StreamProvider<Sect?>((ref) async* {
  final isar = ref.watch(isarProvider);
  final clock = ref.watch(systemClockProvider);
  if (isar == null) {
    yield _defaultSect(clock.now());
    return;
  }
  // ensure exists
  final existing = await isar.sects.get(1);
  if (existing == null) {
    final fresh = _defaultSect(clock.now());
    await isar.writeTxn(() => isar.sects.put(fresh));
  }
  yield* isar.sects.watchObject(1, fireImmediately: true);
});

/// active(pending)sect events Stream。
final activeSectEventsProvider =
    StreamProvider<List<SectEvent>>((ref) async* {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    yield const [];
    return;
  }
  yield* isar.sectEvents
      .filter()
      .statusEqualTo(SectEventStatus.pending)
      .sortByTriggeredAtDesc()
      .watch(fireImmediately: true);
});

/// historical(resolved + expired)sect events Stream(`resolvedAt` 倒序)。
final historicalSectEventsProvider =
    StreamProvider<List<SectEvent>>((ref) async* {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    yield const [];
    return;
  }
  yield* isar.sectEvents
      .filter()
      .statusEqualTo(SectEventStatus.resolved)
      .or()
      .statusEqualTo(SectEventStatus.expired)
      .sortByResolvedAtDesc()
      .watch(fireImmediately: true);
});

/// resolve 落库 AsyncNotifier(spec §4 三态:win/loss/expired)。
///
/// 体例同 `tutorial_service.markHintRead` async mutation:
/// - service 端算 delta + mutate 返新实例
/// - 本端 `isar.writeTxn` 持久化 sect + event
/// - 上游 StreamProvider watch 自动刷新 UI
class ResolveSectEventNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> resolve({
    required Sect sect,
    required SectEvent event,
    required SectOutcome outcome,
  }) async {
    final isar = ref.read(isarProvider);
    final svc = ref.read(sectEventServiceProvider);
    final clock = ref.read(systemClockProvider);
    final (newSect, newEvent) = svc.resolve(
      sect: sect,
      event: event,
      outcome: outcome,
      now: clock.now(),
    );
    if (isar == null) return; // widget test 路径 no-op
    await isar.writeTxn(() async {
      await isar.sects.put(newSect);
      await isar.sectEvents.put(newEvent);
    });
  }
}

final resolveSectEventProvider =
    AsyncNotifierProvider<ResolveSectEventNotifier, void>(
  ResolveSectEventNotifier.new,
);

/// seed pending event(monthly tick callback / debug / 测试用)。
///
/// 触发逻辑:[SectEventService.checkAndTrigger] 返非 null event → 本端 writeTxn 落库。
class SeedSectEventNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> seed(SectEvent event) async {
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    await isar.writeTxn(() => isar.sectEvents.put(event));
  }
}

final seedSectEventProvider =
    AsyncNotifierProvider<SeedSectEventNotifier, void>(
  SeedSectEventNotifier.new,
);
