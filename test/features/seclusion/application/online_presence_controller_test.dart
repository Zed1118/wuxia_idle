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
