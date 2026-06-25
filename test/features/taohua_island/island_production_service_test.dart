import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';

/// 测试用配置工厂。允许调参以隔离各场景（cap、产速、境界门槛）。
///
/// 拓扑：
///   tieJiangChang (source, 产 jingtie, baseRate=6)
///     → daZaoTai (processor, 吃 jingtie, recipe forge_mojianshi 产 mojianshi)
TaohuaIslandConfig _config({
  int capHours = 72,
  double tieRate = 6,
  int tieCapBase = 200,
  int tieCapPerLevel = 100,
  int zaoCapBase = 100,
  int zaoCapPerLevel = 50,
  double forgeRate = 3,
  double forgeInputPerOutput = 4,
  int forgeRealmUnlock = 0,
  int tieRealmUnlock = 0,
}) {
  return TaohuaIslandConfig(
    capHours: capHours,
    unlockChapterIndex: 0,
    buildings: {
      BuildingType.tieJiangChang: BuildingConfig(
        type: BuildingType.tieJiangChang,
        kind: BuildingKind.source,
        outputItem: 'jingtie',
        inputItem: null,
        baseRatePerHour: tieRate,
        capBase: tieCapBase,
        capPerLevel: tieCapPerLevel,
        maxLevel: 5,
        upgradeSilverLevels: const [100, 150, 200, 250],
        upgradeRealmLevels: const [0, 0, 0, 0],
        upgradeMaterialItem: 'jingtie',
        upgradeMaterialBase: 10,
        realmUnlockIndex: tieRealmUnlock,
        recipes: const [],
      ),
      BuildingType.daZaoTai: BuildingConfig(
        type: BuildingType.daZaoTai,
        kind: BuildingKind.processor,
        outputItem: null,
        inputItem: 'jingtie',
        baseRatePerHour: 0,
        capBase: zaoCapBase,
        capPerLevel: zaoCapPerLevel,
        maxLevel: 5,
        upgradeSilverLevels: const [100, 150, 200, 250],
        upgradeRealmLevels: const [0, 0, 0, 0],
        upgradeMaterialItem: 'jingtie',
        upgradeMaterialBase: 10,
        realmUnlockIndex: 0,
        recipes: [
          RecipeDef(
            recipeId: 'forge_mojianshi',
            outputItem: 'mojianshi',
            inputPerOutput: forgeInputPerOutput,
            ratePerHour: forgeRate,
            realmUnlockIndex: forgeRealmUnlock,
          ),
        ],
      ),
    },
  );
}

IslandBuildingState _byType(
        List<IslandBuildingState> states, BuildingType type) =>
    states.firstWhere((s) => s.type == type);

void main() {
  group('IslandProductionService.settle', () {
    test('1. 原料滴落 + cap 封顶', () {
      final cfg = _config(tieRate: 6, tieCapBase: 200);
      final states = [
        IslandBuildingState()..type = BuildingType.tieJiangChang..level = 1,
      ];

      // 线性区：5h × 6/h × level1 = 30
      final r5 = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 5,
        founderRealmIndex: 6,
      );
      expect(_byType(r5, BuildingType.tieJiangChang).stored, closeTo(30, 1e-9));

      // 挂超 cap：cap = 200，挂 1000h 也只到 200
      final rCap = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 1000, // 会被 capHours 先夹到 72
        founderRealmIndex: 6,
      );
      expect(_byType(rCap, BuildingType.tieJiangChang).stored, 200);
    });

    test('2. 加工守恒：成品增量×inputPerOutput == 铁匠厂被扣量（铁匠厂不产以隔离）', () {
      // 隔离铁匠厂自身产出，使源料 = 固定可知量，守恒断言才干净。
      // 铁匠厂 baseRate=0 → 本窗口不产精铁，源料恒为预置量。
      final cfg = _config(tieRate: 0, forgeInputPerOutput: 4, zaoCapBase: 1000);
      final states = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 30, // 预置精铁
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = 1
          ..activeRecipeId = 'forge_mojianshi',
      ];

      final r = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 100, // 想产很多，但受源料 30/4=7.5 限
        founderRealmIndex: 6,
      );
      final zao = _byType(r, BuildingType.daZaoTai);
      final tie = _byType(r, BuildingType.tieJiangChang);

      // byMaterial = 30/4 = 7.5；want=3×72=216；cap=1000 不限 → made=7.5
      expect(zao.stored, closeTo(7.5, 1e-6));
      // 守恒：30 - 7.5×4 = 0
      expect(tie.stored, closeTo(0, 1e-6));
      expect(30 - tie.stored, closeTo(zao.stored * 4, 1e-6));
    });

    test('2b. 源料真正成为瓶颈（铁匠厂未解锁不产）', () {
      // 铁匠厂 realmUnlockIndex 设高(5)，founderRealmIndex=0 时不产，源料固定为预置量。
      final cfg = _config(
        tieRealmUnlock: 5, // 高境界才解锁 → founderRealmIndex=0 时不产
        tieRate: 6,
        zaoCapBase: 1000,
        zaoCapPerLevel: 50,
        forgeInputPerOutput: 4,
        forgeRate: 3,
      );
      final states = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 10, // 不再产，固定 10
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = 1
          ..activeRecipeId = 'forge_mojianshi',
      ];
      final r = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 100,
        founderRealmIndex: 0,
      );
      final zao = _byType(r, BuildingType.daZaoTai);
      final tie = _byType(r, BuildingType.tieJiangChang);
      // byMaterial = 10/4 = 2.5；want=3×72=216；cap=1000 不限 → made=2.5
      expect(zao.stored, closeTo(2.5, 1e-6));
      expect(tie.stored, closeTo(0, 1e-6)); // 10 - 2.5×4 = 0
    });

    test('3. 加工受成品 cap 限', () {
      final cfg = _config(zaoCapBase: 50, forgeRate: 3);
      final states = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 100000, // 源料充裕
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = 1
          ..stored = 48 // 接近 cap=50
          ..activeRecipeId = 'forge_mojianshi',
      ];
      final r = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 72,
        founderRealmIndex: 6,
      );
      // 成品封到 cap=50，不超
      expect(_byType(r, BuildingType.daZaoTai).stored, closeTo(50, 1e-9));
    });

    test('4. offline=online 可加性（线性区：源料充裕 + 成品仓远未满）', () {
      // 线性区前提：源料海量(不会被扣空)，成品 cap 极大(不会满)。
      final cfg = _config(
        zaoCapBase: 1000000,
        zaoCapPerLevel: 0,
        forgeRate: 3,
      );
      List<IslandBuildingState> seed() => [
            IslandBuildingState()
              ..type = BuildingType.tieJiangChang
              ..level = 1
              ..stored = 100000000, // 海量源料
            IslandBuildingState()
              ..type = BuildingType.daZaoTai
              ..level = 1
              ..activeRecipeId = 'forge_mojianshi',
          ];

      final once = IslandProductionService.settle(
        states: seed(),
        config: cfg,
        elapsedHours: 4,
        founderRealmIndex: 6,
      );
      final twice2a = IslandProductionService.settle(
        states: seed(),
        config: cfg,
        elapsedHours: 2,
        founderRealmIndex: 6,
      );
      final twice = IslandProductionService.settle(
        states: twice2a,
        config: cfg,
        elapsedHours: 2,
        founderRealmIndex: 6,
      );

      expect(
        _byType(once, BuildingType.daZaoTai).stored,
        closeTo(_byType(twice, BuildingType.daZaoTai).stored, 1e-6),
      );
    });

    test('5. capHours 封顶（100h == 72h）', () {
      final cfg = _config(capHours: 72);
      List<IslandBuildingState> seed() => [
            IslandBuildingState()
              ..type = BuildingType.tieJiangChang
              ..level = 1
              ..stored = 100000,
            IslandBuildingState()
              ..type = BuildingType.daZaoTai
              ..level = 1
              ..activeRecipeId = 'forge_mojianshi',
          ];
      final r100 = IslandProductionService.settle(
        states: seed(),
        config: cfg,
        elapsedHours: 100,
        founderRealmIndex: 6,
      );
      final r72 = IslandProductionService.settle(
        states: seed(),
        config: cfg,
        elapsedHours: 72,
        founderRealmIndex: 6,
      );
      for (final type in [BuildingType.tieJiangChang, BuildingType.daZaoTai]) {
        expect(
          _byType(r100, type).stored,
          closeTo(_byType(r72, type).stored, 1e-9),
          reason: '$type stored 100h 应等于 72h',
        );
      }
    });

    test('6. 无 activeRecipe 的加工建筑不产、不耗源料', () {
      final cfg = _config();
      final states = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 500,
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = 1,
        // activeRecipeId 为 null
      ];
      final r = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 72,
        founderRealmIndex: 6,
      );
      // 打造台不产成品
      expect(_byType(r, BuildingType.daZaoTai).stored, 0);
      // 铁匠厂源料只受自身产出影响、不被打造台扣：500 + 6×72=432 → 932，cap=200
      expect(_byType(r, BuildingType.tieJiangChang).stored, 200);
    });

    test('7. 境界门槛：配方 realm_unlock_index=3 而 founderRealmIndex=0 → 暂停', () {
      final cfg = _config(forgeRealmUnlock: 3);
      final states = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 500,
        IslandBuildingState()
          ..type = BuildingType.daZaoTai
          ..level = 1
          ..activeRecipeId = 'forge_mojianshi',
      ];
      final r = IslandProductionService.settle(
        states: states,
        config: cfg,
        elapsedHours: 72,
        founderRealmIndex: 0, // < 3 → 配方未达境界
      );
      // 打造台暂停：不产
      expect(_byType(r, BuildingType.daZaoTai).stored, 0);
      // 源料不被扣（铁匠厂自身产出 + cap）：500+432→cap 200，未被打造台动
      expect(_byType(r, BuildingType.tieJiangChang).stored, 200);
    });

    test('纯函数：不修改输入 states', () {
      final cfg = _config();
      final input = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 0,
      ];
      IslandProductionService.settle(
        states: input,
        config: cfg,
        elapsedHours: 10,
        founderRealmIndex: 6,
      );
      expect(input.first.stored, 0, reason: '输入不应被修改');
    });

    test('t<=0 直接返回副本', () {
      final cfg = _config();
      final input = [
        IslandBuildingState()
          ..type = BuildingType.tieJiangChang
          ..level = 1
          ..stored = 42,
      ];
      final r = IslandProductionService.settle(
        states: input,
        config: cfg,
        elapsedHours: 0,
        founderRealmIndex: 6,
      );
      expect(r.first.stored, 42);
      expect(identical(r.first, input.first), isFalse, reason: '应为副本');
    });
  });
}
