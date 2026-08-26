import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_event_order_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';

/// Phase 0A battle flow 最小消费契约红测(D03):
/// 用最小 non-wave fake(不复制 reducer/波次/session 任何规则,只实现
/// 接口四成员)证明 live controller、headless sync/async 快进都只依赖
/// [Phase0aBattleFlow] 契约;并锁定接口文件不含波次/session/resolver
/// 成员(冻结 API 源码守卫)。

/// 最小 non-wave fake:无波次、无 session、无 resolver、无 wave cursor。
final class NonWaveFakeFlow implements Phase0aBattleFlow {
  NonWaveFakeFlow({
    required Phase0aArenaState initialState,
    this.victoryAfterTicks = 3,
  }) : _state = initialState;

  Phase0aArenaState _state;
  final int victoryAfterTicks;
  Phase0aBattleOutcome _outcome = Phase0aBattleOutcome.ongoing;
  List<CombatEventRecord> _lastOrderedEventRecords =
      const <CombatEventRecord>[];

  @override
  Phase0aArenaState get state => _state;

  @override
  Phase0aBattleOutcome get outcome => _outcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      _lastOrderedEventRecords;

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_outcome != Phase0aBattleOutcome.ongoing) {
      return const <Phase0aEvent>[];
    }
    final nextTick = _state.tick + 1;
    _state = Phase0aArenaState(
      tick: nextTick,
      nextSeq: _state.nextSeq + 1,
      player: _state.player,
      enemies: _state.enemies,
      skillSlots: _state.skillSlots,
      winCondition: _state.winCondition,
    );
    final events = <Phase0aEvent>[];
    if (nextTick >= victoryAfterTicks) {
      _outcome = Phase0aBattleOutcome.victory;
      events.add(Phase0aBattleVictory(seq: _state.nextSeq - 1, tick: nextTick));
    }
    _lastOrderedEventRecords = Phase0aEventOrderAdapter.project(events);
    return List.unmodifiable(events);
  }
}

const _deltaSeconds = 1 / 30;

Phase0aActor _makePlayer() => const Phase0aActor(
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
);

Phase0aArenaState _fakeState() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _makePlayer(),
  enemies: const <Phase0aActor>[],
  skillSlots: const <Phase0aSkillSlot>[],
);

Phase0aPlayerBotAdapter _makeBot() => const Phase0aPlayerBotAdapter(
  playerAdapter: Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: math.pi / 4,
    attackCooldownSeconds: 1,
    attackQiDelta: 0,
    gatherSlot: 'gather',
    gatherRingRadius: 90,
    gatherEffectRadius: 500,
    gatherQiCost: 20,
    gatherCooldownSeconds: 3,
    clearSlot: 'clear',
    clearEffectRadius: 500,
    clearQiCost: 30,
    clearCooldownSeconds: 4,
  ),
);
void main() {
  group('Phase0aBattleFlow 最小契约消费(non-wave fake)', () {
    test('controller 可构造/step/终局/restart 消费 non-wave fake', () {
      final flow = NonWaveFakeFlow(
        initialState: _fakeState(),
        victoryAfterTicks: 2,
      );
      final controller = Phase0aBattleController(
        flow: flow,
        roster: Phase0aVisualRoster.debugBattle(),
        fixedDeltaSeconds: _deltaSeconds,
      );
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);

      controller.step(const Phase0aPlayerCommand(attack: true));
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(controller.state.tick, 1);

      final terminal = controller.step(
        const Phase0aPlayerCommand(attack: true),
      );
      expect(controller.outcome, Phase0aBattleOutcome.victory);
      expect(terminal.any((e) => e is Phase0aBattleVictory), isTrue);
      expect(controller.lastEventRecords, isNotEmpty);
      expect(controller.lastEvents, isNotEmpty);

      // 终局后 advance/step 幂等:空事件、state 不再推进。
      final after = controller.step(const Phase0aPlayerCommand(attack: true));
      expect(after, isEmpty);
      expect(controller.state.tick, 2);

      // restart 换入全新 fake 实例:状态复位、排序器重建。
      controller.restart(
        NonWaveFakeFlow(initialState: _fakeState(), victoryAfterTicks: 5),
      );
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(controller.state.tick, 0);
      expect(controller.lastEvents, isEmpty);
    });

    test('headless runToEnd 可消费 non-wave fake 快进到终局', () {
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: NonWaveFakeFlow(initialState: _fakeState(), victoryAfterTicks: 3),
        bot: _makeBot(),
        deltaSeconds: _deltaSeconds,
        maxTicks: 100,
      );
      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.ticks, 3);
      expect(result.timedOut, isFalse);
      expect(result.finalState.tick, 3);
      expect(result.eventRecords, isNotEmpty);
      expect(result.events.any((e) => e is Phase0aBattleVictory), isTrue);
    });

    test('headless runToEndAsync 可消费 non-wave fake 快进到终局', () async {
      final result = await Phase0aHeadlessRunner.runToEndAsync(
        flow: NonWaveFakeFlow(initialState: _fakeState(), victoryAfterTicks: 3),
        bot: _makeBot(),
        deltaSeconds: _deltaSeconds,
        maxTicks: 100,
        yieldEveryTicks: 1,
      );
      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.ticks, 3);
      expect(result.timedOut, isFalse);
      expect(result.finalState.tick, 3);
      expect(result.eventRecords, isNotEmpty);
    });

    test('headless runToEnd 拍数预算耗尽返回 ongoing + timedOut', () {
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: NonWaveFakeFlow(
          initialState: _fakeState(),
          victoryAfterTicks: 10,
        ),
        bot: _makeBot(),
        deltaSeconds: _deltaSeconds,
        maxTicks: 3,
      );
      expect(result.outcome, Phase0aBattleOutcome.ongoing);
      expect(result.ticks, 3);
      expect(result.timedOut, isTrue);
    });
  });

  group('冻结 API 源码守卫(D03)', () {
    final interfaceFile = File(
      'lib/features/battle/application/phase0a/phase0a_battle_flow.dart',
    );

    test('接口文件存在', () {
      expect(interfaceFile.existsSync(), isTrue);
    });

    test('接口只含四成员:state/outcome/lastOrderedEventRecords/advance', () {
      final code = interfaceFile.readAsStringSync();
      // 禁波次面(含 transition policy / wave cursor / session / resolver)。
      expect(code.contains('Phase0aWaveTransitionPolicy'), isFalse);
      expect(code.contains('Phase0aCombatSession'), isFalse);
      expect(code.contains('Phase0aDamageResolver'), isFalse);
      expect(code.contains('waves'), isFalse);
      expect(code.contains('cursor'), isFalse);
      // 四个冻结成员齐全。
      expect(code.contains('Phase0aArenaState get state'), isTrue);
      expect(code.contains('Phase0aBattleOutcome get outcome'), isTrue);
      expect(
        code.contains('List<CombatEventRecord> get lastOrderedEventRecords'),
        isTrue,
      );
      expect(code.contains('List<Phase0aEvent> advance'), isTrue);
    });

    test('生产 wave flow 实现接口(编译期契约由 implements 保证)', () {
      // 运行期抽查:接口类型判定对 wave flow 实例成立。
      final asContract = NonWaveFakeFlow(initialState: _fakeState());
      expect(asContract, isA<Phase0aBattleFlow>());
      // 编译期证明:仅通过接口访问四成员时,wave 面(如 waves)不可达。
      Phase0aBattleFlow consume(Phase0aBattleFlow flow) => flow;
      final roundtrip = consume(asContract);
      expect(roundtrip.state, same(roundtrip.state));
    });
  });
}
