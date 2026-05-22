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
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';

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
///   - R5.3 渐进通关 unlock 链 e2e:起点 wuSheng·qiMeng + EXP 留账 →
///     inner_demon_01..06 逐关通关 → applyExperience + isLayerLocked closure →
///     wuSheng·qiMeng → dengFeng 6 步 layer 逐步放行(集成 isLayerLocked +
///     applyExperience hook 真链路)
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
/// **玩家 build**(各关用对应 wuSheng layer,匹配 spec §一矩阵):
///   - wuSheng·N layer + 神物 cap 装备 3 件 + chuanShuoShenGong 心法 jiJing 满
///   - 3 角色覆盖 3 流派(GDD §4.4)
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('P2.2 §12.1 心魔系统 R5 跨阶红线压测', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_r5_inner_demon_');
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

    /// 构造 wuSheng·[layer] 满 build 的 BattleCharacter 三人队。
    /// 沿 Ch6 R5 `buildR5Players()` 体例,绕过 Isar 直接 inline 构造。
    List<BattleCharacter> buildPlayerTeam(RealmLayer layer) {
      final repo = GameRepository.instance;
      final numbers = repo.numbers;
      final wuShengX = repo.getRealm(RealmTier.wuSheng, layer);
      EquipmentDef defOf(EquipmentSlot slot) => repo.equipmentDefs.values
          .firstWhere(
              (d) => d.tier == wuShengX.equipmentTierCap && d.slot == slot);
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
        (d) => d.tier == wuShengX.techniqueTierCap,
        orElse: () => throw StateError(
          'r5 inner_demon: 找不到 wuSheng cap (chuanShuoShenGong) 心法 def',
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
          realmTier: RealmTier.wuSheng,
          realmLayer: layer,
          attributes: Attributes()
            ..constitution = 10
            ..enlightenment = 10
            ..agility = 10
            ..fortune = 10,
          rarity: RarityTier.jueShi,
          lineageRole: LineageRole.disciple,
          createdAt: DateTime(2026, 1, 1),
          internalForce: wuShengX.internalForceMax,
          internalForceMax: wuShengX.internalForceMax,
        );
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

    // 7 关玩家 wuSheng 起步 layer(spec §一矩阵)。
    const stageLayers = <(String, RealmLayer)>[
      ('stage_inner_demon_01', RealmLayer.qiMeng),
      ('stage_inner_demon_02', RealmLayer.ruMen),
      ('stage_inner_demon_03', RealmLayer.shuLian),
      ('stage_inner_demon_04', RealmLayer.jingTong),
      ('stage_inner_demon_05', RealmLayer.yuanShu),
      ('stage_inner_demon_06', RealmLayer.huaJing),
      ('stage_inner_demon_07', RealmLayer.dengFeng),
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

        for (final (stageId, layer) in stageLayers) {
          final left = buildPlayerTeam(layer);
          final right = InnerDemonService.buildMirrorEnemyTeam(
            playerTeam: left,
            stageId: stageId,
            innerDemonDef: innerDemonDef,
          );
          expect(right, hasLength(3),
              reason: '$stageId 应生成 3 镜像(spec §一末关单副本占位)');

          var leftWins = 0;
          var rightWins = 0;
          var draws = 0;
          for (var seed = 0; seed < 50; seed++) {
            final initial =
                BattleState.initial(leftTeam: left, rightTeam: right);
            final finalState = BattleEngine.runToEnd(
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
        for (final (stageId, layer) in stageLayers) {
          final (l, r, d) = dist[stageId]!;
          final buff =
              (innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0) * 100;
          // ignore: avoid_print
          print('  ${layer.name.padRight(8)} $stageId '
              '(+${buff.toStringAsFixed(0)}%): '
              'leftWins=$l rightWins=$r draws=$d');
        }

        for (final (stageId, layer) in stageLayers) {
          final (l, r, d) = dist[stageId]!;
          // 覆盖率:50 种子全跑完,result 非 null
          expect(l + r + d, 50,
              reason:
                  '$stageId: 50 种子全应有 result(leftWin/rightWin/draw),'
                  '不应漏跑');

          // 主红线:玩家方综合不输面(克己语义难赢但不输)
          expect(
            l + d,
            greaterThanOrEqualTo(r),
            reason:
                'R5 主红线 $stageId(wuSheng·${layer.name}):玩家方满 build vs '
                '镜像自己 +${(innerDemonDef.mirrorBuffPerStage[stageId] ?? 0.0 * 100).toStringAsFixed(0)}% '
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
        final left = buildPlayerTeam(RealmLayer.dengFeng);
        final innerDemonDef = GameRepository.instance.numbers.innerDemon;
        final right = InnerDemonService.buildMirrorEnemyTeam(
          playerTeam: left,
          stageId: 'stage_inner_demon_07',
          innerDemonDef: innerDemonDef,
        );

        expect(right, hasLength(3));
        for (final m in right) {
          // §5.4 玩家血上限 20000
          expect(m.maxHp, lessThanOrEqualTo(20000),
              reason: '$m: §5.4 玩家血上限 cap');
          expect(m.currentHp, lessThanOrEqualTo(20000),
              reason: '$m: 镜像开战满血 ≤ §5.4 上限');
          // §5.4 内力上限 15000
          expect(m.maxInternalForce, lessThanOrEqualTo(15000),
              reason: '$m: §5.4 内力上限 cap');
          expect(m.currentInternalForce, lessThanOrEqualTo(15000),
              reason: '$m: 镜像开战满内力 ≤ §5.4 上限');
          // §5.4 装备攻击上限 2000
          expect(m.totalEquipmentAttack, lessThanOrEqualTo(2000),
              reason: '$m: §5.4 装备攻击上限 cap');
          // teamSide 正确
          expect(m.teamSide, 1, reason: '$m: 右队');
        }

        // 玩家 build wuSheng·dengFeng 满应当真的接近 cap(印证测试本身有
        // 覆盖意义,非「玩家 build 太弱永远不触 cap」假覆盖)
        final maxPlayerHp = left.map((p) => p.maxHp).reduce(max);
        final maxPlayerAttack =
            left.map((p) => p.totalEquipmentAttack).reduce(max);
        // ignore: avoid_print
        print('R5.2 玩家 dengFeng 满 build 接近 cap 验证:'
            'maxHp=$maxPlayerHp / maxAttack=$maxPlayerAttack');
        // 玩家 dengFeng 满 build hp 应过 10000(防玩家 build 退化让 cap 测假阳)
        expect(maxPlayerHp, greaterThan(10000),
            reason: 'R5.2 玩家 dengFeng 满 build maxHp 应过 10000 — '
                '否则 cap 验证无意义(玩家 build 退化 → ×1.2 也不触 cap)');
      },
    );

    test(
      'R5.3 渐进通关 unlock 链 e2e(qiMeng→dengFeng 6 步逐关放行)',
      () {
        // 集成 isLayerLocked + applyExperience hook 真链路。
        // 起点:Ch6 stage_06_05 通关后玩家自动升 wuSheng·qiMeng(spec §三 R2)。
        final innerDemonDef = GameRepository.instance.numbers.innerDemon;
        final realmLookup = GameRepository.instance.getRealm;

        final character = Character.create(
          name: 'r5_unlock_e2e_player',
          realmTier: RealmTier.wuSheng,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes()
            ..constitution = 10
            ..enlightenment = 10
            ..agility = 10
            ..fortune = 10,
          rarity: RarityTier.jueShi,
          lineageRole: LineageRole.disciple,
          createdAt: DateTime(2026, 1, 1),
          internalForce: 13000,
          internalForceMax: 13000,
          experienceToNextLayer: 430000, // wuSheng·qiMeng → ruMen
        );

        // clearedStageIds 起点:Ch6 末关已通(玩家自动升 wuSheng·qiMeng 必经)
        final cleared = <String>{'stage_06_05'};
        bool isLocked(RealmTier nextTier, RealmLayer nextLayer) =>
            InnerDemonService.isLayerLocked(
              nextTier: nextTier,
              nextLayer: nextLayer,
              innerDemonDef: innerDemonDef,
              clearedStageIds: cleared,
            );

        // 灌大量 EXP 一次性(GDD §5.1 反留存焦虑 — 玩家挂机攒 EXP,过心魔关
        // 后立刻全部消费),inner_demon_01 未通拦截在 qiMeng→ruMen
        var r = CharacterAdvancementService.applyExperience(
          character,
          10000000, // 覆盖 7 layer 累计 EXP 总和(~4.6M)+ 余量
          realmLookup: realmLookup,
          isLayerLocked: isLocked,
        );
        expect(r.layersGained, 0,
            reason: 'inner_demon_01 未通 → qiMeng→ruMen 被拦,EXP 留账');
        expect(character.realmTier, RealmTier.wuSheng);
        expect(character.realmLayer, RealmLayer.qiMeng);
        expect(character.experience, 10000000,
            reason: 'EXP 不归零(GDD §5.1 反留存焦虑)');

        // 逐关通关 inner_demon_01..06 → 每关通 → 升 1 layer。
        // qiMeng(0) → ruMen(1) → shuLian(2) → jingTong(3) → yuanShu(4) →
        // huaJing(5) → dengFeng(6),共 6 步,inner_demon_07 留 A1 飞升(P2.3
        // spec 接管,本测不验)。
        final expectedAfter = <(String, RealmLayer)>[
          ('stage_inner_demon_01', RealmLayer.ruMen),
          ('stage_inner_demon_02', RealmLayer.shuLian),
          ('stage_inner_demon_03', RealmLayer.jingTong),
          ('stage_inner_demon_04', RealmLayer.yuanShu),
          ('stage_inner_demon_05', RealmLayer.huaJing),
          ('stage_inner_demon_06', RealmLayer.dengFeng),
        ];
        for (final (stageId, nextLayer) in expectedAfter) {
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
          expect(r.layersGained, 1,
              reason: '$stageId 通关 → 应升 1 layer 至 wuSheng·${nextLayer.name}');
          expect(character.realmLayer, nextLayer,
              reason: '$stageId 通关后玩家 layer 应推到 ${nextLayer.name}');
        }

        // 6 步全部跑完后玩家应到 wuSheng·dengFeng,inner_demon_07 留 A1 飞升
        expect(character.realmTier, RealmTier.wuSheng);
        expect(character.realmLayer, RealmLayer.dengFeng);
      },
    );
  });
}
