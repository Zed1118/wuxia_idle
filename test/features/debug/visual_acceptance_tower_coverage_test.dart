import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

/// 爬塔 audit 路由的规模真相源守卫(批 A · A0 解层数硬编码)。
///
/// `visual_acceptance_plan` 是纯元数据层拿不到 GameRepository,故层数落常量
/// [towerAuditFloorCount]。**没有这条守卫时,扩层是静默失效**:towers.yaml 加到
/// 49 层而常量仍是 30 → 第 31-49 层的敌立绘不进任何一轮目检,且不报任何错。
///
/// 体例照 `visual_acceptance_gauntlet_coverage_test`(断魂庄同类问题的既有解法)。
void main() {
  setUpAll(() async {
    Future<String> fileLoader(String path) async {
      final f = File(path);
      if (!await f.exists()) throw FileSystemException('不存在', path);
      return (await f.readAsString()).replaceAll('\r\n', '\n');
    }

    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  group('规模真相源', () {
    test('plan 里的层数常量与 towers.yaml 一致', () {
      final floors = GameRepository.instance.towerFloors;
      expect(floors, isNotEmpty, reason: 'towers.yaml 未加载,断言无意义');
      expect(
        towerAuditFloorCount,
        floors.length,
        reason:
            'visual_acceptance_plan 的 towerAuditFloorCount 与生产 '
            'towers.yaml(${floors.length} 层)漂移;'
            '塔增删层须同步该常量,否则新层的敌立绘不进任何一轮目检',
      );
    });

    test('towerMaxFloor 与 towerFloors.length 同源', () {
      final repo = GameRepository.instance;
      expect(
        repo.towerMaxFloor,
        repo.towerFloors.length,
        reason: 'towerMaxFloor 是层数唯一派生点,与列表长度不符说明派生逻辑被改坏',
      );
      expect(
        repo.towerFloors.last.floorIndex,
        repo.towerMaxFloor,
        reason: '红线保证 floorIndex 从 1 连续,末层 floorIndex 应等于最高层号',
      );
    });

    test('battle suite 为每层各出一条 route', () {
      final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.battle);
      final towerIds = ids
          .where((id) => id.startsWith(battleAuditTowerPrefix))
          .toList();

      expect(towerIds, hasLength(towerAuditFloorCount));
      expect(towerIds.toSet(), hasLength(towerAuditFloorCount));
      for (final id in towerIds) {
        expect(
          parseVisualRoute(id),
          VisualRoute.battleTowerAudit,
          reason: '$id 进了 battle suite 却解析不出路由,capture 会跑空',
        );
      }
    });

    test('route 覆盖的层号 == towers.yaml 的全部 floorIndex', () {
      final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.battle);
      final coveredFloors = <int>{};
      for (final id in ids) {
        final floor = battleAuditTowerFloor(id);
        if (floor != null) coveredFloors.add(floor);
      }
      final expected = GameRepository.instance.towerFloors
          .map((f) => f.floorIndex)
          .toSet();

      expect(
        coveredFloors,
        expected,
        reason:
            '塔层目检覆盖不全:route 覆盖 ${coveredFloors.length} 层,'
            'yaml 实有 ${expected.length} 层;'
            '漏网 = ${expected.difference(coveredFloors)}',
      );
    });
  });
}
