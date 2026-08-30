import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_image.dart';

import '../../../../support/test_data.dart';

void main() {
  setUp(loadTestGameRepository);
  tearDown(GameRepository.resetForTest);

  testWidgets('24-active production standees use bounded decode images', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = (await tester.runAsync(
      () => Phase0aDebugBattleFixture.loadM4Density(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
      ),
    ))!;
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(controller: controller, autoStep: false),
      ),
    );
    await tester.pump();

    final actorImages = tester.widgetList<WuxiaImage>(find.byType(WuxiaImage));
    expect(actorImages, hasLength(25));
    expect(actorImages.map((image) => image.assetPath).toSet(), {
      for (final actor in [
        controller.state.player,
        ...controller.state.enemies,
      ])
        controller.roster.visualFor(actor.id).assetPath,
    });
    expect(actorImages.every((image) => image.fit == BoxFit.contain), isTrue);

    final decodedImages = tester.widgetList<Image>(
      find.descendant(
        of: find.byType(WuxiaImage),
        matching: find.byType(Image),
      ),
    );
    expect(decodedImages, hasLength(25));
    for (final image in decodedImages) {
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, lessThanOrEqualTo(256));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
