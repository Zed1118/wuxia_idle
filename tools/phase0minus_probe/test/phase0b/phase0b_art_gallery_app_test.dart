import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/phase0b_art_gallery_app.dart';

void main() {
  testWidgets('gallery keeps concept boundaries visible while navigating', (
    tester,
  ) async {
    await tester.pumpWidget(const Phase0bArtGalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('01 / Gather gameplay keyframe'), findsOneWidget);
    expect(
      find.textContaining('not damage or runtime evidence'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phase0b-gallery-next')));
    await tester.pumpAndSettle();

    expect(find.text('02 / Clear gameplay keyframe'), findsOneWidget);
    expect(find.textContaining('not an animated asset'), findsOneWidget);
  });
}
