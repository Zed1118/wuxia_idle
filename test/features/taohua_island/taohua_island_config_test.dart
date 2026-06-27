import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

void main() {
  final y = (loadYaml(_yaml) as YamlMap).cast<String, dynamic>();
  final cfg = TaohuaIslandConfig.fromYaml(y);

  test('解析 cap/解锁 + 4 建筑', () {
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
