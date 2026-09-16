import 'package:flutter_test/flutter_test.dart';

import '../support/mainline_onboarding_harness.dart';

void main() {
  testWidgets(
    'second legal fresh-save school and origin record actual continuous-chain outcomes without requiring wins',
    (tester) async {
      await runOnboardingChain(
        tester,
        school: 'ling_qiao',
        origin: 'escort_apprentice',
        requireVictoriesThrough: 0,
      );
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
