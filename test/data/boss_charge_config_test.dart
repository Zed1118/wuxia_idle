import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);
  test('boss_charge 默认值解析', () {
    final bc = GameRepository.instance.numbers.combat.bossCharge;
    expect(bc.defaultChargeTicks, 3);
    expect(bc.defaultStaggerTicks, 2);
    expect(bc.staggerDefenseDown, closeTo(0.3, 1e-9));
  });
}
