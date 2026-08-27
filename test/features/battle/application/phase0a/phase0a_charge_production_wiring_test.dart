import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

/// Phase 0A charge/破招纵切生产接线测:真实 stage_02_05(顶层 chargeSkillId
/// + 阶段 chargeCounter 双入口)与 tower_7(纯阶段入口)经 mapper → flow →
/// headless → settlement 全链,蓄力携带真实 skill id,破招统一投影为姿态事件,
/// 同 seed 可回放。

/// 强档探针:快速压穿阈值(塔层口径)。
CombatantSnapshot makeChargeProbePlayer(NumbersConfig numbers) =>
    _probe(numbers, internalForce: 900, equipmentAttack: 600);

/// 均势档探针:战斗时长足以让招牌技倒计时走完并真实释放(主线口径)。
CombatantSnapshot makeChargeProbeEvenPlayer(NumbersConfig numbers) =>
    _probe(numbers, internalForce: 350, equipmentAttack: 150);

CombatantSnapshot _probe(
  NumbersConfig numbers, {
  required int internalForce,
  required int equipmentAttack,
}) => testCombatantSnapshot(
  characterId: 1,
  name: 'charge_probe',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.dengFeng,
  school: TechniqueSchool.lingQiao,
  maxHp: 20000,
  internalForce: internalForce,
  maxQi: 100,
  speed: 200,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: equipmentAttack,
  mainCultivationLayer: CultivationLayer.chuKui,
  includeProductionBasicAttack: true,
);

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('stage_02_05 装配:双入口招牌技与窗口参数预解析进 actor/AI', () {
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_02_05'),
      playerSnapshot: makeChargeProbePlayer(numbers),
      numbers: numbers,
    );

    final boss = mapping.waves.last.enemies.single;
    expect(boss.id, startsWith('enemy_sanLiu_qingshan_main'));
    expect(boss.chargeCast, isNotNull);
    expect(boss.chargeCast!.skill.id, 'skill_qingshan_qingfeng');
    expect(
      boss.chargeCast!.cooldownSeconds,
      boss.chargeCast!.skill.phase0aEnemyCooldownSeconds,
    );
    expect(boss.phaseChargeCasts, hasLength(2));
    expect(boss.phaseChargeCasts[0], isNull);
    expect(
      boss.phaseChargeCasts[1]!.skill.id,
      'skill_lingqiao_changlian_fang_ult',
    );
    expect(
      boss.phaseChargeCasts[1]!.cooldownSeconds,
      boss.phaseChargeCasts[1]!.skill.phase0aEnemyCooldownSeconds,
    );
    expect(
      boss.chargeCast!.chargeTicks,
      numbers.combat.bossCharge.defaultChargeTicks,
    );
    expect(
      boss.phaseChargeCasts[1]!.chargeTicks,
      numbers.combat.bossCharge.defaultChargeTicks,
    );
    expect(
      boss.staggerTicksTotal,
      numbers.combat.bossCharge.defaultStaggerTicks,
    );
    expect(boss.chargeTicksRemaining, 0);
    expect(boss.staggerTicksRemaining, 0);

    // AI 绑定表必须包含顶层招牌技(否则 BattleAI 永远不会选中它起手蓄力)。
    final bindings =
        mapping.enemyAiAdapter.skillBindingsByActor[boss.id] ?? const [];
    expect(
      bindings.map((binding) => binding.skill.id),
      contains('skill_qingshan_qingfeng'),
    );
    for (final binding in bindings) {
      expect(
        binding.cooldownSeconds,
        binding.skill.phase0aEnemyCooldownSeconds,
        reason: binding.skill.id,
      );
    }

    // 过渡 R 的 typed break 契约进入生产 input adapter(breakPower > 0)。
    expect(mapping.playerAdapter.clearSkillBinding!.breakPower, greaterThan(0));
  });

  test('stage_01_05 生产映射:首领招牌技与第二阶段入口来自真实定义', () {
    final numbers = repo.numbers;
    final stage = repo.getStage('stage_01_05');
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: makeChargeProbeEvenPlayer(numbers),
      numbers: numbers,
    );
    final boss = mapping.waves.last.enemies.single;

    expect(stage.isBossStage, isTrue);
    expect(stage.dropSkillManualId, 'skill_xie_yu_chuan_lian');
    expect(boss.chargeCast, isNotNull);
    expect(boss.chargeCast!.skill.id, 'skill_xie_yu_chuan_lian');
    expect(
      boss.chargeCast!.cooldownSeconds,
      boss.chargeCast!.skill.phase0aEnemyCooldownSeconds,
    );
    expect(boss.phaseChargeCasts, hasLength(2));
    expect(boss.phaseChargeCasts[1]!.skill.id, 'skill_yinrou_jichu_fang_ult');
    expect(
      boss.phaseChargeCasts[1]!.cooldownSeconds,
      boss.phaseChargeCasts[1]!.skill.phase0aEnemyCooldownSeconds,
    );
    expect(
      boss.staggerTicksTotal,
      numbers.combat.bossCharge.defaultStaggerTicks,
    );
    // 当前 stage_01_05 只证明蓄力/姿态破势/踉跄/CD,不宣称存在易伤倍率。
    expect(boss.vulnerabilityMult, isNull);
    expect(
      mapping.enemyAiAdapter.skillBindingsByActor[boss.id]!.map(
        (binding) => binding.skill.id,
      ),
      contains('skill_xie_yu_chuan_lian'),
    );
  });

  test('stage_02_05 headless:真实 skill id 贯穿蓄力事件与结算,可回放', () {
    final numbers = repo.numbers;
    // 均势档玩家:战斗时长足以让双入口蓄力倒计时走完并真实释放招牌技。
    final playerSnapshot = makeChargeProbeEvenPlayer(numbers);
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_02_05'),
      playerSnapshot: playerSnapshot,
      numbers: numbers,
    );

    Phase0aHeadlessResult run() {
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260822),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      return Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );
    }

    final a = run();
    final b = run();
    expect(b.outcome, a.outcome);
    expect(b.ticks, a.ticks);
    expect(b.events, a.events, reason: '同 seed 事件流必须可重放');
    expect(b.finalState, a.finalState);

    final result = a;
    expect(result.outcome, isNot(Phase0aBattleOutcome.ongoing));

    // 顶层入口:青锋绝起手蓄力至少一次,事件携带真实 skill id。
    final chargeStarts = result.events.whereType<Phase0aBossChargeStarted>();
    expect(
      chargeStarts.map((event) => event.skillId),
      contains('skill_qingshan_qingfeng'),
    );
    // 阶段入口:跌破 0.5 阈值进阶并蓄力阶段招牌。
    expect(
      result.events.whereType<Phase0aBossPhaseChanged>(),
      isNotEmpty,
      reason: '玩家获胜路径必跨 0.5 阈值',
    );
    expect(
      chargeStarts.map((event) => event.skillId),
      contains('skill_lingqiao_changlian_fang_ult'),
    );
    // 阶段招牌必须真实释放；顶层招牌已由 chargeStarted 证明进入生产链，
    // 多波续传后它可能被玩家破招，不再强制要求完成倒计时。
    expect(
      result.events.whereType<Phase0aEnemySkillStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_lingqiao_changlian_fang_ult'),
    );

    // 结算保留真实 Q/R 技能 id。
    final settlement = Phase0aSettlementAdapter.fromMapping(
      mapping: mapping,
      outcome: result.outcome,
      finalState: result.finalState,
      events: result.events,
    );
    expect(
      settlement.skillCasts.map((cast) => cast.skillId).toSet(),
      containsAll({'skill_phase0a_gather', 'skill_phase0a_clear'}),
    );
  });

  test('tower_7 装配与 headless:纯阶段入口蓄力成立且确定性回放', () {
    final numbers = repo.numbers;
    final floor = repo.towerFloors.firstWhere(
      (candidate) => candidate.floorIndex == 7,
    );
    final playerSnapshot = makeChargeProbePlayer(numbers);
    final mapping = Phase0aStageContentMapper.mapTower(
      floor: floor,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
    );

    final boss = mapping.waves.last.enemies.single;
    expect(boss.chargeCast, isNull, reason: '塔 7 无顶层 chargeSkillId');
    expect(boss.phaseChargeCasts, hasLength(2));
    expect(boss.phaseChargeCasts[1]!.skill.id, 'skill_lingqiao_jichu_ult');

    Phase0aHeadlessResult run() {
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260822),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      return Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );
    }

    final a = run();
    final b = run();
    expect(b.events, a.events);
    expect(b.finalState, a.finalState);

    expect(
      a.events.whereType<Phase0aBossChargeStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_lingqiao_jichu_ult'),
      reason: '阶段 chargeCounter 入口必须在真实塔层触发',
    );
    expect(
      a.events.whereType<Phase0aEnemySkillStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_lingqiao_jichu_ult'),
      reason: '阶段招牌技倒计时完成后须经既有 enemy skill 路径真实释放',
    );
  });

  test('stage_02_05 e2e:真实姿态来源累计到阈值后阻断招牌', () {
    // 端到端链路(非 getter 断言):真实技能数据经
    // `SkillDef.fromYaml → Phase0aTacticalSkillBinding →
    // Phase0aPlayerInputAdapter(breakPower)` 进入同一生产 reducer,
    // 由生产 `Phase0aDamageCalculatorAdapter`(唯一 DamageCalculator)结算,
    // 必须实际产出姿态破势事件并阻断该次招牌释放。
    // 不依赖随机 bot 时序:玩家指令驱动,固定 seed 完全可重放。
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_02_05'),
      playerSnapshot: makeChargeProbeEvenPlayer(numbers),
      numbers: numbers,
    );
    final boss = mapping.waves.last.enemies.single;
    expect(boss.chargeCast, isNotNull);
    expect(boss.chargeCast!.skill.id, 'skill_qingshan_qingfeng');

    // 预置蓄力运行态 + 把玩家前移至清场作用半径内(几何预置,非玩法语义),
    // 首蓄力循环即破招目标,避免依赖走位/随机时序。
    final clearIntent = mapping.playerAdapter
        .intentsFor(
          state: mapping.initialState,
          command: const Phase0aPlayerCommand(clear: true),
        )
        .whereType<Phase0aClearIntent>()
        .single;
    final totalPostureDamage =
        clearIntent.postureDamage +
        bossControlToPostureDamage(
          clearIntent.breakPower.toDouble(),
          conversionFactor: boss.posture!.config.bossControlConversionFactor,
        );
    final primedPosture = boss.posture!
        .apply(boss.posture!.config.capacity - totalPostureDamage)
        .state;
    final chargingBoss = boss.copyWith(
      chargingCast: boss.chargeCast,
      chargeTicksRemaining: boss.chargeCast!.chargeTicks,
      posture: primedPosture,
    );
    final chargingState = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player.copyWith(position: ArenaVector.zero),
      enemies: [chargingBoss],
      skillSlots: mapping.initialState.skillSlots,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: chargingState,
      waves: [
        Phase0aWave(enemies: [chargingBoss]),
      ],
      combatants: mapping.combatants
          .where(
            (combatant) =>
                combatant.actorId == chargingState.player.id ||
                combatant.actorId == chargingBoss.id,
          )
          .toList(),
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: Random(20260822),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );

    // 玩家指令驱动:蓄力中且清场槽 ready 即按 R;有界推进保证终止。
    final delta = numbers.phase0aArena.fixedDeltaSeconds;
    const maxTicks = 200;
    var ticks = 0;
    var interruptTickEvents = const <Phase0aEvent>[];
    Phase0aArenaState? stateAtInterrupt;
    while (ticks < maxTicks &&
        stateAtInterrupt == null &&
        flow.outcome == Phase0aBattleOutcome.ongoing) {
      final bossCharging = flow.state.enemies.any(
        (enemy) => enemy.chargingCast != null,
      );
      final clearReady = flow.state.skillSlots.any(
        (slot) =>
            slot.slot == 'clear' &&
            slot.availability == Phase0aSkillAvailability.ready,
      );
      final events = flow.advance(
        deltaSeconds: delta,
        command: Phase0aPlayerCommand(clear: bossCharging && clearReady),
      );
      ticks++;
      if (events.whereType<Phase0aPostureChanged>().any(
        (event) => event.eventType == PostureEventType.vulnerabilityEntered,
      )) {
        interruptTickEvents = events;
        stateAtInterrupt = flow.state;
      }
    }

    expect(stateAtInterrupt, isNotNull, reason: '生产链路应在 $maxTicks 拍内实际产生破招');
    // 破招事件携带被打断的真实招牌技 id。
    final interrupted = interruptTickEvents
        .whereType<Phase0aPostureChanged>()
        .where(
          (event) => event.eventType == PostureEventType.vulnerabilityEntered,
        )
        .toList();
    expect(interrupted, hasLength(1));
    expect(interrupted.single.target, boss.id);
    // 该次招牌释放被阻断:破招当拍无招牌技 EnemySkillStarted。
    expect(
      interruptTickEvents.whereType<Phase0aEnemySkillStarted>().where(
        (event) => event.skillId == 'skill_qingshan_qingfeng',
      ),
      isEmpty,
    );
    // 进入踉跄窗口且蓄力清空。
    final bossAfter = stateAtInterrupt!.enemies.single;
    expect(bossAfter.staggerTicksRemaining, greaterThan(0));
    expect(bossAfter.chargingCast, isNull);
    expect(bossAfter.chargeTicksRemaining, 0);
  });

  test('stage_01_05 e2e:真实招牌蓄力可释放，也可被破招并进入 CD', () {
    final numbers = repo.numbers;
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_05'),
      playerSnapshot: makeChargeProbeEvenPlayer(numbers),
      numbers: numbers,
    );
    final boss = mapping.waves.last.enemies.single;
    final chargeCast = boss.chargeCast!;
    final clearIntent = mapping.playerAdapter
        .intentsFor(
          state: mapping.initialState,
          command: const Phase0aPlayerCommand(clear: true),
        )
        .whereType<Phase0aClearIntent>()
        .single;
    final totalPostureDamage =
        clearIntent.postureDamage +
        bossControlToPostureDamage(
          clearIntent.breakPower.toDouble(),
          conversionFactor: boss.posture!.config.bossControlConversionFactor,
        );
    final primedPosture = boss.posture!
        .apply(boss.posture!.config.capacity - totalPostureDamage)
        .state;

    Phase0aWaveBattleFlow buildFlow() {
      final chargingBoss = Phase0aActor(
        id: boss.id,
        side: boss.side,
        position: ArenaVector.zero,
        facing: boss.facing,
        maxHealth: boss.maxHealth,
        currentHealth: boss.currentHealth,
        moveSpeed: boss.moveSpeed,
        qiCurrent: boss.qiMax,
        qiMax: boss.qiMax,
        attackCooldownRemaining: 0,
        defeatKind: boss.defeatKind,
        isBoss: boss.isBoss,
        autoUltimate: boss.autoUltimate,
        bossPhases: boss.bossPhases,
        bossPhaseIndex: boss.bossPhaseIndex,
        enemySkillCooldowns: boss.enemySkillCooldowns,
        chargeCast: boss.chargeCast,
        phaseChargeCasts: boss.phaseChargeCasts,
        staggerTicksTotal: boss.staggerTicksTotal,
        guardianDefIds: boss.guardianDefIds,
        guardianWardMult: boss.guardianWardMult,
        guardInterceptsInterrupt: boss.guardInterceptsInterrupt,
        vulnerabilityMult: boss.vulnerabilityMult,
        posture: primedPosture,
        // 只保留本项要验证的真实招牌技，避免普通技能优先级遮蔽
        // stage_01_05 的 chargeSkillId；技能本体和绑定仍来自生产 YAML。
        unlockedEnemySkillIds: const ['skill_xie_yu_chuan_lian'],
      );
      final chargingState = Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: mapping.initialState.player.copyWith(
          position: ArenaVector.zero,
        ),
        enemies: [chargingBoss],
        skillSlots: mapping.initialState.skillSlots,
      );
      final aiIntent = mapping.enemyAiAdapter
          .intentsFor(state: chargingState)
          .single;
      expect(aiIntent, isA<Phase0aEnemySkillIntent>());
      expect(
        (aiIntent as Phase0aEnemySkillIntent).skill.id,
        chargeCast.skill.id,
      );
      return Phase0aProductionFlowAssembler.assemble(
        initialState: chargingState,
        waves: [
          Phase0aWave(enemies: [chargingBoss]),
        ],
        combatants: mapping.combatants
            .where(
              (combatant) =>
                  combatant.actorId == chargingState.player.id ||
                  combatant.actorId == chargingBoss.id,
            )
            .toList(),
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260824),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
    }

    final releaseFlow = buildFlow();
    final releaseEvents = <Phase0aEvent>[
      ...releaseFlow.advance(
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(),
      ),
    ];
    expect(releaseFlow.state.enemies.single.chargingCast, isNotNull);
    for (var tick = 0; tick < chargeCast.chargeTicks + 1; tick++) {
      releaseEvents.addAll(
        releaseFlow.advance(
          deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
          command: const Phase0aPlayerCommand(),
        ),
      );
    }
    expect(
      releaseEvents.whereType<Phase0aBossChargeStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_xie_yu_chuan_lian'),
    );
    expect(
      releaseEvents.whereType<Phase0aEnemySkillStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_xie_yu_chuan_lian'),
    );

    final interruptFlow = buildFlow();
    final delta = numbers.phase0aArena.fixedDeltaSeconds;
    final startEvents = interruptFlow.advance(
      deltaSeconds: delta,
      command: const Phase0aPlayerCommand(),
    );
    expect(
      startEvents.whereType<Phase0aBossChargeStarted>().map(
        (event) => event.skillId,
      ),
      contains('skill_xie_yu_chuan_lian'),
    );
    Phase0aArenaState? interruptedState;
    var interruptEvents = const <Phase0aEvent>[];
    for (var tick = 0; tick < 20 && interruptedState == null; tick++) {
      final events = interruptFlow.advance(
        deltaSeconds: delta,
        command: const Phase0aPlayerCommand(clear: true),
      );
      if (events.whereType<Phase0aPostureChanged>().any(
        (event) => event.eventType == PostureEventType.vulnerabilityEntered,
      )) {
        interruptEvents = events;
        interruptedState = interruptFlow.state;
      }
    }

    expect(interruptedState, isNotNull);
    final interrupted = interruptEvents
        .whereType<Phase0aPostureChanged>()
        .singleWhere(
          (event) => event.eventType == PostureEventType.vulnerabilityEntered,
        );
    expect(interrupted.target, boss.id);
    expect(interruptEvents.whereType<Phase0aEnemySkillStarted>(), isEmpty);
    final bossAfter = interruptedState!.enemies.single;
    expect(bossAfter.chargingCast, isNull);
    expect(bossAfter.chargeTicksRemaining, 0);
    expect(bossAfter.staggerTicksRemaining, greaterThan(0));
    expect(
      bossAfter.enemySkillCooldowns['skill_xie_yu_chuan_lian'],
      chargeCast.cooldownSeconds,
    );
  });
}
