import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_defense_tuning_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_defense_tuning.dart';

import '../../../../support/test_data.dart';

void main() {
  late NumbersConfig numbers;

  setUpAll(() async {
    numbers = NumbersConfig.fromYaml(
      parseYamlMap(await loadTestAsset('data/numbers.yaml')),
    );
  });

  test('production numbers map to one reusable tuning for both adapters', () {
    final tuning = Phase0aDefenseTuningMapper.fromNumbers(numbers);
    final config = numbers.phase0aArena.defense;

    expect(tuning, isA<Phase0aDefenseTuning>());
    expect(tuning!.shieldAbsorption, config.shieldAbsorption);
    expect(tuning.parryWindowTicks, config.parryWindowTicks);
    expect(tuning.dodgeDistance, config.dodgeDistance);
    expect(tuning.basicAttackFlags.dodgeable, isTrue);
    expect(tuning.skillAttackFlags.parryable, isTrue);
  });

  test('empty arena has no defense binding', () {
    expect(
      Phase0aDefenseTuningMapper.fromArena(Phase0aArenaConfig.empty),
      isNull,
    );
  });
}
