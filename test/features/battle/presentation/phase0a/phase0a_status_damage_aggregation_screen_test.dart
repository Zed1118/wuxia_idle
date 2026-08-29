import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_event_order_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/status_effects.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

final class _NoDamageResolver implements Phase0aDamageResolver {
  const _NoDamageResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 0);
}

final class _StatusReducerFlow implements Phase0aBattleFlow {
  _StatusReducerFlow(this._state);

  Phase0aArenaState _state;
  List<CombatEventRecord> _records = const [];

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => _records;

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final result = reducePhase0aTick(
      state: _state,
      intents: const [],
      deltaSeconds: deltaSeconds,
      damageResolver: const _NoDamageResolver(),
    );
    _state = result.state;
    _records = Phase0aEventOrderAdapter.project(result.events);
    return result.events;
  }
}

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
  TimedStatusLedgerSnapshot statusLedger =
      const TimedStatusLedgerSnapshot.empty(),
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: ArenaVector.zero,
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  statusLedger: statusLedger,
);

void main() {
  for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('poison/内伤同源同目标在既有短窗内显示总伤害与 tick 数 ($viewport)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final ledger = TimedStatusLedger.empty
        ..apply(
          TimedStatusSpec(
            type: TimedStatusType.poison,
            sourceId: 'enemy',
            durationTicks: 4,
            tickIntervalTicks: 1,
            stackLimit: 1,
            damagePerTick: 6,
          ),
        );
      final enemy = _actor(
        id: 'enemy',
        side: Phase0aSide.enemy,
        position: const ArenaVector(80, 0),
      );
      final flow = _StatusReducerFlow(
        Phase0aArenaState(
          tick: 0,
          nextSeq: 1,
          player: _actor(
            id: 'player',
            side: Phase0aSide.player,
            position: ArenaVector.zero,
            statusLedger: ledger.snapshot,
          ),
          enemies: [enemy],
          skillSlots: const [
            Phase0aSkillSlot(
              slot: 'gather',
              cooldownRemaining: 0,
              qiCost: 0,
              availability: Phase0aSkillAvailability.ready,
            ),
            Phase0aSkillSlot(
              slot: 'clear',
              cooldownRemaining: 0,
              qiCost: 0,
              availability: Phase0aSkillAvailability.ready,
            ),
          ],
        ),
      );
      final controller = Phase0aBattleController(
        flow: flow,
        roster: Phase0aVisualRoster(
          visuals: const {
            'player': Phase0aActorVisual(
              name: 'player',
              assetPath: 'assets/characters/battle_founder_v2.png',
              isElite: false,
            ),
            'enemy': Phase0aActorVisual(
              name: 'enemy',
              assetPath: 'assets/enemies/battle_bandit_blade.png',
              isElite: false,
            ),
          },
        ),
        fixedDeltaSeconds: 0.1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            autoStep: false,
            feedbackHoldSeconds: 20,
          ),
        ),
      );
      await tester.pump();

      for (var tick = 0; tick < 3; tick++) {
        final events = controller.step();
        expect(events.whereType<Phase0aStatusDamageApplied>(), hasLength(1));
        await tester.pump();
      }

      expect(find.text('18 ×3'), findsOneWidget);
      final popups = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return widget is Positioned &&
            key is ValueKey<String> &&
            key.value.startsWith('phase0a_popup_');
      });
      expect(popups, findsOneWidget, reason: '同一状态短窗只占一个居民组');
      expect(find.byKey(const ValueKey('phase0a_player_hud')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      controller.step();
      await tester.pump();

      expect(find.text('18 ×3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(popups, findsNWidgets(2), reason: '超过生产短窗后必须开启新的伤害组');
    });
  }
}
