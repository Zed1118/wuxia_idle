import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/status_effects.dart';

import '../../../../support/test_data.dart';

const _basicSkill = SkillDef(
  id: 'status_wiring_basic',
  name: 'status wiring basic',
  description: 'status wiring basic',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

Phase0aDamageSnapshot _snapshot(TechniqueSchool school) =>
    Phase0aDamageSnapshot(
      internalForce: 600,
      equipmentAttack: 100,
      cultivationLayer: CultivationLayer.chuKui,
      school: school,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      defenseRate: 0,
      evasionRate: 0,
      criticalRate: 0,
      attackPowerMultiplier: 1,
      proficiencyDamageMults: const {},
      outputMultiplier: 1,
      schoolDamageTakenMults: const {},
      wardMult: 1,
      vulnerabilityOutMult: null,
      piercePct: 0,
      lifestealPct: 0,
      critDamageTakenMult: 1,
    );

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
  int currentHealth = 100000,
  int dodgeTicksRemaining = 0,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: 100000,
  currentHealth: currentHealth,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  dodgeTicksRemaining: dodgeTicksRemaining,
);

Phase0aAttackIntent _attack(
  String actorId,
  ArenaVector aimDirection, {
  AttackDefenseFlags? defenseFlags,
}) => Phase0aAttackIntent(
  actorId: actorId,
  range: 120,
  halfArcRadians: math.pi / 4,
  cooldownSeconds: 0,
  moveKind: Phase0aMoveKind.light,
  aimDirection: aimDirection,
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
  defenseFlags: defenseFlags,
);

void main() {
  setUp(loadTestGameRepository);
  tearDown(GameRepository.resetForTest);

  Phase0aDamageCalculatorAdapter adapter({
    required TechniqueSchool playerSchool,
    required TechniqueSchool enemySchool,
  }) => Phase0aDamageCalculatorAdapter(
    combatants: {
      'player': _snapshot(playerSchool),
      'enemy': _snapshot(enemySchool),
    },
    moveBindings: const {Phase0aDamageKind.basic: _basicSkill},
    numbers: GameRepository.instance.numbers,
    rng: math.Random(20260829),
  );

  test('阴柔克灵巧从生产 adapter 施加既有内伤配置，下一拍起固定伤害三拍', () {
    final resolver = adapter(
      playerSchool: TechniqueSchool.yinRou,
      enemySchool: TechniqueSchool.lingQiao,
    );
    var state = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
      ),
      enemies: [
        _actor(
          id: 'enemy',
          side: Phase0aSide.enemy,
          position: const ArenaVector(60, 0),
        ),
      ],
      skillSlots: const [],
    );

    final mainHit = reducePhase0aTick(
      state: state,
      intents: [_attack('player', const ArenaVector(1, 0))],
      deltaSeconds: 0.1,
      damageResolver: resolver,
    );
    state = mainHit.state;
    expect(mainHit.events.whereType<Phase0aStatusDamageApplied>(), isEmpty);
    expect(state.enemies.single.statusLedger.instances, hasLength(1));
    final applied = state.enemies.single.statusLedger.instances.single;
    final config =
        GameRepository.instance.numbers.schoolCounter.yinRouInternalInjury;
    expect(applied.spec.type, TimedStatusType.internalInjury);
    expect(applied.spec.sourceId, 'player');
    expect(applied.remainingTicks, config.turnsPersist);
    expect(applied.spec.damagePerTick, config.damagePerTick);
    expect(applied.stacks, 1);

    final dotEvents = <Phase0aStatusDamageApplied>[];
    for (var tick = 0; tick < config.turnsPersist; tick++) {
      final step = reducePhase0aTick(
        state: state,
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: resolver,
      );
      state = step.state;
      dotEvents.addAll(step.events.whereType<Phase0aStatusDamageApplied>());
    }

    expect(dotEvents, hasLength(config.turnsPersist));
    expect(
      dotEvents.map((event) => event.resolvedDamage),
      everyElement(config.damagePerTick),
    );
    expect(dotEvents.map((event) => event.source).toSet(), {'player'});
    expect(dotEvents.map((event) => event.target).toSet(), {'enemy'});
    expect(dotEvents.map((event) => event.statusType).toSet(), {
      TimedStatusType.internalInjury,
    });
    expect(state.enemies.single.statusLedger.instances, isEmpty);
  });

  test('主动闪避阻止 follows-main-hit 内伤进入玩家状态槽', () {
    final resolver = adapter(
      playerSchool: TechniqueSchool.lingQiao,
      enemySchool: TechniqueSchool.yinRou,
    );
    final state = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
        dodgeTicksRemaining: 2,
      ),
      enemies: [
        _actor(
          id: 'enemy',
          side: Phase0aSide.enemy,
          position: const ArenaVector(60, 0),
        ),
      ],
      skillSlots: const [],
    );

    final result = reducePhase0aTick(
      state: state,
      intents: [
        _attack(
          'enemy',
          const ArenaVector(-1, 0),
          defenseFlags: const AttackDefenseFlags(
            blockable: true,
            parryable: true,
            reflectable: true,
            dodgeable: true,
            interruptible: true,
          ),
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: resolver,
    );

    expect(
      result.events.whereType<Phase0aDefenseResolved>().single.branch,
      DefenseBranch.dodge,
    );
    expect(result.state.player.statusLedger.instances, isEmpty);
  });

  test('预置 poison 走同一 reducer 事件链且可致死，不要求新增生产毒技能', () {
    final ledger = TimedStatusLedger.empty
      ..apply(
        TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'enemy',
          durationTicks: 1,
          tickIntervalTicks: 1,
          stackLimit: 1,
          damagePerTick: 7,
        ),
      );
    final state = Phase0aArenaState(
      tick: 0,
      nextSeq: 4,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
      ),
      enemies: [
        _actor(
          id: 'enemy',
          side: Phase0aSide.enemy,
          position: const ArenaVector(60, 0),
          currentHealth: 7,
        ).copyWith(statusLedger: ledger.snapshot),
      ],
      skillSlots: const [],
    );

    final result = reducePhase0aTick(
      state: state,
      intents: const [],
      deltaSeconds: 0.1,
      damageResolver: adapter(
        playerSchool: TechniqueSchool.gangMeng,
        enemySchool: TechniqueSchool.gangMeng,
      ),
    );

    final damage = result.events.whereType<Phase0aStatusDamageApplied>().single;
    expect(damage.statusType, TimedStatusType.poison);
    expect(damage.remainingHealth, 0);
    expect(result.events.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    expect(result.state.enemies, isEmpty);
  });
}
