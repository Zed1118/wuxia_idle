import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/scroll/phase0b_scroll_review_app.dart';

void main() {
  test(
    'scroll review is three screens wide with escalating local encounters',
    () {
      expect(Phase0bScrollReviewGame.worldWidth, 3600);
      expect(Phase0bScrollReviewGame.encounterPopulationByRegion(), [
        6,
        10,
        21,
      ]);
    },
  );

  test('camera dead zone follows and clamps inside the world', () {
    expect(Phase0bScrollReviewGame.nextCameraLeft(0, 600), 0);
    expect(Phase0bScrollReviewGame.nextCameraLeft(0, 1000), greaterThan(0));
    var camera = 2200.0;
    for (var index = 0; index < 120; index++) {
      camera = Phase0bScrollReviewGame.nextCameraLeft(camera, 3560);
    }
    expect(camera, closeTo(2320, 0.01));
  });

  testWidgets('scroll review exposes input and non-final-art boundary', (
    tester,
  ) async {
    await tester.pumpWidget(const Phase0bScrollReviewApp());
    await tester.pump();

    expect(find.textContaining('SCROLLING WORLD REVIEW'), findsOneWidget);
    expect(find.textContaining('WASD'), findsOneWidget);
    expect(find.textContaining('NOT FINAL MAP ART'), findsOneWidget);
  });
}
