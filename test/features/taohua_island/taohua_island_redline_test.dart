import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';

/// 桃花岛一期红线测试（Task 3 RED→GREEN 闭环）。
///
/// 覆盖 [TaohuaIslandConfig.validate] 的所有校验规则：
/// - 合法配置不抛
/// - 各非法变体各自断言 [StateError]
void main() {
  // 已知合法 item defId 集合（覆盖 numbers.yaml taohua_island 段所有引用）
  const Set<String> knownIds = {
    'item_jingtie',
    'item_yaocao',
    'item_mojianshi',
    'item_xinxuejiejing',
    'item_jingyandan_small',
    'item_jingyandan_mid',
  };

  TaohuaIslandConfig parse(String yaml) {
    final y = (loadYaml(yaml) as YamlMap).cast<String, dynamic>();
    return TaohuaIslandConfig.fromYaml(y);
  }

  // ── 合法基准配置 ─────────────────────────────────────────────────────────
  test('合法配置 → 不抛', () {
    final cfg = parse(_validYaml);
    expect(() => TaohuaIslandConfig.validate(cfg, knownIds), returnsNormally);
  });

  // ── 数值红线 ─────────────────────────────────────────────────────────────
  test('source base_rate_per_hour 为负 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'base_rate_per_hour: 6.0',
      'base_rate_per_hour: -1.0',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  test('cap_base 为负 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'cap_base: 200',
      'cap_base: -1',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  test('max_level 为 0 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'max_level: 5',
      'max_level: 0',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  // ── processor 空 recipes → StateError ────────────────────────────────────
  test('processor 没有 recipes → StateError', () {
    final cfg = parse(_noRecipeYaml);
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  // ── recipe 数值红线 ───────────────────────────────────────────────────────
  test('recipe input_per_output = 0 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'input_per_output: 4.0',
      'input_per_output: 0.0',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  test('recipe rate_per_hour 为负 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'rate_per_hour: 1.5',
      'rate_per_hour: -0.5',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  test('recipe realm_unlock_index = 7 → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'realm_unlock_index: 0 }',
      'realm_unlock_index: 7 }',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  // ── 跨引用：recipe output_item 未知 → StateError ─────────────────────────
  test('recipe output_item 指向未知 defId → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'output_item: item_mojianshi',
      'output_item: item_unknown_xyz',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  // ── 跨引用：source output_item 未知 → StateError ─────────────────────────
  test('source output_item 指向未知 defId → StateError', () {
    final cfg = parse(_validYaml.replaceFirst(
      'output_item: item_jingtie',
      'output_item: item_ghost',
    ));
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });

  // ── 跨引用：processor input 无 source 供应 → StateError ──────────────────
  test('processor input_item 无 source 供应 → StateError', () {
    final cfg = parse(_noSupplyYaml);
    expect(
      () => TaohuaIslandConfig.validate(cfg, knownIds),
      throwsA(isA<StateError>()),
    );
  });
}

// ── YAML 夹具 ──────────────────────────────────────────────────────────────

/// 合法完整配置（含 source + processor 各两栋，4 recipe）
const _validYaml = '''
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
    upgrade_silver_base: 500
    upgrade_silver_per_level: 400
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
    upgrade_silver_base: 500
    upgrade_silver_per_level: 400
    upgrade_material_item: item_yaocao
    upgrade_material_base: 40
    realm_unlock_index: 0
  da_zao_tai:
    kind: processor
    input_item: item_jingtie
    cap_base: 80
    cap_per_level: 40
    max_level: 5
    upgrade_silver_base: 800
    upgrade_silver_per_level: 600
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
    upgrade_silver_base: 800
    upgrade_silver_per_level: 600
    upgrade_material_item: item_yaocao
    upgrade_material_base: 80
    recipes:
      - { recipe_id: brew_ningshen, output_item: item_jingyandan_small, input_per_output: 6.0,  rate_per_hour: 1.0, realm_unlock_index: 0 }
      - { recipe_id: brew_peiyuan,  output_item: item_jingyandan_mid,   input_per_output: 18.0, rate_per_hour: 0.3, realm_unlock_index: 3 }
''';

/// processor 无 recipes
const _noRecipeYaml = '''
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
    upgrade_silver_base: 500
    upgrade_silver_per_level: 400
    upgrade_material_item: item_jingtie
    upgrade_material_base: 40
    realm_unlock_index: 0
  da_zao_tai:
    kind: processor
    input_item: item_jingtie
    cap_base: 80
    cap_per_level: 40
    max_level: 5
    upgrade_silver_base: 800
    upgrade_silver_per_level: 600
    upgrade_material_item: item_jingtie
    upgrade_material_base: 80
    recipes: []
''';

/// processor(dan_fang) input_item=item_yaocao，但 source(tie_jiang_chang) 产 item_jingtie，无 source 供应 item_yaocao
const _noSupplyYaml = '''
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
    upgrade_silver_base: 500
    upgrade_silver_per_level: 400
    upgrade_material_item: item_jingtie
    upgrade_material_base: 40
    realm_unlock_index: 0
  dan_fang:
    kind: processor
    input_item: item_yaocao
    cap_base: 60
    cap_per_level: 30
    max_level: 5
    upgrade_silver_base: 800
    upgrade_silver_per_level: 600
    upgrade_material_item: item_yaocao
    upgrade_material_base: 80
    recipes:
      - { recipe_id: brew_ningshen, output_item: item_jingyandan_small, input_per_output: 6.0, rate_per_hour: 1.0, realm_unlock_index: 0 }
''';
