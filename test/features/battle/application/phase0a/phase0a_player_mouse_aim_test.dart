import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';

void main() {
  const adapter = Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: 0.7853981633974483,
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
    clearQiCost: 30,
    clearCooldownSeconds: 4,
  );

  const facing = ArenaVector(1, 0);
  const state = Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
      facing: facing,
      maxHealth: 100,
      currentHealth: 100,
      moveSpeed: 1,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: [],
    skillSlots: [],
  );

  test('attack aim is preserved by the input adapter', () {
    const aim = ArenaVector(0, 1);
    final intents = adapter.intentsFor(
      state: state,
      command: const Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: aim,
      ),
    );

    final attack = intents.whereType<Phase0aAttackIntent>().single;
    expect(attack.aimDirection, aim);
  });

  test('J compatibility without aim falls back to player facing', () {
    final intents = adapter.intentsFor(
      state: state,
      command: const Phase0aPlayerCommand(attack: true),
    );

    final attack = intents.whereType<Phase0aAttackIntent>().single;
    expect(attack.aimDirection, facing);
  });

  test('aim without attack does not create an attack intent', () {
    final intents = adapter.intentsFor(
      state: state,
      command: const Phase0aPlayerCommand(attackAimDirection: facing),
    );

    expect(intents.whereType<Phase0aAttackIntent>(), isEmpty);
  });
}
