import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

/// 桃花岛升级成本「节奏 B」红线测（前低后高曲线 + 按等级分阶境界 gate）。
///
/// B 节奏(2026-06-25 用户拍板)：
/// - 升级银两成本改 per-level 显式数组(才能前低后高陡增,线性公式做不到)。
/// - 新增按等级分阶的境界 gate：升到 L_n+1 需祖师达对应 realm index。
/// - 配方比率(input_per_output)/材料成本(base×level)/产速均不动。
void main() {
  final y = (loadYaml(_yaml) as YamlMap).cast<String, dynamic>();
  final cfg = TaohuaIslandConfig.fromYaml(y);

  group('节奏 B：升级银两 per-level 曲线', () {
    test('source 建筑前低后高曲线 [500, 1200, 2800, 6000]', () {
      final tie = cfg.buildingOf(BuildingType.tieJiangChang);
      expect(tie.upgradeSilverFor(1), 500, reason: 'L1→2 低门槛');
      expect(tie.upgradeSilverFor(2), 1200);
      expect(tie.upgradeSilverFor(3), 2800);
      expect(tie.upgradeSilverFor(4), 6000, reason: 'L4→5 陡增');
    });

    test('processor 建筑前低后高曲线 [800, 1800, 4000, 9000]', () {
      final dz = cfg.buildingOf(BuildingType.daZaoTai);
      expect(dz.upgradeSilverFor(1), 800);
      expect(dz.upgradeSilverFor(2), 1800);
      expect(dz.upgradeSilverFor(3), 4000);
      expect(dz.upgradeSilverFor(4), 9000, reason: 'L4→5 陡增');
    });

    int fullCost(BuildingType t) {
      final b = cfg.buildingOf(t);
      var total = 0;
      for (var l = 1; l <= b.maxLevel - 1; l++) {
        total += b.upgradeSilverFor(l);
      }
      return total;
    }

    test('source 全满累计 = 10,500 银/座', () {
      expect(fullCost(BuildingType.tieJiangChang), 10500);
    });

    test('processor 全满累计 = 15,600 银/座', () {
      expect(fullCost(BuildingType.daZaoTai), 15600);
    });

    test('四座建筑全满累计 = 52,200 银（2×10,500 + 2×15,600）', () {
      final total = fullCost(BuildingType.tieJiangChang) +
          fullCost(BuildingType.caoYaoYuan) +
          fullCost(BuildingType.daZaoTai) +
          fullCost(BuildingType.danFang);
      expect(total, 52200);
    });
  });

  group('节奏 B：按等级分阶境界 gate', () {
    test('source upgradeRealmFor [0, 1, 2, 3]', () {
      final tie = cfg.buildingOf(BuildingType.tieJiangChang);
      expect(tie.upgradeRealmFor(1), 0, reason: 'L1→2 学徒即可');
      expect(tie.upgradeRealmFor(2), 1, reason: 'L2→3 需三流');
      expect(tie.upgradeRealmFor(3), 2, reason: 'L3→4 需二流');
      expect(tie.upgradeRealmFor(4), 3, reason: 'L4→5 需一流(realm3)');
    });

    test('processor upgradeRealmFor [0, 1, 2, 3]', () {
      final dz = cfg.buildingOf(BuildingType.daZaoTai);
      expect(dz.upgradeRealmFor(4), 3,
          reason: '升满 L5 需一流，与高阶配方 realm3 同步解锁');
    });
  });

  group('节奏 B：config 校验', () {
    // loadYaml 返回 unmodifiable map，故用文本替换构造非法配置（replaceFirst
    // 只改 tie_jiang_chang，单建筑越界即足够触发 validate 抛错）。
    TaohuaIslandConfig parse(String yamlText) => TaohuaIslandConfig.fromYaml(
        (loadYaml(yamlText) as YamlMap).cast<String, dynamic>());

    test('upgrade_silver_levels 长度 ≠ max_level-1 → 抛错', () {
      final bad = _yaml.replaceFirst(
        'upgrade_silver_levels: [500, 1200, 2800, 6000]',
        'upgrade_silver_levels: [500, 1200]',
      );
      expect(
        () => TaohuaIslandConfig.validate(parse(bad), _knownItems),
        throwsStateError,
      );
    });

    test('upgrade_realm_levels 长度 ≠ max_level-1 → 抛错', () {
      final bad = _yaml.replaceFirst(
        'upgrade_realm_levels: [0, 1, 2, 3]',
        'upgrade_realm_levels: [0, 1, 2]',
      );
      expect(
        () => TaohuaIslandConfig.validate(parse(bad), _knownItems),
        throwsStateError,
      );
    });

    test('upgrade_realm_levels 非单调递增 → 抛错', () {
      final bad = _yaml.replaceFirst(
        'upgrade_realm_levels: [0, 1, 2, 3]',
        'upgrade_realm_levels: [0, 2, 1, 3]',
      );
      expect(
        () => TaohuaIslandConfig.validate(parse(bad), _knownItems),
        throwsStateError,
      );
    });

    test('合法配置 validate 通过', () {
      expect(
        () => TaohuaIslandConfig.validate(cfg, _knownItems),
        returnsNormally,
      );
    });
  });
}

const _knownItems = <String>{
  'item_jingtie',
  'item_yaocao',
  'item_mojianshi',
  'item_xinxuejiejing',
  'item_jingyandan_small',
  'item_jingyandan_mid',
};

const _yaml = '''
cap_hours: 72
unlock_chapter_index: 1
buildings:
  tie_jiang_chang:
    kind: source
    output_item: item_jingtie
    base_rate_per_hour: 6.0
    cap_base: 450
    cap_per_level: 450
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
    cap_base: 450
    cap_per_level: 450
    max_level: 5
    upgrade_silver_levels: [500, 1200, 2800, 6000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_yaocao
    upgrade_material_base: 40
    realm_unlock_index: 0
  da_zao_tai:
    kind: processor
    input_item: item_jingtie
    cap_base: 120
    cap_per_level: 120
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
    cap_base: 80
    cap_per_level: 80
    max_level: 5
    upgrade_silver_levels: [800, 1800, 4000, 9000]
    upgrade_realm_levels: [0, 1, 2, 3]
    upgrade_material_item: item_yaocao
    upgrade_material_base: 80
    recipes:
      - { recipe_id: brew_ningshen, output_item: item_jingyandan_small, input_per_output: 6.0,  rate_per_hour: 1.0, realm_unlock_index: 0 }
      - { recipe_id: brew_peiyuan,  output_item: item_jingyandan_mid,   input_per_output: 18.0, rate_per_hour: 0.3, realm_unlock_index: 3 }
''';
