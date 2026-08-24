import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_pending_jianghu_affair_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pending_affair_service_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  MainlineSettlementIdentity identity() => MainlineSettlementIdentity(
    runId: 'run-1',
    stageId: 'stage_01_03',
    loadoutVersion: 1,
    participantId: 42,
  );

  MainlinePendingJianghuAffairRef encounter(int ordinal) =>
      MainlinePendingJianghuAffairRef.encounterChoice(
        settlementId: identity().canonical,
        encounterId: 'test-$ordinal',
        ordinal: ordinal,
        resolutionSeed: 100 + ordinal,
      );

  test('核心事务原子提交 typed refs，按列表顺序恢复 FIFO', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );

    await service.commitCore(
      identity: identity(),
      now: DateTime.utc(2026, 8, 25, 0, 1),
      applyInTxn: () async => [encounter(1), encounter(2)],
    );

    expect(await service.firstPending(identity: identity()), encounter(1));
    await service.apply(
      identity: identity(),
      affair: encounter(1),
      now: DateTime.utc(2026, 8, 25, 0, 2),
      applyInTxn: () async {},
    );
    expect(await service.firstPending(identity: identity()), encounter(2));
  });

  test('旧队首已 claim 但后续仍 pending 时，重放旧队首幂等返回 false', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );
    await service.commitCore(
      identity: identity(),
      now: DateTime.utc(2026, 8, 25, 0, 1),
      applyInTxn: () async => [encounter(1), encounter(2)],
    );
    expect(
      await service.apply(
        identity: identity(),
        affair: encounter(1),
        now: DateTime.utc(2026, 8, 25, 0, 2),
        applyInTxn: () async {},
      ),
      isTrue,
    );

    var replayedBusinessWrite = false;
    expect(
      await service.apply(
        identity: identity(),
        affair: encounter(1),
        now: DateTime.utc(2026, 8, 25, 0, 3),
        applyInTxn: () async => replayedBusinessWrite = true,
      ),
      isFalse,
    );
    expect(replayedBusinessWrite, isFalse);
    expect(await service.firstPending(identity: identity()), encounter(2));
  });

  test('拒绝越序消费，业务写入失败时业务字段与 claim 整体回滚', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );
    await service.commitCore(
      identity: identity(),
      now: DateTime.utc(2026, 8, 25, 0, 1),
      applyInTxn: () async => [encounter(1), encounter(2)],
    );

    await expectLater(
      service.apply(
        identity: identity(),
        affair: encounter(2),
        now: DateTime.utc(2026, 8, 25, 0, 2),
        applyInTxn: () async {},
      ),
      throwsStateError,
    );
    await expectLater(
      service.apply(
        identity: identity(),
        affair: encounter(1),
        now: DateTime.utc(2026, 8, 25, 0, 3),
        applyInTxn: () async {
          final save = (await IsarSetup.instance.saveDatas.get(0))!;
          save.totalPlaySeconds += 9;
          await IsarSetup.instance.saveDatas.put(save);
          throw StateError('injected');
        },
      ),
      throwsStateError,
    );

    expect((await IsarSetup.instance.saveDatas.get(0))!.totalPlaySeconds, 0);
    expect(await service.firstPending(identity: identity()), encounter(1));
  });

  test('真实 encounter outcome、trigger 与 claim 在注入失败时整体回滚', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    final encounterService = EncounterService(isar: IsarSetup.instance);
    const def = EncounterDef(
      id: 'enc_real_txn_rollback',
      type: EncounterType.fortuneEvent,
      trigger: EncounterTrigger(schoolKillThreshold: {}),
      baseProbability: 1,
      outcomeMapping: {
        'gain_fortune': OutcomeDef(
          type: OutcomeType.attributeBonus,
          attributeKey: AttributeKey.fortune,
        ),
      },
    );
    await encounterService.getOrCreate(saveDataId: 1);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );
    await service.commitCore(
      identity: identity(),
      now: DateTime.utc(2026, 8, 25, 0, 1),
      applyInTxn: () async => [encounter(1)],
    );

    await expectLater(
      service.apply(
        identity: identity(),
        affair: encounter(1),
        now: DateTime.utc(2026, 8, 25, 0, 2),
        applyInTxn: () async {
          await encounterService.applyOutcomeInTxn(
            saveDataId: 1,
            encounter: def,
            outcomeId: 'gain_fortune',
          );
          await encounterService.markTriggeredInTxn(
            saveDataId: 1,
            encounterId: def.id,
          );
          throw StateError('injected after real encounter writes');
        },
      ),
      throwsStateError,
    );

    final progress = await IsarSetup.instance.encounterProgress
        .filter()
        .saveDataIdEqualTo(1)
        .findFirst();
    expect(progress!.attributeGainsTotal, 0);
    expect(progress.triggeredEncounterIds, isEmpty);
    expect(await service.firstPending(identity: identity()), encounter(1));
  });

  test('拒绝重复 ref，回滚后 journal 仍为 prepared', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );

    await expectLater(
      service.commitCore(
        identity: identity(),
        now: DateTime.utc(2026, 8, 25, 0, 1),
        applyInTxn: () async => [encounter(1), encounter(1)],
      ),
      throwsStateError,
    );
    expect(
      (await journal.activeForSave(1))!.phase,
      MainlineSettlementPhase.prepared,
    );
  });

  test('同一 canonical source 即使 ordinal 不同也拒绝重复入队', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );
    final duplicateSource = MainlinePendingJianghuAffairRef.encounterChoice(
      settlementId: identity().canonical,
      encounterId: 'test-1',
      ordinal: 2,
      resolutionSeed: 999,
    );

    await expectLater(
      service.commitCore(
        identity: identity(),
        now: DateTime.utc(2026, 8, 25, 0, 1),
        applyInTxn: () async => [encounter(1), duplicateSource],
      ),
      throwsStateError,
    );
    expect(
      (await journal.activeForSave(1))!.phase,
      MainlineSettlementPhase.prepared,
    );
  });

  test('未 claim 的 presenting 事项重启后重新呈现，重放 core 不重复入队', () async {
    var journal = MainlineSettlementJournalService(IsarSetup.instance);
    var service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 25),
    );
    expect(
      await service.commitCore(
        identity: identity(),
        now: DateTime.utc(2026, 8, 25, 0, 1),
        applyInTxn: () async => [encounter(1), encounter(2)],
      ),
      MainlineCoreCommitDisposition.applied,
    );

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    journal = MainlineSettlementJournalService(IsarSetup.instance);
    service = MainlinePendingJianghuAffairService(journal);

    expect(await service.firstPending(identity: identity()), encounter(1));
    expect(
      await service.commitCore(
        identity: identity(),
        now: DateTime.utc(2026, 8, 25, 0, 2),
        applyInTxn: () async => [encounter(1), encounter(2)],
      ),
      MainlineCoreCommitDisposition.alreadyApplied,
    );
    final restored = await journal.journalFor(identity());
    expect(restored!.pendingEffectIds, hasLength(2));
    expect(restored.completedEffectIds, isEmpty);
  });

  test('0.40.0 旧 receipt 空 outbox 与 typed facade 兼容', () async {
    final journal = MainlineSettlementJournalService(IsarSetup.instance);
    final service = MainlinePendingJianghuAffairService(journal);
    await journal.prepare(
      saveDataId: 1,
      identity: identity(),
      loadoutSnapshotId: 'snapshot-1',
      now: DateTime.utc(2026, 8, 24),
    );
    await journal.commitCore(
      identity: identity(),
      pendingEffectIds: const [],
      now: DateTime.utc(2026, 8, 24, 0, 1),
      applyInTxn: () async {},
    );

    expect(await service.firstPending(identity: identity()), isNull);
  });
}
