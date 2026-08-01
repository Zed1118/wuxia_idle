import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';

/// 断魂庄敌立绘 audit 路由(BACKLOG §二#5 前半)。
///
/// 补此路由前,断魂庄 7 张敌立绘**从未进过任何一轮目检**——既有 audit 路由只有
/// `battle_audit_stage`(主线/轻功/群战)与 `battle_audit_tower`,而断魂庄敌队
/// 不在 `stageDefs` 里(随 `BossGauntletConfig.enemyTeams` 独立解析),两条都够不着。
///
/// 本测的重点不是「路由能解析」,而是**这批路由真的把每张立绘都摆进了战斗屏**:
/// 逐关次跑生产场景工厂,取右队 iconPath 求并集,与 `boss_gauntlets.yaml` 里
/// 全部敌人的 iconPath 全集比对。任何一张漏出路由覆盖,这条就红。
void main() {
  setUpAll(() async {
    Future<String> fileLoader(String path) async {
      final f = File(path);
      if (!await f.exists()) throw FileSystemException('不存在', path);
      return (await f.readAsString()).replaceAll('\r\n', '\n');
    }

    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  group('route 解析', () {
    test('battle_audit_gauntlet_NN 解析到 battleGauntletAudit', () {
      expect(
        parseVisualRoute('battle_audit_gauntlet_01'),
        VisualRoute.battleGauntletAudit,
      );
      expect(battleAuditGauntletStage('battle_audit_gauntlet_01'), 1);
      expect(battleAuditGauntletStage('battle_audit_gauntlet_03'), 3);
    });

    test('非法后缀与他类前缀不误吞', () {
      // 0/负数会让下游 stages[i-1] 越界,必须判无效而不是兜底成 1
      expect(battleAuditGauntletStage('battle_audit_gauntlet_00'), isNull);
      expect(battleAuditGauntletStage('battle_audit_gauntlet_-1'), isNull);
      expect(battleAuditGauntletStage('battle_audit_gauntlet_'), isNull);
      expect(battleAuditGauntletStage('battle_audit_gauntlet_x'), isNull);
      // 不能把主线/塔的 audit id 吞进断魂庄分支
      expect(battleAuditGauntletStage('battle_audit_stage_01_01'), isNull);
      expect(battleAuditGauntletStage('battle_audit_tower_01'), isNull);
      // 反向:断魂庄 id 也不能被主线/塔的解析器认领
      expect(battleAuditStageId('battle_audit_gauntlet_01'), isNull);
      expect(battleAuditTowerFloor('battle_audit_gauntlet_01'), isNull);
    });
  });

  group('规模真相源', () {
    test('plan 里的关次常量与 boss_gauntlets.yaml 一致', () {
      final config = GameRepository.instance.bossGauntletConfig;
      expect(config, isNotNull, reason: 'boss_gauntlets.yaml 未加载,断言无意义');
      expect(
        gauntletAuditStageCount,
        config!.stages.length,
        reason:
            'visual_acceptance_plan 的 gauntletAuditStageCount 与生产 '
            'boss_gauntlets.yaml stages(${config.stages.length} 关次)漂移;'
            '断魂庄增删关次须同步该常量,否则新关次的敌立绘不进任何一轮目检',
      );
    });

    test('battle suite 为每个关次各出一条 route', () {
      final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.battle);
      final gauntletIds = ids
          .where((id) => id.startsWith(battleAuditGauntletPrefix))
          .toList();

      expect(gauntletIds, hasLength(gauntletAuditStageCount));
      expect(gauntletIds.toSet(), hasLength(gauntletAuditStageCount));
      for (final id in gauntletIds) {
        expect(
          parseVisualRoute(id),
          VisualRoute.battleGauntletAudit,
          reason: '$id 进了 battle suite 却解析不出路由,capture 会跑空',
        );
      }
    });
  });

  group('立绘覆盖(本批真实目的)', () {
    test('三条 route 的右队并集 == boss_gauntlets 全部敌人立绘', () {
      final config = GameRepository.instance.bossGauntletConfig!;

      // 期望集:yaml 里所有敌队的全部 iconPath
      // EnemyDef.iconPath 非空(BattleCharacter.iconPath 才可空),故只滤空串
      final expected = <String>{};
      for (final team in config.enemyTeams.values) {
        for (final enemy in team) {
          if (enemy.iconPath.isNotEmpty) expected.add(enemy.iconPath);
        }
      }
      expect(expected, isNotEmpty, reason: '断魂庄敌人零立绘,覆盖断言无意义');

      // 实得集:逐关次跑生产场景工厂取右队
      final covered = <String>{};
      for (var stage = 1; stage <= gauntletAuditStageCount; stage++) {
        final (_, right) = BattleScenarioData.scenarioGauntletStandeeAudit(
          stage,
        );
        expect(right, isNotEmpty, reason: '关次 $stage 右队为空,该 route 截不到敌立绘');
        for (final c in right) {
          final icon = c.iconPath;
          if (icon != null && icon.isNotEmpty) covered.add(icon);
        }
      }

      expect(
        covered,
        expected,
        reason:
            '断魂庄立绘覆盖不全:route 覆盖 ${covered.length} 张,'
            'yaml 实有 ${expected.length} 张;'
            '漏网 = ${expected.difference(covered)}',
      );
    });

    test('精英关三人 / Boss 关单人,阵列规模随生产配置', () {
      final config = GameRepository.instance.bossGauntletConfig!;
      for (var stage = 1; stage <= gauntletAuditStageCount; stage++) {
        final teamId = config.stages[stage - 1].enemyTeamId;
        final defs = config.enemyTeams[teamId]!;
        final (_, right) = BattleScenarioData.scenarioGauntletStandeeAudit(
          stage,
        );
        // buildEnemyTeam 上限 3 人,故期望值取 min
        final expectedSize = defs.length < 3 ? defs.length : 3;
        expect(
          right,
          hasLength(expectedSize),
          reason: '关次 $stage($teamId) 右队人数与生产配置不符,站位目检结论会失真',
        );
      }
    });
  });
}
