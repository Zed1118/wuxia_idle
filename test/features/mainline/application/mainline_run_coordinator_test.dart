import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_run_coordinator.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';

import '../../../support/combatant_snapshot_fixture.dart';

StageDef _stage(int index) => StageDef(
  id: 'stage_01_0$index',
  name: '第一章第$index关',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: const [],
  isBossStage: index == 5,
  baseExpReward: 0,
  difficultyMultiplier: 1,
  prevStageId: index == 1 ? null : 'stage_01_0${index - 1}',
);

void main() {
  test('第一章五关非递归推进，锁定参与者且快照版本为 1..5', () async {
    final stages = {for (var i = 1; i <= 5; i++) _stage(i).id: _stage(i)};
    final launches = <MainlineRunStageLaunch>[];
    final coordinator = MainlineRunCoordinator(
      executeStage: (launch) async {
        launches.add(launch);
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: (current) {
        final successors = stages.values
            .where((stage) => stage.prevStageId == current.id)
            .toList(growable: false);
        return successors.isEmpty ? null : successors.single;
      },
      loadNextSnapshot: ({required run, required nextStage}) async {
        final nextVersion = run.currentLoadoutVersion + 1;
        return PreparedMainlineLoadoutSnapshot(
          playerSnapshot: testCombatantSnapshot(
            characterId: run.participantId,
            name: '掌门-v$nextVersion',
          ),
          loadoutSnapshotId: 'run-1:loadout:$nextVersion',
        );
      },
    );

    final result = await coordinator.run(
      initialStage: stages['stage_01_01']!,
      initialRun: MainlineRun.begin(
        runId: 'run-1',
        participantId: 7,
        stageId: 'stage_01_01',
        loadoutSnapshotId: 'run-1:loadout:1',
      ),
      initialPlayerSnapshot: testCombatantSnapshot(
        characterId: 7,
        name: '掌门-v1',
      ),
    );

    expect(launches.map((launch) => launch.stage.id), [
      for (var i = 1; i <= 5; i++) 'stage_01_0$i',
    ]);
    expect(launches.map((launch) => launch.run.participantId), everyElement(7));
    expect(launches.map((launch) => launch.run.currentLoadoutVersion), [
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(result.reason, MainlineRunCompletionReason.chapterCompleted);
    expect(result.run.currentStageId, 'stage_01_05');
  });
}
