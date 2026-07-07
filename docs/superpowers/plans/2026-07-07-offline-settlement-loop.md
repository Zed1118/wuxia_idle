# 离线结算闭环（体检 P0-3 方案 B）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 挂后台/退出的离线窗口在重新聚焦与启动时都被正确结算一次且仅一次（丢失/双吃双修）。

**Architecture:** 新 `OnlinePresenceController`（keepAlive Provider,持 Ref）统一「基准 lastOnlineAt 生命周期侧写入 + 静默结算」;gate 范围 B 委托给它;main.dart 经新 `OnlinePresenceLifecycleHook` widget 接 AppLifecycleListener。零 schema/数值变更。

**Tech Stack:** Flutter Desktop / Riverpod 3 / Isar。测试:plain `test()` + 真 Isar temp 目录（Isar 在 testWidgets 内 writeTxn 死锁,memory 已记）,接线冒烟用 fake controller 的 testWidgets。

**Spec:** `docs/superpowers/specs/2026-07-07-offline-settlement-loop-design.md`
**Branch:** `worktree-offline-settlement-loop`（基点 main `e8f99d28`,worktree 已预热:pub get/dylib/build_runner ✓）

**关键既有事实（本会话 grep 核实）:**
- 结算核心:`OfflinePassiveService.settle`（`lib/features/seclusion/application/offline_passive_service.dart:62`,txn 末自置 `lastOnlineAt=now`）。`PassiveYield.awayHours` 为未 cap 原始时长。
- active 闭关查询:`ref.read(seclusionServiceProvider)?.getActiveSession(IsarSetup.currentSlotId)`（`seclusion_service.dart:114`;svc 未 init 时 provider 返 null）。
- invalidate 范例:`stage_entry_flow.dart:374-380`;settle 触及 Character+InventoryItem → 需 `characterByIdProvider`（codegen family,`lib/core/application/character_providers.dart`）+ `allInventoryItemsProvider`（Future 型,`lib/core/application/inventory_providers.dart:57`）。
- 测试 harness 模板:`test/features/seclusion/application/online_timestamp_recorder_test.dart`（initializeIsarCore+GameRepository+temp dir init/close）。
- active session 造数:`RetreatSession()..saveDataId=1..mapType=RetreatMapType.shanLin..durationHours=4..startedAt=...`（`offline_recap_gate_test.dart:27`）。
- 新档 `lastOnlineAt == createdAt`（`isar_setup.dart:231`）→ 旧档首启分支据此判定。

---

### Task 1: OnlinePresenceController 核心 settlePassiveWindow

**Files:**
- Create: `lib/features/seclusion/application/online_presence_controller.dart`
- Test: `test/features/seclusion/application/online_presence_controller_test.dart`

- [ ] **Step 1: 写失败测试**（R1 聚焦窗口结算 / R4 闭关互斥只 touch / R5 未 init no-op / 旧档首启 / 时钟回拨 / R8 provider 刷新）

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_presence_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await IsarSetup.close();
  });

  OnlinePresenceController controller() =>
      container.read(onlinePresenceControllerProvider);

  test('R5: Isar 关闭时 settlePassiveWindow 安全返回 null', () async {
    await IsarSetup.close();
    expect(await controller().settlePassiveWindow(), isNull);
    await IsarSetup.init(directory: tempDir, inspector: false); // 供 tearDown
  });

  test('旧档首启: lastOnlineAt==createdAt → 只建基准不结算', () async {
    final now = DateTime(2026, 7, 7, 20);
    expect(await controller().settlePassiveWindow(now: now), isNull);
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.lastOnlineAt, now);
    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item, isNull);
  });

  test('R1: 8h 窗口结算入包并重置基准', () async {
    final t0 = DateTime(2026, 7, 7, 10);
    final t1 = DateTime(2026, 7, 7, 18);
    await IsarSetup.touchOnlineNow(now: t0); // 建立非 createdAt 基准
    final yield_ = await controller().settlePassiveWindow(now: t1);
    expect(yield_, isNotNull);
    expect(yield_!.awayHours, closeTo(8.0, 0.001));
    expect(yield_.mojianshi, 2); // 0.25/h × 8h × 学徒 scale 1.0 → floor 2
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.lastOnlineAt, t1);
    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item?.quantity, 2);
  });

  test('R4: active 闭关 → 只 touch 不结算(互斥+修 stale 基准边角)', () async {
    final t0 = DateTime(2026, 7, 7, 10);
    final t1 = DateTime(2026, 7, 7, 18);
    await IsarSetup.touchOnlineNow(now: t0);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.retreatSessions.put(
        RetreatSession()
          ..saveDataId = IsarSetup.currentSlotId
          ..mapType = RetreatMapType.shanLin
          ..durationHours = 4
          ..startedAt = t0,
      );
    });
    expect(await controller().settlePassiveWindow(now: t1), isNull);
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.lastOnlineAt, t1); // touch 发生
    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item, isNull); // 被动 0 入包
  });

  test('时钟回拨: awayHours<=0 → no-op 基准不动', () async {
    final t0 = DateTime(2026, 7, 7, 10);
    await IsarSetup.touchOnlineNow(now: t0);
    expect(
      await controller().settlePassiveWindow(now: DateTime(2026, 7, 7, 9)),
      isNull,
    );
    expect((await IsarSetup.currentSaveData())!.lastOnlineAt, t0);
  });

  test('R8: 结算后 allInventoryItemsProvider 读到新值', () async {
    final t0 = DateTime(2026, 7, 7, 10);
    await IsarSetup.touchOnlineNow(now: t0);
    final before = await container.read(allInventoryItemsProvider.future);
    expect(before.where((i) => i.defId == 'item_mojianshi'), isEmpty);
    await controller().settlePassiveWindow(now: DateTime(2026, 7, 7, 18));
    final after = await container.read(allInventoryItemsProvider.future);
    expect(
      after.singleWhere((i) => i.defId == 'item_mojianshi').quantity,
      2,
    );
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test --no-pub test/features/seclusion/application/online_presence_controller_test.dart`
Expected: 编译失败（`online_presence_controller.dart` 不存在）。

- [ ] **Step 3: 最小实现**

```dart
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
/// - [settlePassiveWindow]:对 [基准, now] 窗口静默结算(含互斥/旧档/回拨守卫),
///   gate 启动路径与聚焦路径共用,消灭第二套基准逻辑。
/// - 前台心跳(默认 60s)持续 touch 基准 → 聚焦态直接退出的双吃上界 ≤ 心跳间隔。
///   心跳间隔是纯防御工程参数(不影响任何收益数值),故留代码常量不进 numbers.yaml。
/// - [onAppFocused]/[onAppBlurred]:由 OnlinePresenceLifecycleHook 接线。
///   首启结算归 gate([markStartupSettleDone] 前 focused 整体 no-op,
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
    // stage_entry_flow._invalidateCharacterFamilyAfterCombat)。
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
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test --no-pub test/features/seclusion/application/online_presence_controller_test.dart`
Expected: 6/6 PASS。若 R1 的 `mojianshi==2` 因 numbers 变动失配,按 `numbers.yaml passive_idle`(0.25/h·xueTu scale 1.0)现算修正断言,不改生产码。

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/application/online_presence_controller.dart test/features/seclusion/application/online_presence_controller_test.dart
git commit -m "feat: OnlinePresenceController 统一被动离线结算窗口(P0-3 核心)"
```

---

### Task 2: 心跳 + 聚焦/失焦/首启门控

**Files:**
- Modify: `lib/features/seclusion/application/online_presence_controller.dart`（Task 1 已含实现,本 task 只补测试;若测试暴露缺陷再改）
- Test: `test/features/seclusion/application/online_presence_controller_test.dart`（追加 group）

- [ ] **Step 1: 追加失败测试**（R2 心跳压双吃 / R3 首启去重 / R6 幂等;心跳测试用短间隔 override + 真实延时,不用 fake_async——Isar 真 I/O 在 FakeAsync 下不推进）

```dart
  // 追加到同文件 main() 内:
  group('心跳与生命周期门控', () {
    OnlinePresenceController shortBeat({DateTime Function()? clock}) {
      final c = ProviderContainer(
        overrides: [
          onlinePresenceControllerProvider.overrideWith((ref) {
            final ctl = OnlinePresenceController(
              ref,
              clock: clock,
              heartbeatInterval: const Duration(milliseconds: 40),
            );
            ref.onDispose(ctl.dispose);
            return ctl;
          }),
        ],
      );
      addTearDown(c.dispose);
      return c.read(onlinePresenceControllerProvider);
    }

    test('R3: markStartupSettleDone 前 onAppFocused 整体 no-op', () async {
      final t0 = DateTime(2026, 7, 7, 10);
      await IsarSetup.touchOnlineNow(now: t0);
      final ctl = shortBeat();
      ctl.onAppFocused();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(ctl.isHeartbeatActive, isFalse);
      expect((await IsarSetup.currentSaveData())!.lastOnlineAt, t0); // 基准没被碰
      final item =
          await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
      expect(item, isNull); // 未结算
    });

    test('R2: 心跳持续推进基准(双吃上界≤间隔)', () async {
      await IsarSetup.touchOnlineNow(now: DateTime(2026, 7, 7, 10));
      final ctl = shortBeat(); // clock 默认 DateTime.now
      ctl.markStartupSettleDone();
      expect(ctl.isHeartbeatActive, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final save = (await IsarSetup.currentSaveData())!;
      // 基准已被心跳刷到「现在」附近 → 模拟 kill 后重启,窗口≈0
      expect(
        DateTime.now().difference(save.lastOnlineAt).inMilliseconds,
        lessThan(500),
      );
    });

    test('R6: 失焦停心跳+终 touch;再聚焦结算窗口并恢复;重复聚焦幂等', () async {
      final t0 = DateTime(2026, 7, 7, 10);
      await IsarSetup.touchOnlineNow(now: t0);
      // 固定时钟只用于失焦 touch/心跳;结算窗口用显式 now 驱动
      final tBlur = DateTime(2026, 7, 7, 12);
      final ctl = shortBeat(clock: () => tBlur);
      ctl.markStartupSettleDone();
      ctl.onAppBlurred();
      expect(ctl.isHeartbeatActive, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect((await IsarSetup.currentSaveData())!.lastOnlineAt, tBlur);

      // 8h 后聚焦:先直接调 settlePassiveWindow 验证窗口(focused 的 unawaited
      // 路径不可注入 now),再验 onAppFocused 恢复心跳 + 幂等不双结。
      final tBack = DateTime(2026, 7, 7, 20);
      final yield_ = await ctl.settlePassiveWindow(now: tBack);
      expect(yield_!.awayHours, closeTo(8.0, 0.001));
      ctl.onAppFocused();
      expect(ctl.isHeartbeatActive, isTrue);
      ctl.onAppFocused(); // 幂等:已在前台直接 return
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final item = await IsarSetup.instance.inventoryItems
          .getByDefId('item_mojianshi');
      expect(item?.quantity, 2); // 只有 8h 窗口那一次入包
    });
  });
```

- [ ] **Step 2: 跑测**

Run: `flutter test --no-pub test/features/seclusion/application/online_presence_controller_test.dart`
Expected: 9/9 PASS（Task 1 实现已覆盖;若 R2/R6 时序 flaky,放宽延时到 200ms 级再跑 3 次确认稳定）。

- [ ] **Step 3: Commit**

```bash
git add test/features/seclusion/application/online_presence_controller_test.dart
git commit -m "test: 心跳压双吃/首启门控/聚焦幂等三族用例(P0-3)"
```

---

### Task 3: gate 范围 B 委托 controller

**Files:**
- Modify: `lib/features/seclusion/presentation/offline_recap_gate.dart`（范围 B 全段 :75-120 替换;范围 A 块首加 mark）
- Test: 既有 `test/features/seclusion/presentation/offline_passive_gate_test.dart` / `offline_recap_gate_test.dart` 零改动跑绿（R7）

- [ ] **Step 1: 改 gate**（imports 增 `../application/online_presence_controller.dart`,删不再用的 `../../../data/isar_setup.dart`/`offline_passive_service.dart` import 若 analyze 报 unused）

范围 A `if (session != null) {` 块内**首行**加:

```dart
    // P0-3:闭关期间也起心跳保基准新鲜(修收功后 stale 基准双吃边角)。
    ref.read(onlinePresenceControllerProvider).markStartupSettleDone();
```

范围 B 整段(原 `// —— 范围 B ...` 注释起到函数尾)替换为:

```dart
  // —— 范围 B:无 active 闭关,统一经 OnlinePresenceController 结算被动 ——
  // (体检 P0-3:基准检查/互斥/旧档首启/回拨守卫全在 controller 单点,
  //  gate 只保留启动路径专属的弹卡语义。)
  final controller = ref.read(onlinePresenceControllerProvider);
  final yield_ = await controller.settlePassiveWindow(now: now);
  controller.markStartupSettleDone();
  if (yield_ == null) return;

  final cfg = GameRepository.instance.numbers.passiveIdle;
  if (yield_.awayHours < cfg.minRecapHours) return; // 已静默入包,不弹卡
  if ((yield_.mojianshi == 0 && yield_.experience == 0) || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: OfflineRecapCard.passive(
        mojianshi: yield_.mojianshi,
        experience: yield_.experience,
        awayHours: yield_.awayHours,
        settledHours: yield_.settledHours,
        isCapped: yield_.isCapped,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
```

- [ ] **Step 2: 跑既有 gate 测试(零改动)**

Run: `flutter test --no-pub test/features/seclusion/presentation/`
Expected: 全 PASS。注意:gate 现在会经 markStartupSettleDone 起 60s 心跳,widget 测靠 ProviderScope 卸载 → provider onDispose → timer cancel 回收;若出现 pending timer 报错,说明该测试自建 container 未 dispose——修测试侧 addTearDown,不改生产码。

- [ ] **Step 3: `flutter analyze lib test` 确认 0**（unused import 一并清）

- [ ] **Step 4: Commit**

```bash
git add lib/features/seclusion/presentation/offline_recap_gate.dart
git commit -m "refactor: gate 范围B委托 OnlinePresenceController,基准写入单点化(P0-3)"
```

---

### Task 4: main.dart 生命周期接线(hook widget)

**Files:**
- Create: `lib/features/seclusion/presentation/online_presence_lifecycle_hook.dart`
- Modify: `lib/main.dart`（删 `_lifecycle`/`_recordOnline`/相关 import,MaterialApp 外包 hook）
- Test: `test/features/seclusion/presentation/online_presence_lifecycle_hook_test.dart`

- [ ] **Step 1: 写失败测试**（fake controller 录调用,不碰 Isar）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/features/seclusion/presentation/online_presence_lifecycle_hook.dart';

class _RecordingController extends OnlinePresenceController {
  _RecordingController(super.ref);
  final calls = <String>[];
  @override
  void onAppFocused() => calls.add('focused');
  @override
  void onAppBlurred() => calls.add('blurred');
}

void main() {
  testWidgets('生命周期状态变化路由到 controller', (tester) async {
    late _RecordingController recorder;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onlinePresenceControllerProvider.overrideWith((ref) {
            recorder = _RecordingController(ref);
            return recorder;
          }),
        ],
        child: const OnlinePresenceLifecycleHook(child: SizedBox()),
      ),
    );
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(recorder.calls, contains('blurred'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(recorder.calls, contains('focused'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(recorder.calls.where((c) => c == 'blurred').length,
        greaterThanOrEqualTo(2));
  });
}
```

- [ ] **Step 2: 实现 hook widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/online_presence_controller.dart';

/// App 生命周期 → [OnlinePresenceController] 接线(体检 P0-3)。
/// 原 main.dart `_recordOnline`(只 touch 不结算)由此取代:
/// 失焦停心跳+终 touch,聚焦结算失焦窗口+恢复心跳。
class OnlinePresenceLifecycleHook extends ConsumerStatefulWidget {
  const OnlinePresenceLifecycleHook({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnlinePresenceLifecycleHook> createState() =>
      _OnlinePresenceLifecycleHookState();
}

class _OnlinePresenceLifecycleHookState
    extends ConsumerState<OnlinePresenceLifecycleHook> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onShow: _onFocused,
      onResume: _onFocused,
      onHide: _onBlurred,
      onInactive: _onBlurred,
      onDetach: _onBlurred,
    );
  }

  void _onFocused() =>
      ref.read(onlinePresenceControllerProvider).onAppFocused();

  void _onBlurred() =>
      ref.read(onlinePresenceControllerProvider).onAppBlurred();

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 3: main.dart 收编**——`_WuxiaAppState` 删 `_lifecycle` 字段/`initState`/`_recordOnline`/`dispose`(整个 State 只剩 build → `WuxiaApp` 降为 `ConsumerWidget`),删 `dart:async`+`data/isar_setup.dart` import,加 hook import;`MaterialApp` 外包:

```dart
        child: OnlinePresenceLifecycleHook(
          child: MaterialApp(
            title: UiStrings.appTitle,
            theme: wuxiaAppTheme(),
            debugShowCheckedModeBanner: false,
            builder: _wuxiaTextScaleBuilder,
            home: const SplashScreen(),
          ),
        ),
```

- [ ] **Step 4: 跑测 + analyze**

Run: `flutter test --no-pub test/features/seclusion/presentation/online_presence_lifecycle_hook_test.dart && flutter analyze lib test`
Expected: PASS + No issues。

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/features/seclusion/presentation/online_presence_lifecycle_hook.dart test/features/seclusion/presentation/online_presence_lifecycle_hook_test.dart
git commit -m "feat: 生命周期接线 OnlinePresenceLifecycleHook,失焦/聚焦驱动结算闭环(P0-3)"
```

---

### Task 5: 批末验证

- [ ] `flutter analyze lib test` → 0
- [ ] targeted:`flutter test --no-pub test/features/seclusion/` 全绿
- [ ] **全量** `flutter test --no-pub`(并发,~2.5min;跨切面:触结算路径)——落日志 grep 首个 `-1`,禁 `| tail` 截尾;基线 3723 pass/1 skip,新增测试数对上算式
- [ ] 真机冒烟(可选,主会话拍板):`flutter run -d macos` 失焦→聚焦观察结算日志/仓库数
- [ ] Commit(若有收尾修正)

**合并回 main(主会话执行,不在本 plan 内):**`git status -sb` 查分支漂移 → main 上 `git merge --no-ff` → 主 checkout targeted 复验 → push + CI → PROGRESS 更新。
