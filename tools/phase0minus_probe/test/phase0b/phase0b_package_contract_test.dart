import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 0B package keeps review-only claim and signs embedded assets', () {
    final source = File(
      'scripts/build_phase0b_art_review_macos.sh',
    ).readAsStringSync();

    expect(source, contains('PROBE_MODE=phase0b_gallery'));
    expect(source, contains('PROBE_MODE=phase0b_runtime'));
    expect(source, contains('PROBE_MODE=phase0b_joint_compare'));
    expect(source, contains('PROBE_MODE=phase0b_art_load'));
    expect(source, contains('PROBE_MODE=phase0b_scroll_review'));
    expect(source, contains('scroll_panorama_mountain_to_gate_v1.png'));
    expect(source, contains('连续地图长卷_3600x720.png'));
    expect(
      source,
      contains(
        'claim=concept_camera_v2_art_load_and_rejected_auto_cutout_review_only',
      ),
    );
    expect(source, contains('EMBEDDED_MANIFEST_MISSING'));
    expect(source, contains('EMBEDDED_MANIFEST_DRIFT'));
    expect(source, contains('SHA256SUMS.txt'));
    expect(source, contains('EMBEDDED_RUNTIME_ASSET_MISSING'));
  });
}
