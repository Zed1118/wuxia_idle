import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/qi_drain_effect.dart';

void main() {
  group('QiDrainEffect', () {
    test('扣减基于最大真气（§5.2 锁脉针=30% 最大真气），只降至零不为负', () {
      // 100 当前、140 最大 → 扣 round(0.30*140)=42 → 58
      expect(QiDrainEffect(pct: 0.30).applyTo(currentQi: 100, maxQi: 140), 58);
      // 10 当前扣 42 会为负 → 钳到 0（只降至零不为负）
      expect(QiDrainEffect(pct: 0.30).applyTo(currentQi: 10, maxQi: 140), 0);
    });

    test('比例上界 0.5 合法可构造（区间 (0, 0.5] 闭上界）', () {
      // 140 当前、140 最大 → 扣 round(0.5*140)=70 → 70
      expect(QiDrainEffect(pct: 0.5).applyTo(currentQi: 140, maxQi: 140), 70);
    });

    test('越界比例构造抛错（schema 硬界 ∈ (0, 0.5]）', () {
      expect(() => QiDrainEffect(pct: 0.0), throwsArgumentError);
      expect(() => QiDrainEffect(pct: 0.6), throwsArgumentError);
      expect(() => QiDrainEffect(pct: -0.1), throwsArgumentError);
    });
  });
}
