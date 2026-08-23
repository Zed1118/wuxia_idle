import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';

/// P2-M2-R01 纯合同（MAINLINE-RUN-01）：
/// A=整段锁同一参与者；B=关间允许换装并生成版本化新战斗快照，快照用
/// 独立不透明的 loadoutSnapshotId（REOPEN-LOADOUT-PLAN-01=A 单一持久
/// 装配，不得混用持久装配方案）；B=仅当外部事实表明参与者下一关不再
/// 可战时才中断，且 proceedToNext 强制消费该事实（不可绕过）。
/// 不发明 eligibility 判定、伤势阈值或 tuning 默认。
void main() {
  group('begin 校验', () {
    test('合法入参建立第一关与版本 1 快照', () {
      final run = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-1',
      );
      expect(run.runId, 'run-1');
      expect(run.participantId, 42);
      expect(run.currentStageId, 'mainline_1_1');
      expect(run.currentLoadoutVersion, 1);
      expect(run.loadoutSnapshots.single.loadoutSnapshotId, 'snap-1');
    });

    test('runId / 关卡 / 快照 ID 空白即拒绝', () {
      expect(
        () => MainlineRun.begin(
          runId: ' ',
          participantId: 42,
          stageId: 's',
          loadoutSnapshotId: 'snap-1',
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlineRun.begin(
          runId: 'r',
          participantId: 42,
          stageId: ' ',
          loadoutSnapshotId: 'snap-1',
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlineRun.begin(
          runId: 'r',
          participantId: 42,
          stageId: 's',
          loadoutSnapshotId: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('参与者必须是正数角色 ID', () {
      expect(
        () => MainlineRun.begin(
          runId: 'r',
          participantId: 0,
          stageId: 's',
          loadoutSnapshotId: 'snap-1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('A：整段锁定同一参与者', () {
    test('跨多关推进后参与者不变', () {
      final run =
          MainlineRun.begin(
                runId: 'run-1',
                participantId: 42,
                stageId: 'mainline_1_1',
                loadoutSnapshotId: 'snap-1',
              )
              .proceedToNext(
                stageId: 'mainline_1_2',
                loadoutSnapshotId: 'snap-2',
                participantBattleEligibleForNextStage: true,
              )
              .proceedToNext(
                stageId: 'mainline_1_3',
                loadoutSnapshotId: 'snap-3',
                participantBattleEligibleForNextStage: true,
              );
      expect(run.participantId, 42);
      expect(run.currentStageId, 'mainline_1_3');
    });

    test('成长与伤势归属恒为锁定的实际参与者（含推进后）', () {
      final run =
          MainlineRun.begin(
            runId: 'run-1',
            participantId: 42,
            stageId: 'mainline_1_1',
            loadoutSnapshotId: 'snap-1',
          ).proceedToNext(
            stageId: 'mainline_1_2',
            loadoutSnapshotId: 'snap-2',
            participantBattleEligibleForNextStage: true,
          );
      expect(run.growthAndInjuryOwnerId, run.participantId);
      expect(run.growthAndInjuryOwnerId, 42);
    });
  });

  group('B：关间换装生成版本化快照（不透明快照 ID）', () {
    test('每次推进生成递增版本快照并保留历史', () {
      final run =
          MainlineRun.begin(
                runId: 'run-1',
                participantId: 42,
                stageId: 'mainline_1_1',
                loadoutSnapshotId: 'snap-a',
              )
              .proceedToNext(
                stageId: 'mainline_1_2',
                loadoutSnapshotId: 'snap-b',
                participantBattleEligibleForNextStage: true,
              )
              .proceedToNext(
                stageId: 'mainline_1_3',
                loadoutSnapshotId: 'snap-c',
                participantBattleEligibleForNextStage: true,
              );
      expect(run.loadoutSnapshots.map((s) => s.version).toList(), [1, 2, 3]);
      expect(run.loadoutSnapshots.map((s) => s.loadoutSnapshotId).toList(), [
        'snap-a',
        'snap-b',
        'snap-c',
      ]);
      expect(run.currentLoadoutVersion, 3);
    });

    test('快照只携带不透明快照 ID：trim 规范化携带、不解析内容', () {
      const opaqueId = 'opaque-9f3c';
      final snapshot = MainlineRunLoadoutSnapshot(
        version: 1,
        loadoutSnapshotId: opaqueId,
      );
      expect(snapshot.loadoutSnapshotId, opaqueId);
      expect(
        snapshot,
        MainlineRunLoadoutSnapshot(version: 1, loadoutSnapshotId: opaqueId),
      );
      expect(
        snapshot,
        isNot(
          MainlineRunLoadoutSnapshot(version: 2, loadoutSnapshotId: opaqueId),
        ),
      );
    });

    test('快照 ID 前后空白规范为 trimmed ID；全空白仍拒绝', () {
      final snapshot = MainlineRunLoadoutSnapshot(
        version: 1,
        loadoutSnapshotId: '  snap-x ',
      );
      expect(snapshot.loadoutSnapshotId, 'snap-x');
      expect(
        snapshot,
        MainlineRunLoadoutSnapshot(version: 1, loadoutSnapshotId: 'snap-x'),
      );
      expect(
        () => MainlineRunLoadoutSnapshot(version: 1, loadoutSnapshotId: ' \t '),
        throwsArgumentError,
      );
    });

    test('快照 ID 与持久装配方案语义解耦：同一快照 ID 不因方案命名而特殊', () {
      // 快照值相等只由版本与不透明 ID 决定；合同不把任何持久装配方案
      // 语义（如 'plan-*'）注入快照，也不从 ID 反查装配内容。
      final runA = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-1',
      );
      final runB = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-1',
      );
      expect(runA, runB);
      expect(runA.loadoutSnapshots.single, runB.loadoutSnapshots.single);
    });

    test('快照历史不可变', () {
      final run = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-a',
      );
      expect(
        () => run.loadoutSnapshots.add(run.loadoutSnapshots.single),
        throwsUnsupportedError,
      );
    });

    test('推进时空关卡或空快照 ID 即拒绝', () {
      final run = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-a',
      );
      expect(
        () => run.proceedToNext(
          stageId: ' ',
          loadoutSnapshotId: 'snap-b',
          participantBattleEligibleForNextStage: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => run.proceedToNext(
          stageId: 's',
          loadoutSnapshotId: ' ',
          participantBattleEligibleForNextStage: true,
        ),
        throwsArgumentError,
      );
    });

    test('推进不改动原 run（值不可变）', () {
      final run = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-a',
      );
      run.proceedToNext(
        stageId: 'mainline_1_2',
        loadoutSnapshotId: 'snap-b',
        participantBattleEligibleForNextStage: true,
      );
      expect(run.currentStageId, 'mainline_1_1');
      expect(run.loadoutSnapshots, hasLength(1));
    });
  });

  group('B：仅下一关不再可战才停止（消费外部事实）', () {
    MainlineRun run() => MainlineRun.begin(
      runId: 'run-1',
      participantId: 42,
      stageId: 'mainline_1_1',
      loadoutSnapshotId: 'snap-a',
    );

    test('外部事实为可战则不停（无其他停止理由）', () {
      expect(
        run().stopReasonForNextStage(
          participantBattleEligibleForNextStage: true,
        ),
        isNull,
      );
    });

    test('外部事实为不可战则停止，理由是下一关不再可战', () {
      expect(
        run().stopReasonForNextStage(
          participantBattleEligibleForNextStage: false,
        ),
        MainlineRunStopReason.participantNotBattleEligibleForNextStage,
      );
    });
  });

  group('proceedToNext 强制中断：不可战事实不可绕过', () {
    MainlineRun run() => MainlineRun.begin(
      runId: 'run-1',
      participantId: 42,
      stageId: 'mainline_1_1',
      loadoutSnapshotId: 'snap-a',
    );

    test('不可战事实为 false 时抛 typed error 并携带停止理由', () {
      expect(
        () => run().proceedToNext(
          stageId: 'mainline_1_2',
          loadoutSnapshotId: 'snap-b',
          participantBattleEligibleForNextStage: false,
        ),
        throwsA(
          isA<MainlineRunTransitionRefusedError>().having(
            (e) => e.reason,
            'reason',
            MainlineRunStopReason.participantNotBattleEligibleForNextStage,
          ),
        ),
      );
    });

    test('拒绝推进后原 run 的状态与快照完全不变', () {
      final before = run();
      try {
        before.proceedToNext(
          stageId: 'mainline_1_2',
          loadoutSnapshotId: 'snap-b',
          participantBattleEligibleForNextStage: false,
        );
        fail('proceedToNext 必须在不可战时拒绝推进');
      } on MainlineRunTransitionRefusedError {
        // 预期：绝不返回新 run/新快照。
      }
      expect(before.currentStageId, 'mainline_1_1');
      expect(before.loadoutSnapshots, hasLength(1));
      expect(before.currentLoadoutVersion, 1);
      expect(before, run());
    });

    test('可战事实为 true 才允许推进并生成新版本快照', () {
      final advanced = run().proceedToNext(
        stageId: 'mainline_1_2',
        loadoutSnapshotId: 'snap-b',
        participantBattleEligibleForNextStage: true,
      );
      expect(advanced.currentStageId, 'mainline_1_2');
      expect(advanced.currentLoadoutVersion, 2);
      expect(advanced.loadoutSnapshots.last.loadoutSnapshotId, 'snap-b');
    });
  });

  group('值相等', () {
    test('同输入恒等，不同版本不等', () {
      final a = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-a',
      );
      final b = MainlineRun.begin(
        runId: 'run-1',
        participantId: 42,
        stageId: 'mainline_1_1',
        loadoutSnapshotId: 'snap-a',
      );
      final c = a.proceedToNext(
        stageId: 'mainline_1_2',
        loadoutSnapshotId: 'snap-a',
        participantBattleEligibleForNextStage: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
