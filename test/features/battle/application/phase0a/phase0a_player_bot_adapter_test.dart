import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_defense_tuning.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

const _burstSkill = SkillDef(
  id: 'c12_burst',
  name: 'c12_burst',
  description: 'c12_burst',
  type: SkillType.powerSkill,
  powerMultiplier: 1,
  qiDelta: -30,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
  targetType: TargetType.aoe,
);

Phase0aNumericSkillBinding _burstBinding() => Phase0aNumericSkillBinding(
  hotkey: 1,
  loadoutSlot: CombatantSkillLoadout.numericSlots[0],
  skill: _burstSkill,
  slotId: 'burst',
  attackRange: 100,
  halfArc: math.pi / 4,
  effectRadius: 200,
  cooldownSeconds: 1,
);

Phase0aPlayerInputAdapter _adapter({
  bool withBurst = false,
  Phase0aDefenseTuning? defenseTuning,
}) => Phase0aPlayerInputAdapter(
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
  numericSkillBindings: withBurst
      ? Phase0aNumericSkillBindings(one: _burstBinding())
      : const Phase0aNumericSkillBindings.empty(),
  defenseTuning: defenseTuning,
);

const _defenseTuning = Phase0aDefenseTuning(
  shieldAbsorption: 100,
  shieldDurationTicks: 4,
  parryWindowTicks: 2,
  counterDamage: 25,
  counterUpperBound: 25,
  dodgeIframeTicks: 2,
  dodgeDistance: 100,
  defenseCooldownSeconds: 1,
  basicAttackFlags: AttackDefenseFlags(
    blockable: true,
    parryable: true,
    reflectable: false,
    dodgeable: true,
    interruptible: true,
  ),
  skillAttackFlags: AttackDefenseFlags(
    blockable: true,
    parryable: true,
    reflectable: false,
    dodgeable: true,
    interruptible: true,
  ),
);

Phase0aActor _actor({
  required Phase0aSide side,
  required String id,
  ArenaVector position = const ArenaVector(0, 0),
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aArenaState _state({bool window = false, bool withBurst = false}) =>
    Phase0aArenaState(
      tick: 4,
      nextSeq: 8,
      player: _actor(side: Phase0aSide.player, id: 'player'),
      enemies: [
        _actor(
          side: Phase0aSide.enemy,
          id: 'enemy',
        ).copyWith(staggerTicksRemaining: window ? 1 : 0),
      ],
      skillSlots: [
        const Phase0aSkillSlot(
          slot: 'gather',
          cooldownRemaining: 0,
          qiCost: 20,
          availability: Phase0aSkillAvailability.ready,
        ),
        const Phase0aSkillSlot(
          slot: 'clear',
          cooldownRemaining: 0,
          qiCost: 30,
          availability: Phase0aSkillAvailability.ready,
        ),
        if (withBurst)
          const Phase0aSkillSlot(
            slot: 'burst',
            cooldownRemaining: 0,
            qiCost: 30,
            availability: Phase0aSkillAvailability.ready,
          ),
      ],
    );

void main() {
  test('custom policy copies mutable collections into immutable values', () {
    final priority = <Phase0aBotAction>[Phase0aBotAction.clear];
    final enabled = <Phase0aBotAction>{Phase0aBotAction.clear};
    final policy = Phase0aBotTacticPolicy(
      tactic: Phase0aBotTactic.steadyGuard,
      actionPriority: priority,
      enabledActions: enabled,
      parallelTacticalActions: false,
      requiresBurstWindow: true,
      prioritizeBurstWindowTarget: true,
    );

    priority.clear();
    enabled.clear();

    expect(policy.actionPriority, [Phase0aBotAction.clear]);
    expect(policy.allows(Phase0aBotAction.clear), isTrue);
    expect(() => policy.actionPriority.clear(), throwsUnsupportedError);
    expect(() => policy.enabledActions.clear(), throwsUnsupportedError);
  });

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
            playerAdapter: _adapter(withBurst: true),
            policy: policy,
          ).commandFor(_state(window: true, withBurst: true));

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

  final burstCast = Phase0aChargeCast(
    skill: _burstSkill,
    chargeTicks: 2,
    attackRange: 120,
    halfArcRadians: math.pi / 4,
    effectRadius: 120,
    cooldownSeconds: 1,
    actionCooldownSeconds: 1,
  );

  test('seek gap holds resources outside a visible stagger window', () {
    final bot = Phase0aPlayerBotAdapter(
      playerAdapter: _adapter(withBurst: true),
      policy: const Phase0aBotTacticPolicy.seekGap(),
    );
    final closed = bot.commandFor(_state(withBurst: true));
    final open = bot.commandFor(_state(window: true, withBurst: true));

    expect(closed.gather, isFalse);
    expect(closed.clear, isFalse);
    expect(closed.skillHotkey, isNull);
    expect(open.gather, isFalse);
    expect(open.clear, isFalse);
    expect(open.skillHotkey, 1);
  });

  test('steady guard prioritizes clear during an observable enemy window', () {
    final enemy = _actor(side: Phase0aSide.enemy, id: 'enemy');
    final bot = Phase0aPlayerBotAdapter(
      playerAdapter: _adapter(withBurst: true),
      policy: const Phase0aBotTacticPolicy.steadyGuard(),
    );
    final closed = bot.commandFor(_state());
    final open = bot.commandFor(
      Phase0aArenaState(
        tick: 4,
        nextSeq: 8,
        player: _actor(side: Phase0aSide.player, id: 'player'),
        enemies: [enemy.copyWith(staggerTicksRemaining: 1)],
        skillSlots: _state().skillSlots,
      ),
    );

    expect(closed.clear, isFalse);
    expect(open.clear, isTrue);
    expect(open.gather, isFalse);
  });

  test('steady guard emits shield outside burst and dodge inside burst', () {
    final bot = Phase0aPlayerBotAdapter(
      playerAdapter: _adapter(defenseTuning: _defenseTuning),
      policy: const Phase0aBotTacticPolicy.steadyGuard(),
    );

    final safe = bot.commandFor(_state());
    final burst = bot.commandFor(
      Phase0aArenaState(
        tick: 4,
        nextSeq: 8,
        player: _state().player,
        enemies: [
          _actor(
            side: Phase0aSide.enemy,
            id: 'enemy',
          ).copyWith(chargingCast: burstCast),
        ],
        skillSlots: _state().skillSlots,
      ),
    );

    expect(safe.defenseAction, Phase0aDefenseAction.shield);
    expect(burst.defenseAction, Phase0aDefenseAction.dodge);
  });

  test(
    'seek gap deterministically selects the nearest visible window target',
    () {
      final bot = Phase0aPlayerBotAdapter(
        playerAdapter: _adapter(),
        policy: const Phase0aBotTacticPolicy.seekGap(),
      );
      final normal = _actor(
        side: Phase0aSide.enemy,
        id: 'near-normal',
        position: const ArenaVector(-40, 0),
      );
      final window = _actor(
        side: Phase0aSide.enemy,
        id: 'window',
        position: const ArenaVector(200, 0),
      ).copyWith(staggerTicksRemaining: 1);
      final command = bot.commandFor(
        Phase0aArenaState(
          tick: 4,
          nextSeq: 8,
          player: _actor(side: Phase0aSide.player, id: 'player'),
          enemies: [normal, window],
          skillSlots: _state(withBurst: true).skillSlots,
        ),
      );

      expect(command.right, isTrue);
      expect(command.left, isFalse);
    },
  );
}
