import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../support/test_data.dart';
import '../../../support/combatant_snapshot_fixture.dart';

/// Phase 1 纵切切片 2 红测(拍板 α 主线入口灰度开关):
/// ① 路线 C 门:默认开 + testOverride + 关型过滤;
/// ② roster.fromMapping:真实 Ch1 内容 → 玩家灰盒立绘/敌人 iconPath 零口径
///    复制 + 空 asset fail-fast;
/// ③ host 集成:注入玩家角色 + 固定 seed 真跑 stage_01_01 → victory 回调;
///    极弱玩家 → defeat 回调 + 自 pop;
/// ④ runStageFlow 灰度分支:门开走 phase0a 注入器(胜利链/战败重试),
///    门关 phase0a 注入器零消费。

CombatantSnapshot _makeCh1Player(NumbersConfig numbers) =>
    testCombatantSnapshot(
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
      includeProductionBasicAttack: true,
      availableSkills: const [],
      openingSkillCooldowns: const {},
      activeBuffs: const [],
    );

const EnemyDef _testEnemy = EnemyDef(
  id: 'enemy_test_thug',
  name: '测试喽啰',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  baseHp: 1500,
  baseAttack: 80,
  baseSpeed: 100,
  skillIds: [],
  iconPath: 'assets/enemies/test_thug.png',
);

StageDef _flowStage() => const StageDef(
  id: 'stage_01_01',
  name: '灰度门测试关',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [_testEnemy],
  isBossStage: false,
  baseExpReward: 0,
  difficultyMultiplier: 1.0,
);

StageDef _bossFlowStage() => const StageDef(
  id: 'stage_01_05',
  name: '灰度门 Boss 测试关',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [_testEnemy],
  isBossStage: true,
  baseExpReward: 0,
  difficultyMultiplier: 1.0,
);

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  group('Phase0a 心魔镜像装配', () {
    test('01 复制单主角并按分关系数强化，YAML 空敌队不冒充剧情关', () {
      final player = _makeCh1Player(repo.numbers);
      final mapping = Phase0aStageContentMapper.mapInnerDemon(
        stage: repo.getStage('stage_inner_demon_01'),
        playerSnapshot: player,
        numbers: repo.numbers,
      );
      final mirror = mapping.combatants.last.snapshot;
      final buff =
          repo.numbers.innerDemon.mirrorBuffPerStage['stage_inner_demon_01']!;

      expect(mapping.combatants, hasLength(2));
      expect(mirror.characterId, -1);
      expect(mirror.maxHp, (player.maxHp * (1 + buff)).round());
      expect(mirror.currentHp, mirror.maxHp);
      expect(mirror.internalForce, (player.internalForce * (1 + buff)).round());
      expect(
        mirror.totalEquipmentAttack,
        (player.totalEquipmentAttack * (1 + buff)).round(),
      );
      expect(mirror.isBoss, isTrue);
      expect(() => Phase0aVisualRoster.fromMapping(mapping), returnsNormally);
      expect(
        mapping.waves.single.enemies.single.defeatKind,
        Phase0aDefeatKind.elite,
      );
    });

    test('05 原子注入蓄力技与脆弱窗口；07 保留 surviveTicks=20', () {
      final player = _makeCh1Player(repo.numbers);
      final stage05 = repo.getStage('stage_inner_demon_05');
      final mapping05 = Phase0aStageContentMapper.mapInnerDemon(
        stage: stage05,
        playerSnapshot: player,
        numbers: repo.numbers,
      );
      final mirror05 = mapping05.combatants.last.snapshot;
      final chargeId = repo.numbers.innerDemon.mirrorChargeSkillId;

      expect(mirror05.chargeSkillId, chargeId);
      expect(
        mirror05.availableSkills.map((skill) => skill.id),
        contains(chargeId),
      );
      expect(
        mirror05.vulnerabilityMult,
        repo
            .numbers
            .innerDemon
            .mirrorVulnerabilityPerStage[stage05.id]!
            .outOfWindowDamageMult,
      );
      expect(mapping05.waves.single.enemies.single.chargeCast, isNotNull);

      final mapping07 = Phase0aStageContentMapper.mapInnerDemon(
        stage: repo.getStage('stage_inner_demon_07'),
        playerSnapshot: player,
        numbers: repo.numbers,
      );
      expect(
        mapping07.initialState.winCondition?.type,
        Phase0aWinConditionType.surviveTicks,
      );
      expect(mapping07.initialState.winCondition?.surviveTicksRequired, 20);
    });
  });

  group('Phase0a 轻功地形装配', () {
    test('5 关均对称烘焙地形修正到主角与敌人', () {
      final originalPlayer = _makeCh1Player(repo.numbers);
      for (var index = 1; index <= 5; index++) {
        final stage = repo.getStage('stage_light_foot_0$index');
        final modifier =
            repo.numbers.lightFoot.terrainModifiers[stage.terrainBiome!]!;
        final mapping = Phase0aStageContentMapper.mapLightFoot(
          stage: stage,
          playerSnapshot: originalPlayer,
          numbers: repo.numbers,
        );
        final player = mapping.combatants.first.snapshot;

        expect(
          player.attackPowerMultiplier,
          modifier.damageMultiplier,
          reason: stage.id,
        );
        expect(
          player.criticalRate,
          closeTo(
            originalPlayer.criticalRate + modifier.criticalRateDelta,
            1e-9,
          ),
          reason: stage.id,
        );
        for (final enemy in mapping.combatants.skip(1)) {
          expect(
            enemy.snapshot.attackPowerMultiplier,
            modifier.damageMultiplier,
            reason: '${stage.id}/${enemy.actorId}',
          );
        }
      }
    });

    test('轻功缺 terrainBiome 时 fail-fast 且门控拒绝', () {
      final stage = repo.getStage('stage_light_foot_01');
      final malformed = StageDef(
        id: stage.id,
        name: stage.name,
        stageType: stage.stageType,
        requiredRealm: stage.requiredRealm,
        enemyTeam: stage.enemyTeam,
        isBossStage: stage.isBossStage,
        baseExpReward: stage.baseExpReward,
        difficultyMultiplier: stage.difficultyMultiplier,
      );
      final player = _makeCh1Player(repo.numbers);
      expect(
        () => Phase0aStageContentMapper.mapLightFoot(
          stage: malformed,
          playerSnapshot: player,
          numbers: repo.numbers,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Phase0a 群战多波装配', () {
    test('5 关波次数量与每波人数逐项对齐生产配置，actor id 全场唯一', () {
      final player = _makeCh1Player(repo.numbers);
      for (var index = 1; index <= 5; index++) {
        final stage = repo.getStage('stage_mass_battle_0$index');
        final mapping = Phase0aStageContentMapper.mapMassBattle(
          stage: stage,
          playerSnapshot: player,
          numbers: repo.numbers,
        );
        final actorIds = mapping.combatants.map((c) => c.actorId).toList();

        expect(
          mapping.waves.map((wave) => wave.enemies.length).toList(),
          stage.massBattleEnemyCounts,
          reason: stage.id,
        );
        expect(actorIds.toSet(), hasLength(actorIds.length), reason: stage.id);
        expect(mapping.initialState.enemies, mapping.waves.first.enemies);
        expect(mapping.waveTransitionPolicy, isNotNull);
        expect(() => Phase0aVisualRoster.fromMapping(mapping), returnsNormally);
      }
    });

    test('阵型只修正主角，敌方不沾；缺波次配置 fail-fast', () {
      final originalPlayer = _makeCh1Player(repo.numbers);
      final stage = repo.getStage('stage_mass_battle_03');
      final modifier = repo.numbers.massBattle.formations[Formation.fengShi]!;
      final mapping = Phase0aStageContentMapper.mapMassBattle(
        stage: stage,
        playerSnapshot: originalPlayer,
        numbers: repo.numbers,
        formation: Formation.fengShi,
      );

      expect(
        mapping.combatants.first.snapshot.attackPowerMultiplier,
        modifier.damageMultiplier,
      );
      expect(
        mapping.combatants
            .skip(1)
            .every((enemy) => enemy.snapshot.attackPowerMultiplier == 1.0),
        isTrue,
      );

      final malformed = StageDef(
        id: stage.id,
        name: stage.name,
        stageType: stage.stageType,
        requiredRealm: stage.requiredRealm,
        enemyTeam: stage.enemyTeam,
        isBossStage: stage.isBossStage,
        baseExpReward: stage.baseExpReward,
        difficultyMultiplier: stage.difficultyMultiplier,
      );
      expect(
        () => Phase0aStageContentMapper.mapMassBattle(
          stage: malformed,
          playerSnapshot: originalPlayer,
          numbers: repo.numbers,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Phase0aVisualRoster.fromMapping(真实 Ch1 内容)', () {
    test('stage_01_01: 玩家灰盒立绘 + 敌人 iconPath 零口径复制', () {
      final stage = repo.getStage('stage_01_01');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final roster = Phase0aVisualRoster.fromMapping(mapping);

      final player = roster.visualFor('player');
      expect(player.assetPath, 'assets/characters/battle_founder_v2.png');
      expect(player.name, '纵切玩家');

      final enemy = roster.visualFor(mapping.waves.first.enemies.first.id);
      // iconPath 与 stages.yaml EnemyDef 同值,零口径复制。
      expect(enemy.assetPath, stage.enemyTeam.single.iconPath);
      expect(enemy.name, stage.enemyTeam.single.name);
      expect(enemy.isElite, isFalse);
    });

    test('stage_01_03 多波小怪: 全部 actor 登记且名字来自 EnemyDef', () {
      final stage = repo.getStage('stage_01_03');
      final mapping = Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final roster = Phase0aVisualRoster.fromMapping(mapping);
      for (final combatant in mapping.combatants) {
        expect(roster.visualFor(combatant.actorId).name, isNotEmpty);
      }
    });

    test('Boss 敌人保留 elite 视觉与 defeat kind', () {
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_05'),
        playerSnapshot: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      final roster = Phase0aVisualRoster.fromMapping(mapping);
      final boss = mapping.combatants.last;
      expect(boss.snapshot.isBoss, isTrue);
      expect(roster.visualFor(boss.actorId).isElite, isTrue);
      expect(
        mapping.waves.last.enemies.last.defeatKind,
        Phase0aDefeatKind.elite,
      );
    });

    test('敌人 iconPath 空串 → fail-fast', () {
      final stage = repo.getStage('stage_01_01');
      final broken = StageDef(
        id: stage.id,
        name: stage.name,
        stageType: stage.stageType,
        requiredRealm: stage.requiredRealm,
        enemyTeam: [
          const EnemyDef(
            id: 'enemy_broken',
            name: '无图敌人',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.gangMeng,
            baseHp: 1500,
            baseAttack: 80,
            baseSpeed: 100,
            skillIds: ['skill_gangmeng_jichu_basic'],
            iconPath: '',
          ),
        ],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
      );
      final mapping = Phase0aStageContentMapper.map(
        stage: broken,
        playerSnapshot: _makeCh1Player(repo.numbers),
        numbers: repo.numbers,
      );
      expect(() => Phase0aVisualRoster.fromMapping(mapping), throwsStateError);
    });
  });

  group('Phase0aMainlineBattleHost 集成(注入玩家角色,真跑 0A flow)', () {
    testWidgets('前台 playerBot 每个 fixed tick 驾驶同一宿主至终局', (tester) async {
      CombatSettlementSnapshot? terminal;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Phase0aMainlineBattleHost(
              stage: repo.getStage('stage_01_01'),
              playerSnapshotForTest: _makeCh1Player(repo.numbers),
              seedForTest: 20260825,
              controller: ActivityController.playerBot,
              onVictory: (settlement) => terminal = settlement,
              onDefeat: (settlement) => terminal = settlement,
            ),
          ),
        ),
      );
      await tester.pump();
      var simulatedSeconds = 0;
      while (terminal == null && simulatedSeconds < 180) {
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }

      expect(terminal, isNotNull);
      expect(terminal!.isFinished, isTrue);
      expect(terminal!.participantCharacterIds.where((id) => id > 0), {1});
    });

    testWidgets('stage_01_01 固定 seed → 键盘驾驶至 victory 回调', (tester) async {
      var victoryCalled = false;
      CombatSettlementSnapshot? victorySettlement;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Phase0aMainlineBattleHost(
              stage: repo.getStage('stage_01_01'),
              playerSnapshotForTest: _makeCh1Player(repo.numbers),
              seedForTest: 20260819,
              onVictory: (settlement) {
                victoryCalled = true;
                victorySettlement = settlement;
              },
              onDefeat: (_) {},
            ),
          ),
        ),
      );
      // 装配在 postFrameCallback;先泵一帧完成 setup。
      await tester.pump();
      // 宿主接真人输入 adapter(非 bot):测试模拟玩家连按 J 普攻驾驶战斗。
      var simulatedSeconds = 0;
      while (!victoryCalled && simulatedSeconds < 180) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }
      expect(
        victoryCalled,
        isTrue,
        reason:
            'stage_01_01 键盘驾驶应在模拟 180s 内取胜'
            '(切片 1 headless bot 25/25 全胜同口径)',
      );
      expect(victorySettlement!.result, BattleResult.leftWin);
      expect(victorySettlement!.totalDamage, greaterThan(0));
      expect(victorySettlement!.participantFor(1)!.currentHp, greaterThan(0));
    });

    testWidgets('极弱玩家 → defeat 回调且宿主自 pop', (tester) async {
      var defeatCalled = false;
      final weakPlayer = _makeCh1Player(repo.numbers);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => Phase0aMainlineBattleHost(
                      stage: repo.getStage('stage_01_01'),
                      playerSnapshotForTest: testCombatantSnapshot(
                        characterId: 1,
                        name: '脆皮玩家',
                        realmTier: RealmTier.xueTu,
                        realmLayer: RealmLayer.qiMeng,
                        school: TechniqueSchool.gangMeng,
                        maxHp: 1,
                        currentHp: 1,
                        internalForce: 0,
                        maxQi: 0,
                        currentQi: 0,
                        speed: 100,
                        criticalRate: 0,
                        evasionRate: 0,
                        defenseRate: 0,
                        totalEquipmentAttack: 0,
                        mainCultivationLayer: CultivationLayer.chuKui,
                        includeProductionBasicAttack: true,
                        availableSkills: const [],
                        openingSkillCooldowns: const {},
                        activeBuffs: const [],
                      ),
                      seedForTest: 20260819,
                      onVictory: (_) {},
                      onDefeat: (settlement) {
                        defeatCalled = true;
                        expect(settlement.result, BattleResult.rightWin);
                        expect(settlement.participantFor(1)!.currentHp, 0);
                      },
                    ),
                  ),
                ),
                child: const Text('enter'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('enter'));
      await tester.pump();
      var simulatedSeconds = 0;
      while (!defeatCalled && simulatedSeconds < 60) {
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }
      expect(defeatCalled, isTrue, reason: 'HP=1 玩家应迅速战败');
      // 战败宿主自 pop → 回到 enter 页。
      await tester.pumpAndSettle();
      expect(find.text('enter'), findsOneWidget);
      expect(weakPlayer.name, '纵切玩家'); // fixture 锚点,防误删
    });

    testWidgets('真实 Ch1 Boss 宿主在 1280×720 / 1440×900 无布局异常', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
        await tester.binding.setSurfaceSize(viewport);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Phase0aMainlineBattleHost(
                stage: repo.getStage('stage_01_05'),
                playerSnapshotForTest: _makeCh1Player(repo.numbers),
                seedForTest: 20260820,
                onVictory: (_) {},
                onDefeat: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(Phase0aBattleScreen), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$viewport');
      }
    });
  });

  test('Ch1 五关同 seed: live controller 与 headless 胜负/末态 HP 一致', () {
    final numbers = repo.numbers;
    for (var stageIndex = 1; stageIndex <= 5; stageIndex++) {
      final stage = repo.getStage('stage_01_0$stageIndex');
      final seed = 20260820 + stageIndex;

      Phase0aStageMapping makeMapping() => Phase0aStageContentMapper.map(
        stage: stage,
        playerSnapshot: _makeCh1Player(numbers),
        numbers: numbers,
      );

      final headlessMapping = makeMapping();
      final headlessFlow = Phase0aProductionFlowAssembler.assemble(
        initialState: headlessMapping.initialState,
        waves: headlessMapping.waves,
        combatants: headlessMapping.combatants,
        moveBindings: headlessMapping.moveBindings,
        numbers: numbers,
        rng: Random(seed),
        playerAdapter: headlessMapping.playerAdapter,
        enemyAiAdapter: headlessMapping.enemyAiAdapter,
      );
      final headless = Phase0aHeadlessRunner.runToEnd(
        flow: headlessFlow,
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: headlessMapping.playerAdapter,
        ),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );
      final headlessSettlement = Phase0aSettlementAdapter.fromMapping(
        mapping: headlessMapping,
        outcome: headless.outcome,
        finalState: headless.finalState,
        events: headless.events,
      );

      final liveMapping = makeMapping();
      final liveFlow = Phase0aProductionFlowAssembler.assemble(
        initialState: liveMapping.initialState,
        waves: liveMapping.waves,
        combatants: liveMapping.combatants,
        moveBindings: liveMapping.moveBindings,
        numbers: numbers,
        rng: Random(seed),
        playerAdapter: liveMapping.playerAdapter,
        enemyAiAdapter: liveMapping.enemyAiAdapter,
      );
      final liveController = Phase0aBattleController(
        flow: liveFlow,
        roster: Phase0aVisualRoster.fromMapping(liveMapping),
        fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      );
      final liveBot = Phase0aPlayerBotAdapter(
        playerAdapter: liveMapping.playerAdapter,
      );
      var liveTicks = 0;
      final liveEventRecords = <CombatEventRecord>[];
      while (liveController.outcome == Phase0aBattleOutcome.ongoing &&
          liveTicks < numbers.phase0aArena.maxSimulationTicks) {
        liveController.step(liveBot.commandFor(liveController.state));
        liveEventRecords.addAll(liveController.lastEventRecords);
        liveTicks += 1;
      }
      final liveSettlement = Phase0aSettlementAdapter.fromMapping(
        mapping: liveMapping,
        outcome: liveController.outcome,
        finalState: liveController.state,
        events: liveController.events,
      );
      addTearDown(liveController.dispose);

      expect(
        liveSettlement.result,
        headlessSettlement.result,
        reason: stage.id,
      );
      expect(
        liveSettlement.totalTicks,
        headlessSettlement.totalTicks,
        reason: stage.id,
      );
      expect(
        [
          for (final participant in liveSettlement.participants)
            (participant.characterId, participant.currentHp),
        ],
        [
          for (final participant in headlessSettlement.participants)
            (participant.characterId, participant.currentHp),
        ],
        reason: stage.id,
      );
      expect(liveController.events, headless.events, reason: stage.id);
      expect(liveEventRecords, headless.eventRecords, reason: stage.id);
    }
  });

  group('runStageFlow 灰度分支', () {
    testWidgets('门开 + phase0a 注入器 victory → 进度记录链被调用', (tester) async {
      String? recordedStageId;
      await tester.pumpWidget(
        _gateHarness(
          phase0aBattleOutcome: () async =>
              (won: true, surrendered: false, settlement: null),
          victoryRecorder: (stageId) async => recordedStageId = stageId,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(recordedStageId, equals('stage_01_01'));
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('门开 + phase0a 注入器 defeat 不重试 → 进度链零消费', (tester) async {
      var victoryCalled = false;
      await tester.pumpWidget(
        _gateHarness(
          phase0aBattleOutcome: () async =>
              (won: false, surrendered: false, settlement: null),
          victoryRecorder: (_) async => victoryCalled = true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(victoryCalled, isFalse);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('中途退出(surrendered) → Boss 惩罚/奖励/进度均不消费', (tester) async {
      var penaltyCalled = false;
      var victoryCalled = false;
      await tester.pumpWidget(
        _gateHarness(
          stage: _bossFlowStage(),
          phase0aBattleOutcome: () async =>
              (won: false, surrendered: true, settlement: null),
          victoryRecorder: (_) async => victoryCalled = true,
          bossDefeatPenalty: (_) async {
            penaltyCalled = true;
            return const <DefeatLossEntry>[];
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      expect(penaltyCalled, isFalse);
      expect(victoryCalled, isFalse);
      expect(find.text('done'), findsOneWidget);
    });
  });
}

/// 灰度分支专用 harness(沿 stage_entry_flow_test 体例):battleRunner/
/// battleOutcome 均可缺省,只喂需要验证的注入器。
Widget _gateHarness({
  StageDef? stage,
  Future<MainlineBattleExit> Function()? phase0aBattleOutcome,
  Future<void> Function(String stageId)? victoryRecorder,
  Future<List<DefeatLossEntry>> Function(StageDef stage)? bossDefeatPenalty,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: _GateHarnessPage(
        stage: stage ?? _flowStage(),
        phase0aBattleOutcome: phase0aBattleOutcome,
        victoryRecorder: victoryRecorder ?? (_) async {},
        bossDefeatPenalty:
            bossDefeatPenalty ?? (_) async => const <DefeatLossEntry>[],
      ),
    ),
  );
}

class _GateHarnessPage extends ConsumerStatefulWidget {
  const _GateHarnessPage({
    required this.stage,
    required this.phase0aBattleOutcome,
    required this.victoryRecorder,
    required this.bossDefeatPenalty,
  });

  final StageDef stage;
  final Future<MainlineBattleExit> Function()? phase0aBattleOutcome;
  final Future<void> Function(String stageId) victoryRecorder;
  final Future<List<DefeatLossEntry>> Function(StageDef stage)
  bossDefeatPenalty;

  @override
  ConsumerState<_GateHarnessPage> createState() => _GateHarnessPageState();
}

class _GateHarnessPageState extends ConsumerState<_GateHarnessPage> {
  String _status = 'idle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_status),
          TextButton(
            onPressed: () async {
              setState(() => _status = 'running');
              try {
                await runStageFlow(
                  context: context,
                  ref: ref,
                  stage: widget.stage,
                  phase0aBattleOutcomeForTest: widget.phase0aBattleOutcome,
                  stageRetryDeciderForTest: () async => false,
                  victoryRecorderForTest: widget.victoryRecorder,
                  bossDefeatPenaltyForTest: widget.bossDefeatPenalty,
                );
                if (mounted) setState(() => _status = 'done');
              } catch (e) {
                if (mounted) setState(() => _status = 'error: $e');
              }
            },
            child: const Text('start'),
          ),
        ],
      ),
    );
  }
}
