import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

const _phases = [
  BossPhaseDef(hpThresholdPct: 1),
  BossPhaseDef(
    hpThresholdPct: 0.7,
    unlockSkillIds: ['phase_skill_a'],
    aiMode: BossAiMode.focus,
  ),
  BossPhaseDef(
    hpThresholdPct: 0.3,
    unlockSkillIds: ['phase_skill_b'],
    aiMode: BossAiMode.aggressive,
  ),
];

const _phaseSkill = SkillDef(
  id: 'phase_skill_a',
  name: 'phase_skill_a',
  description: 'phase_skill_a',
  type: SkillType.powerSkill,
  powerMultiplier: 1200,
  qiDelta: -30,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);

final class _Resolver
    implements Phase0aDamageResolver, Phase0aEnemySkillDamageResolver {
  const _Resolver({required this.basicDamage});

  final int basicDamage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) => Phase0aResolvedHit(isHit: true, isCritical: false, damage: basicDamage);

  @override
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
    bool defenderStaggered = false,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 17);
}

Phase0aActor _player() => const Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector.zero,
  facing: ArenaVector(1, 0),
  maxHealth: 200,
  currentHealth: 200,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _boss({int currentHealth = 100, int phaseIndex = 0}) =>
    Phase0aActor(
      id: 'boss',
      side: Phase0aSide.enemy,
      position: const ArenaVector(1, 0),
      facing: const ArenaVector(-1, 0),
      maxHealth: 100,
      currentHealth: currentHealth,
      moveSpeed: 50,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.elite,
      autoUltimate: true,
      bossPhases: _phases,
      bossPhaseIndex: phaseIndex,
      unlockedEnemySkillIds: phaseIndex == 0
          ? const []
          : const ['phase_skill_a'],
    );

Phase0aArenaState _state(Phase0aActor boss) => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _player(),
  enemies: [boss],
  skillSlots: const [],
);

const _playerAttack = Phase0aAttackIntent(
  actorId: 'player',
  range: 10,
  halfArcRadians: 1,
  cooldownSeconds: 1,
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
  moveKind: Phase0aMoveKind.light,
  aimDirection: ArenaVector(1, 0),
);

void main() {
  test(
    'single hit crosses multiple thresholds once and unlocks in phase order',
    () {
      final result = reducePhase0aTick(
        state: _state(_boss()),
        intents: const [_playerAttack],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(basicDamage: 75),
      );

      final boss = result.state.enemies.single;
      expect(boss.currentHealth, 25);
      expect(boss.bossPhaseIndex, 2);
      expect(boss.unlockedEnemySkillIds, ['phase_skill_a', 'phase_skill_b']);
      final transitions = result.events.whereType<Phase0aBossPhaseChanged>();
      expect(transitions.map((event) => event.phaseIndex), [1, 2]);
      expect(transitions.expand((event) => event.unlockedSkillIds), [
        'phase_skill_a',
        'phase_skill_b',
      ]);

      final stable = reducePhase0aTick(
        state: result.state,
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(basicDamage: 0),
      );
      expect(stable.events.whereType<Phase0aBossPhaseChanged>(), isEmpty);
    },
  );

  test(
    'dead boss is removed without emitting impossible phase transitions',
    () {
      final result = reducePhase0aTick(
        state: _state(_boss()),
        intents: const [_playerAttack],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(basicDamage: 100),
      );

      expect(result.state.enemies, isEmpty);
      expect(result.events.whereType<Phase0aBossPhaseChanged>(), isEmpty);
      expect(result.events.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    },
  );

  test(
    'AI casts only unlocked phase skill and reducer applies qi/cooldown/damage',
    () {
      final ai = Phase0aEnemyAiAdapter(
        attackRange: 10,
        attackHalfArcRadians: 1,
        attackCooldownSeconds: 1,
        postureBasicPowerMultiplier: 1,
        uniformBasicPowerMultiplier: 1,
        skillBindingsByActor: {
          'boss': [
            Phase0aEnemySkillBinding(
              skill: _phaseSkill,
              attackRange: 10,
              halfArcRadians: 1,
              effectRadius: 10,
              cooldownSeconds: 2,
            ),
          ],
        },
      );
      final before = _state(
        _boss(
          currentHealth: 60,
          phaseIndex: 1,
        ).copyWith(attackCooldownRemaining: 0.05),
      );
      final intents = ai.intentsFor(state: before);
      expect(intents.single, isA<Phase0aEnemySkillIntent>());

      final result = reducePhase0aTick(
        state: before,
        intents: intents,
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(basicDamage: 1),
        enemySkillDamageResolver: const _Resolver(basicDamage: 1),
      );
      expect(result.state.player.currentHealth, 183);
      expect(result.state.enemies.single.qiCurrent, 70);
      expect(result.state.enemies.single.attackCooldownRemaining, 1);
      expect(
        result.state.enemies.single.enemySkillCooldowns['phase_skill_a'],
        2,
      );
      expect(result.events.whereType<Phase0aEnemySkillStarted>(), hasLength(1));
      expect(
        result.events.whereType<Phase0aHitLanded>().single.isUltimate,
        isFalse,
      );

      final whileCooling = ai.intentsFor(state: result.state);
      expect(whileCooling.single, isA<Phase0aAttackIntent>());
    },
  );

  test('locked phase skill is never selected', () {
    final ai = Phase0aEnemyAiAdapter(
      attackRange: 10,
      attackHalfArcRadians: 1,
      attackCooldownSeconds: 1,
      postureBasicPowerMultiplier: 1,
      uniformBasicPowerMultiplier: 1,
      skillBindingsByActor: {
        'boss': [
          Phase0aEnemySkillBinding(
            skill: _phaseSkill,
            attackRange: 10,
            halfArcRadians: 1,
            effectRadius: 10,
            cooldownSeconds: 2,
          ),
        ],
      },
    );

    expect(
      ai.intentsFor(state: _state(_boss())).single,
      isA<Phase0aAttackIntent>(),
    );
  });
}
