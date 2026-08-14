import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/load/phase0b_art_load_app.dart';

void main() {
  test('art load timeline keeps 1 plus 20 plus 1 actors', () {
    for (final phase in <double>[0, 2.4, 3.9, 5.2, 7.4]) {
      expect(Phase0bArtLoadGame.actorCountAt(phase), 22);
    }
  });

  test('ordinary actors preserve the hero readability pocket', () {
    for (final phase in <double>[0, 2.4, 3.2, 3.8, 5.2, 7.4]) {
      for (final position in Phase0bArtLoadGame.ordinaryPositionsAt(phase)) {
        final dx = (position.dx - 640).abs();
        final dy = (position.dy - 510).abs();
        expect(
          dx >= 100 || dy >= 72,
          isTrue,
          reason: 'phase=$phase position=$position enters the hero pocket',
        );
      }
    }
  });

  testWidgets('art load watermark prevents Gate confusion', (tester) async {
    await tester.pumpWidget(
      const Phase0bArtLoadApp(
        runId: 'widget-test',
        outputRoot: 'build/test-results',
        durationScale: 0.001,
        autoClose: false,
        viewportId: 'desktop_1280x720',
        expectedWidth: 1280,
        expectedHeight: 720,
        buildCommit: 'test-commit',
        assetSha256: {
          'background': 'bg-sha',
          'founder': 'founder-sha',
          'bandit': 'bandit-sha',
          'elite': 'elite-sha',
        },
        enableRun: false,
      ),
    );
    await tester.pump();

    expect(find.textContaining('ART LOAD REPLAY'), findsOneWidget);
    expect(find.textContaining('NOT GAMEPLAY GATE'), findsOneWidget);
    expect(find.textContaining('NOT BONE RIG'), findsOneWidget);
  });
}
