// CANDIDATE-ONLY NON-PRODUCTION TEST CONTRACT.
// This matrix composes only one idle, drop-all, no-mutation runtime tick. It
// does not execute defeat objectives or validate gameplay policy.

import 'package:flutter_test/flutter_test.dart';

import '../../support/ch1_candidate_defeat_projection_declarations.dart';

void main() {
  test('candidate observable composition uses one explicit declaration truth', () {
    expect(ch1CandidateDefeatProjectionEntriesByStageId, hasLength(5));
  });
}
