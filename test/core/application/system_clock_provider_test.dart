import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';

/// T19b 技术债清账:systemClockProvider 默认 + override 注 fake clock 测族。
void main() {
  group('SystemClock', () {
    test('R3.1 SystemClock.now() 返当前时间(σ < 2s)', () {
      const clock = SystemClock();
      final delta = clock.now().difference(DateTime.now()).abs();
      expect(delta.inSeconds, lessThan(2));
    });

    test('R3.2 systemClockProvider override 注 FakeClock → 固定返期值', () {
      final fixed = DateTime(2026, 5, 25, 10);
      final container = ProviderContainer(
        overrides: [
          systemClockProvider.overrideWithValue(_FakeClock(fixed)),
        ],
      );
      addTearDown(container.dispose);

      final clock = container.read(systemClockProvider);
      expect(clock.now(), fixed);
    });
  });
}

class _FakeClock extends SystemClock {
  const _FakeClock(this._fixed);
  final DateTime _fixed;
  @override
  DateTime now() => _fixed;
}
