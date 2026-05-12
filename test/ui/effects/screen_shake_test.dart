import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/ui/effects/screen_shake.dart';

void main() {
  group('screenShakeOffset', () {
    test('t=0 returns zero offset', () {
      final offset = screenShakeOffset(t: 0);

      expect(offset.dx, 0);
      expect(offset.dy, 0);
    });

    test('middle value uses sine wave and half y offset', () {
      final offset = screenShakeOffset(t: 0.25, amplitude: 4);

      expect(offset.dx, closeTo(4, 0.000001));
      expect(offset.dy, closeTo(2, 0.000001));
    });

    test('boundary t=1 returns near zero offset', () {
      final offset = screenShakeOffset(t: 1, amplitude: 4);

      expect(offset.dx, closeTo(0, 0.000001));
      expect(offset.dy, closeTo(0, 0.000001));
    });
  });
}
