import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// F1 里程碑装备授予映射 production drift guard。
/// 沿 numbers_config_red_lines_test 体例：loadAllDefs 真 numbers.yaml 后断言。
void main() {
  group('production numbers.yaml milestone_equipment_grants', () {
    setUpAll(() async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    test('解析 2 条 stageId→tag 映射', () {
      final map = GameRepository.instance.numbers.milestoneEquipmentGrants;
      expect(map['stage_mass_battle_05'], 'mass_battle_merit');
      expect(map['stage_inner_demon_07'], 'inner_demon_reward');
    });

    test('非里程碑关 → null(getter 不兜底错值)', () {
      final map = GameRepository.instance.numbers.milestoneEquipmentGrants;
      expect(map['stage_01_01'], isNull);
    });
  });
}
