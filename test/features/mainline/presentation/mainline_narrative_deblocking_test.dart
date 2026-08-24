import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';

import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test(
    'all 105 mainline stages, including every Boss, skip automatic readers',
    () {
      final mainlineStages = repository.stageDefs.values
          .where((stage) => stage.stageType == StageType.mainline)
          .toList(growable: false);

      expect(mainlineStages, hasLength(105));
      expect(mainlineStages.where((stage) => stage.isBossStage), hasLength(42));
      expect(
        mainlineStages.every(
          (stage) => !shouldAutomaticallyPresentStageNarratives(stage),
        ),
        isTrue,
      );
      expect(
        mainlineStages.where((stage) => stage.id.endsWith('_04')),
        isNotEmpty,
        reason: 'guard includes chapter mini-Boss positions',
      );
      expect(
        mainlineStages.where((stage) => stage.id.endsWith('_05')),
        hasLength(21),
        reason: 'guard includes every chapter-final Boss position',
      );
    },
  );

  test('inner demon, light foot, and mass battle retain automatic readers', () {
    for (final type in const [
      StageType.innerDemon,
      StageType.lightFoot,
      StageType.massBattle,
    ]) {
      final stages = repository.stageDefs.values.where(
        (stage) => stage.stageType == type,
      );
      expect(stages, isNotEmpty, reason: '${type.name} fixture must exist');
      expect(
        stages.every(shouldAutomaticallyPresentStageNarratives),
        isTrue,
        reason: '${type.name} narrative flow must remain unchanged',
      );
    }
  });

  test('guard is based on StageType, not Boss or chapter metadata', () {
    const specialBoss = StageDef(
      id: 'special_boss',
      name: 'special',
      stageType: StageType.innerDemon,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: true,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );
    const mainlineNormal = StageDef(
      id: 'mainline_normal',
      name: 'mainline',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );

    expect(shouldAutomaticallyPresentStageNarratives(specialBoss), isTrue);
    expect(shouldAutomaticallyPresentStageNarratives(mainlineNormal), isFalse);
  });
}
