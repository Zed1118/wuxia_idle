import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_mainline_settlement_journal_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  MainlineSettlementIdentity identity({
    String runId = 'run-1',
    String stageId = 'stage_01_01',
    int version = 1,
    int participantId = 42,
  }) => MainlineSettlementIdentity(
    runId: runId,
    stageId: stageId,
    loadoutVersion: version,
    participantId: participantId,
  );

  MainlineSettlementJournalService service() =>
      MainlineSettlementJournalService(IsarSetup.instance);

  test('prepare 持久化；close/reopen 后仍恢复同关同人', () async {
    final prepared = await service().prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'run-1:loadout:1',
      loadoutSnapshotIds: const ['run-1:loadout:1'],
      now: DateTime.utc(2026, 8, 24),
    );
    expect(
      prepared.recoveryAction,
      MainlineSettlementRecoveryAction.restartSameStage,
    );

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final restored = await service().activeForSave(1);
    expect(restored, isNotNull);
    expect(restored!.identity, identity());
    expect(restored.loadoutSnapshotId, 'run-1:loadout:1');
    expect(restored.loadoutSnapshotIds, const ['run-1:loadout:1']);
  });

  test('同槽只允许一条 active journal；同 identity prepare 幂等复用', () async {
    final first = await service().prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );
    final again = await service().prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24, 0, 1),
    );
    expect(again.id, first.id);

    expect(
      () => service().prepare(
        saveDataId: 1,
        identity: identity(runId: 'run-2'),
        loadoutSnapshotId: 'run-2:loadout:1',
        now: DateTime.utc(2026, 8, 24, 0, 2),
      ),
      throwsStateError,
    );
  });

  test('core callback 与 receipt 同事务提交；重复提交不再执行 callback', () async {
    final key = identity();
    await service().prepare(
      saveDataId: 1,
      identity: key,
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );
    var calls = 0;
    final first = await service().commitCore(
      identity: key,
      pendingEffectIds: const ['skill_drop'],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {
        calls += 1;
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.totalPlaySeconds += 7;
        await IsarSetup.instance.saveDatas.put(save);
      },
    );
    expect(first, MainlineCoreCommitDisposition.applied);

    final repeated = await service().commitCore(
      identity: key,
      pendingEffectIds: const ['skill_drop'],
      now: DateTime.utc(2026, 8, 24, 0, 2),
      applyInTxn: () async {
        calls += 1;
      },
    );
    expect(repeated, MainlineCoreCommitDisposition.alreadyApplied);
    expect(calls, 1);
    expect((await IsarSetup.instance.saveDatas.get(0))!.totalPlaySeconds, 7);
  });

  test('core callback 抛错：业务写入与 receipt 一并回滚为 prepared', () async {
    final key = identity();
    await service().prepare(
      saveDataId: 1,
      identity: key,
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );

    expect(
      () => service().commitCore(
        identity: key,
        pendingEffectIds: const ['skill_drop'],
        now: DateTime.utc(2026, 8, 24, 0, 1),
        applyInTxn: () async {
          final save = (await IsarSetup.instance.saveDatas.get(0))!;
          save.totalPlaySeconds += 9;
          await IsarSetup.instance.saveDatas.put(save);
          throw StateError('破坏点');
        },
      ),
      throwsStateError,
    );
    expect((await IsarSetup.instance.saveDatas.get(0))!.totalPlaySeconds, 0);
    expect(
      (await service().activeForSave(1))!.phase,
      MainlineSettlementPhase.prepared,
    );
  });

  test('effect callback 与 effect claim 同事务；重复与失败均不双写', () async {
    final key = identity();
    await service().prepare(
      saveDataId: 1,
      identity: key,
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );
    await service().commitCore(
      identity: key,
      pendingEffectIds: const ['skill_drop', 'reputation'],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {},
    );

    expect(
      () => service().applyEffect(
        identity: key,
        effectId: 'skill_drop',
        now: DateTime.utc(2026, 8, 24, 0, 2),
        applyInTxn: () async {
          final save = (await IsarSetup.instance.saveDatas.get(0))!;
          save.totalPlaySeconds += 3;
          await IsarSetup.instance.saveDatas.put(save);
          throw StateError('破坏点');
        },
      ),
      throwsStateError,
    );
    expect((await IsarSetup.instance.saveDatas.get(0))!.totalPlaySeconds, 0);

    expect(
      await service().applyEffect(
        identity: key,
        effectId: 'skill_drop',
        now: DateTime.utc(2026, 8, 24, 0, 3),
        applyInTxn: () async {
          final save = (await IsarSetup.instance.saveDatas.get(0))!;
          save.totalPlaySeconds += 3;
          await IsarSetup.instance.saveDatas.put(save);
        },
      ),
      isTrue,
    );
    expect(
      await service().applyEffect(
        identity: key,
        effectId: 'skill_drop',
        now: DateTime.utc(2026, 8, 24, 0, 4),
        applyInTxn: () async {
          fail('重复 effect 不得执行 callback');
        },
      ),
      isFalse,
    );
    expect((await IsarSetup.instance.saveDatas.get(0))!.totalPlaySeconds, 3);
  });

  test('未排空 outbox 不可 close；排空后 active 查询归零', () async {
    final key = identity();
    await service().prepare(
      saveDataId: 1,
      identity: key,
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );
    await service().commitCore(
      identity: key,
      pendingEffectIds: const ['skill_drop'],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {},
    );
    expect(
      () =>
          service().close(identity: key, now: DateTime.utc(2026, 8, 24, 0, 2)),
      throwsStateError,
    );
    await service().applyEffect(
      identity: key,
      effectId: 'skill_drop',
      now: DateTime.utc(2026, 8, 24, 0, 3),
      applyInTxn: () async {},
    );
    await service().recordPostSettlementAction(
      identity: key,
      action: MainlinePostSettlementAction.returnToMap,
      now: DateTime.utc(2026, 8, 24, 0, 3, 30),
    );
    await service().close(identity: key, now: DateTime.utc(2026, 8, 24, 0, 4));
    expect(await service().activeForSave(1), isNull);
  });

  test('结算后动作与 journal 同事务持久化且冲突选择 fail closed', () async {
    final key = identity();
    await service().prepare(
      saveDataId: 1,
      identity: key,
      loadoutSnapshotId: 'run-1:loadout:1',
      now: DateTime.utc(2026, 8, 24),
    );
    await service().commitCore(
      identity: key,
      pendingEffectIds: const [],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {},
    );

    expect(
      await service().recordPostSettlementAction(
        identity: key,
        action: MainlinePostSettlementAction.enterNextStage,
        now: DateTime.utc(2026, 8, 24, 0, 2),
      ),
      isTrue,
    );
    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    expect(
      (await service().activeForSave(1))!.postSettlementAction,
      MainlinePostSettlementAction.enterNextStage,
    );
    expect(
      await service().recordPostSettlementAction(
        identity: key,
        action: MainlinePostSettlementAction.enterNextStage,
        now: DateTime.utc(2026, 8, 24, 0, 3),
      ),
      isFalse,
    );
    expect(
      () => service().recordPostSettlementAction(
        identity: key,
        action: MainlinePostSettlementAction.returnToMap,
        now: DateTime.utc(2026, 8, 24, 0, 4),
      ),
      throwsStateError,
    );
  });

  test('进入下一关时原子关闭旧 receipt 并继承同 run 同参与者', () async {
    final first = identity();
    await service().prepare(
      saveDataId: 1,
      identity: first,
      loadoutSnapshotId: 'run-1:loadout:1',
      loadoutSnapshotIds: const ['run-1:loadout:1'],
      now: DateTime.utc(2026, 8, 24),
    );
    await service().commitCore(
      identity: first,
      pendingEffectIds: const [],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {},
    );
    await service().recordPostSettlementAction(
      identity: first,
      action: MainlinePostSettlementAction.enterNextStage,
      now: DateTime.utc(2026, 8, 24, 0, 2),
    );

    final second = identity(stageId: 'stage_01_02', version: 2);
    final next = await service().prepare(
      saveDataId: 1,
      identity: second,
      loadoutSnapshotId: 'run-1:loadout:2',
      loadoutSnapshotIds: const ['run-1:loadout:1', 'run-1:loadout:2'],
      now: DateTime.utc(2026, 8, 24, 0, 3),
    );

    expect(next.identity, second);
    expect(next.phase, MainlineSettlementPhase.prepared);
    expect((await service().activeForSave(1))!.identity, second);
    final rows = await IsarSetup.instance.mainlineSettlementJournals
        .where()
        .findAll();
    expect(
      rows.singleWhere((row) => row.settlementId == first.canonical).phase,
      MainlineSettlementPhase.closed,
    );
  });

  test('进入下一章时原子关闭旧章卷轴游标并创建版本 1 的新 run', () async {
    final previous = identity(
      runId: 'chapter-1-run',
      stageId: 'stage_01_05',
      version: 5,
    );
    await service().prepare(
      saveDataId: 1,
      identity: previous,
      loadoutSnapshotId: 'chapter-1-run:loadout:5',
      loadoutSnapshotIds: [
        for (var version = 1; version <= 5; version++)
          'chapter-1-run:loadout:$version',
      ],
      now: DateTime.utc(2026, 8, 31),
    );
    await service().commitCore(
      identity: previous,
      pendingEffectIds: const [],
      now: DateTime.utc(2026, 8, 31, 0, 1),
      applyInTxn: () async {},
    );
    await service().recordPostSettlementAction(
      identity: previous,
      action: MainlinePostSettlementAction.showChapterScroll,
      now: DateTime.utc(2026, 8, 31, 0, 2),
    );

    final next = identity(
      runId: 'chapter-2-run',
      stageId: 'stage_02_01',
      version: 1,
      participantId: 84,
    );
    final prepared = await service().beginNextChapter(
      previousIdentity: previous,
      nextIdentity: next,
      nextLoadoutSnapshotId: 'chapter-2-run:loadout:1',
      now: DateTime.utc(2026, 8, 31, 0, 3),
    );

    expect(prepared.identity, next);
    expect(prepared.phase, MainlineSettlementPhase.prepared);
    expect(prepared.loadoutSnapshotIds, ['chapter-2-run:loadout:1']);
    expect((await service().activeForSave(1))!.identity, next);
    final rows = await IsarSetup.instance.mainlineSettlementJournals
        .where()
        .findAll();
    expect(
      rows.singleWhere((row) => row.settlementId == previous.canonical).phase,
      MainlineSettlementPhase.closed,
    );
  });

  test('下一章 journal 创建中断时旧章卷轴游标不关闭且零部分新 run', () async {
    final previous = identity(
      runId: 'chapter-1-run',
      stageId: 'stage_01_05',
      version: 5,
    );
    await service().prepare(
      saveDataId: 1,
      identity: previous,
      loadoutSnapshotId: 'chapter-1-run:loadout:5',
      loadoutSnapshotIds: [
        for (var version = 1; version <= 5; version++)
          'chapter-1-run:loadout:$version',
      ],
      now: DateTime.utc(2026, 8, 31),
    );
    await service().commitCore(
      identity: previous,
      pendingEffectIds: const [],
      now: DateTime.utc(2026, 8, 31, 0, 1),
      applyInTxn: () async {},
    );
    await service().recordPostSettlementAction(
      identity: previous,
      action: MainlinePostSettlementAction.showChapterScroll,
      now: DateTime.utc(2026, 8, 31, 0, 2),
    );

    final next = identity(
      runId: 'chapter-2-run',
      stageId: 'stage_02_01',
      participantId: 84,
    );
    await expectLater(
      service().beginNextChapter(
        previousIdentity: previous,
        nextIdentity: next,
        nextLoadoutSnapshotId: 'chapter-2-run:loadout:1',
        now: DateTime.utc(2026, 8, 31, 0, 3),
        afterPreviousClosedInTxnForTest: () async {
          throw StateError('crash');
        },
      ),
      throwsStateError,
    );

    final active = await service().activeForSave(1);
    expect(active!.identity, previous);
    expect(active.phase, MainlineSettlementPhase.coreApplied);
    expect(
      active.postSettlementAction,
      MainlinePostSettlementAction.showChapterScroll,
    );
    expect(
      await IsarSetup.instance.mainlineSettlementJournals
          .filter()
          .settlementIdEqualTo(next.canonical)
          .count(),
      0,
    );
  });
}
