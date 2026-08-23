import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('招募资质视觉接线以 profile.total 作为出生点数输入', () {
    final source = File(
      'lib/features/recruitment/presentation/recruitment_dialog.dart',
    ).readAsStringSync();
    expect(source, contains('RarityTierBadge('));
    expect(
      source,
      contains('rarityForTotalPoints(\n              profile.total'),
    );
    expect(source, contains('birthTotal: profile.total'));
  });
}
