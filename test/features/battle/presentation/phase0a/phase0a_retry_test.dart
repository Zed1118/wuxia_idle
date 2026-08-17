import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import '../../../../support/test_data.dart';

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

  /// 原地普攻打到终局(确定性 fixture,9A 已证 2000 拍内必胜)。
  void driveToEnd() {
    for (var i = 0; i < 2000; i++) {
      if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
      controller.step(const Phase0aPlayerCommand(attack: true));
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
    }) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            retryFlowBuilder: withRetryBuilder
                ? () async => (await loadFixture()).flow
                : null,
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> driveToEndPumped(WidgetTester tester) async {
      for (var i = 0; i < 2000; i++) {
        if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
        controller.step(const Phase0aPlayerCommand(attack: true));
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
