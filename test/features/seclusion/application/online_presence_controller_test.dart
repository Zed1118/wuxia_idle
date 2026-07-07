import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
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
      final item = await IsarSetup.instance.inventoryItems
          .getByDefId('item_mojianshi');
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
