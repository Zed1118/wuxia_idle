import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/sweep_readiness.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_readiness_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

// Delay transaction acquisition only. Every collection read and transaction
// still uses the real native Isar database; no data or service result is faked.
class _QueuedWriteIsar extends Fake implements Isar {
  _QueuedWriteIsar(this.database);

  final Isar database;
  final requested = Completer<void>();
  final release = Completer<void>();

  @override
  IsarCollection<T> collection<T>() => database.collection<T>();

  @override
  Future<T> writeTxn<T>(
    Future<T> Function() callback, {
    bool silent = false,
  }) async {
    requested.complete();
    await release.future;
    return database.writeTxn(callback, silent: silent);
  }
}

void main() {
  late Directory directory;
  final start = DateTime(2026, 9, 13, 10);
  final now = start.add(const Duration(hours: 5, minutes: 30));
  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sweep_concurrent_save_');
    await IsarSetup.init(directory: directory, inspector: false);
    final database = IsarSetup.instance;
    final character = Character.create(
      name: 'concurrent startup fixture',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: start.subtract(const Duration(days: 1)),
      internalForce: 500,
    )..id = 1;
    await database.writeTxn(() async {
      await database.characters.put(character);
      final save = (await database.saveDatas.get(0))!
        ..founderCharacterId = character.id
        ..activeCharacterIds = [character.id]
        ..createdAt = character.createdAt
        ..lastOnlineAt = start
        ..passiveLastSettledAt = start
        ..sweepReadinessPoints = 60
        ..sweepReadinessLastRecoveredAt = start;
      await database.saveDatas.put(save);
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  test(
    'queued readiness refresh preserves passive ledger across reopen',
    () async {
      final database = IsarSetup.instance;
      final queued = _QueuedWriteIsar(database);
      final refresh = SweepReadinessService(
        isar: queued,
        config: config,
      ).getStatus(now: now);
      try {
        await queued.requested.future.timeout(const Duration(seconds: 5));
        final accrual = await OfflinePassiveService.settleWindow(
          isar: database,
          now: now,
          updatePresence: true,
        );
        expect(accrual!.experience, 16);
        expect(accrual.mojianshi, 1);
      } finally {
        queued.release.complete();
        await refresh;
      }

      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false);
      final reopened = IsarSetup.instance;
      final save = (await reopened.saveDatas.get(0))!;
      expect(save.totalPassiveExperience, 16);
      expect(save.totalPassiveMojianshi, 1);
      expect(save.passiveLastSettledAt, now);
      expect(save.lastOnlineAt, now);
      expect(save.passiveMojianshiRemainder, closeTo(0.375, 1e-9));
      expect(save.sweepReadinessPoints, 60);
      expect(save.sweepReadinessLastRecoveredAt, now);

      final repeated = await OfflinePassiveService.settleWindow(
        isar: reopened,
        now: now,
        updatePresence: true,
      );
      expect(repeated, isNull);
      final character = (await reopened.characters.get(1))!;
      expect(character.experience, 16);
      expect(character.passiveExperienceRemainder, closeTo(0.5, 1e-9));
      expect(
        (await reopened.inventoryItems.getByDefId('item_mojianshi'))!.quantity,
        1,
      );
    },
  );

  test('queued readiness refresh preserves a completed sweep spend', () async {
    final database = IsarSetup.instance;
    final queued = _QueuedWriteIsar(database);
    final refresh = SweepReadinessService(
      isar: queued,
      config: config,
    ).getStatus(now: now);
    try {
      await queued.requested.future.timeout(const Duration(seconds: 5));
      final spent = await SweepReadinessService(
        isar: database,
        config: config,
      ).trySpendMainlineStages(5, now: now);
      expect(spent, isTrue);
    } finally {
      queued.release.complete();
      await refresh;
    }
    expect((await refresh).points, 55);
    final save = (await database.saveDatas.get(0))!;
    expect(save.sweepReadinessPoints, 55);
    expect(save.sweepReadinessLastRecoveredAt, now);
  });
}
