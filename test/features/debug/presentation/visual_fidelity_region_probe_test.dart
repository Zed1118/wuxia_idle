import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_fidelity_region_probe.dart';

void main() {
  testWidgets('collects actual keyed battle region rectangles', (tester) async {
    late BuildContext probeContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              probeContext = context;
              return const Column(
                children: [
                  SizedBox(
                    key: ValueKey('battle_header_surface'),
                    width: 200,
                    height: 20,
                  ),
                  SizedBox(
                    key: ValueKey('battle_scene_stage_viewport'),
                    width: 200,
                    height: 60,
                  ),
                  SizedBox(
                    key: ValueKey('battle_command_desk'),
                    width: 200,
                    height: 20,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final regions = collectVisualFidelityRegions(probeContext);

    expect(regions['header'], containsPair('height', 20.0));
    expect(regions['battlefield'], containsPair('y', 20.0));
    expect(regions['command_desk'], containsPair('y', 80.0));
  });

  testWidgets('emits one JSON region line after keyed layout mounts', (
    tester,
  ) async {
    final messages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: VisualFidelityRegionProbe(
            child: Column(
              children: [
                SizedBox(key: ValueKey('battle_header_surface'), height: 20),
                SizedBox(
                  key: ValueKey('battle_scene_stage_viewport'),
                  height: 60,
                ),
                SizedBox(key: ValueKey('battle_command_desk'), height: 20),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final regionLines = messages.where(
        (message) => message.startsWith('VISUAL_FIDELITY_REGIONS: '),
      );
      expect(regionLines, hasLength(1));
      expect(regionLines.single, contains('"command_desk"'));
    } finally {
      debugPrint = originalDebugPrint;
    }
  });
}
