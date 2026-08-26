import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_event_order_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

void main() {
  test('manual and auto drive the same host flow contract', () {
    final manualFlow = _HostFakeFlow();
    final manualHost = Phase0aEncounterHost.fromFlow(
      stageId: 'stage_01_03',
      nextStageId: 'stage_01_04',
      flow: manualFlow,
    );
    final command = const Phase0aPlayerCommand(attack: true);
    manualHost.advanceManual(deltaSeconds: 1 / 30, command: command);
    expect(manualFlow.commands.single, same(command));

    final autoFlow = _HostFakeFlow();
    final autoHost = Phase0aEncounterHost.fromFlow(
      stageId: 'stage_01_03',
      nextStageId: 'stage_01_04',
      flow: autoFlow,
    );
    final expectedAutoCommand = _makeBot().commandFor(autoFlow.state);
    autoHost.advanceAuto(deltaSeconds: 1 / 30, bot: _makeBot());
    expect(autoFlow.commands, hasLength(1));
    final actualAutoCommand = autoFlow.commands.single;
    expect(actualAutoCommand.left, expectedAutoCommand.left);
    expect(actualAutoCommand.right, expectedAutoCommand.right);
    expect(actualAutoCommand.up, expectedAutoCommand.up);
    expect(actualAutoCommand.down, expectedAutoCommand.down);
    expect(actualAutoCommand.attack, expectedAutoCommand.attack);
    expect(actualAutoCommand.skillHotkey, expectedAutoCommand.skillHotkey);
    expect(actualAutoCommand.gather, expectedAutoCommand.gather);
    expect(actualAutoCommand.clear, expectedAutoCommand.clear);
  });

  test('headless host delegates to the existing headless runner', () {
    final flow = _HostFakeFlow(victoryAfterTicks: 2);
    final host = Phase0aEncounterHost.fromFlow(
      stageId: 'stage_01_03',
      nextStageId: 'stage_01_04',
      flow: flow,
    );
    final result = host.runHeadless(
      bot: _makeBot(),
      deltaSeconds: 1 / 30,
      maxTicks: 4,
    );
    expect(result.outcome, Phase0aBattleOutcome.victory);
    expect(result.ticks, 2);
    expect(flow.commands, hasLength(2));
  });

  test('three fresh sessions preserve the same seeded flow outcome', () {
    final manualFlow = _HostFakeFlow(victoryAfterTicks: 2);
    final manualHost = _newHost(manualFlow);
    manualHost.advanceManual(
      deltaSeconds: 1 / 30,
      command: const Phase0aPlayerCommand(attack: true),
    );
    manualHost.advanceManual(
      deltaSeconds: 1 / 30,
      command: const Phase0aPlayerCommand(attack: true),
    );

    final autoFlow = _HostFakeFlow(victoryAfterTicks: 2);
    final autoHost = _newHost(autoFlow);
    autoHost.advanceAuto(deltaSeconds: 1 / 30, bot: _makeBot());
    autoHost.advanceAuto(deltaSeconds: 1 / 30, bot: _makeBot());

    final headlessFlow = _HostFakeFlow(victoryAfterTicks: 2);
    final headlessResult = _newHost(
      headlessFlow,
    ).runHeadless(bot: _makeBot(), deltaSeconds: 1 / 30, maxTicks: 2);

    expect(manualFlow.outcome, Phase0aBattleOutcome.victory);
    expect(autoFlow.outcome, Phase0aBattleOutcome.victory);
    expect(headlessResult.outcome, Phase0aBattleOutcome.victory);
    expect(manualFlow.state.tick, autoFlow.state.tick);
    expect(autoFlow.state.tick, headlessFlow.state.tick);
  });
}

Phase0aEncounterHost _newHost(_HostFakeFlow flow) =>
    Phase0aEncounterHost.fromFlow(
      stageId: 'stage_01_03',
      nextStageId: 'stage_01_04',
      flow: flow,
    );

final class _HostFakeFlow implements Phase0aBattleFlow {
  _HostFakeFlow({this.victoryAfterTicks = 100}) : _state = _stateAt(0);

  final int victoryAfterTicks;
  final List<Phase0aPlayerCommand> commands = <Phase0aPlayerCommand>[];
  Phase0aArenaState _state;
  Phase0aBattleOutcome _outcome = Phase0aBattleOutcome.ongoing;
  List<CombatEventRecord> _records = const <CombatEventRecord>[];

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => _outcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords => _records;

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    commands.add(command);
    final nextTick = _state.tick + 1;
    _state = _stateAt(nextTick);
    final events = <Phase0aEvent>[];
    if (nextTick >= victoryAfterTicks) {
      _outcome = Phase0aBattleOutcome.victory;
      events.add(Phase0aBattleVictory(seq: nextTick, tick: nextTick));
    }
    _records = Phase0aEventOrderAdapter.project(events);
    return events;
  }
}

Phase0aPlayerBotAdapter _makeBot() => const Phase0aPlayerBotAdapter(
  playerAdapter: Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: math.pi / 4,
    attackCooldownSeconds: 1,
    attackQiDelta: 0,
    postureBasicPowerMultiplier: 1,
    attackPowerMultiplier: 1,
    gatherPowerMultiplier: 1,
    clearPowerMultiplier: 1,
    gatherSlot: 'gather',
    gatherRingRadius: 90,
    gatherEffectRadius: 500,
    gatherQiCost: 20,
    gatherCooldownSeconds: 3,
    clearSlot: 'clear',
    clearEffectRadius: 500,
    clearQiCost: 20,
    clearCooldownSeconds: 3,
  ),
);

Phase0aArenaState _stateAt(int tick) => Phase0aArenaState(
  tick: tick,
  nextSeq: tick + 1,
  player: const Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: ArenaVector(0, 0),
    facing: ArenaVector(1, 0),
    maxHealth: 100,
    currentHealth: 100,
    moveSpeed: 100,
    qiCurrent: 100,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  ),
  enemies: const <Phase0aActor>[],
  skillSlots: const <Phase0aSkillSlot>[],
);
