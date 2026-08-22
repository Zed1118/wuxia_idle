import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import '../../../../support/test_data.dart';

void main() {
  final basic = const SkillDef(
    id: 'coop_basic',
    name: 'basic',
    description: 'basic',
    type: SkillType.normalAttack,
    powerMultiplier: 100,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
    proficiency: SkillProficiencyEffects({}, {}, {}, {}),
  );

  Phase0aActor actor({
    required String id,
    required Phase0aSide side,
    required double x,
    int hp = 100,
    int qi = 10,
    double cooldown = 0,
    int stagger = 0,
    Phase0aChargeCast? chargingCast,
    bool guardInterceptsInterrupt = false,
    List<String> guardianDefIds = const [],
    bool coopUsed = false,
  }) => Phase0aActor(
    id: id,
    side: side,
    position: ArenaVector(x, 0),
    facing: side == Phase0aSide.player
        ? const ArenaVector(1, 0)
        : const ArenaVector(-1, 0),
    maxHealth: hp,
    currentHealth: hp,
    moveSpeed: 0,
    qiCurrent: qi,
    qiMax: 100,
    attackCooldownRemaining: cooldown,
    defeatKind: Phase0aDefeatKind.normal,
    staggerTicksTotal: 2,
    staggerTicksRemaining: stagger,
    chargeCast: chargingCast,
    chargingCast: chargingCast,
    chargeTicksRemaining: chargingCast == null ? 0 : chargingCast.chargeTicks,
    guardInterceptsInterrupt: guardInterceptsInterrupt,
    guardianDefIds: guardianDefIds,
    guardianCoopUsedInCharge: coopUsed,
  );

  Phase0aArenaState state({
    int playerHp = 100,
    int guardianAStagger = 0,
    int guardianBHp = 100,
    bool coopUsed = false,
    bool bossCharging = true,
  }) {
    final charge = Phase0aChargeCast(
      skill: basic,
      chargeTicks: 3,
      attackRange: 100,
      halfArcRadians: math.pi,
      effectRadius: 100,
      cooldownSeconds: 2,
      actionCooldownSeconds: 1,
    );
    final boss = actor(
      id: 'boss',
      side: Phase0aSide.enemy,
      x: 70,
      qi: 100,
      chargingCast: bossCharging ? charge : null,
      guardInterceptsInterrupt: true,
      guardianDefIds: const ['g_a', 'g_b'],
      coopUsed: coopUsed,
    );
    return Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: actor(id: 'player', side: Phase0aSide.player, x: 0, hp: playerHp),
      enemies: [
        bossCharging
            ? boss
            : boss.copyWith(clearChargingCast: true, chargeTicksRemaining: 0),
        actor(id: 'g_a', side: Phase0aSide.enemy, x: 50, qi: 20),
        actor(
          id: 'g_b',
          side: Phase0aSide.enemy,
          x: 60,
          hp: guardianBHp,
          qi: 30,
          stagger: guardianAStagger,
        ),
      ],
      skillSlots: const [],
    );
  }

  List<Phase0aIntent> attacks() => [
    const Phase0aAttackIntent(
      actorId: 'g_b',
      range: 100,
      halfArcRadians: math.pi,
      cooldownSeconds: 0.5,
      moveKind: Phase0aMoveKind.light,
      aimDirection: ArenaVector(-1, 0),
      qiDelta: 4,
    ),
    const Phase0aAttackIntent(
      actorId: 'g_a',
      range: 100,
      halfArcRadians: math.pi,
      cooldownSeconds: 0.5,
      moveKind: Phase0aMoveKind.light,
      aimDirection: ArenaVector(-1, 0),
      qiDelta: 3,
    ),
  ];

  test('两护法按稳定顺序各 resolver 一次、合并一次扣血并消费 partner intent', () {
    final calls = <String>[];
    final result = reducePhase0aTick(
      state: state(),
      intents: attacks(),
      deltaSeconds: 0,
      damageResolver: _RecordingResolver(calls),
    );

    final event = result.events.whereType<Phase0aGuardianCoopStrike>().single;
    expect(calls, ['g_a->player', 'g_b->player']);
    expect(event.mainGuardian, 'g_a');
    expect(event.partner, 'g_b');
    expect(event.boss, 'boss');
    expect(event.totalDamage, 24);
    expect(result.state.player.currentHealth, 76);
    expect(result.state.enemies.firstWhere((e) => e.id == 'g_a').qiCurrent, 23);
    expect(result.state.enemies.firstWhere((e) => e.id == 'g_b').qiCurrent, 34);
    expect(
      result.state.enemies
          .firstWhere((e) => e.id == 'boss')
          .guardianCoopUsedInCharge,
      isTrue,
    );
    expect(result.events.whereType<Phase0aAttackStarted>(), isEmpty);
  });

  test('相位闩保证一次；任一护法受控时回落普通攻击', () {
    final first = reducePhase0aTick(
      state: state(),
      intents: attacks(),
      deltaSeconds: 0,
      damageResolver: _RecordingResolver([]),
    );
    final second = reducePhase0aTick(
      state: first.state,
      intents: attacks(),
      deltaSeconds: 0.5,
      damageResolver: _RecordingResolver([]),
    );
    expect(second.events.whereType<Phase0aGuardianCoopStrike>(), isEmpty);
    expect(second.events.whereType<Phase0aAttackStarted>(), hasLength(2));

    final controlled = reducePhase0aTick(
      state: state(guardianAStagger: 1),
      intents: attacks(),
      deltaSeconds: 0,
      damageResolver: _RecordingResolver([]),
    );
    expect(controlled.events.whereType<Phase0aGuardianCoopStrike>(), isEmpty);
    expect(controlled.events.whereType<Phase0aAttackStarted>(), hasLength(1));
  });

  test('任一护法未覆盖玩家时不得越过几何闸门合击', () {
    final intents = attacks();
    intents[0] = const Phase0aAttackIntent(
      actorId: 'g_b',
      range: 1,
      halfArcRadians: math.pi,
      cooldownSeconds: 0.5,
      moveKind: Phase0aMoveKind.light,
      aimDirection: ArenaVector(-1, 0),
      qiDelta: 4,
    );

    final result = reducePhase0aTick(
      state: state(),
      intents: intents,
      deltaSeconds: 0,
      damageResolver: _RecordingResolver([]),
    );

    expect(result.events.whereType<Phase0aGuardianCoopStrike>(), isEmpty);
    expect(result.events.whereType<Phase0aAttackStarted>(), hasLength(2));
  });

  test('真实塔42 Phase0A production flow 可触发护法合击且同 seed 稳定', () async {
    final repo = await loadTestGameRepository();
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.mapTower(
      floor: repo.getTowerFloor(42),
      playerSnapshot: Legacy3v3CombatantAdapter.toSnapshot(
        const BattleCharacter(
          characterId: 42,
          name: 'tower42_coop_probe',
          realmTier: RealmTier.zongShi,
          realmLayer: RealmLayer.dengFeng,
          school: TechniqueSchool.gangMeng,
          maxHp: 200000,
          currentHp: 200000,
          internalForce: 100,
          maxQi: 15000,
          currentQi: 15000,
          speed: 200,
          criticalRate: 0,
          evasionRate: 0,
          defenseRate: 0.2,
          totalEquipmentAttack: 0,
          mainCultivationLayer: CultivationLayer.daCheng,
          availableSkills: [],
          skillCooldowns: {},
          activeBuffs: [],
          actionPoint: 0,
          isAlive: true,
          teamSide: 0,
          slotIndex: 0,
        ),
      ),
      numbers: numbers,
    );

    Phase0aHeadlessResult run() {
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: math.Random(42),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      return Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: 0.25,
        maxTicks: 240,
      );
    }

    final first = run();
    final second = run();
    final firstCoops = first.events.whereType<Phase0aGuardianCoopStrike>();
    expect(firstCoops, isNotEmpty);
    expect(first.events, second.events);
    expect(first.finalState, second.finalState);
  });
}

final class _RecordingResolver implements Phase0aDamageResolver {
  _RecordingResolver(this.calls);

  final List<String> calls;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    double defenderWardMult = 1.0,
  }) {
    calls.add('$attackerId->$targetId');
    return Phase0aResolvedHit(
      isHit: true,
      isCritical: false,
      damage: attackerId == 'g_a' ? 11 : 13,
    );
  }
}
