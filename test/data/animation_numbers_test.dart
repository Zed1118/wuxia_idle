import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';

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

  test('AnimationNumbers.defaults 含 keyMomentHoldMs', () {
    expect(AnimationNumbers.defaults.keyMomentHoldMs, 400);
  });

  test('fromYaml 解析 key_moment_hold_ms', () {
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
      'key_moment_hold_ms': 555,
    });
    expect(n.keyMomentHoldMs, 555);
  });

  test('fromYaml 缺 key_moment_hold_ms 走默认 400', () {
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
    expect(n.keyMomentHoldMs, 400);
  });

  // 一键扫荡 T1：关间过场间隔（连播逐关切换时的短暂停顿）。
  test('AnimationNumbers.defaults 含 sweepInterBattleGapMs', () {
    expect(AnimationNumbers.defaults.sweepInterBattleGapMs, 150);
  });

  test('fromYaml 解析 sweep_inter_battle_gap_ms', () {
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
      'sweep_inter_battle_gap_ms': 222,
      'readable_victory_min_ms': 9999,
    });
    expect(n.sweepInterBattleGapMs, 222);
    expect(n.readableVictoryMinMs, 9999);
  });

  test('fromYaml 缺可选动画参数走默认值', () {
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
    expect(n.sweepInterBattleGapMs, 150);
    expect(n.readableVictoryMinMs, 10000);
  });

  // 飘字随速度缩放:防快档(rapid/快进)飘字时长 > 拍间隔致跨拍重叠。
  // 慢档(relaxed/normal)飘字 1000 ≤ 拍长,手感保持不变。
  group('effectivePopupMs 随拍间隔 clamp', () {
    const n = AnimationNumbers.defaults; // damagePopupMs = 1000

    test('normal(1000)/relaxed(1250) 飘字不缩(1000 ≤ 拍)', () {
      expect(n.effectivePopupMs(1000), 1000);
      expect(n.effectivePopupMs(1250), 1000);
    });

    test('brisk(750) 飘字收缩到拍长', () {
      expect(n.effectivePopupMs(750), 750);
    });

    test('rapid(500) 飘字收缩到拍长', () {
      expect(n.effectivePopupMs(500), 500);
    });

    test('fast-forward(100) 飘字收缩到拍长', () {
      expect(n.effectivePopupMs(100), 100);
    });

    // 语义不变量:任何玩家可选速度档下,有效飘字时长都不超过该档拍间隔
    // (消除跨拍渗漏)。断言约束而非具体数字,防未来加/改速度档时静默回归。
    test('全速度档不变量:有效飘字 ≤ 该档拍间隔', () {
      for (final speed in BattlePlaybackSpeed.values) {
        final interval =
            const GameplaySettings(
                  battlePlaybackSpeed: BattlePlaybackSpeed.normal,
                )
                .copyWith(battlePlaybackSpeed: speed)
                .scaledBattleIntervalMs(n.actionIntervalMs);
        expect(
          n.effectivePopupMs(interval) <= interval,
          isTrue,
          reason: '$speed 档飘字 ${n.effectivePopupMs(interval)} > 拍 $interval',
        );
      }
    });
  });
}
