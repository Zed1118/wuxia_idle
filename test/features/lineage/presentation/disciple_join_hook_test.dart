import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/lineage/presentation/disciple_join_hook.dart';
import 'package:wuxia_idle/features/lineage/presentation/disciple_join_overlay.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_reader_screen.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 轮询直到 [finder] 命中(或到 [maxTries] 上限),再走 [settleRounds] 轮让过场 /
/// hook 续拍落定:全程交替 [WidgetTester.runAsync](让 Isar 写 / 资产加载等真 async
/// 落地)+ [WidgetTester.pump](推进虚拟时钟 = 路由过场 / dialog pop 动画 / 渲染)。
/// 取代写死 sleep + 固定 pump 次数——全量并发下机器争用会让 async 链耗时超过任何固定
/// 延时 → flaky;轮询到可观测状态即停,既确定又通常更快。不用 [WidgetTester.pumpAndSettle]
/// ——它推进虚拟时钟会触发 overlay 的 auto-dismiss timer,破坏后续断言。超时后不额外
/// 断言,交由调用点的 expect 给出清晰失败。
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxTries = 120,
  int settleRounds = 4,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) break;
    // runAsync 推进真 async(Isar 写 / 资产加载);pump(step) 推进虚拟时钟
    // (路由过场 / dialog pop 动画 / hook 续拍),两者缺一 junior 段续不上。
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump(step);
  }
  // 找到后再走几轮 runAsync+pump 让过场 / hook 续拍的真 async 落定,后续 tap 才打得中。
  // 不用 pump(大时长):那是纯 fake-async 跳变,会把早返回时仍在途的真 async 打乱
  // (实测 pump(400) 会把刚 push 的叙事屏又弹掉)。
  for (var i = 0; i < settleRounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump(step);
  }
}

/// 第七阶段批三 · Task 8:拜入 overlay 渲染 + hook 接线(seeded Isar 直 pump)。
void main() {
  const holdMs = 3200; // > 默认 3.0s hold,覆盖 auto-dismiss timer。

  group('DiscipleJoinOverlay 渲染', () {
    testWidgets('缺图 portraitPath 不抛异常 + 题字渲染 + 点击触发 onDone', (tester) async {
      var doneCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscipleJoinOverlay(
              portraitPath: 'assets/does_not_exist.png',
              caption: UiStrings.discipleJoinCaption('剑无尘'),
              onDone: () => doneCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // errorBuilder 纸调兜底,不抛异常。
      expect(tester.takeException(), isNull);
      // 题字渲染。
      expect(find.text('剑无尘 拜入门下'), findsOneWidget);

      // 点击任意处 → onDone。
      await tester.tap(find.byType(DiscipleJoinOverlay));
      await tester.pump();
      expect(doneCount, 1);

      // 推进剩余 timer:once-guard 拦下二次。
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('空串 portraitPath 走兜底方框,不抛异常', (tester) async {
      var doneCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscipleJoinOverlay(
              portraitPath: '',
              caption: UiStrings.discipleJoinCaption('柳清歌'),
              onDone: () => doneCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('柳清歌 拜入门下'), findsOneWidget);

      // auto-dismiss timer 触发。
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCalled, isTrue);
    });
  });

  group('runDiscipleJoinHookAfterVictory 接线', () {
    late Directory tempDir;
    late Isar isar;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_disciple_join_hook_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      isar = IsarSetup.instance;
      // SOLO 开局:仅祖师 id=1。
      await OnboardingService(isar: isar).ensureFoundingMasters();
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 注意:hook 内含 Isar writeTxn(joinForClearedStage),testWidgets 的
    // fake-async 不驱动 Isar 真 async(memory「Isar widget test 死锁」),须用
    // [WidgetTester.runAsync] 让真 async 完成。hook 末尾 presentDiscipleJoin 会
    // await showGeneralDialog(只点击/timer 才 resolve),故 fire-and-forget 不 await
    // 整个 future,改用 [_pumpUntilFound] 轮询到目标屏出现——确定性同步点,不写死
    // sleep(全量并发下 async 链可 >600ms,固定延时会 flaky,曾致 disciple_join 全量偶挂)。
    testWidgets('过终局关(06_05) → 两弟子依次拜师叙事 + 立绘 + 满队', (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedContext = context;
                  capturedRef = ref;
                  return const Center(child: Text('host'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        // fire-and-forget:hook 末尾的 dialog 会阻塞整个 future,不 await。
        unawaited(runDiscipleJoinHookAfterVictory(
          context: capturedContext,
          ref: capturedRef,
          stageId: 'stage_06_05',
        ));
      });
      // 轮询到 senior 拜师叙事屏推入(Isar writeTxn + load 落地后 hook 才 push)。
      await _pumpUntilFound(tester, find.byType(NarrativeReaderScreen));

      // 第一段:senior 拜师叙事屏渲染 + 两弟子已入队(满队 3 人,写已落地)。
      expect(find.byType(NarrativeReaderScreen), findsOneWidget);
      await tester.runAsync(() async {
        final save = await isar.saveDatas.get(0);
        expect(save!.activeCharacterIds.length, 3, reason: '祖师+两弟子满队');
        final seniors = (await isar.characters.where().findAll())
            .where((c) => c.lineageRole == LineageRole.senior)
            .toList();
        expect(seniors.length, 1);
        final juniors = (await isar.characters.where().findAll())
            .where((c) => c.lineageRole == LineageRole.junior)
            .toList();
        expect(juniors.length, 1);
      });

      // 跳过 senior 叙事 → senior 立绘 overlay。
      await tester.tap(find.text('跳过'));
      await _pumpUntilFound(tester, find.byType(DiscipleJoinOverlay));
      expect(find.byType(DiscipleJoinOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 点击关闭 senior 立绘 → hook 续第二段 junior 叙事。
      await tester.tap(find.byType(DiscipleJoinOverlay));
      await _pumpUntilFound(tester, find.byType(NarrativeReaderScreen));
      expect(find.byType(NarrativeReaderScreen), findsOneWidget,
          reason: 'junior 第二段拜师叙事');

      // 跳过 junior 叙事 → junior 立绘 → 关闭,清 pending timer。
      await tester.tap(find.text('跳过'));
      await _pumpUntilFound(tester, find.byType(DiscipleJoinOverlay));
      expect(find.byType(DiscipleJoinOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DiscipleJoinOverlay));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('非 join 关 → no-op,不弹叙事/overlay,弟子不变', (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedContext = context;
                  capturedRef = ref;
                  return const Center(child: Text('host'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        // 非 join 关:hook 内 service gate 返回 null → 提前 return,可安全 await 全程。
        await runDiscipleJoinHookAfterVictory(
          context: capturedContext,
          ref: capturedRef,
          stageId: 'stage_01_01',
        );
      });
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(NarrativeReaderScreen), findsNothing);
      expect(find.byType(DiscipleJoinOverlay), findsNothing);
      // 仅 founder(Isar 真 async 查询包 runAsync 防死锁)。
      await tester.runAsync(() async {
        expect((await isar.characters.where().findAll()).length, 1);
      });
    });
  });
}
