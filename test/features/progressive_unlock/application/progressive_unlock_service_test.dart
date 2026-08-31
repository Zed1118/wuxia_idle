import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/progressive_unlock/application/progressive_unlock_service.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';

import '../../../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('progressive_unlock_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProgressiveUnlockSnapshot snapshot({
    ProgressiveUnlockState lightFoot = ProgressiveUnlockState.heard,
    ProgressiveUnlockState massBattle = ProgressiveUnlockState.heard,
    ProgressiveUnlockState expedition = ProgressiveUnlockState.hidden,
  }) {
    return ProgressiveUnlockSnapshot({
      ProgressiveUnlockId.tower: ProgressiveUnlockState.open,
      ProgressiveUnlockId.lightFoot: lightFoot,
      ProgressiveUnlockId.discipleScheduling: ProgressiveUnlockState.open,
      ProgressiveUnlockId.massBattle: massBattle,
      ProgressiveUnlockId.expedition: expedition,
      ProgressiveUnlockId.gauntlet: ProgressiveUnlockState.hidden,
      ProgressiveUnlockId.innerDemon: ProgressiveUnlockState.hidden,
    });
  }

  test(
    'first observation establishes a quiet baseline for existing saves',
    () async {
      final service = ProgressiveUnlockService(IsarSetup.instance);
      final pending = await service.observe(
        saveDataId: 1,
        snapshot: snapshot(),
        now: DateTime(2026, 9, 1),
      );

      expect(pending, isEmpty);
      final receipts = await IsarSetup.instance.progressiveUnlockReceipts
          .where()
          .findAll();
      expect(receipts, hasLength(7));
      expect(
        receipts
            .where((row) => row.highestState == ProgressiveUnlockState.open)
            .every((row) => row.sealAcknowledgedAt != null),
        isTrue,
        reason: '升级旧档和新档首帧都不能补弹历史上已开放的入口',
      );
    },
  );

  test(
    'heard to open creates durable pending seals until acknowledged',
    () async {
      final first = ProgressiveUnlockService(IsarSetup.instance);
      await first.observe(
        saveDataId: 1,
        snapshot: snapshot(),
        now: DateTime(2026, 9, 1, 0),
      );

      final opened = snapshot(
        lightFoot: ProgressiveUnlockState.open,
        massBattle: ProgressiveUnlockState.open,
      );
      final pending = await first.observe(
        saveDataId: 1,
        snapshot: opened,
        now: DateTime(2026, 9, 1, 1),
      );
      expect(pending.map((entry) => entry.unlockId).toSet(), {
        ProgressiveUnlockId.lightFoot,
        ProgressiveUnlockId.massBattle,
      });

      final afterRestart = ProgressiveUnlockService(IsarSetup.instance);
      expect(
        (await afterRestart.observe(
          saveDataId: 1,
          snapshot: opened,
          now: DateTime(2026, 9, 1, 2),
        )).map((entry) => entry.unlockId).toSet(),
        {ProgressiveUnlockId.lightFoot, ProgressiveUnlockId.massBattle},
        reason: '弹窗关闭前崩溃必须在重启后继续恢复待确认题签',
      );

      await afterRestart.acknowledge(
        saveDataId: 1,
        unlockIds: pending.map((entry) => entry.unlockId),
        now: DateTime(2026, 9, 1, 3),
      );
      expect(
        await afterRestart.observe(
          saveDataId: 1,
          snapshot: opened,
          now: DateTime(2026, 9, 1, 4),
        ),
        isEmpty,
        reason: '已收下蜡封不得永久红点化或重复弹出',
      );
    },
  );

  test(
    'a later downgrade cannot reopen or erase an acknowledged fact',
    () async {
      final service = ProgressiveUnlockService(IsarSetup.instance);
      await service.observe(
        saveDataId: 1,
        snapshot: snapshot(),
        now: DateTime(2026, 9, 1, 0),
      );
      final opened = snapshot(lightFoot: ProgressiveUnlockState.open);
      final pending = await service.observe(
        saveDataId: 1,
        snapshot: opened,
        now: DateTime(2026, 9, 1, 1),
      );
      await service.acknowledge(
        saveDataId: 1,
        unlockIds: pending.map((entry) => entry.unlockId),
        now: DateTime(2026, 9, 1, 2),
      );

      await service.observe(
        saveDataId: 1,
        snapshot: snapshot(lightFoot: ProgressiveUnlockState.heard),
        now: DateTime(2026, 9, 1, 3),
      );
      final row = await IsarSetup.instance.progressiveUnlockReceipts
          .filter()
          .receiptKeyEqualTo('v1:1:lightFoot')
          .findFirst();
      expect(row!.highestState, ProgressiveUnlockState.open);
      expect(row.sealAcknowledgedAt, isNotNull);
    },
  );

  test(
    'hidden to heard stays quiet and only the later open transition seals',
    () async {
      final service = ProgressiveUnlockService(IsarSetup.instance);
      await service.observe(
        saveDataId: 1,
        snapshot: snapshot(),
        now: DateTime(2026, 9, 1, 0),
      );

      expect(
        await service.observe(
          saveDataId: 1,
          snapshot: snapshot(expedition: ProgressiveUnlockState.heard),
          now: DateTime(2026, 9, 1, 1),
        ),
        isEmpty,
      );
      expect(
        (await service.observe(
          saveDataId: 1,
          snapshot: snapshot(expedition: ProgressiveUnlockState.open),
          now: DateTime(2026, 9, 1, 2),
        )).map((entry) => entry.unlockId),
        [ProgressiveUnlockId.expedition],
      );
    },
  );

  test('acknowledge rejects duplicates before mutating the receipt', () async {
    final service = ProgressiveUnlockService(IsarSetup.instance);
    await service.observe(
      saveDataId: 1,
      snapshot: snapshot(),
      now: DateTime(2026, 9, 1, 0),
    );
    await service.observe(
      saveDataId: 1,
      snapshot: snapshot(lightFoot: ProgressiveUnlockState.open),
      now: DateTime(2026, 9, 1, 1),
    );

    expect(
      () => service.acknowledge(
        saveDataId: 1,
        unlockIds: const [
          ProgressiveUnlockId.lightFoot,
          ProgressiveUnlockId.lightFoot,
        ],
        now: DateTime(2026, 9, 1, 2),
      ),
      throwsArgumentError,
    );
    final row = await IsarSetup.instance.progressiveUnlockReceipts
        .getByReceiptKey('v1:1:lightFoot');
    expect(row!.sealAcknowledgedAt, isNull);
  });

  test('acknowledge is atomic when any requested receipt is missing', () async {
    final service = ProgressiveUnlockService(IsarSetup.instance);
    await service.observe(
      saveDataId: 1,
      snapshot: snapshot(),
      now: DateTime(2026, 9, 1, 0),
    );
    await service.observe(
      saveDataId: 1,
      snapshot: snapshot(lightFoot: ProgressiveUnlockState.open),
      now: DateTime(2026, 9, 1, 1),
    );
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.progressiveUnlockReceipts.deleteByReceiptKey(
        'v1:1:expedition',
      ),
    );

    expect(
      () => service.acknowledge(
        saveDataId: 1,
        unlockIds: const [
          ProgressiveUnlockId.lightFoot,
          ProgressiveUnlockId.expedition,
        ],
        now: DateTime(2026, 9, 1, 2),
      ),
      throwsStateError,
    );
    final row = await IsarSetup.instance.progressiveUnlockReceipts
        .getByReceiptKey('v1:1:lightFoot');
    expect(row!.sealAcknowledgedAt, isNull);
  });

  test(
    'identity drift fails closed without replacing the durable row',
    () async {
      final service = ProgressiveUnlockService(IsarSetup.instance);
      await service.observe(
        saveDataId: 1,
        snapshot: snapshot(),
        now: DateTime(2026, 9, 1, 0),
      );
      final row = await IsarSetup.instance.progressiveUnlockReceipts
          .getByReceiptKey('v1:1:lightFoot');
      await IsarSetup.instance.writeTxn(() async {
        row!.receiptVersion = 99;
        await IsarSetup.instance.progressiveUnlockReceipts.put(row);
      });

      expect(
        () => service.observe(
          saveDataId: 1,
          snapshot: snapshot(lightFoot: ProgressiveUnlockState.open),
          now: DateTime(2026, 9, 1, 1),
        ),
        throwsStateError,
      );
      final unchanged = await IsarSetup.instance.progressiveUnlockReceipts
          .getByReceiptKey('v1:1:lightFoot');
      expect(unchanged!.receiptVersion, 99);
      expect(unchanged.highestState, ProgressiveUnlockState.heard);
    },
  );
}
