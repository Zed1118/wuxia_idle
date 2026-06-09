import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('skill_proficiency 5 阶 min_uses 单调 + 倍率封顶 1.30', () {
    final p = GameRepository.instance.numbers.skillProficiency;
    expect(p.stages.length, 5);
    expect(p.stages.map((s) => s.minUses).toList(), [0, 30, 100, 300, 800]);
    expect(p.stages.first.damageMult, 1.00);
    expect(p.stages.last.damageMult, 1.30);
    // 单调递增守
    for (var i = 1; i < p.stages.length; i++) {
      expect(p.stages[i].minUses, greaterThan(p.stages[i - 1].minUses));
      expect(p.stages[i].damageMult,
          greaterThanOrEqualTo(p.stages[i - 1].damageMult));
    }
    expect(p.maxDamageMult, 1.30); // = 末阶,作综合 cap
  });
}
