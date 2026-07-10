import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  test('skill_unlock 阈值 + 残页掉率', () {
    final u = GameRepository.instance.numbers.skillUnlock;
    expect(u.fragmentThreshold, 5);
    expect(u.towerFragmentDropProb, closeTo(0.20, 1e-9));
  });
}
