import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_sfx.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/strings.dart';

final class _DefenseEventFlow implements Phase0aBattleFlow {
  _DefenseEventFlow(this.event);

  final Phase0aEvent event;
  bool _emitted = false;

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => Phase0aBattleOutcome.ongoing;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      const <CombatEventRecord>[];

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_emitted) return const <Phase0aEvent>[];
    _emitted = true;
    return <Phase0aEvent>[event];
  }

  static const _state = Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
      facing: ArenaVector(1, 0),
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 100,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: <Phase0aActor>[],
    skillSlots: <Phase0aSkillSlot>[
      Phase0aSkillSlot(
        slot: 'gather',
        cooldownRemaining: 0,
        qiCost: 20,
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: 'clear',
        cooldownRemaining: 0,
        qiCost: 30,
        availability: Phase0aSkillAvailability.ready,
      ),
    ],
  );
}

void main() {
  const started = Phase0aDefenseStarted(
    seq: 1,
    tick: 1,
    actor: 'player',
    action: Phase0aDefenseAction.dodge,
    fromPosition: ArenaVector.zero,
    toPosition: ArenaVector(110, 0),
    windowTicks: 2,
    shieldAbsorption: 0,
  );
  const resolved = Phase0aDefenseResolved(
    seq: 2,
    tick: 1,
    attackId: 'enemy:1:player',
    attacker: 'enemy',
    target: 'player',
    branch: DefenseBranch.dodge,
    incomingDamage: 0,
    counterDamage: 0,
    shieldRemaining: 0,
    nonRecursive: true,
    targetPosition: ArenaVector(110, 0),
  );

  Future<void> expectVisibleFeedback(
    WidgetTester tester, {
    required Phase0aEvent event,
    required String keyPrefix,
    required String label,
  }) async {
    final controller = Phase0aBattleController(
      flow: _DefenseEventFlow(event),
      roster: Phase0aVisualRoster.debugBattle(),
      fixedDeltaSeconds: 1 / 30,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: false,
          feedbackHoldSeconds: 5,
        ),
      ),
    );

    controller.step();
    await tester.pump();

    final feedback = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith(keyPrefix),
    );
    expect(feedback, findsOneWidget);
    expect(tester.widget(feedback), isNot(isA<SizedBox>()));
    expect(tester.getSize(feedback).width, greaterThan(0));
    expect(tester.getSize(feedback).height, greaterThan(0));
    expect(
      find.descendant(of: feedback, matching: find.text(label)),
      findsOneWidget,
    );
  }

  test('defense events produce anchored VFX and existing audio feedback', () {
    final entries = Phase0aVfxController().consume([started, resolved]);

    expect(entries.map((entry) => entry.kind), [
      Phase0aVfxKind.defenseStarted,
      Phase0aVfxKind.defenseResolved,
    ]);
    expect(entries.first.anchor, const ArenaVector(110, 0));
    expect(entries.first.statusTicks, 2);
    expect(
      phase0aSfxAssetForEvent(started, playerId: 'player'),
      'audio/sfx/battleChargeStart.mp3',
    );
    expect(
      phase0aSfxAssetForEvent(resolved, playerId: 'player'),
      'audio/sfx/battleChargeStart.mp3',
    );
  });

  testWidgets('defenseStarted renders non-empty visible feedback', (
    tester,
  ) async {
    await expectVisibleFeedback(
      tester,
      event: started,
      keyPrefix: 'phase0a_defense_start_',
      label: UiStrings.phase0aDefenseStarted,
    );
  });

  testWidgets('defenseResolved renders non-empty visible feedback', (
    tester,
  ) async {
    await expectVisibleFeedback(
      tester,
      event: resolved,
      keyPrefix: 'phase0a_defense_resolved_',
      label: UiStrings.phase0aDefenseResolved,
    );
  });
}
