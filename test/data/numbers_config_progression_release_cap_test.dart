import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/progression_release_cap.dart';

import '../support/test_data.dart';

void main() {
  group('ProgressionReleaseCap.fromYaml', () {
    test('defaults to all 49 realm layers for partial fixtures', () {
      expect(
        ProgressionReleaseCap.fromYaml(const {}).maxAbsoluteRealmLevel,
        49,
      );
    });

    test('rejects values outside the 49-layer realm table', () {
      expect(
        () => ProgressionReleaseCap.fromYaml(const {
          'release_cap': {'max_absolute_realm_level': 0},
        }),
        throwsStateError,
      );
      expect(
        () => ProgressionReleaseCap.fromYaml(const {
          'release_cap': {'max_absolute_realm_level': 50},
        }),
        throwsStateError,
      );
    });
  });

  group('production progression release cap', () {
    setUpAll(loadTestGameRepository);

    test('current release ends at absolute realm layer 28', () {
      expect(
        GameRepository
            .instance
            .numbers
            .progressionReleaseCap
            .maxAbsoluteRealmLevel,
        28,
      );
    });
  });
}
