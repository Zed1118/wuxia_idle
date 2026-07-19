import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:yaml/yaml.dart';

/// 语义守卫（2026-07-19 决议 1A）：闭关经验的境界倍率必须逐阶 ≥ passive_idle
/// 倍率，且最优闭关图基础经验速率不劣于离线基础速率——否则「开着游戏挂闭关」
/// 严格劣于「关游戏等离线」（速率倒挂，progression 量化报告 §五.1 实锤）。
/// 写约束语义不钉具体数字，防未来调参再倒挂。
void main() {
  YamlMap loadNumbers() =>
      loadYaml(File('data/numbers.yaml').readAsStringSync()) as YamlMap;

  test('闭关经验倍率逐阶 ≥ passive_idle 倍率（防速率倒挂·约束语义）', () {
    final root = loadNumbers();
    final retreat = root['retreat'] as YamlMap;
    final passive = root['passive_idle'] as YamlMap;
    final expScale = (retreat['experience_realm_scale_per_tier'] as num)
        .toDouble();
    final passiveScale = (passive['realm_scale_per_tier'] as num).toDouble();

    expect(
      expScale,
      greaterThanOrEqualTo(passiveScale),
      reason: '闭关经验每阶倍率低于离线即速率倒挂',
    );
    var retreatCompound = 1.0;
    var passiveCompound = 1.0;
    for (var i = 0; i < RealmTier.values.length - 1; i++) {
      retreatCompound *= expScale;
      passiveCompound *= passiveScale;
      expect(
        retreatCompound,
        greaterThanOrEqualTo(passiveCompound),
        reason: '第 ${i + 1} 阶复合倍率倒挂',
      );
    }
  });

  test('最优闭关图基础经验速率 ≥ 离线基础速率（同基数下闭关不劣）', () {
    final root = loadNumbers();
    final retreat = root['retreat'] as YamlMap;
    final passive = root['passive_idle'] as YamlMap;
    final maps = retreat['maps'] as YamlList;
    final maxMapExpPerHour = maps
        .map(
          (m) =>
              (((m as YamlMap)['base_outputs']
                          as YamlMap)['experience_per_hour']
                      as num)
                  .toDouble(),
        )
        .reduce((a, b) => a > b ? a : b);
    final passiveBase = (passive['base_exp_per_hour'] as num).toDouble();

    expect(
      maxMapExpPerHour,
      greaterThanOrEqualTo(passiveBase),
      reason: '所有闭关图基础经验速率都低于离线基础速率',
    );
  });
}
