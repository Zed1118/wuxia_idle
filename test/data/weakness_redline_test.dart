/// 批二②：弱点/抗性乘子值域红线校验单测。
///
/// 直接调 [GameRepository.enforceWeaknessRedLines]（纯 static，接受 stageDefs Map
/// + minMult/maxMult），无需走完整 loadAllDefs，与 enforceBossPhaseSkillIds 同模式。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

TowerFloorDef _towerFloor(int floorIndex, List<EnemyDef> team) => TowerFloorDef(
      floorIndex: floorIndex,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: team,
    );

EnemyDef _enemy({Map<TechniqueSchool, double>? mult}) => EnemyDef(
      id: 'boss_x',
      name: '测试Boss',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 5000,
      baseAttack: 200,
      baseSpeed: 50,
      skillIds: const ['skill_normal'],
      iconPath: 'x.png',
      isBoss: true,
      schoolDamageTakenMult: mult,
    );

StageDef _stage(String id, List<EnemyDef> team) => StageDef(
      id: id,
      name: '测试关',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: team,
      isBossStage: false,
      baseExpReward: 100,
      difficultyMultiplier: 1.0,
    );

void main() {
  group('GameRepository.enforceWeaknessRedLines(批二②)', () {
    test('值在 [0.5, 2.0] 内 → 不抛', () {
      final stages = {
        's1': _stage('s1', [
          _enemy(mult: {
            TechniqueSchool.lingQiao: 1.25,
            TechniqueSchool.yinRou: 0.75,
          }),
        ]),
      };
      expect(
        () => GameRepository.enforceWeaknessRedLines(stages, 0.5, 2.0),
        returnsNormally,
      );
    });

    test('值 2.5 > max → 抛 StateError 含敌人/流派/值', () {
      final stages = {
        's1': _stage('s1', [
          _enemy(mult: {TechniqueSchool.lingQiao: 2.5}),
        ]),
      };
      expect(
        () => GameRepository.enforceWeaknessRedLines(stages, 0.5, 2.0),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('boss_x'))
            .having((e) => e.message, 'message', contains('lingQiao'))
            .having((e) => e.message, 'message', contains('2.5'))),
      );
    });

    test('值 0.3 < min → 抛 StateError', () {
      final stages = {
        's1': _stage('s1', [
          _enemy(mult: {TechniqueSchool.yinRou: 0.3}),
        ]),
      };
      expect(
        () => GameRepository.enforceWeaknessRedLines(stages, 0.5, 2.0),
        throwsA(isA<StateError>()),
      );
    });

    test('schoolDamageTakenMult==null 的敌人跳过 → 不抛', () {
      final stages = {
        's1': _stage('s1', [_enemy(mult: null)]),
      };
      expect(
        () => GameRepository.enforceWeaknessRedLines(stages, 0.5, 2.0),
        returnsNormally,
      );
    });
  });

  group('GameRepository.enforceWeaknessRedLines — tower floors(批二②)', () {
    test('塔层 boss 乘子在 [0.5, 2.0] → 不抛', () {
      final floor = _towerFloor(10, [
        _enemy(mult: {
          TechniqueSchool.lingQiao: 1.5,
          TechniqueSchool.yinRou: 0.75,
        }),
      ]);
      expect(
        () => GameRepository.enforceWeaknessRedLines({}, 0.5, 2.0,
            towerFloors: [floor]),
        returnsNormally,
      );
    });

    test('塔层 boss 乘子 2.5 > max → 抛 StateError 含敌人/流派/值/floor号', () {
      final floor = _towerFloor(10, [
        _enemy(mult: {TechniqueSchool.gangMeng: 2.5}),
      ]);
      expect(
        () => GameRepository.enforceWeaknessRedLines({}, 0.5, 2.0,
            towerFloors: [floor]),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('boss_x'))
              .having((e) => e.message, 'message', contains('gangMeng'))
              .having((e) => e.message, 'message', contains('2.5'))
              .having((e) => e.message, 'message', contains('10')),
        ),
      );
    });

    test('塔层 boss 乘子 0.3 < min → 抛 StateError', () {
      final floor = _towerFloor(5, [
        _enemy(mult: {TechniqueSchool.yinRou: 0.3}),
      ]);
      expect(
        () => GameRepository.enforceWeaknessRedLines({}, 0.5, 2.0,
            towerFloors: [floor]),
        throwsA(isA<StateError>()),
      );
    });

    test('塔层 schoolDamageTakenMult==null 的敌人跳过 → 不抛', () {
      final floor = _towerFloor(3, [_enemy(mult: null)]);
      expect(
        () => GameRepository.enforceWeaknessRedLines({}, 0.5, 2.0,
            towerFloors: [floor]),
        returnsNormally,
      );
    });
  });
}
