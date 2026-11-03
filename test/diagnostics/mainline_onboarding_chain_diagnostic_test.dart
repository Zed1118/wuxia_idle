import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/mainline_onboarding_harness.dart';

void main() {
  testWidgets(
    'legal fresh-save chain records actual outcomes including unproven Blackwind',
    (tester) async {
      final environment = Platform.environment;
      final output = environment['P2_ONBOARDING_EVIDENCE_DIR'];
      final school = environment['P2_ONBOARDING_SCHOOL'] ?? 'gang_meng';
      final throughStage =
          int.tryParse(environment['P2_ONBOARDING_THROUGH_STAGE'] ?? '') ?? 5;
      final requireVictoriesThrough =
          int.tryParse(environment['P2_ONBOARDING_REQUIRE_VICTORIES'] ?? '') ??
          1;
      await runOnboardingChain(
        tester,
        throughStage: throughStage,
        requireVictoriesThrough: requireVictoriesThrough,
        checkpoints: output == null ? null : Directory('$output/checkpoints'),
        school: school,
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
