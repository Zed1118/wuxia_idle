import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/scroll/phase0b_scroll_observation_app.dart';

void main() {
  testWidgets('scroll observation is explicitly non-gating', (tester) async {
    await tester.pumpWidget(
      const Phase0bScrollObservationApp(
        runId: 'widget-test',
        outputRoot: '/tmp/unused',
        durationScale: 1,
        autoClose: false,
        viewportId: 'desktop_1280x720',
        expectedWidth: 1280,
        expectedHeight: 720,
        enableRun: false,
      ),
    );
    await tester.pump();
    expect(find.textContaining('NOT A GAMEPLAY GATE'), findsOneWidget);
  });

  test('scroll runner preserves observation-only contract', () {
    final single = File(
      'scripts/run_phase0b_scroll_macos.sh',
    ).readAsStringSync();
    final matrix = File(
      'scripts/run_phase0b_scroll_matrix_macos.sh',
    ).readAsStringSync();
    expect(single, contains('PROBE_MODE=phase0b_scroll_profile'));
    expect(single, contains('.gate_eligible == false'));
    expect(single, contains('.workload.encounter_peaks == [6,10,21]'));
    expect(
      single,
      contains('.workload.scene_layer_logical_ops_per_frame == 18'),
    );
    expect(matrix, contains('expected 6 fresh summaries'));
    expect(
      matrix,
      contains('continuous_map_camera_and_local_art_load_observation_only'),
    );
  });
}
