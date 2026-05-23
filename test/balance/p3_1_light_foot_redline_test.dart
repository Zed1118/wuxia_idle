import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/light_foot_strategy.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/light_foot/application/light_foot_service.dart';

/// P3.1 §12.3 轻功对决 Batch C.1 R5 跨地形红线压测。
///
/// 沿 P2.2 inner_demon R5 体例(`test/balance/inner_demon_r5_redline_test.dart`)+
/// memory `feedback_red_line_test_semantics`(约束语义不写瞬时事实)。
///
/// **3 测**:
///   - R5.1 5 关 × 50 种子分布:玩家 yiLiu/jueDing 满 build vs stage enemyTeam,
///     断言 leftWins + draws ≥ rightWins(玩家强 build 应主导支线 · 与心魔克己
///     语义对称)+ runToEnd 不抛
///   - R5.2 terrain modifier cap e2e:water/rooftop/bamboo 三 terrain bake 后
///     critRate/evasionRate/defenseRate clamp ≤0.95 + 不破 §5.4 红线(maxHp ≤20k
///     / maxInternalForce ≤15k 不动)
///   - R5.3 unlock 链 e2e:stage_06_05 victory → light_foot_01 unlock + 链式
///     5 关顺序解锁 + LightFootService.statusOf 三态语义对齐
///
/// **断言语义**(memory `feedback_red_line_test_semantics`):
///   - ✅ 50 种子全有 result(覆盖率 + runToEnd 不抛)
///   - ✅ leftWins + draws ≥ rightWins(平行支线红线 · 玩家强 build 主导)
///   - ✅ clamp 约束(stat ≤0.95 / §5.4 红线不动)
///   - ❌ 不写「胜率 X%」「leftWins ≥ 30」之类瞬时数字断言
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('P3.1 §12.3 轻功对决 R5 跨地形红线压测', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_r5_light_foot_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    });

    tearDownAll(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// 构造指定 tier/layer 满 build 的 BattleCharacter 三人队。
    /// 沿 inner_demon R5 体例,绕过 Isar 玩家路径直接 inline。
    List<BattleCharacter> buildPlayerTeam({
      required RealmTier tier,
      required RealmLayer layer,
    }) {
      final repo = GameRepository.instance;
      final numbers = repo.numbers;
      final realmDef = repo.getRealm(tier, layer);
      EquipmentDef defOf(EquipmentSlot slot) => repo.equipmentDefs.values
          .firstWhere(
              (d) => d.tier == realmDef.equipmentTierCap && d.slot == slot);
      Equipment buildEq(EquipmentSlot slot) {
        final def = defOf(slot);
        return Equipment.create(
          defId: def.id,
          tier: def.tier,
          slot: def.slot,
          obtainedAt: DateTime(2026, 1, 1),
          obtainedFrom: 'r5_light_foot',
          baseAttack: def.baseAttackMax,
          baseHealth: def.baseHealthMax,
          baseSpeed: def.baseSpeedMax,
        );
      }

      final mainTechDef = repo.techniqueDefs.values.firstWhere(
        (d) => d.tier == realmDef.techniqueTierCap,
        orElse: () => throw StateError(
          'r5 light_foot: 找不到 ${tier.name} cap 心法 def',
        ),
      );

      BattleCharacter buildOne(int slotIndex, TechniqueSchool school) {
        final equipped = [
          buildEq(EquipmentSlot.weapon),
          buildEq(EquipmentSlot.armor),
          buildEq(EquipmentSlot.accessory),
        ];
        final character = Character.create(
          name: 'r5_light_foot_player_$slotIndex',
          realmTier: tier,
          realmLayer: layer,
          attributes: Attributes()
            ..constitution = 10
            ..enlightenment = 10
            ..agility = 10
            ..fortune = 10,
          rarity: RarityTier.jueShi,
          lineageRole: LineageRole.disciple,
          createdAt: DateTime(2026, 1, 1),
          internalForce: realmDef.internalForceMax,
          internalForceMax: realmDef.internalForceMax,
        );
        character.school = school;
        final mainTech = Technique.create(
          defId: mainTechDef.id,
          ownerCharacterId: -500 - slotIndex,
          tier: mainTechDef.tier,
          school: mainTechDef.school,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 1, 1),
          cultivationLayer: CultivationLayer.jiJing,
          cultivationProgress: 100,
          cultivationProgressToNext: 100,
        );
        return BattleCharacter.fromCharacter(
          character: character,
          equipped: equipped,
          mainTechnique: mainTech,
          numbers: numbers,
          teamSide: 0,
          slotIndex: slotIndex,
        );
      }

      // 3 流派覆盖(GDD §4.4)
      return [
        buildOne(0, TechniqueSchool.gangMeng),
        buildOne(1, TechniqueSchool.lingQiao),
        buildOne(2, TechniqueSchool.yinRou),
      ];
    }

    // 5 关玩家 tier/layer 矩阵(对齐 stages.yaml + spec §一)
    const stageMatrix = <(String, RealmTier, RealmLayer)>[
      ('stage_light_foot_01', RealmTier.yiLiu, RealmLayer.qiMeng),
      ('stage_light_foot_02', RealmTier.yiLiu, RealmLayer.jingTong),
      ('stage_light_foot_03', RealmTier.yiLiu, RealmLayer.dengFeng),
      ('stage_light_foot_04', RealmTier.jueDing, RealmLayer.qiMeng),
      ('stage_light_foot_05', RealmTier.jueDing, RealmLayer.jingTong),
    ];

    test(
      'R5.1 5 关 × 50 种子分布 · leftWins+draws ≥ rightWins(平行支线玩家主导)',
      () {
        final repo = GameRepository.instance;
        final numbers = repo.numbers;
        final lightFootDef = numbers.lightFoot;
        final dist = <String, (int, int, int)>{};

        for (final (stageId, tier, layer) in stageMatrix) {
          final stage = repo.getStage(stageId);
          final left = buildPlayerTeam(tier: tier, layer: layer);
          // 敌队从 stages.yaml enemyTeam[] 走(沿 StageBattleSetup.buildEnemyTeam
          // static 体例),不走 inner_demon 镜像。
          final right = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
          expect(right, hasLength(3),
              reason: '$stageId 应有 3 敌人(stages.yaml enemyTeam[])');

          // terrainBiome 必须非空(stages.yaml 全 5 关已配)
          expect(stage.terrainBiome, isNotNull,
              reason: '$stageId stages.yaml 必配 terrainBiome');
          final terrainBiome = stage.terrainBiome!;

          // LightFootStrategy 入口 bake terrain modifier 到双方
          final initial =
              BattleState.initial(leftTeam: left, rightTeam: right);
          final modified = LightFootStrategy.applyTerrainTo(
            initial,
            terrainBiome: terrainBiome,
            config: lightFootDef,
          );

          var leftWins = 0;
          var rightWins = 0;
          var draws = 0;
          // ignore: prefer_const_constructors
          const ground = DefaultGroundStrategy();
          for (var seed = 0; seed < 50; seed++) {
            final finalState =
                ground.runToEnd(modified, numbers, rng: Random(seed));
            switch (finalState.result) {
              case BattleResult.leftWin:
                leftWins++;
                break;
              case BattleResult.rightWin:
                rightWins++;
                break;
              case BattleResult.draw:
                draws++;
                break;
              case null:
                break;
            }
          }

          expect(leftWins + rightWins + draws, 50,
              reason: '$stageId 50 种子全有 result');
          expect(leftWins + draws >= rightWins, isTrue,
              reason: '$stageId 平行支线红线:leftWins($leftWins) + '
                  'draws($draws) >= rightWins($rightWins)');

          dist[stageId] = (leftWins, rightWins, draws);
        }

        // ignore: avoid_print
        print('R5.1 light_foot 5 关 × 50 种子 distribution:');
        for (final (stageId, _, _) in stageMatrix) {
          final (l, r, d) = dist[stageId]!;
          // ignore: avoid_print
          print('  $stageId: leftWins=$l rightWins=$r draws=$d');
        }
      },
    );

    test(
      'R5.2 terrain modifier cap e2e · clamp ≤0.95 + §5.4 红线不动',
      () {
        final repo = GameRepository.instance;
        final numbers = repo.numbers;
        final lightFootDef = numbers.lightFoot;

        // 用 jueDing·jingTong 满 build(最高 stat 接近 cap)+ 三 terrain bake
        // 验证各字段 clamp + §5.4 红线不动。
        final left = buildPlayerTeam(
          tier: RealmTier.jueDing,
          layer: RealmLayer.jingTong,
        );
        final right = buildPlayerTeam(
          tier: RealmTier.jueDing,
          layer: RealmLayer.jingTong,
        );
        final initial =
            BattleState.initial(leftTeam: left, rightTeam: right);

        for (final terrain in TerrainBiome.values) {
          final modified = LightFootStrategy.applyTerrainTo(
            initial,
            terrainBiome: terrain,
            config: lightFootDef,
          );

          for (final c in [...modified.leftTeam, ...modified.rightTeam]) {
            // clamp ≤0.95(防破 §5.5 极端值)
            expect(c.criticalRate, lessThanOrEqualTo(0.95),
                reason: '$terrain ${c.name} critRate clamp');
            expect(c.evasionRate, lessThanOrEqualTo(0.95),
                reason: '$terrain ${c.name} evasionRate clamp');
            expect(c.defenseRate, lessThanOrEqualTo(0.95),
                reason: '$terrain ${c.name} defenseRate clamp');
            // clamp ≥0.0
            expect(c.criticalRate, greaterThanOrEqualTo(0.0));
            expect(c.evasionRate, greaterThanOrEqualTo(0.0));
            expect(c.defenseRate, greaterThanOrEqualTo(0.0));

            // §5.4 红线不动(maxHp/maxInternalForce/totalEquipmentAttack)
            expect(c.maxHp, lessThanOrEqualTo(20000),
                reason: '$terrain ${c.name} §5.4 maxHp 红线');
            expect(c.maxInternalForce, lessThanOrEqualTo(15000),
                reason: '$terrain ${c.name} §5.4 maxInternalForce 红线');
            // totalEquipmentAttack 是 3 件求和,§5.4 单件 2000 cap,
            // 3 件求和理论上界 6000;light_foot 不动 totalEquipmentAttack。
            expect(c.totalEquipmentAttack, lessThanOrEqualTo(6000),
                reason: '$terrain ${c.name} 3 件求和 ≤6000(§5.4 单件 2000 × 3)');
          }
        }
      },
    );

    test(
      'R5.3 unlock 链 e2e · stage_06_05 → light_foot_01 → ... → 05 顺序',
      () {
        final lightFootDef = GameRepository.instance.numbers.lightFoot;

        // 起点:玩家通过 Ch6 末关 stage_06_05
        var cleared = {'stage_06_05'};

        // light_foot_01 应 available(unlock 链起点)
        expect(
          LightFootService.statusOf(
            stageId: 'stage_light_foot_01',
            config: lightFootDef,
            clearedStageIds: cleared,
          ),
          LightFootStageStatus.available,
          reason: 'stage_06_05 cleared → light_foot_01 available',
        );

        // light_foot_02..05 应 locked
        for (final id in [
          'stage_light_foot_02',
          'stage_light_foot_03',
          'stage_light_foot_04',
          'stage_light_foot_05',
        ]) {
          expect(
            LightFootService.statusOf(
              stageId: id,
              config: lightFootDef,
              clearedStageIds: cleared,
            ),
            LightFootStageStatus.locked,
            reason: '$id 未到 prev cleared 仍 locked',
          );
        }

        // 渐进通关 light_foot_01..04,验证下一关逐步放行
        final progression = [
          ('stage_light_foot_01', 'stage_light_foot_02'),
          ('stage_light_foot_02', 'stage_light_foot_03'),
          ('stage_light_foot_03', 'stage_light_foot_04'),
          ('stage_light_foot_04', 'stage_light_foot_05'),
        ];
        for (final (clearedNow, nextAvailable) in progression) {
          cleared = {...cleared, clearedNow};
          expect(
            LightFootService.statusOf(
              stageId: nextAvailable,
              config: lightFootDef,
              clearedStageIds: cleared,
            ),
            LightFootStageStatus.available,
            reason: '$clearedNow cleared → $nextAvailable available',
          );
        }

        // 最终全 cleared → 5 关全 cleared 三态
        cleared = {
          'stage_06_05',
          'stage_light_foot_01',
          'stage_light_foot_02',
          'stage_light_foot_03',
          'stage_light_foot_04',
          'stage_light_foot_05',
        };
        for (var i = 1; i <= 5; i++) {
          final id = 'stage_light_foot_0$i';
          expect(
            LightFootService.statusOf(
              stageId: id,
              config: lightFootDef,
              clearedStageIds: cleared,
            ),
            LightFootStageStatus.cleared,
            reason: '$id 通关后 cleared',
          );
        }

        // orderedStageIds 拓扑序印证
        expect(
          LightFootService.orderedStageIds(lightFootDef),
          [
            'stage_light_foot_01',
            'stage_light_foot_02',
            'stage_light_foot_03',
            'stage_light_foot_04',
            'stage_light_foot_05',
          ],
        );
      },
    );
  });
}
