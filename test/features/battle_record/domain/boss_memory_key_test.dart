import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_key.dart';

void main() {
  group('mainlineBossKey', () {
    test('返回 stageId 原样', () {
      expect(mainlineBossKey('stage_01_05'), 'stage_01_05');
      expect(mainlineBossKey('stage_06_04'), 'stage_06_04');
      expect(mainlineBossKey('stage_inner_demon_01'), 'stage_inner_demon_01');
    });
  });

  group('towerBossKey', () {
    test('格式 tower_floor_<N>', () {
      expect(towerBossKey(5), 'tower_floor_5');
      expect(towerBossKey(10), 'tower_floor_10');
      expect(towerBossKey(30), 'tower_floor_30');
    });
  });

  group('mainlineGroupIndex', () {
    test('Ch1 → 1', () => expect(mainlineGroupIndex('stage_01_05'), 1));
    test('Ch2 → 2', () => expect(mainlineGroupIndex('stage_02_04'), 2));
    test('Ch3 → 3', () => expect(mainlineGroupIndex('stage_03_05'), 3));
    test('Ch4 → 4', () => expect(mainlineGroupIndex('stage_04_04'), 4));
    test('Ch5 → 5', () => expect(mainlineGroupIndex('stage_05_05'), 5));
    test('Ch6 → 6', () => expect(mainlineGroupIndex('stage_06_05'), 6));
    test('inner_demon → 7', () => expect(mainlineGroupIndex('stage_inner_demon_01'), 7));
    test('light_foot → 8', () => expect(mainlineGroupIndex('stage_light_foot_05'), 8));
    test('mass_battle → 9', () => expect(mainlineGroupIndex('stage_mass_battle_05'), 9));
    test('未知前缀 → 99', () => expect(mainlineGroupIndex('unknown_stage'), 99));
  });
}
