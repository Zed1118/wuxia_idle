import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  test('founder_creation.yaml 覆盖三流派且命盘池可抽 3 份', () async {
    final repo = await GameRepository.loadAllDefs(
      loader: (p) => File(p).readAsString(),
    );

    final config = repo.founderCreation;
    expect(config.schools.map((e) => e.school).toSet().length, 3);
    expect(config.origins.length, greaterThanOrEqualTo(3));
    expect(config.fatePool.length, greaterThanOrEqualTo(3));

    for (final fate in config.fatePool) {
      expect(fate.attributeProfile.total, inInclusiveRange(16, 24));
      expect(fate.attributeProfile.constitution, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.enlightenment, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.agility, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.fortune, inInclusiveRange(1, 10));
    }
  });
}
