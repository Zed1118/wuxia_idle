import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';

void main() {
  group('ProgressiveUnlockState', () {
    test(
      'maps the existing production visibility contract to three states',
      () {
        expect(
          resolveProgressiveUnlockState(visible: false, enabled: false),
          ProgressiveUnlockState.hidden,
        );
        expect(
          resolveProgressiveUnlockState(visible: true, enabled: false),
          ProgressiveUnlockState.heard,
        );
        expect(
          resolveProgressiveUnlockState(visible: true, enabled: true),
          ProgressiveUnlockState.open,
        );
      },
    );

    test('rejects an enabled route that is not visible', () {
      expect(
        () => resolveProgressiveUnlockState(visible: false, enabled: true),
        throwsStateError,
      );
    });
  });

  test('snapshot must cover all seven frozen capabilities exactly once', () {
    final states = {
      for (final id in ProgressiveUnlockId.values)
        id: ProgressiveUnlockState.hidden,
    };
    final snapshot = ProgressiveUnlockSnapshot(states);
    expect(snapshot.states, hasLength(7));

    states.remove(ProgressiveUnlockId.innerDemon);
    expect(() => ProgressiveUnlockSnapshot(states), throwsArgumentError);
  });
}
