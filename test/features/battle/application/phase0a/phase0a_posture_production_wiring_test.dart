import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/phase0a_skill_behavior.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _HitResolver implements Phase0aDamageResolver {
  const _HitResolver();

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

CombatantSnapshot _player(GameRepository repo) {
  final basic = repo.getSkill('skill_gangmeng_jichu_basic');
  final numeric = repo.getSkill('skill_gangmeng_jichu_ult');
  return testCombatantSnapshot(
    characterId: 1,
    name: 'posture_probe',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.dengFeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 20000,
    currentQi: 100,
    maxQi: 100,
    criticalRate: repo.numbers.combat.critical.baseRate,
    defenseRate: repo.numbers.defenseRateByTier[RealmTier.xueTu]!,
    skillLoadout: CombatantSkillLoadout(basicAttack: basic, main1: numeric),
    availableSkills: [basic, numeric],
  );
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('combat.posture 五字段严格解析，缺失或非法值 fail-closed', () {
    final numbers = repo.numbers;
    final rawPosture = (numbers.raw['combat'] as Map)['posture'] as Map;
    final posture = numbers.combat.posture;

    expect(posture.capacity, rawPosture['capacity']);
    expect(posture.vulnerabilityTicks, rawPosture['vulnerability_ticks']);
    expect(posture.recoveryPolicy.name, rawPosture['recovery_policy']);
    expect(
      posture.postVulnerabilityAccumulated,
      rawPosture['post_vulnerability_accumulated'],
    );
    expect(posture.bossConversionFactor, rawPosture['boss_conversion_factor']);

    Map<String, dynamic> mutableNumbers() =>
        (jsonDecode(jsonEncode(numbers.raw)) as Map).cast<String, dynamic>();

    final missing = mutableNumbers();
    (missing['combat'] as Map).remove('posture');
    expect(
      () => NumbersConfig.fromYaml(missing),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('combat.posture'),
        ),
      ),
    );

    for (final key in <String>[
      'capacity',
      'vulnerability_ticks',
      'recovery_policy',
      'post_vulnerability_accumulated',
      'boss_conversion_factor',
    ]) {
      final missingField = mutableNumbers();
      ((missingField['combat'] as Map)['posture'] as Map).remove(key);
      expect(
        () => NumbersConfig.fromYaml(missingField),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('combat.posture.$key'),
          ),
        ),
        reason: key,
      );
    }

    final invalid = mutableNumbers();
    ((invalid['combat'] as Map)['posture'] as Map)['recovery_policy'] =
        'fixture_fallback';
    expect(
      () => NumbersConfig.fromYaml(invalid),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('combat.posture.recovery_policy'),
        ),
      ),
    );
  });

  test('普通敌与 Boss 均由 mapper 注入同一 PostureState 配置', () {
    final numbers = repo.numbers;
    final player = _player(repo);
    final ordinary = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_01'),
      playerSnapshot: player,
      numbers: numbers,
    );
    final boss = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_05'),
      playerSnapshot: player,
      numbers: numbers,
    );

    final enemies = [
      ...ordinary.waves.expand((wave) => wave.enemies),
      ...boss.waves.expand((wave) => wave.enemies),
    ];
    expect(enemies, isNotEmpty);
    for (final enemy in enemies) {
      expect(enemy.posture, isNotNull, reason: enemy.id);
      expect(enemy.posture!.accumulated, 0, reason: enemy.id);
      expect(
        enemy.posture!.config.capacity,
        numbers.combat.posture.capacity,
        reason: enemy.id,
      );
      expect(
        enemy.posture!.config.bossControlConversionFactor,
        numbers.combat.posture.bossConversionFactor,
        reason: enemy.id,
      );
    }
    expect(ordinary.initialState.player.posture, isNull);
  });

  test('普攻/数字技/Q/R/敌技 intent 姿态伤害只由真实 powerMultiplier 映射', () {
    final numbers = repo.numbers;
    final baseline = numbers.phase0aArena.basicPowerMultiplier;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_05'),
      playerSnapshot: _player(repo),
      numbers: numbers,
    );

    final playerIntents = mapping.playerAdapter.intentsFor(
      state: mapping.initialState,
      command: const Phase0aPlayerCommand(
        attack: true,
        gather: true,
        clear: true,
        skillHotkey: 1,
      ),
    );
    final basicIntent = playerIntents.whereType<Phase0aAttackIntent>().single;
    final numericIntent = playerIntents.whereType<Phase0aSkillIntent>().single;
    final gatherIntent = playerIntents.whereType<Phase0aGatherIntent>().single;
    final clearIntent = playerIntents.whereType<Phase0aClearIntent>().single;
    final playerBasic = _player(repo).skillLoadout.basicAttack!;
    final numeric = _player(repo).skillLoadout.main1!;
    final gather = mapping.playerAdapter.gatherSkillBinding!.skill;
    final clear = mapping.playerAdapter.clearSkillBinding!.skill;

    expect(basicIntent.postureDamage, playerBasic.powerMultiplier / baseline);
    expect(basicIntent.postureHitKind, PostureHitKind.light);
    expect(numericIntent.postureDamage, numeric.powerMultiplier / baseline);
    expect(numericIntent.postureHitKind, PostureHitKind.heavy);
    expect(gatherIntent.postureDamage, gather.powerMultiplier / baseline);
    expect(gatherIntent.postureHitKind, PostureHitKind.heavy);
    expect(clearIntent.postureDamage, clear.powerMultiplier / baseline);
    expect(clearIntent.postureHitKind, PostureHitKind.bossControl);
    expect(
      clearIntent.breakPower,
      clear.phase0aBehavior!
          .effectOf(Phase0aSkillEffectType.breakPower)!
          .points,
    );

    final ordinary = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_01'),
      playerSnapshot: _player(repo),
      numbers: numbers,
    );
    final ordinaryEnemy = ordinary.initialState.enemies.first;
    final ordinaryState = Phase0aArenaState(
      tick: ordinary.initialState.tick,
      nextSeq: ordinary.initialState.nextSeq,
      player: ordinary.initialState.player.copyWith(
        position: ordinaryEnemy.position,
      ),
      enemies: ordinary.initialState.enemies,
      skillSlots: ordinary.initialState.skillSlots,
      winCondition: ordinary.initialState.winCondition,
    );
    final enemyBasic = ordinary.combatants
        .firstWhere((entry) => entry.actorId == ordinaryEnemy.id)
        .snapshot
        .availableSkills
        .firstWhere((skill) => skill.type == SkillType.normalAttack);
    final enemyBasicIntent = ordinary.enemyAiAdapter
        .intentsFor(state: ordinaryState)
        .whereType<Phase0aAttackIntent>()
        .single;
    expect(
      enemyBasicIntent.postureDamage,
      enemyBasic.powerMultiplier / baseline,
    );
    expect(enemyBasicIntent.postureHitKind, PostureHitKind.light);

    final boss = mapping.waves.last.enemies.single;
    final bossState = Phase0aArenaState(
      tick: mapping.initialState.tick,
      nextSeq: mapping.initialState.nextSeq,
      player: mapping.initialState.player.copyWith(position: boss.position),
      enemies: [boss],
      skillSlots: mapping.initialState.skillSlots,
      winCondition: mapping.initialState.winCondition,
    );
    final enemySkillIntent = mapping.enemyAiAdapter
        .intentsFor(state: bossState)
        .whereType<Phase0aEnemySkillIntent>()
        .single;
    expect(
      enemySkillIntent.postureDamage,
      enemySkillIntent.skill.powerMultiplier / baseline,
    );
    expect(enemySkillIntent.postureHitKind, PostureHitKind.heavy);
  });

  test('破招未达阈值不清蓄力，只在累计破势时中断并开统一窗', () {
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_05'),
      playerSnapshot: _player(repo),
      numbers: numbers,
    );
    final mappedBoss = mapping.waves.last.enemies.single;
    final clearIntent = mapping.playerAdapter
        .intentsFor(
          state: mapping.initialState,
          command: const Phase0aPlayerCommand(clear: true),
        )
        .whereType<Phase0aClearIntent>()
        .single;
    final convertedBreak = bossControlToPostureDamage(
      clearIntent.breakPower.toDouble(),
      conversionFactor: numbers.combat.posture.bossConversionFactor,
    );
    final totalPostureDamage = clearIntent.postureDamage + convertedBreak;

    Phase0aArenaState chargingState(PostureState posture) => Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player.copyWith(
        position: mappedBoss.position,
      ),
      enemies: [
        mappedBoss.copyWith(
          posture: posture,
          chargingCast: mappedBoss.chargeCast,
          chargeTicksRemaining: mappedBoss.chargeCast!.chargeTicks,
        ),
      ],
      skillSlots: mapping.initialState.skillSlots,
    );

    final below = reducePhase0aTick(
      state: chargingState(PostureState.initial(mappedBoss.posture!.config)),
      intents: [clearIntent],
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      damageResolver: const _HitResolver(),
    );
    final belowBoss = below.state.enemies.single;
    expect(belowBoss.chargingCast, isNotNull);
    expect(belowBoss.enemySkillCooldowns, isEmpty);
    expect(belowBoss.staggerTicksRemaining, 0);
    expect(belowBoss.posture!.accumulated, totalPostureDamage);
    expect(belowBoss.posture!.isVulnerable, isFalse);

    final preload = mappedBoss.posture!.config.capacity - totalPostureDamage;
    final primed = PostureState.initial(
      mappedBoss.posture!.config,
    ).apply(preload).state;
    final broken = reducePhase0aTick(
      state: chargingState(primed),
      intents: [clearIntent],
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      damageResolver: const _HitResolver(),
    );
    final brokenBoss = broken.state.enemies.single;
    expect(brokenBoss.chargingCast, isNull);
    expect(brokenBoss.posture!.isVulnerable, isTrue);
    expect(
      brokenBoss.posture!.vulnerabilityTicksRemaining,
      numbers.combat.posture.vulnerabilityTicks,
    );
    expect(
      brokenBoss.staggerTicksRemaining,
      numbers.combat.bossCharge.defaultStaggerTicks,
    );
    expect(
      brokenBoss.enemySkillCooldowns[mappedBoss.chargeCast!.skill.id],
      mappedBoss.chargeCast!.cooldownSeconds,
    );
    expect(
      broken.events.whereType<Phase0aPostureChanged>().where(
        (event) => event.eventType == PostureEventType.vulnerabilityEntered,
      ),
      hasLength(1),
    );
  });

  test('统一破绽窗每拍 advance 并按冻结策略关窗恢复', () {
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_05'),
      playerSnapshot: _player(repo),
      numbers: numbers,
    );
    final mappedBoss = mapping.waves.last.enemies.single;
    final opened = PostureState.initial(
      mappedBoss.posture!.config,
    ).apply(mappedBoss.posture!.config.capacity).state;
    var state = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player,
      enemies: [mappedBoss.copyWith(posture: opened)],
      skillSlots: mapping.initialState.skillSlots,
    );

    final first = reducePhase0aTick(
      state: state,
      intents: const [],
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      damageResolver: const _HitResolver(),
    );
    expect(
      first.state.enemies.single.posture!.vulnerabilityTicksRemaining,
      numbers.combat.posture.vulnerabilityTicks - 1,
    );
    expect(first.events.whereType<Phase0aPostureChanged>(), isEmpty);
    state = first.state;

    for (
      var tick = 1;
      tick < numbers.combat.posture.vulnerabilityTicks;
      tick += 1
    ) {
      final result = reducePhase0aTick(
        state: state,
        intents: const [],
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        damageResolver: const _HitResolver(),
      );
      state = result.state;
      if (tick == numbers.combat.posture.vulnerabilityTicks - 1) {
        final postureEvents = result.events
            .whereType<Phase0aPostureChanged>()
            .toList();
        expect(postureEvents.map((event) => event.eventType), [
          PostureEventType.vulnerabilityEnded,
          PostureEventType.postureRecovered,
        ]);
      }
    }

    final recovered = state.enemies.single.posture!;
    expect(recovered.isVulnerable, isFalse);
    expect(
      recovered.accumulated,
      numbers.combat.posture.postVulnerabilityAccumulated,
    );
  });
}
