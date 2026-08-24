import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';

void main() {
  group('MainlineSettlementIdentity', () {
    test('canonical 同时绑定 run、关卡、装配版本与实际参与者', () {
      final identity = MainlineSettlementIdentity(
        runId: ' run-1 ',
        stageId: ' stage_01_03 ',
        loadoutVersion: 3,
        participantId: 42,
      );

      expect(identity.runId, 'run-1');
      expect(identity.stageId, 'stage_01_03');
      expect(identity.canonical, 'v1|run-1|stage_01_03|3|42');
      expect(MainlineSettlementIdentity.parse(identity.canonical), identity);
    });

    test('空组件、分隔符、非正版本/参与者全部 fail closed', () {
      expect(
        () => MainlineSettlementIdentity(
          runId: '',
          stageId: 'stage_01_01',
          loadoutVersion: 1,
          participantId: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlineSettlementIdentity(
          runId: 'run|1',
          stageId: 'stage_01_01',
          loadoutVersion: 1,
          participantId: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlineSettlementIdentity(
          runId: 'run-1',
          stageId: 'stage_01_01',
          loadoutVersion: 0,
          participantId: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => MainlineSettlementIdentity(
          runId: 'run-1',
          stageId: 'stage_01_01',
          loadoutVersion: 1,
          participantId: 0,
        ),
        throwsArgumentError,
      );
    });

    test('parse 拒绝旧版本、别名与畸形键', () {
      for (final value in [
        'v2|run-1|stage_01_01|1|1',
        'v1| run-1|stage_01_01|1|1',
        'v1|run-1|stage_01_01|01|1',
        'v1|run-1|stage_01_01|1|+1',
        'garbage',
      ]) {
        expect(
          () => MainlineSettlementIdentity.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  group('MainlineSettlementJournal 状态机', () {
    MainlineSettlementJournal prepared() => MainlineSettlementJournal.prepare(
      saveDataId: 1,
      identity: MainlineSettlementIdentity(
        runId: 'run-1',
        stageId: 'stage_01_01',
        loadoutVersion: 1,
        participantId: 42,
      ),
      loadoutSnapshotId: 'run-1:loadout:1',
      loadoutSnapshotIds: const ['run-1:loadout:1'],
      createdAt: DateTime.utc(2026, 8, 24),
    );

    test('prepared 重启只允许同关同人重试', () {
      final journal = prepared();
      expect(journal.phase, MainlineSettlementPhase.prepared);
      expect(
        journal.recoveryAction,
        MainlineSettlementRecoveryAction.restartSameStage,
      );
      expect(journal.completedEffectIds, isEmpty);
      expect(journal.loadoutSnapshotIds, const ['run-1:loadout:1']);
    });

    test('coreApplied 重启只恢复后置流且 effect claim 幂等', () {
      final journal = prepared();
      journal.markCoreApplied(
        pendingEffectIds: const ['skill_drop', 'reputation'],
        at: DateTime.utc(2026, 8, 24, 0, 1),
      );
      expect(
        journal.recoveryAction,
        MainlineSettlementRecoveryAction.resumePostSettlement,
      );
      expect(journal.pendingEffectIds, ['skill_drop', 'reputation']);

      expect(
        journal.markEffectCompleted(
          'skill_drop',
          at: DateTime.utc(2026, 8, 24, 0, 2),
        ),
        isTrue,
      );
      expect(
        journal.markEffectCompleted(
          'skill_drop',
          at: DateTime.utc(2026, 8, 24, 0, 3),
        ),
        isFalse,
      );
      expect(journal.completedEffectIds, ['skill_drop']);
    });

    test('非法跳转、未知 effect 与未排空关闭均拒绝', () {
      final journal = prepared();
      expect(
        () => journal.markEffectCompleted(
          'skill_drop',
          at: DateTime.utc(2026, 8, 24),
        ),
        throwsStateError,
      );
      journal.markCoreApplied(
        pendingEffectIds: const ['skill_drop'],
        at: DateTime.utc(2026, 8, 24, 0, 1),
      );
      expect(
        () => journal.markEffectCompleted(
          'unknown',
          at: DateTime.utc(2026, 8, 24, 0, 2),
        ),
        throwsStateError,
      );
      expect(
        () => journal.close(at: DateTime.utc(2026, 8, 24, 0, 3)),
        throwsStateError,
      );
    });

    test('effect 全排空后才能 closed，closed 无恢复动作', () {
      final journal = prepared();
      journal.markCoreApplied(
        pendingEffectIds: const ['skill_drop'],
        at: DateTime.utc(2026, 8, 24, 0, 1),
      );
      journal.markEffectCompleted(
        'skill_drop',
        at: DateTime.utc(2026, 8, 24, 0, 2),
      );
      journal.recordPostSettlementAction(
        MainlinePostSettlementAction.returnToMap,
        at: DateTime.utc(2026, 8, 24, 0, 2, 30),
      );
      journal.close(at: DateTime.utc(2026, 8, 24, 0, 3));
      expect(journal.phase, MainlineSettlementPhase.closed);
      expect(journal.recoveryAction, MainlineSettlementRecoveryAction.none);
    });

    test('结算后选择持久化；同值重放幂等、冲突选择拒绝', () {
      final journal = prepared();
      journal.markCoreApplied(
        pendingEffectIds: const [],
        at: DateTime.utc(2026, 8, 24, 0, 1),
      );
      expect(journal.postSettlementAction, MainlinePostSettlementAction.none);
      expect(
        journal.recordPostSettlementAction(
          MainlinePostSettlementAction.enterNextStage,
          at: DateTime.utc(2026, 8, 24, 0, 2),
        ),
        isTrue,
      );
      expect(
        journal.recordPostSettlementAction(
          MainlinePostSettlementAction.enterNextStage,
          at: DateTime.utc(2026, 8, 24, 0, 3),
        ),
        isFalse,
      );
      expect(
        () => journal.recordPostSettlementAction(
          MainlinePostSettlementAction.returnToMap,
          at: DateTime.utc(2026, 8, 24, 0, 4),
        ),
        throwsStateError,
      );
    });
  });
}
