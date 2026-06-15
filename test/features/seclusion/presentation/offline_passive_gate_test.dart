import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_gate.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// M2 范围 B gate「旧档首启不回溯」守卫专测（spec §7 #4）。
///
/// 场景：lastOnlineAt == createdAt（新档 / 旧档基准未建立），无 active 闭关。
/// 预期：不结算被动、不弹被动卡；lastOnlineAt 更新为传入 now（建基准）。
///
/// 注意：范围 B 旧档守卫调 touchOnlineNow（Isar writeTxn），testWidgets 的
/// fake-async 不驱动 Isar 真 async，须用 [WidgetTester.runAsync] 包裹交互让
/// writeTxn 真正完成（否则 tearDown close 撞 "Cannot add event while adding
/// stream"，见 memory feedback_isar_widget_test_deadlock）。直接 await
/// maybeShowOfflineRecap（捕获 context/ref），不经 button tap（fake-async 下
/// onPressed 的 async 不被 await）。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_gate_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    // init 后 createdAt == lastOnlineAt（新档天然如此）
  });

  tearDown(() async {
    await IsarSetup.close();
  });

  testWidgets('旧档首启不回溯：不结算被动、不弹被动卡、建立 lastOnlineAt 基准',
      (tester) async {
    await tester.runAsync(() async {
      // 确认初始状态：lastOnlineAt == createdAt（守卫触发条件）
      final saveBefore = (await IsarSetup.currentSaveData())!;
      expect(saveBefore.lastOnlineAt, saveBefore.createdAt);

      // 传一个比 createdAt 晚很久的 now，模拟「离线很久的旧档首次启动」。
      // 守卫看的是 lastOnlineAt==createdAt（基准未建立），与时长无关。
      final nowInject = saveBefore.createdAt.add(const Duration(hours: 48));

      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 无 active 闭关 → 走范围 B 路径
            activeRetreatSessionProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold();
              },
            ),
          ),
        ),
      );

      // 直接 await gate（旧档守卫在 settle/showDialog 之前 return）。
      await maybeShowOfflineRecap(
        context: capturedContext,
        ref: capturedRef,
        now: nowInject,
      );

      // 不弹被动卡 / 归来卡（守卫在 settle 之前 return）
      expect(find.text(UiStrings.passiveRecapTitle), findsNothing);
      expect(find.text(UiStrings.offlineRecapTitle), findsNothing);

      // 被动累计字段仍为 0（未结算 → 旧档不回溯）
      final saveAfter = (await IsarSetup.currentSaveData())!;
      expect(saveAfter.totalPassiveMojianshi, 0);
      expect(saveAfter.totalPassiveExperience, 0);

      // lastOnlineAt 已更新为 nowInject（touchOnlineNow 建基准，走的是守卫
      // 而非结算路径）
      expect(saveAfter.lastOnlineAt, nowInject);
    });
  });
}
