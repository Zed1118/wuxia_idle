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

  test('encounters arrive in fixed off-screen batches', () {
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(0, 0.2), 4);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(0, 0.8), 6);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(1, 0.3), 5);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(1, 0.9), 10);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(2, 0.7), 12);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(2, 1.0), 20);
    expect(Phase0bScrollReviewGame.spawnedPopulationAt(2, 1.3), 21);
    expect(Phase0bScrollReviewGame.activePopulationAt(0, 2.8), 6);
    expect(Phase0bScrollReviewGame.activePopulationAt(0, 2.9), 0);
    expect(Phase0bScrollReviewGame.activePopulationAt(1, 4.0), 0);
    expect(Phase0bScrollReviewGame.activePopulationAt(2, 5.2), 0);
  });

  test('readability pocket changes actor position before depth rendering', () {
    const hero = Offset(640, 510);
    expect(
      Phase0bScrollReviewGame.applyReadabilityPocket(
        const Offset(630, 520),
        hero,
        2,
      ),
      const Offset(528, 520),
    );
    expect(
      Phase0bScrollReviewGame.applyReadabilityPocket(
        const Offset(800, 520),
        hero,
        2,
      ),
      const Offset(800, 520),
    );
  });

  test('scene layers use independent parallax without slicing panorama', () {
    expect(Phase0bScrollReviewGame.parallaxScreenX(1000, 500, 0.18), 910);
    expect(Phase0bScrollReviewGame.parallaxScreenX(1000, 500, 0.72), 640);
    expect(Phase0bScrollReviewGame.parallaxScreenX(1000, 500, 1.04), 480);
  });

  test('pose alpha inset is compensated so visible feet meet ground', () {
    expect(
      Phase0bScrollReviewGame.visibleBottomInsetRatio('hero', 0),
      closeTo(28 / 470, 0.0001),
    );
    expect(
      Phase0bScrollReviewGame.visibleBottomInsetRatio('bandit', 3),
      closeTo(86 / 441, 0.0001),
    );
    expect(Phase0bScrollReviewGame.visibleBottomInsetRatio('unknown', 0), 0);
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
