import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  group('TreasureDropConfig', () {
    test('解析 min_tier', () {
      final c = TreasureDropConfig.fromYaml({'min_tier': 'zhongQi'});
      expect(c.minTier, EquipmentTier.zhongQi);
    });
    test('空/缺字段兜底重器', () {
      expect(TreasureDropConfig.fromYaml(null).minTier, EquipmentTier.zhongQi);
      expect(TreasureDropConfig.fromYaml({}).minTier, EquipmentTier.zhongQi);
    });
    test('非法 tier 名抛 ArgumentError(yaml typo 不静默)', () {
      expect(
        () => TreasureDropConfig.fromYaml({'min_tier': 'zhongqi'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('HeroCameraConfig', () {
    test('HC1 全字段解析', () {
      final c = HeroCameraConfig.fromYaml({
        'hold_seconds': 3.0,
        'portrait_slide_px': 48,
        'portrait_scale_from': 0.88,
      });
      expect(c.holdSeconds, 3.0);
      expect(c.portraitSlidePx, 48.0);
      expect(c.portraitScaleFrom, 0.88);
    });

    test('HC2 null/空 → empty 兜底', () {
      expect(HeroCameraConfig.fromYaml(null).holdSeconds, 3.0);
      expect(HeroCameraConfig.fromYaml({}).portraitScaleFrom, 0.88);
    });

    test('HC3 portraitScaleFrom < 1.0(缩放起点必须小于终点)', () {
      expect(HeroCameraConfig.empty.portraitScaleFrom, lessThan(1.0));
    });
  });

  group('production data/numbers.yaml heroCamera 解析', () {
    setUpAll(() async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    test('HC4 holdSeconds 在 (0, 4] 区间', () {
      final cfg = GameRepository.instance.numbers.heroCamera;
      expect(cfg.holdSeconds, greaterThan(0));
      expect(cfg.holdSeconds, lessThanOrEqualTo(4.0));
    });

    test('HC5 portraitScaleFrom < 1.0', () {
      final cfg = GameRepository.instance.numbers.heroCamera;
      expect(cfg.portraitScaleFrom, lessThan(1.0));
    });
  });
}
