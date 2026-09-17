import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

import '../support/test_data.dart';

void main() {
  test('HitTierConfig 解析 yaml', () {
    final c = HitTierConfig.fromYaml(const {
      'caption_peak_size': 68,
      'caption_glow_blur': 12.0,
      'closeup_scale': 1.10,
      'closeup_pulse_ms': 220,
    });
    expect(c.captionPeakSize, 68);
    expect(c.captionGlowBlur, 12.0);
    expect(c.closeupScale, 1.10);
    expect(c.closeupPulseMs, 220);
  });
  test('生产完整配置保留原有演出数值', () {
    final c = HitTierConfig.fromYaml(
      loadTestNumbersSection(['animation', 'hit_tier']),
    );
    expect(c.captionPeakSize, 68);
    expect(c.closeupScale, 1.10);
  });

  for (final key in [
    'caption_peak_size',
    'caption_glow_blur',
    'closeup_scale',
    'closeup_pulse_ms',
  ]) {
    test('演出数值缺 $key 明确拒绝加载', () {
      final yaml = loadTestNumbersSection(['animation', 'hit_tier'])
        ..remove(key);
      expect(
        () => HitTierConfig.fromYaml(yaml),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            '缺失字段路径',
            contains('animation.hit_tier.$key'),
          ),
        ),
      );
    });
  }
}
