import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';

/// 桃花岛 cap 自洽红线测（2026-06-25 「cap 对齐 72h」拍板后落地）。
///
/// 语义不变量(非瞬时数字)：用 **真实 numbers.yaml** 配置,验证
/// 「离开 cap_hours 一次性 settle」== 「同样时长分成 N 段持续 settle」。
///
/// 这正是 §5.5「在线=离线」的可量化保证:成品仓收获量与玩家是否中途回岛
/// 无关。等式成立的前提是各仓 cap ≥ 该建筑满速 × cap_hours × level——
/// 即用户拍板的「cap 对齐 72h」。任何把 cap 调小到无法容下整段产出的回退
/// (或在不提 cap 的情况下提产速)都会让一次性结算被 cap 提前截断 → 此测变红。
///
/// 与既有 island_production_service_test.dart 的 case 4 区别:那条用合成的
/// 「无限源料 + 无限成品仓」config 验线性区可加性(只证 settle 函数本身的代数
/// 性质);本测用真实 cap 数值,证 cap 配置本身足够大、不会成为 offline≠online
/// 的来源。两条互补,缺一不可。
void main() {
  late TaohuaIslandConfig cfg;

  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
    cfg = GameRepository.instance.numbers.taohuaIsland;
  });

  IslandBuildingState byType(
          List<IslandBuildingState> states, BuildingType type) =>
      states.firstWhere((s) => s.type == type);

  /// 构造满供应链快照:四源 + 三加工,全部 level=[level],各加工激活指定配方。
  List<IslandBuildingState> seed(
    int level, {
    required String daRecipe,
    required String danRecipe,
  }) =>
      [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = level
          ..stored = 0,
        IslandBuildingState()
          ..type = BuildingType.caoYaoYuan
          ..level = level
          ..stored = 0,
        IslandBuildingState()
          ..type = BuildingType.muGongFang
          ..level = level
          ..stored = 0,
        IslandBuildingState()
          ..type = BuildingType.lingQuan
          ..level = level
          ..stored = 0,
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = level
          ..stored = 0
          ..activeRecipeId = daRecipe,
        IslandBuildingState()
          ..type = BuildingType.danFang
          ..level = level
          ..stored = 0
          ..activeRecipeId = danRecipe,
        IslandBuildingState()
          ..type = BuildingType.zhuZaoTai
          ..level = level
          ..stored = 0
          ..activeRecipeId = 'forge_kaifeng_fucai',
      ];

  /// 一次性结算整段 [hours]。founderRealmIndex=6 → 全配方解锁,不受境界门槛干扰。
  List<IslandBuildingState> once(int level, String da, String dan, double hours) =>
      IslandProductionService.settle(
        states: seed(level, daRecipe: da, danRecipe: dan),
        config: cfg,
        elapsedHours: hours,
        founderRealmIndex: 6,
      );

  /// 分 [n] 段持续结算(模拟玩家中途多次回岛 settle),累积到同样 [hours]。
  List<IslandBuildingState> chunked(
      int level, String da, String dan, double hours, int n) {
    var st = seed(level, daRecipe: da, danRecipe: dan);
    final step = hours / n;
    for (var i = 0; i < n; i++) {
      st = IslandProductionService.settle(
        states: st,
        config: cfg,
        elapsedHours: step,
        founderRealmIndex: 6,
      );
    }
    return st;
  }

  // 这两个常量在 test 注册期(setUpAll 之前)就要用于展开循环,故不能读 late cfg;
  // 用字面值,并在「配置前提」test 内对真实配置复核,防 numbers.yaml 漂移。
  const capHours = 72;
  const maxLevel = 5;

  group('cap 对齐 72h:一次性 settle == 分块 settle(offline=online 红线)', () {
    // 配方组合:realm0 默认配方 + realm3 高阶配方,均纳入覆盖。
    final recipeCombos = <(String, String, String)>[
      ('realm0 默认(磨剑石/凝神丹)', 'forge_mojianshi', 'brew_ningshen'),
      ('realm3 高阶(心血结晶/培元丹)', 'forge_xinxue', 'brew_peiyuan'),
    ];

    test('配置前提:cap_hours=72 且 max_level=5(漂移则同步本测常量)', () {
      expect(cfg.capHours, capHours, reason: 'cap_hours 改了须同步本测常量与派生 cap');
      expect(cfg.buildingOf(BuildingType.daZaoTai).maxLevel, maxLevel,
          reason: 'max_level 改了须同步本测 maxLevel 循环上界');
    });

    for (final (label, da, dan) in recipeCombos) {
      for (var level = 1; level <= maxLevel; level++) {
        test('$label · level=$level:72h 一次性 == 72×1h 分块', () {
          final r1 = once(level, da, dan, capHours.toDouble());
          final rN = chunked(level, da, dan, capHours.toDouble(), 72);

          for (final type in BuildingType.values) {
            expect(
              byType(r1, type).stored,
              closeTo(byType(rN, type).stored, 1e-3),
              reason: '$type 在 $label/level=$level 下,'
                  '一次性结算与分块结算 stored 应一致'
                  '(不一致 = cap 被一次性结算提前截断,违 offline=online)',
            );
          }
        });
      }
    }

    test('防回退:成品确实拿满 72h 理论量(cap 未截断 realm0 配方)', () {
      // 磨剑石 = rate(1.5) × level × 72;凝神丹 = rate(1.0) × level × 72。
      // 若 cap 回退到旧值(打造台 80 / 丹房 60)→ 此处会被 cap 截断 → 断言失败。
      for (var level = 1; level <= 3; level++) {
        final r = once(level, 'forge_mojianshi', 'brew_ningshen', 72);
        expect(
          byType(r, BuildingType.daZaoTai).stored,
          closeTo(1.5 * level * 72, 1e-3),
          reason: 'level=$level 磨剑石应满产 ${1.5 * level * 72},未被成品 cap 截断',
        );
        expect(
          byType(r, BuildingType.danFang).stored,
          closeTo(1.0 * level * 72, 1e-3),
          reason: 'level=$level 凝神丹应满产 ${1.0 * level * 72},未被成品 cap 截断',
        );
      }
    });
  });
}
