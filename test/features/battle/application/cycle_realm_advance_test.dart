import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart';

import '../../../support/test_data.dart';

/// 批 B 周目境界段推进（spec 2026-08-01-tower-extension 拍板 #5）。
///
/// 纯 [StageBattleSetup.buildEnemyTeam] 层，不落 Isar。断言写语义
/// （推进量 = tiersFor(cycle)、clamp 武圣、三轴联动、非白名单零回归），
/// 不钉具体敌人数值，防 stages.yaml 调数后假红。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  RealmTier advanced(RealmTier base, int tiers) {
    final idx = base.index + tiers;
    return idx >= RealmTier.wuSheng.index
        ? RealmTier.wuSheng
        : RealmTier.values[idx];
  }

  group('批 B 境界段推进 · buildEnemyTeam', () {
    test('入口白名单 = 轻功对决 + 群战守城（主线/爬塔/心魔不推进）', () {
      expect(StageBattleSetup.realmAdvanceStageTypes, {
        StageType.lightFoot,
        StageType.massBattle,
      });
    });

    test('cycle=1 开启推进 → 境界不变（tiersFor(1)=0 零变化）', () {
      final stage = GameRepository.instance.getStage('stage_light_foot_01');
      final base = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
      final adv = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        advanceRealmPerCycle: true,
      );
      for (var i = 0; i < base.length; i++) {
        expect(adv[i].realmTier, base[i].realmTier);
        expect(adv[i].internalForce, base[i].internalForce);
        expect(adv[i].defenseRate, base[i].defenseRate);
      }
    });

    test('cycle=2 推进 → tier +tiersFor(2)，内力/防御率随境界表联动', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      final stage = GameRepository.instance.getStage('stage_light_foot_01');
      // 对照组同 cycle 同词条（mainline 表两边一致），唯一差异 = 推进开关。
      final plain = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 2,
      );
      final adv = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 2,
        advanceRealmPerCycle: true,
      );
      for (var i = 0; i < adv.length; i++) {
        final baseTier = stage.enemyTeam[i].realmTier;
        final effTier = advanced(baseTier, ra.tiersFor(2));
        expect(
          effTier.index - baseTier.index,
          ra.tiersFor(2),
          reason: '轻功 01 敌为低段位，+3 不应撞 clamp',
        );
        expect(adv[i].realmTier, effTier);
        // 内力派生自境界表：同层(layer)下高 tier 的 internal_force_max 更大。
        expect(adv[i].internalForce, greaterThan(plain[i].internalForce));
        // 防御率档随 tier 抬升（词条 yuti 两边同加，差值即境界档差）。
        final tierDelta =
            RealmUtils.defenseRateOf(effTier) -
            RealmUtils.defenseRateOf(baseTier);
        expect(
          adv[i].defenseRate - plain[i].defenseRate,
          closeTo(tierDelta, 1e-9),
        );
      }
    });

    test('cycle=3 推进 → +tiersFor(3) 且 clamp 武圣', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      for (final stageId in ['stage_light_foot_05', 'stage_mass_battle_05']) {
        final stage = GameRepository.instance.getStage(stageId);
        final adv = StageBattleSetup.buildEnemyTeam(
          stage.enemyTeam,
          cycleIndex: 3,
          advanceRealmPerCycle: true,
        );
        for (var i = 0; i < adv.length; i++) {
          expect(
            adv[i].realmTier,
            advanced(stage.enemyTeam[i].realmTier, ra.tiersFor(3)),
            reason: '$stageId 敌 $i cycle3 推进后应 clamp 武圣顶格',
          );
        }
      }
    });

    test('主线语义零回归：cycle=2 不开推进 → tier 保持 yaml 原值', () {
      final stage = GameRepository.instance.getStage('stage_light_foot_01');
      final plain = StageBattleSetup.buildEnemyTeam(
        stage.enemyTeam,
        cycleIndex: 2,
      );
      for (var i = 0; i < plain.length; i++) {
        expect(plain[i].realmTier, stage.enemyTeam[i].realmTier);
      }
    });

    test('爬塔零回归：isTower + cycle=2 默认不推进', () {
      final floor = GameRepository.instance.towerFloors.first;
      final plain = StageBattleSetup.buildEnemyTeam(
        floor.enemyTeam,
        cycleIndex: 2,
        isTower: true,
      );
      for (var i = 0; i < plain.length; i++) {
        expect(plain[i].realmTier, floor.enemyTeam[i].realmTier);
      }
    });
  });

  group('批 B 三系锁死守卫（B3 · §5.3）：掉落基准阶不吃境界推进', () {
    // 摸底实证（2026-08-04）：4 入口掉落基准阶全部锚定静态配置——
    // 稀有彩头 baseTier = equipmentTierForRealm(stageDef.requiredRealm)
    // （battle_resolution.dart，关卡静态字段）；断魂庄奖励 = 3 件固定 defId；
    // 远征零装备掉落。周目推进只改 BattleCharacter.realmTier（战斗内），
    // 不入掉落路径 → 结构性满足「推进不得让掉落越出玩家可装备阶」。
    // 本测钉死该语义：若未来有人把推进后的敌境界接进掉落基准，此处红。
    test(
      '稀有彩头 baseTier 锚 stageDef.requiredRealm 静态值，不消费敌 BattleCharacter 境界',
      () {
        final source = File(
          'lib/features/battle/application/battle_resolution.dart',
        ).readAsStringSync();
        expect(
          source,
          contains('baseTier: equipmentTierForRealm(stageDef.requiredRealm)'),
          reason:
              '彩头基准阶必须锚关卡静态 requiredRealm（§5.3），'
              '不得改为战斗队列推进后的 realmTier',
        );
      },
    );

    test('轻功/群战关 requiredRealm 与 yaml 敌境界一致（推进前静态锚自洽）', () {
      for (final stageId in [
        'stage_light_foot_01',
        'stage_light_foot_05',
        'stage_mass_battle_01',
        'stage_mass_battle_05',
      ]) {
        final stage = GameRepository.instance.getStage(stageId);
        final maxEnemyTier = stage.enemyTeam
            .map((e) => e.realmTier.index)
            .reduce((a, b) => a >= b ? a : b);
        expect(
          stage.requiredRealm.index,
          lessThanOrEqualTo(maxEnemyTier),
          reason:
              '$stageId requiredRealm 应 ≤ yaml 敌最高境界'
              '（掉落阶提前发放守卫，同塔 A4 口径）',
        );
      }
    });
  });

  group('批 B 境界段推进 · buildEnemyTeamsPerWave（群战守城）', () {
    test('massBattle cycle=2 → 每波敌全员推进', () {
      final ra = GameRepository.instance.numbers.cycleEvolution.realmAdvance;
      final stage = GameRepository.instance.getStage('stage_mass_battle_01');
      final waves = StageBattleSetup.buildEnemyTeamsPerWave(
        stage,
        cycleIndex: 2,
      );
      expect(waves, isNotEmpty);
      final templates = stage.enemyTeam;
      for (final wave in waves) {
        for (var j = 0; j < wave.length; j++) {
          final baseTier = templates[j % templates.length].realmTier;
          expect(wave[j].realmTier, advanced(baseTier, ra.tiersFor(2)));
        }
      }
    });
  });
}
