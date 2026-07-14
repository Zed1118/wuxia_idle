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
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/application/progression_gate_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import "../support/isar_test_support.dart";
import '../support/test_data.dart';

/// Phase 2 P2.2 §12.1 心魔系统 Batch 2.5.A R5 跨阶红线压测。
///
/// 沿 Ch6 R5 体例(`test/balance/ch6_r5_crosstier_redline_test.dart`)+
/// closeout: `docs/handoff/p2_x_inner_demon_implementation_closeout_2026-05-22.md` §六
///
/// **3 测**:
///   - R5.1 7 关 × 50 种子双边断言:每关 leftWins+draws ≥ rightWins(克己语义
///     「难赢但不输」)+ print 7 关 distribution 支持 inner_demon_07 双镜像决议
///     (Batch 2.5.C)
///   - R5.2 e2e mirror cap §5.4 红线 verify:玩家 wuSheng·dengFeng 满 build +
///     stage_inner_demon_07 +20% → mirror 各字段 ≤ §5.4 cap(20k/15k/2k)
///     印证 R3 在真实 numbers.yaml innerDemon 数据流真生效
///   - R5.3 当前发布节点 e2e:起点 xueTu·shuLian + EXP 留账 →
///     inner_demon_01..07 逐关通关 → applyExperience + 统一门禁 →
///     停在 sanLiu·shuLian（绝对层 10）
///
/// **断言语义**(memory `feedback_red_line_test_semantics`):
///   - ✅ 50 种子全有 result(覆盖率 + runToEnd 不抛)
///   - ✅ leftWins + draws ≥ rightWins(主红线 · 玩家镜像难赢但不输)
///   - ❌ 不写「胜率 X%」「leftWins ≥ 30」之类瞬时数字断言
///
/// **inner_demon 设计意图与 Ch6 R5 差异**:
///   Ch6 R5 验「跨阶 boss 仍有威慑(rightWins+draws ≥ 1)」,因为跨阶设计意图
///   = 玩家不该 100% leftWin(boss 跨阶应难)。但 inner_demon 镜像 = 玩家自己
///   +10-20% buff,设计意图 = 「克己」语义 — 难赢但不输,平局 / 玩家 100%
///   leftWin 都是可接受设计意图(没有「跨阶威慑」语义)。**因此 R5.1 只断言
///   上边界 leftWins+draws ≥ rightWins,不加 Ch6 R5 那种下边界。**
///
/// **玩家 build**:各关使用其生产 `required_realm_layer` 对应境界与同阶三系装备/心法。
///   - 3 角色覆盖 3 流派(GDD §4.4)
void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  group('P2.2 §12.1 心魔系统 R5 跨阶红线压测', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_r5_inner_demon_');
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

    /// 构造指定境界层满 build 的 BattleCharacter 三人队。
    /// 沿 Ch6 R5 `buildR5Players()` 体例,绕过 Isar 直接 inline 构造。
    List<BattleCharacter> buildPlayerTeam(RealmTier tier, RealmLayer layer) {
      final repo = GameRepository.instance;
      final numbers = repo.numbers;
      final realm = repo.getRealm(tier, layer);
      EquipmentDef defOf(EquipmentSlot slot) =>
          repo.equipmentDefs.values.firstWhere(
            (d) => d.tier == realm.equipmentTierCap && d.slot == slot,
          );
      Equipment buildEq(EquipmentSlot slot) {
        final def = defOf(slot);
        // 满 build 直接取各维度 max(玩家满 build 验红线)。Ch6 R5 只传
        // baseHealth 因跨阶 ×1.4/0.7 修正能区分,但 inner_demon 同阶同 build
        // (玩家 vs 镜像 = 自己 +buff)需要装备攻击/速度真实数值才有意义。
        return Equipment.create(
          defId: def.id,
          tier: def.tier,
          slot: def.slot,
          obtainedAt: DateTime(2026, 1, 1),
          obtainedFrom: 'r5_inner_demon',
          baseAttack: def.baseAttackMax,
          baseHealth: def.baseHealthMax,
          baseSpeed: def.baseSpeedMax,
        );
      }

      final mainTechDef = repo.techniqueDefs.values.firstWhere(
        (d) => d.tier == realm.techniqueTierCap,
        orElse: () => throw StateError(
          'r5 inner_demon: missing technique for ${tier.name}/${layer.name}',
        ),
      );

      BattleCharacter buildOne(int slotIndex, TechniqueSchool school) {
        final equipped = [
          buildEq(EquipmentSlot.weapon),
          buildEq(EquipmentSlot.armor),
          buildEq(EquipmentSlot.accessory),
        ];
        final character = Character.create(
          name: 'r5_inner_demon_player_$slotIndex',
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
          internalForce: realm.internalForceMax,
          internalForceMax: realm.internalForceMax,
        );
        character.id = -700 - slotIndex;
        character.school = school;
        final mainTech = Technique.create(
          defId: mainTechDef.id,
          ownerCharacterId: -400 - slotIndex,
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

      // 3 流派覆盖(GDD §4.4 三流派克制)
      return [
        buildOne(0, TechniqueSchool.gangMeng),
        buildOne(1, TechniqueSchool.lingQiao),
        buildOne(2, TechniqueSchool.yinRou),
      ];
    }

    // 7 关玩家当前发布版节点。
    const stageLayers = <(String, RealmTier, RealmLayer)>[
      ('stage_inner_demon_01', RealmTier.xueTu, RealmLayer.shuLian),
      ('stage_inner_demon_02', RealmTier.xueTu, RealmLayer.jingTong),
      ('stage_inner_demon_03', RealmTier.xueTu, RealmLayer.yuanShu),
      ('stage_inner_demon_04', RealmTier.xueTu, RealmLayer.huaJing),
      ('stage_inner_demon_05', RealmTier.xueTu, RealmLayer.dengFeng),
      ('stage_inner_demon_06', RealmTier.sanLiu, RealmLayer.qiMeng),
      ('stage_inner_demon_07', RealmTier.sanLiu, RealmLayer.ruMen),
    ];

    test(
      'R5.1 7 关 × 50 种子双边断言 · leftWins+draws ≥ rightWins(克己语义)',
      () {
        final repo = GameRepository.instance;
        final numbers = repo.numbers;
        final innerDemonDef = numbers.innerDemon;
        // 「stage_id → (leftWins, rightWins, draws)」聚合分布,支持 2.5.C
        // 双镜像决议(closeout §六 inner_demon_07)。
        final dist = <String, (int, int, int)>{};

        for (final (stageId, tier, layer) in stageLayers) {
          final left = buildPlayerTeam(tier, layer);
          final right = InnerDemonService.buildMirrorEnemyTeam(
            playerTeam: left,
            stageId: stageId,
            innerDemonDef: innerDemonDef,
          );
          expect(
            right,
            hasLength(3),
            reason: '$stageId 应生成 3 镜像(spec §一末关单副本占位)',
          );

          var leftWins = 0;
          var rightWins = 0;
          var draws = 0;
          for (var seed = 0; seed < 50; seed++) {
            final initial = BattleState.initial(
              leftTeam: left,
              rightTeam: right,
            );
            final finalState = defaultGroundStrategy.runToEnd(
              initial,
              numbers,
              rng: Random(seed),
            );
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
                // runToEnd 必写 result,此分支不应到达
                break;
            }
          }
          dist[stageId] = (leftWins, rightWins, draws);
        }

        // 实测分布印 stdout(支持 2.5.C inner_demon_07 双镜像决议:若 _07
        // 平局率 / 玩家 leftWin 率与 _06 差异不显著 → 升 +40% 单副本 / 扩
        // BattleState 6v3 / 连战;若已差异显著 → 保持单副本 +20% 占位)。
        // ignore: avoid_print
        print('R5.1 inner_demon 7 关 50 种子分布(layer / stage / buff %):');
        for (final (stageId, tier, layer) in stageLayers) {
          final (l, r, d) = dist[stageId]!;
          final buff = (innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0) * 100;
          // ignore: avoid_print
          print(
            '  ${tier.name}.${layer.name.padRight(8)} $stageId '
            '(+${buff.toStringAsFixed(0)}%): '
            'leftWins=$l rightWins=$r draws=$d',
          );
        }

        for (final (stageId, tier, layer) in stageLayers) {
          final (l, r, d) = dist[stageId]!;
          // 覆盖率:50 种子全跑完,result 非 null
          expect(
            l + r + d,
            50,
            reason:
                '$stageId: 50 种子全应有 result(leftWin/rightWin/draw),'
                '不应漏跑',
          );

          // 主红线:玩家方综合不输面(克己语义难赢但不输)
          expect(
            l + d,
            greaterThanOrEqualTo(r),
            reason:
                'R5 主红线 $stageId(${tier.name}·${layer.name}):玩家方满 build vs '
                '镜像自己 +${((innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0) * 100).toStringAsFixed(0)}% '
                '50 种子(leftWins=$l + draws=$d)应 ≥ rightWins=$r — '
                'spec §一表注「克己语义 acceptable 难赢但不输」(memory '
                '`feedback_red_line_test_semantics`)。',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'R5.2 e2e mirror cap §5.4 红线 verify(stage_inner_demon_07 + dengFeng 满 build)',
      () {
        // 玩家 wuSheng·dengFeng 满 build → mirror +20% buff,验数据流 cap
        // 在真实 numbers.yaml innerDemonDef + buildMirrorEnemyTeam 中真生效
        // (R3 在 inner_demon_service_test 单测已验,本 R5.2 走真 yaml 数据)。
        final left = buildPlayerTeam(RealmTier.wuSheng, RealmLayer.dengFeng);
        final innerDemonDef = GameRepository.instance.numbers.innerDemon;
        final right = InnerDemonService.buildMirrorEnemyTeam(
          playerTeam: left,
          stageId: 'stage_inner_demon_07',
          innerDemonDef: innerDemonDef,
        );

        expect(right, hasLength(3));
        for (final m in right) {
          // §5.4 玩家血上限 20000
          expect(
            m.maxHp,
            lessThanOrEqualTo(20000),
            reason: '$m: §5.4 玩家血上限 cap',
          );
          expect(
            m.currentHp,
            lessThanOrEqualTo(20000),
            reason: '$m: 镜像开战满血 ≤ §5.4 上限',
          );
          // §5.4 内力上限 15000
          expect(
            m.internalForce,
            lessThanOrEqualTo(15000),
            reason: '$m: §5.4 内力上限 cap',
          );
          expect(
            m.currentQi,
            lessThanOrEqualTo(15000),
            reason: '$m: 镜像开战满内力 ≤ §5.4 上限',
          );
          // mirror totalEquipmentAttack cap = 3 × §5.4 单件 2000 = 6000
          // (Batch 2.5.C: 原 2000 锚错 §5.4 维度,§5.4 装备攻击是单件 cap,
          // 镜像 totalEquipmentAttack 是 3 件求和)
          expect(
            m.totalEquipmentAttack,
            lessThanOrEqualTo(6000),
            reason:
                '$m: mirror totalEquipmentAttack cap '
                '(3 × §5.4 单件 2000 = 6000)',
          );
          // teamSide 正确
          expect(m.teamSide, 1, reason: '$m: 右队');
        }

        // 玩家 build wuSheng·dengFeng 满应当真的接近 cap(印证测试本身有
        // 覆盖意义,非「玩家 build 太弱永远不触 cap」假覆盖)
        final maxPlayerHp = left.map((p) => p.maxHp).reduce(max);
        final maxPlayerAttack = left
            .map((p) => p.totalEquipmentAttack)
            .reduce(max);
        // ignore: avoid_print
        print(
          'R5.2 玩家 dengFeng 满 build 接近 cap 验证:'
          'maxHp=$maxPlayerHp / maxAttack=$maxPlayerAttack',
        );
        // 玩家 dengFeng 满 build hp 应过 10000(防玩家 build 退化让 cap 测假阳)
        expect(
          maxPlayerHp,
          greaterThan(10000),
          reason:
              'R5.2 玩家 dengFeng 满 build maxHp 应过 10000 — '
              '否则 cap 验证无意义(玩家 build 退化 → ×1.2 也不触 cap)',
        );
      },
    );

    test('R5.3 当前版七节点逐关放行并停在绝对层10', () {
      // 集成 isLayerLocked + applyExperience hook 真链路。
      final innerDemonDef = GameRepository.instance.numbers.innerDemon;
      final realmLookup = GameRepository.instance.getRealm;

      final character = Character.create(
        name: 'r5_unlock_e2e_player',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.shuLian,
        attributes: Attributes()
          ..constitution = 10
          ..enlightenment = 10
          ..agility = 10
          ..fortune = 10,
        rarity: RarityTier.jueShi,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 1, 1),
        internalForce: 700,
        internalForceMax: 700,
        experienceToNextLayer: 120,
      );

      final cleared = <String>{'stage_01_03'};
      bool isLocked(RealmTier nextTier, RealmLayer nextLayer) =>
          ProgressionGateService.isLayerLocked(
            nextTier: nextTier,
            nextLayer: nextLayer,
            releaseCap: GameRepository.instance.numbers.progressionReleaseCap,
            realmLookup: realmLookup,
            innerDemonDef: innerDemonDef,
            clearedStageIds: cleared,
          );

      // 灌大量 EXP 一次性(GDD §5.1 反留存焦虑 — 玩家挂机攒 EXP,过心魔关
      // 后立刻全部消费),inner_demon_01 未通拦截在绝对层3→4。
      var r = CharacterAdvancementService.applyExperience(
        character,
        10000,
        realmLookup: realmLookup,
        isLayerLocked: isLocked,
      );
      expect(r.layersGained, 0, reason: 'inner_demon_01 未通 → 绝对层3→4 被拦,EXP 留账');
      expect(character.realmTier, RealmTier.xueTu);
      expect(character.realmLayer, RealmLayer.shuLian);
      expect(character.experience, 10000, reason: 'EXP 不归零(GDD §5.1 反留存焦虑)');

      final expectedAfter = <(String, RealmTier, RealmLayer)>[
        ('stage_inner_demon_01', RealmTier.xueTu, RealmLayer.jingTong),
        ('stage_inner_demon_02', RealmTier.xueTu, RealmLayer.yuanShu),
        ('stage_inner_demon_03', RealmTier.xueTu, RealmLayer.huaJing),
        ('stage_inner_demon_04', RealmTier.xueTu, RealmLayer.dengFeng),
        ('stage_inner_demon_05', RealmTier.sanLiu, RealmLayer.qiMeng),
        ('stage_inner_demon_06', RealmTier.sanLiu, RealmLayer.ruMen),
        ('stage_inner_demon_07', RealmTier.sanLiu, RealmLayer.shuLian),
      ];
      for (final (stageId, nextTier, nextLayer) in expectedAfter) {
        cleared.add(stageId);
        // delta=0 在 applyExperience 走短路分支不进 while-loop;喂 1 EXP
        // 触发 while-loop 消费已攒 EXP(character.experience 已 10M+),
        // 单次只升 1 layer(因下一关心魔仍 locked → break)。
        r = CharacterAdvancementService.applyExperience(
          character,
          1,
          realmLookup: realmLookup,
          isLayerLocked: isLocked,
        );
        expect(
          r.layersGained,
          1,
          reason:
              '$stageId 通关 → 应升 1 layer 至 ${nextTier.name}·${nextLayer.name}',
        );
        expect(character.realmTier, nextTier);
        expect(
          character.realmLayer,
          nextLayer,
          reason: '$stageId 通关后玩家 layer 应推到 ${nextLayer.name}',
        );
      }

      expect(character.realmTier, RealmTier.sanLiu);
      expect(character.realmLayer, RealmLayer.shuLian);
    });
  });
}
