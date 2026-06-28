import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(GameRepository.resetForTest);

  final y = (loadYaml(_yaml) as YamlMap).cast<String, dynamic>();
  final cfg = TaohuaIslandConfig.fromYaml(y);

  test('解析 fixture cap/解锁 + 4 建筑', () {
    expect(cfg.capHours, 72);
    expect(cfg.unlockChapterIndex, 1);
    expect(cfg.buildings.length, 4);
    final tie = cfg.buildingOf(BuildingType.tieJiangChang);
    expect(tie.kind, BuildingKind.source);
    expect(tie.outputItem, 'item_jingtie');
    expect(tie.capFor(1), 200);
    expect(tie.capFor(3), 400);
  });

  test('processor 配方 + 境界门槛', () {
    final dz = cfg.buildingOf(BuildingType.daZaoTai);
    expect(dz.kind, BuildingKind.processor);
    expect(dz.inputItem, 'item_jingtie');
    expect(dz.recipes.length, 2);
    final r = dz.recipeById('forge_mojianshi')!;
    expect(r.outputItem, 'item_mojianshi');
    expect(r.realmUnlockIndex, 0);
    expect(dz.recipeById('forge_xinxue')!.realmUnlockIndex, 3);
  });

  test('升级成本随等级', () {
    final tie = cfg.buildingOf(BuildingType.tieJiangChang);
    expect(tie.upgradeSilverFor(1), 500);
    expect(tie.upgradeSilverFor(2), 1200); // 节奏 B 前低后高曲线 index=level-1
    // upgradeMaterialFor = base × level（线性递增，未改）
    expect(tie.upgradeMaterialFor(1), 40);
    expect(tie.upgradeMaterialFor(2), 80);
    expect(tie.upgradeMaterialFor(5), 200);
  });

  test('phase 2 island building yaml keys parse', () {
    expect(buildingTypeFromYamlKey('mu_gong_fang'), BuildingType.muGongFang);
    expect(buildingTypeFromYamlKey('ling_quan'), BuildingType.lingQuan);
    expect(buildingTypeFromYamlKey('zhu_zao_tai'), BuildingType.zhuZaoTai);
  });

  test('GameRepository 加载 phase 2 桃花岛建筑配置', () async {
    final repo = await GameRepository.loadAllDefs();
    final cfg = GameRepository.instance.numbers.taohuaIsland;

    expect(cfg.buildings.length, 7);

    final muGongFang = cfg.buildingOf(BuildingType.muGongFang);
    expect(muGongFang.kind, BuildingKind.source);
    expect(muGongFang.outputItem, 'item_mucai');

    final lingQuan = cfg.buildingOf(BuildingType.lingQuan);
    expect(lingQuan.kind, BuildingKind.source);
    expect(lingQuan.outputItem, 'item_lingquanshui');

    final zhuZaoTai = cfg.buildingOf(BuildingType.zhuZaoTai);
    expect(zhuZaoTai.kind, BuildingKind.processor);
    expect(zhuZaoTai.inputItem, 'item_mucai');
    expect(
      zhuZaoTai.recipes.map((r) => r.outputItem),
      containsAll(['item_kaifeng_fucai', 'item_xingnang_buji']),
    );

    final daZaoTai = cfg.buildingOf(BuildingType.daZaoTai);
    expect(daZaoTai.inputItem, 'item_jingtie');
    expect(
      daZaoTai.recipeById('forge_mojianshi')!.outputItem,
      'item_mojianshi',
    );
    expect(
      daZaoTai.recipeById('forge_xinxue')!.outputItem,
      'item_xinxuejiejing',
    );
    expect(daZaoTai.recipeById('forge_duancai')!.outputItem, 'item_duancai');

    final danFang = cfg.buildingOf(BuildingType.danFang);
    expect(danFang.inputItem, 'item_yaocao');
    expect(
      danFang.recipeById('brew_ningshen')!.outputItem,
      'item_jingyandan_small',
    );
    expect(
      danFang.recipeById('brew_peiyuan')!.outputItem,
      'item_jingyandan_mid',
    );
    expect(
      danFang.recipeById('brew_liaoshang')!.outputItem,
      'item_liaoshangdan',
    );

    final productionItemRefs = <String>{
      for (final b in cfg.buildings.values) ...[
        if (b.outputItem != null) b.outputItem!,
        if (b.inputItem != null) b.inputItem!,
        for (final r in b.recipes) r.outputItem,
      ],
    };
    const phaseTwoItemIds = {
      'item_mucai',
      'item_lingquanshui',
      'item_liaoshangdan',
      'item_duancai',
      'item_kaifeng_fucai',
      'item_xingnang_buji',
    };
    expect(repo.itemDefs.keys, containsAll(phaseTwoItemIds));
    expect(productionItemRefs, containsAll(phaseTwoItemIds));
  });

  test('GameRepository phase 2 桃花岛真实 7 建筑全满累计 = 88,800 银', () async {
    await GameRepository.loadAllDefs();
    final cfg = GameRepository.instance.numbers.taohuaIsland;

    int fullCost(BuildingType type) {
      final building = cfg.buildingOf(type);
      var total = 0;
      for (var level = 1; level < building.maxLevel; level++) {
        total += building.upgradeSilverFor(level);
      }
      return total;
    }

    final sourceTypes = cfg.buildings.values
        .where((building) => building.kind == BuildingKind.source)
        .map((building) => building.type)
        .toList();
    final processorTypes = cfg.buildings.values
        .where((building) => building.kind == BuildingKind.processor)
        .map((building) => building.type)
        .toList();

    expect(sourceTypes, hasLength(4));
    expect(processorTypes, hasLength(3));
    expect(
      sourceTypes.fold<int>(0, (sum, type) => sum + fullCost(type)),
      42000,
      reason: '4 座 source × 10,500',
    );
    expect(
      processorTypes.fold<int>(0, (sum, type) => sum + fullCost(type)),
      46800,
      reason: '3 座 processor × 15,600',
    );
    expect(
      cfg.buildings.keys.fold<int>(0, (sum, type) => sum + fullCost(type)),
      88800,
    );
  });
}

const _yaml = '''
cap_hours: 72
unlock_chapter_index: 1
buildings:
  tie_jiang_chang:
    kind: source
    output_item: item_jingtie
    base_rate_per_hour: 6.0
    cap_base: 200
    cap_per_level: 100
    max_level: 5
    upgrade_silver_levels: [500, 1200, 2800, 6000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_jingtie
    upgrade_material_base: 40
    realm_unlock_index: 0
  cao_yao_yuan:
    kind: source
    output_item: item_yaocao
    base_rate_per_hour: 6.0
    cap_base: 200
    cap_per_level: 100
    max_level: 5
    upgrade_silver_levels: [500, 1200, 2800, 6000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_yaocao
    upgrade_material_base: 40
    realm_unlock_index: 0
  da_zao_tai:
    kind: processor
    input_item: item_jingtie
    cap_base: 80
    cap_per_level: 40
    max_level: 5
    upgrade_silver_levels: [800, 1800, 4000, 9000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_jingtie
    upgrade_material_base: 80
    recipes:
      - { recipe_id: forge_mojianshi, output_item: item_mojianshi,     input_per_output: 4.0,  rate_per_hour: 1.5, realm_unlock_index: 0 }
      - { recipe_id: forge_xinxue,    output_item: item_xinxuejiejing, input_per_output: 20.0, rate_per_hour: 0.4, realm_unlock_index: 3 }
  dan_fang:
    kind: processor
    input_item: item_yaocao
    cap_base: 60
    cap_per_level: 30
    max_level: 5
    upgrade_silver_levels: [800, 1800, 4000, 9000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_yaocao
    upgrade_material_base: 80
    recipes:
      - { recipe_id: brew_ningshen, output_item: item_jingyandan_small, input_per_output: 6.0,  rate_per_hour: 1.0, realm_unlock_index: 0 }
      - { recipe_id: brew_peiyuan,  output_item: item_jingyandan_mid,   input_per_output: 18.0, rate_per_hour: 0.3, realm_unlock_index: 3 }
''';
