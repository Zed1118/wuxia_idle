import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/mainline_wave_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_intel_dialog.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/stage_enemy_summary.dart';
import 'package:wuxia_idle/features/mainline/application/new_save_goal_guidance.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../support/combatant_snapshot_fixture.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  StageDef stage({
    bool boss = false,
    List<EnemyDef>? enemies,
    StageType type = StageType.mainline,
    String id = 'stage_test',
  }) {
    return StageDef(
      id: id,
      name: '试剑坡',
      stageType: type,
      chapterIndex: 1,
      requiredRealm: RealmTier.sanLiu,
      enemyTeam:
          enemies ??
          [
            const EnemyDef(
              id: 'bandit_a',
              name: '山道悍匪',
              realmTier: RealmTier.sanLiu,
              realmLayer: RealmLayer.ruMen,
              school: TechniqueSchool.gangMeng,
              baseHp: 1200,
              baseAttack: 180,
              baseSpeed: 110,
              skillIds: ['skill_normal'],
              iconPath: '',
            ),
          ],
      isBossStage: boss,
      dropTable: const [
        EquipmentDrop(
          equipmentDefId: 'weapon_xunchang_tie_jian',
          dropChance: 0.3,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_mojianshi',
          quantityMin: 1,
          quantityMax: 2,
          dropChance: 1.0,
        ),
      ],
      baseExpReward: 100,
      difficultyMultiplier: 1,
    );
  }

  Future<void> pumpIntel(
    WidgetTester tester,
    StageDef stage, {
    RealmTier currentRealm = RealmTier.xueTu,
    int targetCycle = 1,
    List<Character> activeCharacters = const [],
    NewSaveGoalGuidance? goalGuidance,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageIntelContent(
            stage: stage,
            currentRealm: currentRealm,
            targetCycle: targetCycle,
            activeCharacters: activeCharacters,
            goalGuidance: goalGuidance,
            rumorTable: DropRumorTable.fromDropTable(
              stage.dropTable,
              gating: FirstClearGating.scrollOnly,
            ),
          ),
        ),
      ),
    );
  }

  Character woundedCharacter() {
    final c = Character.create(
      name: '沈青',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 29),
      internalForce: 100,
      internalForceMax: 500,
    );
    c.lightInjuryStacks = 2;
    return c;
  }

  testWidgets('真实首关情报显示 catalog 的 25 总敌人和 10 同屏上限', (tester) async {
    final repository = GameRepository.instance;
    final firstStage = repository.getStage('stage_01_01');
    final encounter = repository.combatEncounterForStage(firstStage.id)!;
    expect(encounter.spawnEntries, hasLength(25));
    expect(encounter.spawnConfig.activeLimit, 10);

    await pumpIntel(tester, firstStage);

    expect(find.text('共 25 名敌人 · 同屏上限 10 名'), findsOneWidget);
    expect(
      find.text(
        UiStrings.prebattleCatalogReinforcements(
          encounter.spawnConfig.reinforcementThreshold,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('3 波 · 共 9 名敌人'), findsNothing);
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsOneWidget);
  });

  test('共享概要的主线 fallback 保留旧波次和未配置波次的敌人队伍', () {
    final waves = GameRepository.instance.numbers.mainlineWave;
    for (final boss in [false, true]) {
      final profile = waves.profileFor(isBossStage: boss);
      final summary = StageEnemySummary.fromStage(
        stage(boss: boss),
        mainlineWaves: waves,
        catalog: GameRepository.instance.combatCatalog,
      );
      expect(summary.totalEnemyCount, profile.totalEnemyCount);
      expect(
        summary.listText,
        UiStrings.stageListEnemyWaves(
          profile.waveCount,
          profile.totalEnemyCount,
        ),
      );
      expect(summary.detailLines, [
        UiStrings.prebattleMainlineWaveSummary(
          profile.waveCount,
          profile.totalEnemyCount,
          bossFinal: boss,
        ),
      ]);
    }
    final fallback = StageEnemySummary.fromStage(
      stage(),
      mainlineWaves: MainlineWaveDef.empty(),
    );
    expect(fallback.totalEnemyCount, stage().enemyTeam.length);
    expect(fallback.listText, UiStrings.stageListEnemyCount(1));
    expect(fallback.detailLines, isEmpty);
  });

  test('真实首关概要与 production factory 实际装配名单及同屏配置一致', () async {
    final repository = GameRepository.instance;
    final firstStage = repository.getStage('stage_01_01');
    final host = await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: firstStage,
        playerMapping: Phase0aStageContentMapper.mapPlayerOnly(
          contentId: firstStage.id,
          playerSnapshot: testCombatantSnapshot(
            includeProductionBasicAttack: true,
          ),
          numbers: repository.numbers,
        ),
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(7),
        runtimeBindingSource:
            const Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
              loader: loadPhase0aMainlineRuntimeBindingBundleFromRepository,
            ),
      ),
    );
    final mapping = host!.mapping!;
    final summary = StageEnemySummary.fromStage(
      firstStage,
      mainlineWaves: repository.numbers.mainlineWave,
      catalog: repository.combatCatalog,
    );
    expect(summary.totalEnemyCount, mapping.combatants.length - 1);
    expect(
      summary.listText,
      UiStrings.stageCatalogEnemySummary(
        mapping.combatants.length - 1,
        mapping.director.config.activeLimit,
      ),
    );
  });

  for (final type in [
    StageType.innerDemon,
    StageType.lightFoot,
    StageType.massBattle,
  ]) {
    testWidgets('$type 情报与列表概要保留特殊模式，不套主线 catalog 或波次', (tester) async {
      // Even a colliding catalog id must not reroute a special mode.
      final special = stage(type: type, id: 'stage_01_01');
      final summary = StageEnemySummary.fromStage(
        special,
        mainlineWaves: GameRepository.instance.numbers.mainlineWave,
        catalog: GameRepository.instance.combatCatalog,
      );
      expect(summary.totalEnemyCount, special.enemyTeam.length);
      expect(summary.listText, UiStrings.stageListEnemyCount(1));
      expect(summary.detailLines, isEmpty);
      await pumpIntel(tester, special);
      expect(find.textContaining('山道悍匪'), findsOneWidget);
      expect(find.textContaining('同屏上限'), findsNothing);
      expect(find.text('3 波 · 共 9 名敌人'), findsNothing);
      expect(find.text(UiStrings.prebattleRiskOutnumbered), findsNothing);
    });
  }

  testWidgets('catalog 单敌关不沿用旧波次的敌众风险', (tester) async {
    final repository = GameRepository.instance;
    final singleStage = repository.getStage('stage_13_01');
    final encounter = repository.combatEncounterForStage(singleStage.id)!;
    expect(encounter.spawnEntries, hasLength(1));
    await pumpIntel(tester, singleStage);
    expect(
      find.text(
        UiStrings.stageCatalogEnemySummary(
          encounter.spawnEntries.length,
          encounter.spawnConfig.activeLimit,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.prebattleCatalogSingleDeployment),
      findsOneWidget,
    );
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsNothing);
  });

  testWidgets('catalog 前敌依赖展示真实依赖人数，不换算为固定波数', (tester) async {
    final repository = GameRepository.instance;
    final dependencyStage = repository.getStage('stage_13_02');
    final encounter = repository.combatEncounterForStage(dependencyStage.id)!;
    final dependentCount = encounter.spawnEntries
        .where((entry) => entry.spawnAfterDefeated.isNotEmpty)
        .length;
    expect(dependentCount, greaterThan(0));
    await pumpIntel(tester, dependencyStage);
    expect(
      find.text(UiStrings.prebattleCatalogSpawnDependencies(dependentCount)),
      findsOneWidget,
    );
    expect(find.textContaining(' 波 · 共 '), findsNothing);
  });

  testWidgets('战前情报显敌阵/应对/风险/掉落，去整备难度冗余', (tester) async {
    await pumpIntel(tester, stage());

    expect(find.text(UiStrings.prebattleIntelEnemySection), findsOneWidget);
    expect(find.text('3 波 · 共 9 名敌人'), findsOneWidget);
    expect(find.textContaining('山道悍匪'), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelResponseSection), findsOneWidget);
    expect(find.textContaining('可备克制路数'), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelLootSection), findsOneWidget);
    expect(find.text(UiStrings.lootBucketChangKeDe), findsOneWidget);
    expect(find.text(UiStrings.prebattleIntelCycleTraitSection), findsNothing);
    expect(find.textContaining('推荐：'), findsNothing);
    expect(find.textContaining('境界低于推荐'), findsNothing);
  });

  testWidgets('首领蓄力三人阵给应对与风险提示', (tester) async {
    await pumpIntel(
      tester,
      stage(
        boss: true,
        enemies: const [
          EnemyDef(
            id: 'm1',
            name: '黑风喽啰',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.lingQiao,
            baseHp: 1000,
            baseAttack: 120,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'm2',
            name: '黑风刀客',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.ruMen,
            school: TechniqueSchool.lingQiao,
            baseHp: 1100,
            baseAttack: 140,
            baseSpeed: 130,
            skillIds: ['skill_normal'],
            iconPath: '',
          ),
          EnemyDef(
            id: 'boss',
            name: '黑风寨主',
            realmTier: RealmTier.sanLiu,
            realmLayer: RealmLayer.shuLian,
            school: TechniqueSchool.lingQiao,
            baseHp: 2200,
            baseAttack: 220,
            baseSpeed: 130,
            skillIds: ['skill_normal', 'skill_charge'],
            iconPath: '',
            isBoss: true,
            chargeSkillId: 'skill_charge',
          ),
        ],
      ),
    );

    expect(find.textContaining('黑风寨主'), findsOneWidget);
    expect(
      find.textContaining(
        '${UiStrings.prebattleIntelBossTag} / ${UiStrings.prebattleIntelChargeTag}',
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.prebattlePrepGroup), findsOneWidget);
    expect(find.text(UiStrings.prebattlePrepCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskBoss), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskCharge), findsOneWidget);
    expect(find.text(UiStrings.prebattleRiskOutnumbered), findsOneWidget);
  });

  testWidgets('二周目战前情报解释周目词条', (tester) async {
    await pumpIntel(tester, stage(), targetCycle: 2);

    expect(
      find.text(UiStrings.prebattleIntelCycleTraitSection),
      findsOneWidget,
    );
    expect(find.textContaining('御体'), findsOneWidget);
    expect(find.textContaining('真气'), findsOneWidget);
    expect(find.textContaining('御体 · 御体'), findsNothing);
    expect(find.textContaining('多放一次大招'), findsOneWidget);
  });

  testWidgets('有受伤出战角色时显示我方伤势段', (tester) async {
    await pumpIntel(tester, stage(), activeCharacters: [woundedCharacter()]);

    expect(
      find.text(UiStrings.prebattleIntelAllyConditionSection),
      findsOneWidget,
    );
    expect(find.textContaining('沈青：'), findsOneWidget);
    expect(find.textContaining(UiStrings.injuryLightLabel), findsOneWidget);
  });

  testWidgets('传入目标引导时显示当前目标段', (tester) async {
    final def = stage();
    await pumpIntel(
      tester,
      def,
      goalGuidance: NewSaveGoalGuidance.fromStage(
        chapterIndex: 1,
        stageIndex: 2,
        stage: def,
      ),
    );

    expect(find.text(UiStrings.stageGoalGuidanceTitle), findsOneWidget);
    expect(find.textContaining('打第1章第2关「试剑坡」'), findsOneWidget);
    expect(find.textContaining('取磨剑石'), findsOneWidget);
  });
}
