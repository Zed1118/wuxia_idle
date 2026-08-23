import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';

Phase0aPlayerInputAdapter _adapter() => const Phase0aPlayerInputAdapter(
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
);

Phase0aActor _actor({required Phase0aSide side, required String id}) =>
    Phase0aActor(
      id: id,
      side: side,
      position: const ArenaVector(0, 0),
      facing: const ArenaVector(1, 0),
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 100,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );

Phase0aArenaState _state() => Phase0aArenaState(
  tick: 4,
  nextSeq: 8,
  player: _actor(side: Phase0aSide.player, id: 'player'),
  enemies: [_actor(side: Phase0aSide.enemy, id: 'enemy')],
  skillSlots: const [
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

void main() {
  test('production policy preserves the pre-C12 command', () {
    final command = Phase0aPlayerBotAdapter(
      playerAdapter: _adapter(),
    ).commandFor(_state());

    expect(command.attack, isTrue);
    expect(command.gather, isTrue);
    expect(command.clear, isTrue);
    expect(command.skillHotkey, isNull);
    expect(
      command.left || command.right || command.up || command.down,
      isFalse,
    );
  });

  test('same state and policy produce the same command', () {
    final bot = Phase0aPlayerBotAdapter(
      playerAdapter: _adapter(),
      policy: const Phase0aBotTacticPolicy.steadyGuard(),
    );
    final first = bot.commandFor(_state());
    final second = bot.commandFor(_state());

    expect(first.attack, second.attack);
    expect(first.gather, second.gather);
    expect(first.clear, second.clear);
    expect(first.skillHotkey, second.skillHotkey);
  });

  test(
    'seek gap, assault and steady guard have distinct ready-action profiles',
    () {
      Phase0aPlayerCommand command(Phase0aBotTacticPolicy policy) =>
          Phase0aPlayerBotAdapter(
            playerAdapter: _adapter(),
            policy: policy,
          ).commandFor(_state());

      final seek = command(const Phase0aBotTacticPolicy.seekGap());
      final assault = command(const Phase0aBotTacticPolicy.assault());
      final guard = command(const Phase0aBotTacticPolicy.steadyGuard());

      expect(seek.gather, isFalse);
      expect(seek.clear, isFalse);
      expect(assault.gather, isTrue);
      expect(assault.clear, isTrue);
      expect(guard.gather, isFalse);
      expect(guard.clear, isTrue);
    },
  );
}
