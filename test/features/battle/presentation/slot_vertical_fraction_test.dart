import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

/// `slotVerticalFraction` 纯函数测(2026-06-25「1 怪居中 / 2 怪上下对称」)。
///
/// 锁死语义:竖直比例 = (slotIndex + 0.5) / teamSize。视觉队列布局(_TeamColumn)
/// 与弹道坐标(_slotFrac)共用此式,故此处一旦改回硬编码 3 或分母错位,
/// 居中/对称即破。
void main() {
  group('slotVerticalFraction', () {
    test('1 怪 → 居中(0.5)', () {
      expect(slotVerticalFraction(0, 1), closeTo(0.5, 1e-9));
    });

    test('2 怪 → 上下对称(0.25 / 0.75)', () {
      expect(slotVerticalFraction(0, 2), closeTo(0.25, 1e-9));
      expect(slotVerticalFraction(1, 2), closeTo(0.75, 1e-9));
      // 关于中线 0.5 对称
      final top = slotVerticalFraction(0, 2);
      final bottom = slotVerticalFraction(1, 2);
      expect(0.5 - top, closeTo(bottom - 0.5, 1e-9));
    });

    test('3 怪 → 1/6,3/6,5/6(保持原行为)', () {
      expect(slotVerticalFraction(0, 3), closeTo(1 / 6, 1e-9));
      expect(slotVerticalFraction(1, 3), closeTo(0.5, 1e-9));
      expect(slotVerticalFraction(2, 3), closeTo(5 / 6, 1e-9));
    });

    test('teamSize <= 0 兜底 0.5 防除零', () {
      expect(slotVerticalFraction(0, 0), 0.5);
      expect(slotVerticalFraction(0, -1), 0.5);
    });
  });
}
