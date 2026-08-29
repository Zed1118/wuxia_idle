import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import '../../../../support/test_data.dart';
import 'phase0a_terminal_test_driver.dart';

/// Phase 0A Batch 9B 终局重试入口红测(plan §验收):
/// - controller.restart 换入新 flow 后 state 完全复位且事件流重新被接受;
/// - 终局后「再战」纸签按钮出现,点击/Enter 再战,封签消失;
/// - retryFlowBuilder == null(静态验收路由)时按钮不出现。
void main() {
  const retryButtonKey = ValueKey('phase0a_retry_button');
  const outcomeSealKey = ValueKey('phase0a_outcome_seal');

  late Phase0aDebugBattleFixture fixture;
  late Phase0aBattleController controller;

  Future<Phase0aDebugBattleFixture> loadFixture() =>
      Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
      );

  setUp(() async {
    await loadTestGameRepository();
    fixture = await loadFixture();
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
  });

  tearDown(GameRepository.resetForTest);

  /// 用真实移动、普攻和清场技把确定性 fixture 驱动到胜利终局。
  void driveToEnd() {
    for (var i = 0; i < 2000; i++) {
      if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
      controller.step(phase0aVictoryTerminalCommand(controller));
    }
    expect(controller.outcome, Phase0aBattleOutcome.victory);
  }

  group('Phase0aBattleController.restart', () {
    test('终局后换入新 flow:state 完全复位,新事件流被排序器接受', () async {
      final initialTick = controller.state.tick;
      final initialSeq = controller.state.nextSeq;
      final initialEnemyIds = [
        for (final enemy in controller.state.enemies) enemy.id,
      ];
      driveToEnd();
      final endTick = controller.state.tick;
      expect(endTick, greaterThan(initialTick));

      final fresh = await loadFixture();
      controller.restart(fresh.flow);

      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(controller.state.tick, initialTick);
      expect(controller.state.nextSeq, initialSeq);
      expect(
        controller.state.player.currentHealth,
        controller.state.player.maxHealth,
      );
      expect([
        for (final enemy in controller.state.enemies) enemy.id,
      ], initialEnemyIds);
      expect(controller.lastEvents, isEmpty);
      expect(controller.events, isEmpty);
      expect(controller.feedback, isEmpty);

      // 排序器已重建:新会话从同一初始 seq 起的事件不得被当重复吞掉。
      final events = controller.step(const Phase0aPlayerCommand());
      expect(events, isNotEmpty);
      expect(events.any((e) => e is Phase0aWaveStarted), isTrue);
    });
  });

  group('Phase0aBattleScreen 终局重试入口', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required bool withRetryBuilder,
      Future<Phase0aWaveBattleFlow> Function()? retryBuilderOverride,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            retryFlowBuilder: withRetryBuilder
                ? retryBuilderOverride ?? () async => (await loadFixture()).flow
                : null,
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> driveToEndPumped(WidgetTester tester) async {
      for (var i = 0; i < 2000; i++) {
        if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
        controller.step(phase0aVictoryTerminalCommand(controller));
        await tester.pump();
      }
      expect(controller.outcome, Phase0aBattleOutcome.victory);
    }

    testWidgets('终局后出现「再战」,点击后封签消失、state 复位再战', (tester) async {
      await pumpScreen(tester, withRetryBuilder: true);
      // 进行中不出现重试按钮。
      expect(find.byKey(retryButtonKey), findsNothing);

      await driveToEndPumped(tester);
      expect(find.byKey(outcomeSealKey), findsOneWidget);
      expect(find.byKey(retryButtonKey), findsOneWidget);

      // _retry 内部 await retryFlowBuilder(真实异步资产加载),
      // 需 runAsync 让真实事件循环跑完,再 pump 触发重建。
      await tester.runAsync(() async {
        await tester.tap(find.byKey(retryButtonKey));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump();

      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(find.byKey(outcomeSealKey), findsNothing);
      expect(find.byKey(retryButtonKey), findsNothing);
      expect(
        controller.state.player.currentHealth,
        controller.state.player.maxHealth,
      );
    });

    testWidgets('终局清理 held movement,同 controller 直接 restart 不继承', (
      tester,
    ) async {
      await pumpScreen(tester, withRetryBuilder: true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 220));

      await driveToEndPumped(tester);
      expect(find.byKey(retryButtonKey), findsOneWidget);

      late Phase0aDebugBattleFixture fresh;
      await tester.runAsync(() async {
        fresh = await loadFixture();
      });
      controller.restart(fresh.flow);
      await tester.pump();
      final freshX = controller.state.player.position.x;

      await tester.pump(const Duration(milliseconds: 220));
      expect(controller.state.player.position.x, freshX);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    });

    testWidgets('retry restart 成功后显式清除等待期间产生的 held input', (tester) async {
      final retryGate = Completer<Phase0aWaveBattleFlow>();
      await pumpScreen(
        tester,
        withRetryBuilder: true,
        retryBuilderOverride: () => retryGate.future,
      );
      await driveToEndPumped(tester);

      late Phase0aDebugBattleFixture intermediate;
      late Phase0aDebugBattleFixture retryTarget;
      await tester.runAsync(() async {
        intermediate = await loadFixture();
        retryTarget = await loadFixture();
      });
      await tester.tap(find.byKey(retryButtonKey));
      await tester.pump();

      // 模拟 retry 异步等待期间同一 controller 被恢复为 ongoing；此时按住 D
      // 会写入 screen held 集合。真正 retry 完成后必须显式清掉该集合。
      controller.restart(intermediate.flow);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      retryGate.complete(retryTarget.flow);
      await tester.pump();
      await tester.pump();

      final freshX = controller.state.player.position.x;
      await tester.pump(const Duration(milliseconds: 220));
      expect(controller.state.player.position.x, freshX);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    });

    testWidgets('Enter 键终局再战与点击同效', (tester) async {
      await pumpScreen(tester, withRetryBuilder: true);
      await driveToEndPumped(tester);
      expect(find.byKey(retryButtonKey), findsOneWidget);

      await tester.runAsync(() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump();

      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(find.byKey(outcomeSealKey), findsNothing);
    });

    testWidgets('retryFlowBuilder 为 null 时终局只有封签没有按钮', (tester) async {
      await pumpScreen(tester, withRetryBuilder: false);
      await driveToEndPumped(tester);

      expect(find.byKey(outcomeSealKey), findsOneWidget);
      expect(find.byKey(retryButtonKey), findsNothing);

      // Enter 也不应触发任何变化。
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.outcome, Phase0aBattleOutcome.victory);
    });
  });
}
