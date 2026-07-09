import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/game_loop/monthly_tick.dart';

void main() {
  group('MonthlyTickCoordinator', () {
    test('register/clear maintain registeredCount', () {
      final coordinator = MonthlyTickCoordinator();

      expect(coordinator.registeredCount, 0);

      coordinator.register((_) async {});
      coordinator.register((_) async {});
      expect(coordinator.registeredCount, 2);

      coordinator.clear();
      expect(coordinator.registeredCount, 0);
    });

    test(
      'tick invokes callbacks sequentially with the same DateTime',
      () async {
        final coordinator = MonthlyTickCoordinator();
        final now = DateTime(2026, 7, 10, 9, 30);
        final calls = <String>[];

        coordinator.register((dt) async {
          expect(dt, same(now));
          calls.add('a:start');
          await Future<void>.delayed(Duration.zero);
          calls.add('a:end');
        });
        coordinator.register((dt) async {
          expect(dt, same(now));
          calls.add('b');
        });

        await coordinator.tick(now);

        expect(calls, const ['a:start', 'a:end', 'b']);
      },
    );

    test(
      'callback failure is logged and does not block later callbacks',
      () async {
        final coordinator = MonthlyTickCoordinator();
        final oldDebugPrint = debugPrint;
        final logs = <String>[];
        addTearDown(() => debugPrint = oldDebugPrint);
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };

        final calls = <String>[];
        coordinator.register((_) async {
          calls.add('before');
        });
        coordinator.register((_) async {
          throw StateError('broken monthly tick');
        });
        coordinator.register((_) async {
          calls.add('after');
        });

        await coordinator.tick(DateTime(2026, 7));

        expect(calls, const ['before', 'after']);
        expect(
          logs.single,
          contains(
            'MonthlyTickCoordinator callback failed: Bad state: broken monthly tick',
          ),
        );
      },
    );
  });
}
