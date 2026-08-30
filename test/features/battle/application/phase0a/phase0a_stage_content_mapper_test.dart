import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

/// Phase 1 纵切切片 1 红测(spec 2026-08-19 · P1=α 主线 Ch1 · D1=α 机械映射):
/// ① 映射结构:真实 stages.yaml stage_01_01 → 单波装配,actor 覆盖/
///   moveBindings 三 kind 完备/空间排布玩家左敌右/HP 口径沿用 buildEnemyTeam;
/// ② fail-fast:arena 段空(empty.isEmpty)+ 空敌队关卡;
/// ③ headless 全链:Ch1 五关 bot 驾驶全部 victory(P3 双跑口径地基);
/// ④ 确定性:同 seed 两次运行 ticks/终局/末态玩家 HP 全等。

CombatantSnapshot makeCh1Player(NumbersConfig numbers) => testCombatantSnapshot(
  characterId: 1,
  name: '纵切玩家',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  internalForce: 600,
  maxQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0.0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0.0,
  totalEquipmentAttack: 130,
  mainCultivationLayer: CultivationLayer.chuKui,
  skillLoadout: CombatantSkillLoadout(
    basicAttack:
        GameRepository.instance.skillDefs['skill_gangmeng_jichu_basic'],
  ),
);

CombatantSnapshot makeBossPhasePlayer(NumbersConfig numbers) =>
    testCombatantSnapshot(
      characterId: 1,
      name: 'phase_player',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.dengFeng,
      school: TechniqueSchool.lingQiao,
      maxHp: 20000,
      internalForce: 300,
      maxQi: 100,
      speed: 200,
      criticalRate: numbers.combat.critical.baseRate,
      evasionRate: 0,
      defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      skillLoadout: CombatantSkillLoadout(
        basicAttack:
            GameRepository.instance.skillDefs['skill_lingqiao_jichu_basic'],
      ),
    );

void main() {
  late GameRepository repo;
  late Map<String, dynamic> phase0aArenaYaml;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    final numbersYaml = parseYamlMap(await loadTestAsset('data/numbers.yaml'));
    phase0aArenaYaml = (numbersYaml['phase0a_arena'] as Map).cast();
  });

  group('映射结构(真实数据底座)', () {
    test('玩家快照缺真实 basicAttack 时 mapper fail-closed', () {
      final numbers = repo.numbers;
      expect(
        () => Phase0aStageContentMapper.map(
          stage: repo.getStage('stage_01_01'),
          playerSnapshot: makeCh1Player(
            numbers,
          ).copyWith(skillLoadout: const CombatantSkillLoadout.empty()),
          numbers: numbers,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('lacks a real basic skill'),
          ),
        ),
      );
    });

    test('stage_01_01 单敌模板 → YAML 多波装配,actor 覆盖与 HP 口径沿 buildEnemyTeam', () {
      final stage = repo.getStage('stage_01_01');
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );

      expect(mapping.waves.map((wave) => wave.enemies.length), [2, 3, 4]);
      expect(
        mapping.waves.first.enemies.first.id,
        contains('enemy_xueTu_thug_a'),
      );
      expect(mapping.combatants, hasLength(1 + 2 + 3 + 4));
      expect(mapping.combatants.map((c) => c.actorId), contains('player'));
      // 固定三 kind 全覆盖；Q/R 已由真实数据技能绑定，fixture 无数字槽。
      expect(mapping.moveBindings.keys, hasLength(3));
      expect(mapping.playerAdapter.numericSkillBindings.equipped, isEmpty);
      expect(mapping.moveBindings[Phase0aDamageKind.basic], isNotNull);
      expect(
        mapping.moveBindings[Phase0aDamageKind.gather]?.id,
        'skill_phase0a_gather',
      );
      expect(
        mapping.moveBindings[Phase0aDamageKind.clear]?.id,
        'skill_phase0a_clear',
      );
      final gatherBinding = mapping.playerAdapter.gatherSkillBinding!;
      final clearBinding = mapping.playerAdapter.clearSkillBinding!;
      final cameraWidth =
          (numbers.phase0aArena.arenaMaxX - numbers.phase0aArena.arenaMinX) *
          Phase0aPresentationTokens.cameraWorldFraction;
      final cameraHeight =
          (numbers.phase0aArena.arenaMaxY - numbers.phase0aArena.arenaMinY) *
          Phase0aPresentationTokens.cameraWorldFraction;
      final cameraDiagonal = sqrt(
        cameraWidth * cameraWidth + cameraHeight * cameraHeight,
      );
      expect(
        gatherBinding.effectRadius,
        greaterThanOrEqualTo(cameraDiagonal),
        reason: '点击位聚怪必须覆盖同一镜头内从一端到另一端的敌人',
      );
      expect(gatherBinding.destinationRadius, 120);
      expect(gatherBinding.qiCost, 25);
      expect(gatherBinding.cooldownSeconds, 5);
      expect(clearBinding.effectRadius, 340);
      expect(clearBinding.qiCost, 50);
      expect(clearBinding.cooldownSeconds, 8);
      // 空间排布:玩家在左,敌在右。
      expect(mapping.initialState.player.position.x, lessThan(0));
      expect(mapping.waves.first.enemies.first.position.x, greaterThan(0));
      // 玩家 actor HP 口径 = 玩家中立快照。
      expect(mapping.initialState.player.maxHealth, 15000);
      // 小怪 HP 口径 = 原快照 × YAML mainline_wave ordinary.hp_multiplier。
      expect(mapping.waves.first.enemies.first.maxHealth, 150);
      // 非阶段敌人保持旧的中性内力/CD 路径。
      expect(
        mapping.waves.first.enemies.first.qiCurrent,
        numbers.phase0aArena.enemyQi,
      );
      expect(mapping.waves.first.enemies.first.enemySkillCooldowns, isEmpty);
      // 技能印双槽 ready。
      expect(mapping.initialState.skillSlots, hasLength(2));
      expect(
        mapping.initialState.skillSlots.every(
          (s) => s.availability == Phase0aSkillAvailability.ready,
        ),
        isTrue,
      );
    });

    test('玩家开场真气透传 CombatantSnapshot.currentQi,不擅自补满', () {
      final numbers = repo.numbers;
      final player = makeCh1Player(numbers).copyWith(currentQi: 37);
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: player,
        numbers: numbers,
      );
      expect(mapping.initialState.player.qiCurrent, 37);
      expect(mapping.initialState.player.qiMax, 100);
    });

    test('玩家与普通敌人普攻真气只读各自真实 SkillDef.qiDelta', () {
      final numbers = repo.numbers;
      final player = makeCh1Player(numbers);
      final playerBasic = player.skillLoadout.basicAttack!;
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: player,
        numbers: numbers,
      );

      final playerAttack = mapping.playerAdapter
          .intentsFor(
            state: mapping.initialState,
            command: const Phase0aPlayerCommand(attack: true),
          )
          .whereType<Phase0aAttackIntent>()
          .single;
      expect(playerAttack.qiDelta, playerBasic.qiDelta);

      final enemyBasic = mapping.combatants[1].snapshot.availableSkills
          .singleWhere((skill) => skill.type == SkillType.normalAttack);
      final enemyState = Phase0aArenaState(
        tick: mapping.initialState.tick,
        nextSeq: mapping.initialState.nextSeq,
        player: mapping.initialState.player.copyWith(
          position: mapping.initialState.enemies.first.position,
        ),
        enemies: mapping.initialState.enemies,
        skillSlots: mapping.initialState.skillSlots,
        winCondition: mapping.initialState.winCondition,
      );
      final enemyAttack = mapping.enemyAiAdapter
          .intentsFor(state: enemyState)
          .whereType<Phase0aAttackIntent>()
          .single;
      expect(enemyAttack.qiDelta, enemyBasic.qiDelta);
      expect(enemyAttack.qiDelta, isPositive);
    });

    test('生产 player mapping 连续普攻始终无链段且玩家零攻击位移', () {
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      expect(mapping.playerAdapter.basicAttackChain, isNull);
      expect(mapping.playerAdapter.basicAttackGeometryRegistry, isNull);
      expect(mapping.playerAdapter.basicAttackArenaBounds, isNull);

      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260829),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      final attackSegments = <BasicAttackSegment?>[];
      final initialPosition = flow.state.player.position;

      final firstEvents = flow.advance(
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(attack: true),
      );
      attackSegments.add(
        firstEvents
            .whereType<Phase0aAttackStarted>()
            .singleWhere((event) => event.actor == 'player')
            .basicAttackSegment,
      );
      expect(flow.state.player.basicAttackSegmentIndex, 0);
      expect(flow.state.player.position, initialPosition);

      final rejectedEvents = flow.advance(
        deltaSeconds: 0,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(
        rejectedEvents.whereType<Phase0aAttackStarted>().where(
          (event) => event.actor == 'player',
        ),
        isEmpty,
      );
      expect(
        flow.state.player.basicAttackSegmentIndex,
        0,
        reason: '冷却拒绝的重复输入不得改变单段游标',
      );

      for (var tick = 0; tick < 40 && attackSegments.length < 4; tick++) {
        final events = flow.advance(
          deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
          command: const Phase0aPlayerCommand(attack: true),
        );
        attackSegments.addAll(
          events
              .whereType<Phase0aAttackStarted>()
              .where((event) => event.actor == 'player')
              .map((event) => event.basicAttackSegment),
        );
        expect(flow.state.player.position, initialPosition);
      }

      expect(attackSegments, List<BasicAttackSegment?>.filled(4, null));
      expect(flow.state.player.basicAttackSegmentIndex, 0);
    });

    test('Q/R 真实 skill id 经 intent 进入 reducer started 事件', () {
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260821),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );

      final events = flow.advance(
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(gather: true, clear: true),
      );

      expect(
        events.whereType<Phase0aGatherStarted>().single.skillId,
        'skill_phase0a_gather',
      );
      expect(
        events.whereType<Phase0aClearStarted>().single.skillId,
        'skill_phase0a_clear',
      );
    });

    test('production Q/R 尺寸、真气与 CD 不再读 legacy player 固定值', () {
      final yaml = (jsonDecode(jsonEncode(repo.numbers.raw)) as Map)
          .cast<String, dynamic>();
      final arena = (yaml['phase0a_arena'] as Map).cast<String, dynamic>();
      final player = (arena['player'] as Map).cast<String, dynamic>();
      player
        ..['gather_ring_radius'] = 0
        ..['gather_effect_radius'] = 1
        ..['gather_qi_cost'] = 1
        ..['gather_cooldown_seconds'] = 1
        ..['clear_effect_radius'] = 1
        ..['clear_qi_cost'] = 1
        ..['clear_cooldown_seconds'] = 1;
      final numbers = NumbersConfig.fromYaml(yaml);

      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      final gather = mapping.playerAdapter.gatherSkillBinding!;
      final clear = mapping.playerAdapter.clearSkillBinding!;

      expect(
        (
          gather.destinationRadius,
          gather.effectRadius,
          gather.qiCost,
          gather.cooldownSeconds,
        ),
        (120, 1100, 25, 5),
      );
      expect(
        (clear.effectRadius, clear.qiCost, clear.cooldownSeconds),
        (340, 50, 8),
      );
      expect(
        (
          mapping.playerAdapter.gatherRingRadius,
          mapping.playerAdapter.gatherEffectRadius,
          mapping.playerAdapter.gatherQiCost,
          mapping.playerAdapter.gatherCooldownSeconds,
        ),
        (120, 1100, 25, 5),
      );
      expect(
        (
          mapping.playerAdapter.clearEffectRadius,
          mapping.playerAdapter.clearQiCost,
          mapping.playerAdapter.clearCooldownSeconds,
        ),
        (340, 50, 8),
      );
    });

    test('Q/R skill id 缺失或空白时 loader fail-closed', () {
      for (final mutation in <String, void Function(Map<String, dynamic>)>{
        'missing gather': (moves) => moves.remove('gather_skill_id'),
        'missing clear': (moves) => moves.remove('clear_skill_id'),
        'blank gather': (moves) => moves['gather_skill_id'] = '  ',
        'blank clear': (moves) => moves['clear_skill_id'] = '',
      }.entries) {
        final yaml = (jsonDecode(jsonEncode(repo.numbers.raw)) as Map)
            .cast<String, dynamic>();
        final arena = (yaml['phase0a_arena'] as Map).cast<String, dynamic>();
        final moves = (arena['moves'] as Map).cast<String, dynamic>();
        mutation.value(moves);

        expect(
          () => NumbersConfig.fromYaml(yaml),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('must both be non-empty'),
            ),
          ),
          reason: mutation.key,
        );
      }
    });

    test('Q/R 首帧可用态按开场真气推导', () {
      final numbers = repo.numbers;

      for (final openingQi in [0, numbers.phase0aArena.gatherQiCost]) {
        final player = makeCh1Player(numbers).copyWith(currentQi: openingQi);
        final mapping = Phase0aStageContentMapper.map(
          stage: repo.getStage('stage_01_01'),
          playerSnapshot: player,
          numbers: numbers,
        );
        final gather = mapping.initialState.skillSlots.singleWhere(
          (slot) => slot.slot == numbers.phase0aArena.gatherSlot,
        );
        final clear = mapping.initialState.skillSlots.singleWhere(
          (slot) => slot.slot == numbers.phase0aArena.clearSlot,
        );

        expect(
          gather.availability,
          openingQi >= numbers.phase0aArena.gatherQiCost
              ? Phase0aSkillAvailability.ready
              : Phase0aSkillAvailability.qi,
          reason: 'openingQi=$openingQi gather',
        );
        expect(
          clear.availability,
          Phase0aSkillAvailability.qi,
          reason: 'openingQi=$openingQi clear',
        );
      }
    });

    test('stage_01_03 单敌模板 → 多波,id 全场唯一防撞', () {
      final stage = repo.getStage('stage_01_03');
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      expect(mapping.waves.map((wave) => wave.enemies.length), [2, 3, 4]);
      final ids = mapping.waves
          .expand((wave) => wave.enemies)
          .map((e) => e.id)
          .toSet();
      final allIds = {mapping.initialState.player.id, ...ids};
      expect(allIds, hasLength(1 + 2 + 3 + 4));
    });

    test('塔薄适配复用同核并透传 isTower 敌方装配语义', () {
      final numbers = repo.numbers;
      final floor = repo.towerFloors.firstWhere(
        (floor) => floor.floorIndex == 7,
      );
      final player = makeCh1Player(numbers);
      final towerMapping = Phase0aStageContentMapper.mapTower(
        floor: floor,
        playerSnapshot: player,
        numbers: numbers,
      );
      final stageMapping = Phase0aStageContentMapper.map(
        stage: StageDef(
          id: 'stage_fixture',
          name: 'fixture',
          stageType: StageType.tower,
          requiredRealm: floor.requiredRealm,
          enemyTeam: floor.enemyTeam,
          isBossStage: true,
          baseExpReward: 0,
          difficultyMultiplier: 1,
        ),
        playerSnapshot: player,
        numbers: numbers,
      );

      expect(towerMapping.waves, hasLength(1));
      expect(
        towerMapping.combatants.map((combatant) => combatant.actorId),
        stageMapping.combatants.map((combatant) => combatant.actorId),
      );
      expect(
        towerMapping.combatants[1].snapshot.currentQi,
        greaterThan(stageMapping.combatants[1].snapshot.currentQi),
      );
      final boss = towerMapping.initialState.enemies.single;
      expect(boss.bossPhases, hasLength(2));
      expect(boss.bossPhaseIndex, 0);
      expect(boss.qiCurrent, towerMapping.combatants[1].snapshot.currentQi);
      expect(
        towerMapping.enemyAiAdapter.skillBindingsByActor[boss.id]?.map(
          (binding) => binding.skill.id,
        ),
        contains('skill_lingqiao_jichu_ult'),
      );
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
          playerSnapshot: makeCh1Player(numbers),
          numbers: numbers,
        ),
        throwsArgumentError,
      );
    });
  });

  group('主线群怪波次配置与包络', () {
    test('普通关使用 YAML 波型，最大并发生命/有效输出不超过原单敌', () {
      final numbers = repo.numbers;
      final stage = repo.getStage('stage_01_01');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      final original = EnemyCombatantSnapshotAssembler.assembleAll(
        stage.enemyTeam,
      ).single;
      expect(mapping.waves.map((wave) => wave.enemies.length), [2, 3, 4]);
      expect(
        mapping.waves
            .expand((wave) => wave.enemies)
            .every((enemy) => enemy.maxHealth < original.maxHp),
        isTrue,
      );
      final maxWaveHp = mapping.waves
          .map(
            (wave) => wave.enemies.fold<int>(0, (sum, e) => sum + e.maxHealth),
          )
          .reduce(max);
      expect(maxWaveHp, lessThanOrEqualTo(original.maxHp));
      final maxWaveEffectiveOutput = mapping.waves
          .map(
            (wave) => wave.enemies.fold<double>(
              0,
              (sum, enemy) =>
                  sum +
                  mapping.combatants
                          .firstWhere((c) => c.actorId == enemy.id)
                          .snapshot
                          .outputMultiplier *
                      (mapping.combatants
                              .firstWhere((c) => c.actorId == enemy.id)
                              .snapshot
                              .internalForce +
                          mapping.combatants
                              .firstWhere((c) => c.actorId == enemy.id)
                              .snapshot
                              .totalEquipmentAttack),
            ),
          )
          .reduce(max);
      final originalEffectiveOutput =
          original.internalForce + original.totalEquipmentAttack;
      expect(
        maxWaveEffectiveOutput,
        lessThanOrEqualTo(originalEffectiveOutput),
      );
    });

    test('Boss 机制只在独立终波，原快照不降级，波间不回血', () {
      final numbers = repo.numbers;
      final stage = repo.getStage('stage_01_05');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      expect(mapping.waves.map((wave) => wave.enemies.length), [2, 3, 1]);
      for (final enemy
          in mapping.waves.take(2).expand((wave) => wave.enemies)) {
        final snapshot = mapping.combatants
            .firstWhere((combatant) => combatant.actorId == enemy.id)
            .snapshot;
        expect(snapshot.isBoss, isFalse);
        expect(snapshot.chargeSkillId, isNull);
        expect(snapshot.bossPhases, isNull);
        expect(snapshot.vulnerabilityMult, isNull);
        expect(snapshot.guardianDefIds, isEmpty);
      }
      final boss = mapping.waves.last.enemies.single;
      final bossSnapshot = mapping.combatants
          .firstWhere((combatant) => combatant.actorId == boss.id)
          .snapshot;
      expect(bossSnapshot.isBoss, isTrue);
      expect(bossSnapshot.chargeSkillId, isNotNull);
      expect(mapping.waveTransitionPolicy?.healPlayerToFull, isFalse);
      expect(mapping.waveTransitionPolicy?.qiRecoveryPct, 0.25);
      expect(mapping.waveTransitionPolicy?.resetSkillCooldowns, isFalse);
      expect(mapping.waveTransitionPolicy?.intermissionSeconds, 0.0);
    });

    test('非主线塔路径继续使用 arena.enemyMoveSpeed', () {
      final numbers = repo.numbers;
      final floor = repo.towerFloors.firstWhere(
        (floor) => floor.floorIndex == 1,
      );
      final mapping = Phase0aStageContentMapper.mapTower(
        floor: floor,
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      expect(
        mapping.initialState.enemies.every(
          (enemy) => enemy.moveSpeed == numbers.phase0aArena.enemyMoveSpeed,
        ),
        isTrue,
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
      expect(arena.playerAttackRange, 420);
      expect(arena.playerAttackHalfArcRadians, 0.72);
      expect(arena.playerAttackCooldownSeconds, 0.55);
      expect(arena.basicAttackChain.segmentIds, swordBasicAttackSegmentIds);
      final thrust = arena.basicAttackChain.tuningForSegmentId('sword_thrust');
      final sweep = arena.basicAttackChain.tuningForSegmentId('sword_sweep');
      final advancing = arena.basicAttackChain.tuningForSegmentId(
        'sword_advancing_slash',
      );
      expect(
        (
          thrust.attackRange,
          thrust.attackHalfArcRadians,
          thrust.maxTargets,
          thrust.advanceDistance,
          thrust.aimAssistRadians,
        ),
        (480, 0.35, 1, 0, 0),
      );
      expect(
        (
          sweep.attackRange,
          sweep.attackHalfArcRadians,
          sweep.maxTargets,
          sweep.advanceDistance,
          sweep.aimAssistRadians,
        ),
        (400, 1.30, 1, 0, 0),
      );
      expect(
        (
          advancing.attackRange,
          advancing.attackHalfArcRadians,
          advancing.maxTargets,
          advancing.advanceDistance,
          advancing.aimAssistRadians,
        ),
        (440, 0.60, 1, 120, 0),
      );
      expect(arena.enemyMoveSpeed, greaterThan(0));
      expect(arena.basicPowerMultiplier, greaterThan(0));
      expect(arena.clearPowerMultiplier, greaterThan(0));
      expect(arena.fixedDeltaSeconds, 0.1);
      expect(arena.maxBattleSeconds, 300);
      expect(arena.maxSimulationTicks, 3000);
    });

    test('simulation 非正或非有限 → 解析期 fail-fast', () {
      for (final value in [0.0, -0.1, double.nan, double.infinity]) {
        final broken = Map<String, dynamic>.from(phase0aArenaYaml);
        broken['simulation'] = <String, dynamic>{
          ...((phase0aArenaYaml['simulation'] as Map).cast<String, dynamic>()),
          'fixed_delta_seconds': value,
        };
        expect(
          () => Phase0aArenaConfig.fromYaml(broken),
          throwsArgumentError,
          reason: 'fixed_delta_seconds=$value',
        );
      }
      final broken = Map<String, dynamic>.from(phase0aArenaYaml);
      broken['simulation'] = <String, dynamic>{
        ...((phase0aArenaYaml['simulation'] as Map).cast<String, dynamic>()),
        'max_battle_seconds': 0,
      };
      expect(() => Phase0aArenaConfig.fromYaml(broken), throwsArgumentError);
    });
  });

  group('headless 全链(Ch1 五关 bot 驾驶)', () {
    test(
      'production tower_7 headless phase threshold → unlock skill → AI cast',
      () {
        final numbers = repo.numbers;
        final floor = repo.towerFloors.firstWhere(
          (floor) => floor.floorIndex == 7,
        );
        final mapping = Phase0aStageContentMapper.mapTower(
          floor: floor,
          playerSnapshot: makeBossPhasePlayer(numbers),
          numbers: numbers,
        );
        final flow = Phase0aProductionFlowAssembler.assemble(
          initialState: mapping.initialState,
          waves: mapping.waves,
          combatants: mapping.combatants,
          moveBindings: mapping.moveBindings,
          numbers: numbers,
          rng: Random(20260821),
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
        );
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: mapping.playerAdapter,
        );
        final events = <Phase0aEvent>[];
        var phaseEntered = false;
        for (
          var tick = 0;
          tick < numbers.phase0aArena.maxSimulationTicks &&
              flow.outcome == Phase0aBattleOutcome.ongoing;
          tick++
        ) {
          final botCommand = bot.commandFor(flow.state);
          final batch = flow.advance(
            deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
            // Stop attacking after the production threshold is observed so the
            // newly unlocked boss action gets a deterministic headless window;
            // before that, use only the production-mapped basic attack so other
            // same-tick player skills cannot kill the boss after phase entry.
            command: phaseEntered
                ? const Phase0aPlayerCommand()
                : Phase0aPlayerCommand(
                    left: botCommand.left,
                    right: botCommand.right,
                    up: botCommand.up,
                    down: botCommand.down,
                    attack: botCommand.attack,
                    attackAimDirection: botCommand.attackAimDirection,
                  ),
          );
          events.addAll(batch);
          phaseEntered =
              phaseEntered ||
              batch.whereType<Phase0aBossPhaseChanged>().isNotEmpty;
          if (events.whereType<Phase0aEnemySkillStarted>().isNotEmpty) break;
        }

        final phaseEvents = events
            .whereType<Phase0aBossPhaseChanged>()
            .where((event) => event.actor.startsWith('enemy_tower_boss_07'))
            .toList();
        expect(phaseEvents, isNotEmpty);
        expect(phaseEvents.first.phaseIndex, 1);
        expect(
          phaseEvents.first.unlockedSkillIds,
          contains('skill_lingqiao_jichu_ult'),
        );
        expect(
          events.whereType<Phase0aEnemySkillStarted>().map(
            (event) => event.skillId,
          ),
          contains('skill_lingqiao_jichu_ult'),
        );
      },
    );

    test('五关全部 victory(纵切成立判据·headless 侧)', () {
      final numbers = repo.numbers;
      for (var i = 1; i <= 5; i++) {
        final stageId = 'stage_01_0$i';
        final stage = repo.getStage(stageId);
        final mapping = Phase0aStageContentMapper.map(
          stage: stage,
          playerSnapshot: makeCh1Player(numbers),
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
        final result = Phase0aHeadlessRunner.runToEnd(
          flow: flow,
          bot: bot,
          deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
          maxTicks: numbers.phase0aArena.maxSimulationTicks,
        );
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
          playerSnapshot: makeCh1Player(numbers),
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
          deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
          maxTicks: numbers.phase0aArena.maxSimulationTicks,
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
      expect(b.events, a.events, reason: '同 seed 事件流必须可重放');
    });

    test('headless 真实事件 + 末态 → 引擎无关结算快照', () {
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260820),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );

      final settlement = Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: result.outcome,
        finalState: result.finalState,
        events: result.events,
      );

      expect(settlement.result, BattleResult.leftWin);
      expect(settlement.totalTicks, result.finalState.tick);
      expect(settlement.hadActions, isTrue);
      expect(settlement.totalDamage, greaterThan(0));
      expect(settlement.damageByCharacterId[1], greaterThan(0));
      expect(
        settlement.skillCasts.map((cast) => cast.skillId).toSet(),
        containsAll({'skill_phase0a_gather', 'skill_phase0a_clear'}),
        reason: '数据定义的 Q/R 应进入真实技能结算记录',
      );
      expect(settlement.participantFor(1)!.currentHp, greaterThan(0));
      final enemyId = mapping.combatants.last.snapshot.characterId;
      expect(settlement.participantFor(enemyId)!.currentHp, 0);
    });

    test('群体技能暴击位进入战后 criticalCount', () {
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final settlement = Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: Phase0aBattleOutcome.victory,
        finalState: Phase0aArenaState(
          tick: 1,
          nextSeq: 3,
          player: mapping.initialState.player,
          enemies: const [],
          skillSlots: mapping.initialState.skillSlots,
        ),
        events: const [
          Phase0aClearStarted(seq: 1, tick: 1, actor: 'player'),
          Phase0aClearApplied(
            seq: 2,
            tick: 1,
            actor: 'player',
            outcomes: [
              Phase0aSkillOutcome(
                target: 'enemy_xueTu_thug_a',
                resolvedDamage: 88,
                isCritical: true,
                defeated: true,
                statusApplied: Phase0aSkillStatus.staggered,
              ),
            ],
          ),
        ],
      );
      expect(settlement.totalDamage, 88);
      expect(settlement.criticalCount, 1);
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
            playerSnapshot: makeCh1Player(numbers),
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
            deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
            maxTicks: numbers.phase0aArena.maxSimulationTicks,
          );
          total++;
          if (result.outcome == Phase0aBattleOutcome.victory) wins++;
        }
      }
      expect(total, 25);
      expect(wins, total, reason: 'Ch1 五关 × 五 seed bot 应全胜');
    });

    test('真实塔42 mapper/flow 透传 guardian interrupt 配置并保留运行链', () {
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.mapTower(
        floor: repo.getTowerFloor(42),
        playerSnapshot: makeCh1Player(numbers),
        numbers: numbers,
      );
      final boss = mapping.initialState.enemies.firstWhere(
        (enemy) => enemy.guardInterceptsInterrupt,
      );
      expect(boss.guardianDefIds, isNotEmpty);
      expect(boss.guardianWardMult, isNotNull);
      expect(
        mapping.initialState.enemies
            .where((enemy) => enemy.id != boss.id)
            .where(
              (enemy) => boss.guardianDefIds.any(
                (defId) => enemy.id.startsWith('${defId}_w'),
              ),
            )
            .length,
        greaterThanOrEqualTo(1),
      );

      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(42),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );
      expect(result.events, isNotEmpty);
      expect(result.finalState.enemies, isNotEmpty);
    });
  });
}
