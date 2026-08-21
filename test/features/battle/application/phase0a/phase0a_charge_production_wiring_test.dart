import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

import '../../../../support/test_data.dart';

/// Phase 0A charge/破招纵切生产接线测:真实 stage_02_05(顶层 chargeSkillId
/// + 阶段 chargeCounter 双入口)与 tower_7(纯阶段入口)经 mapper → flow →
/// headless → settlement 全链,蓄力/破招事件携带真实 skill id,同 seed 可回放。

/// 强档探针:快速压穿阈值(塔层口径)。
BattleCharacter makeChargeProbePlayer(NumbersConfig numbers) =>
    _probe(numbers, internalForce: 900, equipmentAttack: 600);

/// 均势档探针:战斗时长足以让招牌技倒计时走完并真实释放(主线口径)。
BattleCharacter makeChargeProbeEvenPlayer(NumbersConfig numbers) =>
    _probe(numbers, internalForce: 350, equipmentAttack: 150);

BattleCharacter _probe(
  NumbersConfig numbers, {
  required int internalForce,
  required int equipmentAttack,
}) => BattleCharacter(
  characterId: 1,
  name: 'charge_probe',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.dengFeng,
  school: TechniqueSchool.lingQiao,
  maxHp: 20000,
  currentHp: 20000,
  internalForce: internalForce,
  maxQi: 100,
  currentQi: 100,
  speed: 200,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: equipmentAttack,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: 0,
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
      playerSnapshot: Legacy3v3CombatantAdapter.toSnapshot(
        makeChargeProbePlayer(numbers),
      ),
      numbers: numbers,
    );

    final boss = mapping.initialState.enemies.single;
    expect(boss.id, 'enemy_sanLiu_qingshan_main');
    expect(boss.chargeCast, isNotNull);
    expect(boss.chargeCast!.skill.id, 'skill_qingshan_qingfeng');
    expect(boss.phaseChargeCasts, hasLength(2));
    expect(boss.phaseChargeCasts[0], isNull);
    expect(
      boss.phaseChargeCasts[1]!.skill.id,
      'skill_lingqiao_changlian_fang_ult',
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

    // 过渡 R 的 typed break 契约进入生产 input adapter(breakPower > 0)。
    expect(mapping.playerAdapter.clearSkillBinding!.breakPower, greaterThan(0));
  });

  test('stage_02_05 headless:真实 skill id 贯穿蓄力事件与结算,可回放', () {
    final numbers = repo.numbers;
    // 均势档玩家:战斗时长足以让双入口蓄力倒计时走完并真实释放招牌技。
    final playerSnapshot = Legacy3v3CombatantAdapter.toSnapshot(
      makeChargeProbeEvenPlayer(numbers),
    );
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
    // 招牌技真实释放(headless 不丢真实 skill id):双入口招牌均完成倒计时。
    expect(
      result.events.whereType<Phase0aEnemySkillStarted>().map(
        (event) => event.skillId,
      ),
      containsAll({
        'skill_qingshan_qingfeng',
        'skill_lingqiao_changlian_fang_ult',
      }),
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
    final playerSnapshot = Legacy3v3CombatantAdapter.toSnapshot(
      makeChargeProbePlayer(numbers),
    );
    final mapping = Phase0aStageContentMapper.mapTower(
      floor: floor,
      playerSnapshot: playerSnapshot,
      numbers: numbers,
    );

    final boss = mapping.initialState.enemies.single;
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
}
