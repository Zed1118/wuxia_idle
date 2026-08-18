import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import '../../../../support/test_data.dart';

/// Phase 0C 工程嵌入验证红测(2026-08-18,详
/// `docs/superpowers/plans/2026-08-18-phase0c-engineering-embed-verify.md`)。
///
/// 契约(v2 方案 §11 Phase 0C 通过条件的可测子集):
/// - **50 次进退**:整屏反复 mount/unmount 50 次零异常——Ticker/FocusNode
///   dispose 成对由 flutter_test 框架兜底(泄漏即测试红),期间输入通路
///   与暂停键反复抽检不失效;
/// - **Esc 暂停/继续**(spec §3.1):暂停中 autoStep 世界零推进(tick 冻结)、
///   战斗键与 Esc 外的输入不受理、横幅在位;恢复后推进复原、横幅消失;
///   终局态 Esc 无效;
/// - **窗口缩放**:1280×720 → 1440×900 → 1152×648 三视口切换整屏可重建;
/// - **存档零污染静态守卫**:phase0a 三层源码禁止任何 Isar/持久化符号
///   (隔离是架构级保证,本守卫防未来接线回归)。
///
/// 全程真实 `Phase0aDebugBattleFixture` 驱动,禁 fake flow;手动步进与
/// 帧泵结合,不依赖 pumpAndSettle / 像素颜色。
void main() {
  const screenStackKey = ValueKey('phase0a_battle_screen');
  const pausedBannerKey = ValueKey('phase0a_paused_banner');

  late Phase0aDebugBattleFixture fixture;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
  });

  tearDown(GameRepository.resetForTest);

  Phase0aBattleController newController() => Phase0aBattleController(
    flow: fixture.flow,
    roster: fixture.roster,
    fixedDeltaSeconds: fixture.fixedDeltaSeconds,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Phase0aBattleController controller, {
    Size viewport = const Size(1280, 720),
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: Phase0aBattleScreen(controller: controller)),
    );
    await tester.pump();
  }

  group('0C · 50 次进退稳定性', () {
    testWidgets('mount/unmount 50 次零异常,输入与暂停键抽检不失效', (tester) async {
      final controller = newController();
      for (var cycle = 1; cycle <= 50; cycle++) {
        await tester.pumpWidget(
          MaterialApp(home: Phase0aBattleScreen(controller: controller)),
        );
        await tester.pump();
        expect(find.byKey(screenStackKey), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '第 $cycle 次进入异常');

        if (cycle % 10 == 0) {
          if (controller.outcome == Phase0aBattleOutcome.ongoing) {
            // 输入通路抽检:键盘 attack 经 enqueue → step 推进真实 tick。
            await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
            final tickBefore = controller.state.tick;
            controller.step();
            expect(
              controller.state.tick,
              greaterThan(tickBefore),
              reason: '第 $cycle 次进入后输入/推进失效',
            );
          }
          // 暂停键通路抽检:横幅出现(并立即恢复,不污染后续循环)。
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump();
          expect(
            find.byKey(pausedBannerKey),
            findsOneWidget,
            reason: '第 $cycle 次进入后 Esc 暂停失效',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump();
          expect(find.byKey(pausedBannerKey), findsNothing);
        }

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '第 $cycle 次退出异常');
      }
    });

    testWidgets('暂停中发送的战斗键被丢弃,恢复后不补放', (tester) async {
      final controller = newController();
      await pumpScreen(tester, controller);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(pausedBannerKey), findsOneWidget);
      // 暂停中塞入攻击与移动:一律不受理。
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      final frozenTick = controller.state.tick;
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.state.tick, frozenTick);
      // 恢复:横幅消失,autoStep 推进复原,且暂停中的键不补放
      // (恢复后首帧 delta 基准重建,tick 只随恢复后的真实时长推进)。
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(pausedBannerKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.state.tick, greaterThan(frozenTick));
    });
  });

  group('0C · Esc 暂停/继续', () {
    testWidgets('暂停中 autoStep 世界零推进,恢复后推进复原', (tester) async {
      final controller = newController();
      await pumpScreen(tester, controller);
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.state.tick, greaterThan(0), reason: '基线推进未发生');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(pausedBannerKey), findsOneWidget);
      final frozenTick = controller.state.tick;
      // 暂停中连续泵帧:tick 冻结(不记性能样本口径的测试投影)。
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.state.tick, frozenTick);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(pausedBannerKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.state.tick, greaterThan(frozenTick));
    });

    testWidgets('终局态 Esc 无效,不产生暂停横幅', (tester) async {
      final controller = newController();
      await pumpScreen(tester, controller);
      // 打到终局(复用手动步进,最多 3000 拍兜底防 fixture 变更挂死)。
      var guard = 0;
      while (controller.outcome == Phase0aBattleOutcome.ongoing &&
          guard < 3000) {
        controller.step();
        guard++;
      }
      expect(
        controller.outcome,
        isNot(Phase0aBattleOutcome.ongoing),
        reason: '未达终局',
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(pausedBannerKey), findsNothing);
    });
  });

  group('0C · 窗口缩放', () {
    testWidgets('1280×720 → 1440×900 → 1152×648 三视口切换整屏可重建', (tester) async {
      final controller = newController();
      const viewports = [Size(1280, 720), Size(1440, 900), Size(1152, 648)];
      for (final viewport in viewports) {
        await tester.binding.setSurfaceSize(viewport);
        await tester.pumpWidget(
          MaterialApp(home: Phase0aBattleScreen(controller: controller)),
        );
        await tester.pump();
        expect(find.byKey(screenStackKey), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$viewport 构建异常');
        // 缩放后推进一拍仍正常(domain 与视口无关)。
        final tickBefore = controller.state.tick;
        controller.step();
        expect(controller.state.tick, greaterThan(tickBefore));
      }
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('0C · 存档零污染静态守卫', () {
    test('phase0a 三层源码零 Isar/持久化符号', () {
      const dirs = [
        'lib/features/battle/domain/phase0a',
        'lib/features/battle/application/phase0a',
        'lib/features/battle/presentation/phase0a',
      ];
      final forbidden = <RegExp>[
        RegExp(r'\bIsar\b'),
        RegExp(r'\bIsarSetup\b'),
        RegExp(r'isar_setup\.dart'),
        RegExp(r'package:isar'),
      ];
      final violations = <String>[];
      for (final dir in dirs) {
        for (final file in Directory(dir).listSync(recursive: true)) {
          if (file is! File || !file.path.endsWith('.dart')) continue;
          final lines = file.readAsStringSync().split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            final code = line.replaceFirst(RegExp(r'//.*$'), '');
            for (final pattern in forbidden) {
              if (pattern.hasMatch(code)) {
                violations.add('${file.path}:${i + 1}: $line');
              }
            }
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Phase 0A 生产层必须与正式存档架构级隔离'
            '(v2 方案 §9.4 / 0C 存档零污染条件):\n${violations.join('\n')}',
      );
    });
  });
}
