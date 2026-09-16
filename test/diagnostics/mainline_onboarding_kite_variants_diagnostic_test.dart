import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/mainline_onboarding_harness.dart';

void main() {
  testWidgets(
    'kite E reruns existing slow decisions and F omits space using independent real-keyboard entries without requiring wins',
    (tester) async {
      final preparedDirectory =
          Platform.environment['P2_ONBOARDING_CHECKPOINT_DIR'];
      final checkpoints = preparedDirectory == null
          ? (await tester.runAsync(
              () => Directory.systemTemp.createTemp('onboarding_kite_entries_'),
            ))!
          : Directory(preparedDirectory);
      try {
        if (preparedDirectory == null) {
          await runOnboardingChain(
            tester,
            throughStage: 2,
            requireVictoriesThrough: 2,
            checkpoints: checkpoints,
          );
        }
        for (var index = 1; index <= 2; index++) {
          final stageId = 'stage_01_0$index';
          final rows = await runOnboardingTolerance(
            tester,
            checkpoint: File('${checkpoints.path}/$stageId.isar'),
            stageId: stageId,
            policies: const [
              OnboardingPolicy.kiteSlow,
              OnboardingPolicy.kiteNoDodge,
            ],
          );
          expect(
            rows.singleWhere(
              (row) => row['policy'] == OnboardingPolicy.kiteNoDodge.name,
            )['spaceKeyEvents'],
            0,
          );
        }
      } finally {
        if (preparedDirectory == null) {
          await tester.runAsync(() => checkpoints.delete(recursive: true));
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
