import 'package:flutter_test/flutter_test.dart';

import '../support/mainline_onboarding_harness.dart';

void main() {
  testWidgets(
    'legal fresh-save first two victories preserve earned progress and prepare Blackwind',
    (tester) async {
      await runOnboardingChain(
        tester,
        throughStage: 2,
        requireVictoriesThrough: 2,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
