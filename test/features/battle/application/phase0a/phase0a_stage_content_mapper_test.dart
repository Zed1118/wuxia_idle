import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

import '../../../../support/test_data.dart';

/// Phase 1 纵切切片 1 红测(spec 2026-08-19 · P1=α 主线 Ch1 · D1=α 机械映射):
/// ① 映射结构:真实 stages.yaml stage_01_01 → 单波装配,actor 覆盖/
///   moveBindings 三 kind 完备/空间排布玩家左敌右/HP 口径沿用 buildEnemyTeam;
/// ② fail-fast:arena 段空(empty.isEmpty)+ 空敌队关卡;
/// ③ headless 全链:Ch1 五关 bot 驾驶全部 victory(P3 双跑口径地基);
/// ④ 确定性:同 seed 两次运行 ticks/终局/末态玩家 HP 全等。

BattleCharacter makeCh1Player(NumbersConfig numbers) => BattleCharacter(
  characterId: 1,
  name: '纵切玩家',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  currentHp: 15000,
  internalForce: 600,
  maxQi: 100,
  currentQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0.0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0.0,
  totalEquipmentAttack: 130,
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

  group('映射结构(真实数据底座)', () {
    test('stage_01_01 单敌 → 单波装配,actor 覆盖与 HP 口径沿 buildEnemyTeam', () {
      final stage = repo.getStage('stage_01_01');
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerCharacter: makeCh1Player(numbers),
        numbers: numbers,
      );

      // 单波,波内敌数 = enemyTeam 长度。
      expect(mapping.waves, hasLength(1));
      expect(mapping.waves.first.enemies, hasLength(stage.enemyTeam.length));
      // 单敌关 actor id 不加后缀。
      expect(mapping.waves.first.enemies.single.id, 'enemy_xueTu_thug_a');
      // combatants = 玩家 + 全部敌人。
      expect(mapping.combatants, hasLength(1 + stage.enemyTeam.length));
      expect(
        mapping.combatants.map((c) => c.actorId),
        containsAll(['player', 'enemy_xueTu_thug_a']),
      );
      // moveBindings 三 kind 全覆盖:gather 为 control-only。
      expect(
        mapping.moveBindings.keys,
        hasLength(Phase0aDamageKind.values.length),
      );
      expect(mapping.moveBindings[Phase0aDamageKind.basic], isNotNull);
      expect(mapping.moveBindings[Phase0aDamageKind.gather], isNull);
      expect(mapping.moveBindings[Phase0aDamageKind.clear], isNotNull);
      // 空间排布:玩家在左,敌在右。
      expect(mapping.initialState.player.position.x, lessThan(0));
      expect(mapping.waves.first.enemies.single.position.x, greaterThan(0));
      // 玩家 actor HP 口径 = 玩家 BattleCharacter。
      expect(mapping.initialState.player.maxHealth, 15000);
      // 敌 actor HP 口径 = buildEnemyTeam(cycleIndex=1 零回归 = baseHp)。
      expect(mapping.waves.first.enemies.single.maxHealth, 1500);
      // 技能印双槽 ready。
      expect(mapping.initialState.skillSlots, hasLength(2));
      expect(
        mapping.initialState.skillSlots.every(
          (s) => s.availability == Phase0aSkillAvailability.ready,
        ),
        isTrue,
      );
    });

    test('stage_01_03 三敌 → 三敌单波,id 加波次槽位后缀防撞', () {
      final stage = repo.getStage('stage_01_03');
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerCharacter: makeCh1Player(numbers),
        numbers: numbers,
      );
      expect(mapping.waves.first.enemies, hasLength(stage.enemyTeam.length));
      final ids = mapping.waves.first.enemies.map((e) => e.id).toSet();
      expect(ids, hasLength(stage.enemyTeam.length));
      // 全场 actor id 唯一(assembler 覆盖校验前提)。
      final allIds = {mapping.initialState.player.id, ...ids};
      expect(allIds, hasLength(1 + stage.enemyTeam.length));
    });

    test('空敌队关卡 fail-fast', () {
      final numbers = repo.numbers;
      const emptyStage = StageDef(
        id: 'stage_empty',
        name: '空关',
        stageType: StageType.mainline,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: [],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );
      expect(
        () => Phase0aStageContentMapper.map(
          stage: emptyStage,
          playerCharacter: makeCh1Player(numbers),
          numbers: numbers,
        ),
        throwsArgumentError,
      );
    });
  });

  group('phase0a_arena 配置段', () {
    test('缺段兜底 empty(isEmpty=true)', () {
      expect(Phase0aArenaConfig.fromYaml(const {}).isEmpty, isTrue);
      expect(repo.numbers.phase0aArena.isEmpty, isFalse);
    });

    test('真实段边界有序 + 关键调参项为正', () {
      final arena = repo.numbers.phase0aArena;
      expect(arena.arenaMinX, lessThan(arena.arenaMaxX));
      expect(arena.arenaMinY, lessThan(arena.arenaMaxY));
      expect(arena.playerMoveSpeed, greaterThan(0));
      expect(arena.playerAttackRange, greaterThan(0));
      expect(arena.enemyMoveSpeed, greaterThan(0));
      expect(arena.basicPowerMultiplier, greaterThan(0));
      expect(arena.clearPowerMultiplier, greaterThan(0));
    });
  });

  group('headless 全链(Ch1 五关 bot 驾驶)', () {
    test('五关全部 victory(纵切成立判据·headless 侧)', () {
      final numbers = repo.numbers;
      for (var i = 1; i <= 5; i++) {
        final stageId = 'stage_01_0$i';
        final stage = repo.getStage(stageId);
        final mapping = Phase0aStageContentMapper.map(
          stage: stage,
          playerCharacter: makeCh1Player(numbers),
          numbers: numbers,
        );
        final flow = Phase0aProductionFlowAssembler.assemble(
          initialState: mapping.initialState,
          waves: mapping.waves,
          combatants: mapping.combatants,
          moveBindings: mapping.moveBindings,
          numbers: numbers,
          rng: Random(20260819),
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
        );
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: mapping.playerAdapter,
        );
        final result = Phase0aHeadlessRunner.runToEnd(flow: flow, bot: bot);
        expect(
          result.outcome,
          Phase0aBattleOutcome.victory,
          reason:
              '$stageId bot headless 应 victory,'
              '实际 ${result.outcome} / ticks=${result.ticks}',
        );
        expect(result.timedOut, isFalse, reason: stageId);
      }
    });

    test('确定性:同 seed 两次运行 ticks/终局/末态玩家 HP 全等', () {
      final numbers = repo.numbers;
      final stage = repo.getStage('stage_01_05');
      Phase0aHeadlessResult run() {
        final mapping = Phase0aStageContentMapper.map(
          stage: stage,
          playerCharacter: makeCh1Player(numbers),
          numbers: numbers,
        );
        final flow = Phase0aProductionFlowAssembler.assemble(
          initialState: mapping.initialState,
          waves: mapping.waves,
          combatants: mapping.combatants,
          moveBindings: mapping.moveBindings,
          numbers: numbers,
          rng: Random(777),
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
        );
        return Phase0aHeadlessRunner.runToEnd(
          flow: flow,
          bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        );
      }

      final a = run();
      final b = run();
      expect(b.ticks, a.ticks);
      expect(b.outcome, a.outcome);
      expect(
        b.finalState.player.currentHealth,
        a.finalState.player.currentHealth,
      );
      expect(b.finalState.tick, a.finalState.tick);
    });

    test('胜率画像:五关 × 五 seed 全胜(P3 双跑口径基线)', () {
      final numbers = repo.numbers;
      var wins = 0;
      var total = 0;
      for (var i = 1; i <= 5; i++) {
        final stage = repo.getStage('stage_01_0$i');
        for (final seed in [1, 2, 3, 4, 5]) {
          final mapping = Phase0aStageContentMapper.map(
            stage: stage,
            playerCharacter: makeCh1Player(numbers),
            numbers: numbers,
          );
          final flow = Phase0aProductionFlowAssembler.assemble(
            initialState: mapping.initialState,
            waves: mapping.waves,
            combatants: mapping.combatants,
            moveBindings: mapping.moveBindings,
            numbers: numbers,
            rng: Random(seed),
            playerAdapter: mapping.playerAdapter,
            enemyAiAdapter: mapping.enemyAiAdapter,
          );
          final result = Phase0aHeadlessRunner.runToEnd(
            flow: flow,
            bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
          );
          total++;
          if (result.outcome == Phase0aBattleOutcome.victory) wins++;
        }
      }
      expect(total, 25);
      expect(wins, total, reason: 'Ch1 五关 × 五 seed bot 应全胜');
    });
  });
}
