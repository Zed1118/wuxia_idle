import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'numbers.yaml no longer advertises retired residue multipliers',
    () async {
      final numbers = await File('data/numbers.yaml').readAsString();

      expect(numbers, isNot(contains('residue_debuff:')));
      expect(numbers, isNot(contains('battle_output_multiplier: 0.95')));
      expect(
        numbers,
        isNot(contains('internal_force_recovery_multiplier: 0.80')),
      );
      expect(numbers, isNot(contains('failure_penalty:')));
      expect(numbers, isNot(contains('main_cultivation_multiplier:')));
    },
  );
}
