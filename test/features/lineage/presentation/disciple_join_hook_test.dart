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
    // 整个 future,在 runAsync 延时让 Isar+load 落地后再 pump 渲染推入的路由。
    testWidgets('过 join 关 → 弟子入队 + 拜师叙事 + 立绘 overlay', (tester) async {
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
          stageId: 'stage_01_02',
        ));
        // 让 Isar writeTxn + NarrativeLoader.load 真 async 落地。
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 拜师叙事屏渲染。
      expect(find.byType(NarrativeReaderScreen), findsOneWidget);

      // 弟子已入队:senior 弟子存在 + activeCharacterIds 含其 id(Isar 写已落地)。
      // Isar 真 async 查询须在 runAsync 内,否则 testWidgets fake-async 死锁。
      await tester.runAsync(() async {
        final seniors = (await isar.characters.where().findAll())
            .where((c) => c.lineageRole == LineageRole.senior)
            .toList();
        expect(seniors.length, 1);
        final save = await isar.saveDatas.get(0);
        expect(save!.activeCharacterIds.contains(seniors.first.id), true);
      });

      // 跳过叙事 → _finish pop → hook 续 presentDiscipleJoin 弹立绘 overlay。
      await tester.tap(find.text('跳过'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 拜入立绘 overlay 渲染,题字含弟子名「拜入门下」(scope 到 overlay 子树,
      // 因 NarrativeReaderScreen fallbackTitle 也用同一 caption),缺图不崩。
      expect(find.byType(DiscipleJoinOverlay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DiscipleJoinOverlay),
          matching: find.textContaining('拜入门下'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // 点击 overlay 关闭,清掉 pending timer(auto-dismiss)。
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
