import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

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
  test('缺段回落默认（防御 fallback）', () {
    final c = HitTierConfig.fromYaml(const {});
    expect(c.captionPeakSize, 68);
    expect(c.closeupScale, 1.10);
  });
}
