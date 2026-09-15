import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/mainline_onboarding_harness.dart';

void main() {
  testWidgets(
    'legal fresh-save chain records actual outcomes including unproven Blackwind',
    (tester) async {
      final output = Platform.environment['P2_ONBOARDING_EVIDENCE_DIR'];
      await runOnboardingChain(
        tester,
        requireVictoriesThrough: 1,
        checkpoints: output == null ? null : Directory('$output/checkpoints'),
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
