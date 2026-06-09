import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });
  test('boss_charge 默认值解析', () {
    final bc = GameRepository.instance.numbers.combat.bossCharge;
    expect(bc.defaultChargeTicks, 3);
    expect(bc.defaultStaggerTicks, 2);
    expect(bc.staggerDefenseDown, closeTo(0.3, 1e-9));
  });
}
