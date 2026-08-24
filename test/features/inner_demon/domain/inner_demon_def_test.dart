import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/inner_demon_def.dart';

void main() {
  group('InnerDemonDef.fromYaml 退役配置拒绝', () {
    test('存在旧 failure_penalty 段即拒绝', () {
      expect(
        () => InnerDemonDef.fromYaml({
          'failure_penalty': {'main_cultivation_multiplier': 0.90},
        }),
        throwsFormatException,
      );
    });

    test('空段与 null 值也不能静默兼容', () {
      expect(
        () => InnerDemonDef.fromYaml({'failure_penalty': <String, dynamic>{}}),
        throwsFormatException,
      );
      expect(
        () => InnerDemonDef.fromYaml({'failure_penalty': null}),
        throwsFormatException,
      );
    });

    test('缺少退役段仍可解析空配置', () {
      final def = InnerDemonDef.fromYaml(const {});
      expect(def.mirrorBuffPerStage, isEmpty);
      expect(def.unlockTriggers, isEmpty);
    });
  });
}
