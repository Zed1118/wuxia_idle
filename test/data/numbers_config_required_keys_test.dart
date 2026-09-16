import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:yaml/yaml.dart';

Map<String, dynamic> _productionNumbers() =>
    deepConvertYaml(loadYaml(File('data/numbers.yaml').readAsStringSync()))
        as Map<String, dynamic>;

void main() {
  final production = _productionNumbers();
  final redLines = (production['combat'] as Map)['red_lines'] as Map;

  test('生产数值配置无需任何红线兜底即可完整加载', () {
    expect(() => NumbersConfig.fromYaml(_productionNumbers()), returnsNormally);
  });

  for (final key in redLines.keys.cast<String>()) {
    test('缺少 combat.red_lines.$key 时拒绝加载并报告路径', () {
      final copy = _productionNumbers();
      ((copy['combat'] as Map)['red_lines'] as Map).remove(key);
      expect(
        () => NumbersConfig.fromYaml(copy),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            '缺项路径',
            contains('combat.red_lines.$key'),
          ),
        ),
      );
    });
  }
}
