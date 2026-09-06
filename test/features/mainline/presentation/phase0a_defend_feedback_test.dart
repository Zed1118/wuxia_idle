import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // CachingAssetBundle stores Future<String>. Do not reuse a future created
    // in the preceding widget test's fake-async zone after that zone is gone.
    rootBundle.evict('data/narratives/stage_02_01_defend_guidance.yaml');
    rootBundle.evict('data/narratives/stages/stage_02_01_defend_guidance.yaml');
    rootBundle.evict('data/narratives/phase0a_mouse_attack.yaml');
  });

  Future<Phase0aBattleController> openEscort(
    WidgetTester tester,
    Size viewport, {
    ValueChanged<String>? onDefeatReason,
    VoidCallback? onDefeat,
    double defenseRate = 0.05,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Phase0aMainlineBattleHost(
            stage: repository.getStage('stage_02_01'),
            seedForTest: 20260906,
            playerSnapshotForTest: testCombatantSnapshot(
              maxHp: 20000,
              currentHp: 20000,
              defenseRate: defenseRate,
              includeProductionBasicAttack: true,
            ),
            onVictory: (_) {},
            onDefeatReason: onDefeatReason,
            onDefeat: (_) => onDefeat?.call(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.text('镖货').evaluate().isNotEmpty) break;
    }
    expect(
      find.byType(Phase0aBattleScreen),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
    return tester
        .widget<Phase0aBattleScreen>(find.byType(Phase0aBattleScreen))
        .controller;
  }

  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      'real escort explains the protected cargo and seconds: $viewport',
      (tester) async {
        final controller = await openEscort(tester, viewport);
        expect(find.text('镖货'), findsOneWidget);
        expect(find.textContaining('镖货损毁即失败'), findsOneWidget);
        final banner = find.byKey(
          const ValueKey('phase0a_defend_condition_banner'),
        );
        expect(
          find.descendant(of: banner, matching: find.textContaining('秒')),
          findsOneWidget,
        );
        expect(find.text('阵眼'), findsNothing);
        expect(controller.state.defendedEntity!.maxDurability, 300);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'real cargo hit displays its attacking source and reaction: $viewport',
      (tester) async {
        final controller = await openEscort(tester, viewport);
        Phase0aDefendedEntityHit? hit;
        for (var tick = 0; tick < 100 && hit == null; tick++) {
          final events = controller.step();
          final hits = events.whereType<Phase0aDefendedEntityHit>();
          if (hits.isNotEmpty) hit = hits.first;
          await tester.pump();
        }
        expect(hit, isNotNull);
        final strikes = controller.feedback.where(
          (e) => e.kind.name == 'enemyStrike' && e.targetId == hit!.target,
        );
        expect(strikes, isNotEmpty);
        final strike = strikes.first;
        expect(strike.actorId, hit!.actor);
        expect(strike.source, hit.actorPosition);
        expect(strike.vfxTarget, hit.targetPosition);
        expect(
          find.byKey(
            ValueKey('phase0a_enemy_strike_${hit.actor}_${hit.target}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('phase0a_defended_entity_hit_${hit.target}')),
          findsOneWidget,
        );
        expect(
          controller.state.defendedEntity!.currentDurability,
          lessThan(controller.state.defendedEntity!.maxDurability),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('cargo destruction reports its reason in the same tick, once', (
    tester,
  ) async {
    String? reason;
    final callbacks = <String>[];
    int? callbackTick;
    late Phase0aBattleController controller;
    controller = await openEscort(
      tester,
      const Size(1280, 720),
      defenseRate: 0.99,
      onDefeatReason: (value) {
        reason = value;
        callbacks.add('reason');
      },
      onDefeat: () {
        callbacks.add('defeat');
        callbackTick = controller.state.tick;
      },
    );
    while (controller.outcome == Phase0aBattleOutcome.ongoing &&
        controller.state.tick < 601) {
      controller.step();
    }
    expect(controller.state.defendedEntity!.currentDurability, 0);
    expect(controller.state.player.currentHealth, greaterThan(0));
    expect(callbackTick, controller.state.tick);
    expect(callbacks, ['reason', 'defeat']);
    expect(reason, '镖货已被毁，未能守住。');
    final terminalTick = controller.state.tick;
    await tester.pump(const Duration(seconds: 5));
    expect(controller.state.tick, terminalTick);
    expect(callbacks, ['reason', 'defeat']);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StageRetryDialogBody(defeatReason: reason)),
      ),
    );
    expect(find.text(reason!), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('player defeat does not claim undestroyed cargo was lost', (
    tester,
  ) async {
    String? reason;
    var defeats = 0;
    final controller = await openEscort(
      tester,
      const Size(1280, 720),
      onDefeatReason: (value) => reason = value,
      onDefeat: () => defeats++,
    );
    while (controller.outcome == Phase0aBattleOutcome.ongoing &&
        controller.state.tick < 601) {
      controller.step();
    }
    expect(controller.state.player.isAlive, isFalse);
    expect(controller.state.defendedEntity!.currentDurability, greaterThan(0));
    expect(defeats, 1);
    expect(reason, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
