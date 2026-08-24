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

MainlineRun _run() => MainlineRun.begin(
  runId: 'run-1',
  participantId: 7,
  stageId: 'stage_01_01',
  loadoutSnapshotId: 'run-1:loadout:1',
);

PreparedMainlineLoadoutSnapshot _snapshot(MainlineRun run) {
  final nextVersion = run.currentLoadoutVersion + 1;
  return PreparedMainlineLoadoutSnapshot(
    playerSnapshot: testCombatantSnapshot(
      characterId: run.participantId,
      name: '掌门-v$nextVersion',
    ),
    loadoutSnapshotId: 'run-1:loadout:$nextVersion',
  );
}

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
      initialRun: _run(),
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

  test('首关胜利后主动返回地图，不装配也不启动下一关', () async {
    var loadCount = 0;
    var launchCount = 0;
    final coordinator = MainlineRunCoordinator(
      executeStage: (launch) async {
        launchCount += 1;
        return MainlineStageFlowDecision.returnToMapAfterVictory;
      },
      nextStageOf: (_) => _stage(2),
      loadNextSnapshot: ({required run, required nextStage}) async {
        loadCount += 1;
        return _snapshot(run);
      },
    );

    final result = await coordinator.run(
      initialStage: _stage(1),
      initialRun: _run(),
      initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
    );

    expect(launchCount, 1);
    expect(loadCount, 0);
    expect(result.reason, MainlineRunCompletionReason.stageFlowStopped);
    expect(result.completedStageIds, ['stage_01_01']);
    expect(result.run.currentLoadoutVersion, 1);
  });

  test('战前退出不记完成关，不装配下一关', () async {
    var loadCount = 0;
    final coordinator = MainlineRunCoordinator(
      executeStage: (_) async => MainlineStageFlowDecision.stoppedBeforeVictory,
      nextStageOf: (_) => _stage(2),
      loadNextSnapshot: ({required run, required nextStage}) async {
        loadCount += 1;
        return _snapshot(run);
      },
    );

    final result = await coordinator.run(
      initialStage: _stage(1),
      initialRun: _run(),
      initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
    );

    expect(loadCount, 0);
    expect(result.completedStageIds, isEmpty);
    expect(result.run.currentStageId, 'stage_01_01');
  });

  test('下一关参与者不可战时 fail closed，停在已完成关的版本', () async {
    var launchCount = 0;
    final coordinator = MainlineRunCoordinator(
      executeStage: (_) async {
        launchCount += 1;
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: (_) => _stage(2),
      loadNextSnapshot: ({required run, required nextStage}) async => null,
    );

    final result = await coordinator.run(
      initialStage: _stage(1),
      initialRun: _run(),
      initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
    );

    expect(launchCount, 1);
    expect(
      result.reason,
      MainlineRunCompletionReason.participantNotBattleEligibleForNextStage,
    );
    expect(result.completedStageIds, ['stage_01_01']);
    expect(result.run.currentStageId, 'stage_01_01');
    expect(result.run.currentLoadoutVersion, 1);
  });

  test('关间装配返回不同角色时抛错，绝不启动下一关', () async {
    var launchCount = 0;
    final coordinator = MainlineRunCoordinator(
      executeStage: (_) async {
        launchCount += 1;
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: (_) => _stage(2),
      loadNextSnapshot: ({required run, required nextStage}) async =>
          PreparedMainlineLoadoutSnapshot(
            playerSnapshot: testCombatantSnapshot(characterId: 8),
            loadoutSnapshotId: 'run-1:loadout:2',
          ),
    );

    await expectLater(
      coordinator.run(
        initialStage: _stage(1),
        initialRun: _run(),
        initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
      ),
      throwsA(isA<StateError>()),
    );
    expect(launchCount, 1);
  });

  test('关间装配异常时不发布新版本，也不启动下一关', () async {
    var launchCount = 0;
    final initialRun = _run();
    final coordinator = MainlineRunCoordinator(
      executeStage: (_) async {
        launchCount += 1;
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: (_) => _stage(2),
      loadNextSnapshot: ({required run, required nextStage}) async =>
          throw StateError('snapshot assembly failed'),
    );

    await expectLater(
      coordinator.run(
        initialStage: _stage(1),
        initialRun: initialRun,
        initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
      ),
      throwsA(isA<StateError>()),
    );
    expect(launchCount, 1);
    expect(initialRun.currentStageId, 'stage_01_01');
    expect(initialRun.currentLoadoutVersion, 1);
  });

  test('resolver 返回当前关或非直接后继时拒绝，避免无限推进', () async {
    for (final invalidNext in [
      _stage(1),
      const StageDef(
        id: 'stage_01_02',
        name: '错误后继',
        stageType: StageType.mainline,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: [],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1,
        prevStageId: 'stage_wrong',
      ),
    ]) {
      var loadCount = 0;
      final coordinator = MainlineRunCoordinator(
        executeStage: (_) async => MainlineStageFlowDecision.enterNextStage,
        nextStageOf: (_) => invalidNext,
        loadNextSnapshot: ({required run, required nextStage}) async {
          loadCount += 1;
          return _snapshot(run);
        },
      );

      await expectLater(
        coordinator.run(
          initialStage: _stage(1),
          initialRun: _run(),
          initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
        ),
        throwsA(isA<StateError>()),
      );
      expect(loadCount, 0);
    }
  });

  test('初始关卡或参与者与 run 不一致时在首战前拒绝', () async {
    var launchCount = 0;
    final coordinator = MainlineRunCoordinator(
      executeStage: (_) async {
        launchCount += 1;
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: (_) => null,
      loadNextSnapshot: ({required run, required nextStage}) async =>
          _snapshot(run),
    );

    await expectLater(
      coordinator.run(
        initialStage: _stage(2),
        initialRun: _run(),
        initialPlayerSnapshot: testCombatantSnapshot(characterId: 7),
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      coordinator.run(
        initialStage: _stage(1),
        initialRun: _run(),
        initialPlayerSnapshot: testCombatantSnapshot(characterId: 8),
      ),
      throwsA(isA<StateError>()),
    );
    expect(launchCount, 0);
  });
}
