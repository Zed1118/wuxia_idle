import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('AnimationNumbers.defaults 含 projectileMs/hitFlashMs', () {
    expect(AnimationNumbers.defaults.projectileMs, 260);
    expect(AnimationNumbers.defaults.hitFlashMs, 150);
  });

  test('fromYaml 解析 projectile_ms/hit_flash_ms', () {
    final n = AnimationNumbers.fromYaml(<String, dynamic>{
      'attack_rush_ms': 1,
      'attack_hold_ms': 1,
      'attack_retreat_ms': 1,
      'attack_rush_offset_px': 1,
      'damage_popup_float_px': 1,
      'damage_popup_ms': 1,
      'action_interval_ms': 1,
      'fast_forward_interval_ms': 1,
      'shake_offset_px': 1,
      'shake_duration_ms': 1,
      'critical_font_scale': 1,
      'projectile_ms': 300,
      'hit_flash_ms': 120,
    });
    expect(n.projectileMs, 300);
    expect(n.hitFlashMs, 120);
  });

  test('fromYaml 缺 projectile_ms/hit_flash_ms 走默认', () {
    final n = AnimationNumbers.fromYaml(<String, dynamic>{
      'attack_rush_ms': 1,
      'attack_hold_ms': 1,
      'attack_retreat_ms': 1,
      'attack_rush_offset_px': 1,
      'damage_popup_float_px': 1,
      'damage_popup_ms': 1,
      'action_interval_ms': 1,
      'fast_forward_interval_ms': 1,
      'shake_offset_px': 1,
      'shake_duration_ms': 1,
      'critical_font_scale': 1,
    });
    expect(n.projectileMs, 260);
    expect(n.hitFlashMs, 150);
  });
}
