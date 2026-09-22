import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/system_clock_provider.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/isar_setup.dart';
import '../../boss_gauntlet/application/gauntlet_providers.dart';
import '../../expedition/application/expedition_providers.dart';
import '../../light_foot/application/light_foot_participant_service.dart';
import '../../mass_battle/application/mass_battle_participant_service.dart';
import '../../tower/application/tower_providers.dart';
import 'offline_passive_service.dart';

/// Keeps lifecycle presence separate from the persistent passive reward ledger.
/// Foreground heartbeats accrue the same configured rewards as a closed app.
/// 重伤/紊乱在所有时间边界自然恢复；只有首启/返回保留既有轻伤调息事件。
final onlinePresenceControllerProvider = Provider<OnlinePresenceController>((
  ref,
) {
  final controller = OnlinePresenceController(
    ref,
    clock: ref.watch(systemClockProvider).now,
  );
  // 负责 cancel 心跳 Timer:widget 测 ProviderScope 卸载时经此回收,防 pending timer。
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [towerParticipantCandidatesProvider]);

class OnlinePresenceController {
  OnlinePresenceController(
    this._ref, {
    DateTime Function()? clock,
    Duration heartbeatInterval = const Duration(seconds: 60),
  }) : _clock = clock ?? (const SystemClock()).now,
       _heartbeatInterval = heartbeatInterval;

  final Ref _ref;
  final DateTime Function() _clock;
  final Duration _heartbeatInterval;

  Timer? _heartbeat;
  bool _isFocused = true;
  bool _startupSettleDone = false;
  bool _busy = false;
  Future<void> _settlements = Future<void>.value();
  bool _disposed = false;

  @visibleForTesting
  bool get isHeartbeatActive => _heartbeat != null;

  @visibleForTesting
  Future<void> get settlementsComplete => _settlements;

  /// 首启/返回清轻伤，心跳和首次失焦不清；定时疗养不受该事件参数控制。
  Future<PassiveYield?> settlePassiveWindow({
    DateTime? now,
    bool clearLightInjury = true,
  }) {
    if (_disposed) return Future<PassiveYield?>.value();
    final isar = IsarSetup.instanceOrNull;
    if (isar == null) return Future<PassiveYield?>.value();
    final at = now ?? _clock();
    // Queue lifecycle boundaries instead of dropping a focus/blur while an
    // earlier write is in flight. The service rechecks its ledger in each txn.
    final task = _settlements.then((_) async {
      if (_disposed || !isar.isOpen) return null;
      _busy = true;
      try {
        return await _settleLocked(
          isar: isar,
          now: at,
          clearLightInjury: clearLightInjury,
        );
      } finally {
        _busy = false;
      }
    });
    _settlements = task.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return task;
  }

  Future<PassiveYield?> _settleLocked({
    required Isar isar,
    required DateTime now,
    required bool clearLightInjury,
  }) async {
    final result = await OfflinePassiveService.settleWindow(
      isar: isar,
      now: now,
      clearLightInjury: clearLightInjury,
      updatePresence: true,
      expeditionService: _ref.read(expeditionServiceProvider),
    );
    if (_disposed) return result;
    // A return can recover injuries even when a reward boundary already settled
    // all product time, so refresh consumers even if the result is null.
    _ref.invalidate(activeExpeditionProvider);
    _ref.invalidate(expeditionCandidatesProvider);
    _ref.invalidate(pendingExpeditionMilestoneProvider);
    _ref.invalidate(expeditionMaxDepthProvider);
    _ref.invalidate(gauntletCandidatesProvider);
    _ref.invalidate(towerParticipantCandidatesProvider);
    _ref.invalidate(lightFootParticipantCandidatesProvider);
    _ref.invalidate(massBattleParticipantCandidatesProvider);
    _ref.invalidate(characterByIdProvider);
    _ref.invalidate(allInventoryItemsProvider);
    _ref.invalidate(inventoryQuantityByDefIdProvider('item_mojianshi'));
    _ref.invalidate(inventoryQuantityByTypeProvider(ItemType.moJianShi));
    return result;
  }

  /// onShow/onResume:结算失焦窗口后恢复心跳。首启只记录聚焦状态。
  void onAppFocused() {
    if (_disposed) return;
    _isFocused = true;
    if (!_startupSettleDone) return;
    if (_heartbeat != null) return; // 已在前台,幂等
    unawaited(_settlePresenceSafe(clearLightInjury: true));
    _startHeartbeat();
  }

  /// First onHide/onInactive/onDetach after focus: settle and stop heartbeat.
  /// Startup owns its pending offline window; later blur events must preserve
  /// the first background boundary rather than discard time already away.
  void onAppBlurred() {
    if (_disposed) return;
    _isFocused = false;
    if (!_startupSettleDone || _heartbeat == null) return;
    _stopHeartbeat();
    unawaited(_settlePresenceSafe(clearLightInjury: false));
  }

  /// gate 首启结算路径完成后调:开闸,仅前台起心跳。
  void markStartupSettleDone() {
    if (_disposed) return;
    _startupSettleDone = true;
    if (_isFocused) _startHeartbeat();
  }

  void dispose() {
    _disposed = true;
    _stopHeartbeat();
  }

  void _startHeartbeat() {
    if (_disposed) return;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      if (_busy) return;
      unawaited(_settlePresenceSafe(clearLightInjury: false));
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _settlePresenceSafe({required bool clearLightInjury}) async {
    if (_disposed) return;
    try {
      await settlePassiveWindow(clearLightInjury: clearLightInjury);
    } catch (e, st) {
      // 未 init / 切槽瞬间 → 安全忽略(与原 main._recordOnline catchError 一致)。
      // 若 Isar 已存在仍失败,说明存档写入路径异常,保留诊断线索。
      if (IsarSetup.instanceOrNull != null) {
        debugPrint('OnlinePresence settlement skipped: $e\n$st');
      }
    }
  }
}
