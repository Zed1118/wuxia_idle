import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../data/isar_setup.dart';
import 'offline_passive_service.dart';
import 'seclusion_service_providers.dart';

/// 体检 P0-3 修复(方案 B):在线基准 SaveData.lastOnlineAt 的生命周期侧
/// 唯一写入者 + 被动离线静默结算入口。
///
/// 病根:结算原本只在 HomeFeed 首帧跑一次,失焦(onHide/onInactive/onDetach)
/// 只重置基准不结算 → 挂后台窗口收益丢失;退出时 fire-and-forget 写不进 →
/// 基准过期,下次启动把在线时段按离线双吃。
///
/// 职责:
/// - [OnlinePresenceController.settlePassiveWindow]:对 [基准, now] 窗口静默
///   结算(含互斥/旧档/回拨守卫),gate 启动路径与聚焦路径共用,消灭第二套基准逻辑。
/// - 前台心跳(默认 60s)持续 touch 基准 → 聚焦态直接退出的双吃上界 ≤ 心跳间隔。
///   心跳间隔是纯防御工程参数(不影响任何收益数值),故留代码常量不进 numbers.yaml。
/// - [OnlinePresenceController.onAppFocused] / [OnlinePresenceController.onAppBlurred]:
///   由 OnlinePresenceLifecycleHook 接线。首启结算归 gate
///   ([OnlinePresenceController.markStartupSettleDone] 前 focused 整体 no-op,
///   防心跳提前刷新基准毁掉启动离线窗口)。
final onlinePresenceControllerProvider = Provider<OnlinePresenceController>((
  ref,
) {
  final controller = OnlinePresenceController(ref);
  // 负责 cancel 心跳 Timer:widget 测 ProviderScope 卸载时经此回收,防 pending timer。
  ref.onDispose(controller.dispose);
  return controller;
});

class OnlinePresenceController {
  OnlinePresenceController(
    this._ref, {
    DateTime Function()? clock,
    Duration heartbeatInterval = const Duration(seconds: 60),
  }) : _clock = clock ?? DateTime.now,
       _heartbeatInterval = heartbeatInterval;

  final Ref _ref;
  final DateTime Function() _clock;
  final Duration _heartbeatInterval;

  Timer? _heartbeat;
  bool _startupSettleDone = false;
  bool _busy = false;

  @visibleForTesting
  bool get isHeartbeatActive => _heartbeat != null;

  /// 对 [SaveData.lastOnlineAt, now] 窗口做一次被动离线结算。
  /// 返回 null = 本次无结算(未 init/无存档/闭关互斥/旧档首启/回拨/并发中)。
  Future<PassiveYield?> settlePassiveWindow({DateTime? now}) async {
    if (_busy) return null;
    _busy = true;
    try {
      return await _settleLocked(now: now);
    } finally {
      _busy = false;
    }
  }

  Future<PassiveYield?> _settleLocked({DateTime? now}) async {
    if (IsarSetup.instanceOrNull == null) return null;
    final save = await IsarSetup.currentSaveData();
    if (save == null) return null;

    final nowDt = now ?? _clock();

    // 互斥:有 active 闭关该窗口归闭关,只 touch(顺带修收功后 stale 基准双吃边角)。
    final svc = _ref.read(seclusionServiceProvider);
    final session = svc == null
        ? null
        : await svc.getActiveSession(IsarSetup.currentSlotId);
    if (session != null) {
      await IsarSetup.touchOnlineNow(now: nowDt);
      return null;
    }

    // 旧档首启不回溯(语义自 offline_recap_gate 范围 B 原样迁入)。
    if (save.lastOnlineAt == save.createdAt) {
      await IsarSetup.touchOnlineNow(now: nowDt);
      return null;
    }

    final awayHours = nowDt.difference(save.lastOnlineAt).inSeconds / 3600.0;
    if (awayHours <= 0) return null; // 时钟回拨防御(现状保留)

    final ids = await _ref.read(activeCharacterIdsProvider.future);
    final charId = ids.isNotEmpty ? ids.first : 1;
    final yield_ = await OfflinePassiveService.settle(
      saveDataId: save.slotId,
      characterId: charId,
      awayHours: awayHours,
      now: nowDt,
    );
    // settle 写了 Character/InventoryItem,Future 型 provider 缓存必须刷,
    // 否则聚焦静默结算=「结算了 UI 不刷新」(W13-v3 同型,参照
    // battle/application/post_combat_invalidation.dart)。离线被动只产磨剑石材料
    // (offline_passive_service),不涉银两/装备图鉴/Boss 门控,故不刷主菜单门控。
    _ref.invalidate(characterByIdProvider);
    _ref.invalidate(allInventoryItemsProvider);
    return yield_;
  }

  /// onShow/onResume:结算失焦窗口后恢复心跳。首启(gate 未跑)整体 no-op。
  void onAppFocused() {
    if (!_startupSettleDone) return;
    if (_heartbeat != null) return; // 已在前台,幂等
    unawaited(settlePassiveWindow().catchError((_) => null));
    _startHeartbeat();
  }

  /// onHide/onInactive/onDetach:停心跳 + 终 touch(best-effort)。
  void onAppBlurred() {
    _stopHeartbeat();
    unawaited(_touchSafe());
  }

  /// gate 首启结算路径完成后调:开闸 + 起心跳。
  void markStartupSettleDone() {
    _startupSettleDone = true;
    _startHeartbeat();
  }

  void dispose() => _stopHeartbeat();

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      if (_busy) return;
      unawaited(_touchSafe());
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _touchSafe() async {
    try {
      await IsarSetup.touchOnlineNow(now: _clock());
    } catch (_) {
      // 未 init / 切槽瞬间 → 安全忽略(与原 main._recordOnline catchError 一致)。
    }
  }
}
