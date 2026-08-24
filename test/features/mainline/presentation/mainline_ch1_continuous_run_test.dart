import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_run_coordinator.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('真实第一章配置只连续推进 01..05，不跨入第二章', () async {
    StageDef? nextStageInChapterOne(StageDef current) {
      final nextId = nextMainlineStageId(repository, current.id);
      if (nextId == null || !nextId.startsWith('stage_01_')) return null;
      return repository.getStage(nextId);
    }

    final launches = <MainlineRunStageLaunch>[];
    final coordinator = MainlineRunCoordinator(
      executeStage: (launch) async {
        launches.add(launch);
        return MainlineStageFlowDecision.enterNextStage;
      },
      nextStageOf: nextStageInChapterOne,
      loadNextSnapshot: ({required run, required nextStage}) async {
        final version = run.currentLoadoutVersion + 1;
        return PreparedMainlineLoadoutSnapshot(
          playerSnapshot: testCombatantSnapshot(
            characterId: run.participantId,
            name: '锁定参与者-v$version',
          ),
          loadoutSnapshotId: '${run.runId}:loadout:$version',
        );
      },
    );

    final result = await coordinator.run(
      initialStage: repository.getStage('stage_01_01'),
      initialRun: MainlineRun.begin(
        runId: 'ch1-real-config',
        participantId: 19,
        stageId: 'stage_01_01',
        loadoutSnapshotId: 'ch1-real-config:loadout:1',
      ),
      initialPlayerSnapshot: testCombatantSnapshot(characterId: 19),
    );

    expect(launches.map((launch) => launch.stage.id), [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
      'stage_01_05',
    ]);
    expect(
      launches.map((launch) => launch.run.participantId),
      everyElement(19),
    );
    expect(launches.map((launch) => launch.run.currentLoadoutVersion), [
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(result.completedStageIds, [
      'stage_01_01',
      'stage_01_02',
      'stage_01_03',
      'stage_01_04',
      'stage_01_05',
    ]);
    expect(result.reason, MainlineRunCompletionReason.chapterCompleted);
    expect(nextMainlineStageId(repository, 'stage_01_05'), isNull);
    expect(repository.getStage('stage_02_01').prevStageId, isNull);
  });

  test('生产入口只对首次可挑战关启用，宿主优先消费 run 锁定快照', () {
    final stageListSource = File(
      'lib/features/mainline/presentation/stage_list_screen.dart',
    ).readAsStringSync();
    final flowSource = File(
      'lib/features/mainline/presentation/stage_entry_flow.dart',
    ).readAsStringSync();
    final hostSource = File(
      'lib/features/mainline/presentation/phase0a_mainline_battle_host.dart',
    ).readAsStringSync();

    expect(stageListSource, contains('continueFirstClearRun:'));
    expect(stageListSource, contains('targetCycle == 1'));
    expect(stageListSource, contains('StageStatus.available'));
    expect(flowSource, contains('playerSnapshot: launch.playerSnapshot'));
    expect(flowSource, contains('loadExactRoster([participantId])'));
    expect(
      hostSource,
      contains(
        'widget.playerSnapshot ??\n'
        '            widget.playerSnapshotForTest ??',
      ),
    );
  });
}
