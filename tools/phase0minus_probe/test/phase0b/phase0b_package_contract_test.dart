import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Phase 0B package keeps review-only claim and signs embedded assets',
    () {
      final source = File(
        'scripts/build_phase0b_art_review_macos.sh',
      ).readAsStringSync();

      expect(source, contains('PROBE_MODE=phase0b_gallery'));
      expect(
        source,
        contains('claim=concept_review_only_not_runtime_animation_gate'),
      );
      expect(source, contains('EMBEDDED_MANIFEST_MISSING'));
      expect(source, contains('EMBEDDED_MANIFEST_DRIFT'));
      expect(source, contains('SHA256SUMS.txt'));
    },
  );
}
