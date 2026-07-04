import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';

void main() {
  group('StageWinCondition.fromYaml', () {
    test('surviveTicks 型正常解析', () {
      final wc = StageWinCondition.fromYaml({'type': 'surviveTicks', 'ticks': 40});
      expect(wc.type, StageWinConditionType.surviveTicks);
      expect(wc.surviveTicksRequired, 40);
    });

    test('defeatAll 型解析（无 ticks）', () {
      final wc = StageWinCondition.fromYaml({'type': 'defeatAll'});
      expect(wc.type, StageWinConditionType.defeatAll);
      expect(wc.surviveTicksRequired, isNull);
    });

    test('非法 type 启动期抛错', () {
      expect(() => StageWinCondition.fromYaml({'type': 'bogus'}), throwsA(isA<Object>()));
    });

    test('surviveTicks 缺 ticks 抛错', () {
      expect(() => StageWinCondition.fromYaml({'type': 'surviveTicks'}), throwsStateError);
    });

    test('surviveTicks ticks<=0 抛错', () {
      expect(() => StageWinCondition.fromYaml({'type': 'surviveTicks', 'ticks': 0}), throwsStateError);
    });
  });

  group('StageDef.winCondition', () {
    Map<String, dynamic> baseStageYaml() => {
          'id': 'stage_x',
          'name': 'X',
          'stageType': 'innerDemon',
          'requiredRealm': 'wuSheng',
          'enemyTeam': <dynamic>[],
          'isBossStage': true,
          'baseExpReward': 0,
          'difficultyMultiplier': 1.0,
        };

    test('缺 winCondition → null（旧关零影响）', () {
      final s = StageDef.fromYaml(baseStageYaml());
      expect(s.winCondition, isNull);
    });

    test('配 surviveTicks → 解析进 StageDef', () {
      final y = baseStageYaml()
        ..['winCondition'] = {'type': 'surviveTicks', 'ticks': 40};
      final s = StageDef.fromYaml(y);
      expect(s.winCondition?.type, StageWinConditionType.surviveTicks);
      expect(s.winCondition?.surviveTicksRequired, 40);
    });
  });
}
