import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

class _FixedClock extends SystemClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

// Only delay transaction acquisition; all reads and writes use native Isar.
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
    if (!requested.isCompleted) {
      requested.complete();
      await release.future;
    }
    return database.writeTxn(callback, silent: silent);
  }
}

void main() {
  late Directory directory;
  late ProviderContainer container;
  final now = DateTime(2026, 9, 13, 20);

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sect_monthly_startup_');
    await IsarSetup.init(directory: directory, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(
        Character.create(
          name: 'monthly startup founder',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          createdAt: now,
          internalForce: 500,
        )..id = 1,
      );
      final save = (await isar.saveDatas.get(0))!
        ..founderCharacterId = 1
        ..activeCharacterIds = [1];
      await isar.saveDatas.put(save);
    });
    container = ProviderContainer(
      overrides: [systemClockProvider.overrideWithValue(_FixedClock(now))],
    );
  });

  tearDown(() async {
    // Dispose paused streams before closing Isar, including after a tick timeout.
    container.dispose();
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  Future<void> tick() => container
      .read(monthlyTickCoordinatorProvider)
      .tick(now)
      .timeout(const Duration(seconds: 5));

  test(
    'startup without UI listeners creates the default sect and completes',
    () async {
      expect(await IsarSetup.instance.sects.get(1), isNull);

      await tick();

      final sect = (await IsarSetup.instance.sects.get(1))!;
      expect(sect.name, UiStrings.sectLazyInitName);
      expect(sect.founderId, 1);
      expect(sect.createdAt, now);
      expect(sect.lastTickAt, isNull);
      expect(sect.sectReputation, 50);
      expect(await IsarSetup.instance.sectEvents.count(), 0);
    },
  );

  test(
    'startup without UI listeners persists expiry and monthly progress once',
    () async {
      final isar = IsarSetup.instance;
      final config = GameRepository.instance.numbers.sectEvent;
      final createdAt = now.subtract(const Duration(days: 65));
      final event = SectEvent()
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = now.subtract(
          Duration(days: config.tournament.expireDays),
        )
        ..narrativeId = config.tournament.narrativeIds.first;
      await isar.writeTxn(() async {
        await isar.sects.put(
          Sect()
            ..id = 1
            ..name = 'existing sect'
            ..founderId = 1
            ..createdAt = createdAt
            ..sectLevel = 1
            ..sectReputation = 50
            ..totalWins = 0,
        );
        await isar.sectEvents.put(event);
      });

      await tick();

      final sect = (await isar.sects.get(1))!;
      final expired = (await isar.sectEvents.get(event.id))!;
      expect(sect.name, 'existing sect');
      expect(sect.createdAt, createdAt);
      expect(sect.lastTickAt, createdAt.add(const Duration(days: 60)));
      expect(sect.lastEventAt, now);
      expect(sect.sectReputation, 50 + config.reputation.lossDelta);
      expect(expired.status, SectEventStatus.expired);
      expect(expired.resolvedAt, now);
      expect(expired.reputationDelta, config.reputation.lossDelta);
      expect(await isar.sectEvents.count(), 1);

      await tick();

      final repeated = (await isar.sects.get(1))!;
      expect(repeated.lastTickAt, sect.lastTickAt);
      expect(repeated.lastEventAt, sect.lastEventAt);
      expect(repeated.sectReputation, sect.sectReputation);
      expect(await isar.sectEvents.count(), 1);
    },
  );

  test(
    'lazy initialization preserves a sect created while its write is queued',
    () async {
      final database = IsarSetup.instance;
      final queued = _QueuedWriteIsar(database);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          systemClockProvider.overrideWithValue(_FixedClock(now)),
          isarProvider.overrideWithValue(queued),
        ],
      );
      final startup = tick();
      try {
        await queued.requested.future.timeout(const Duration(seconds: 5));
        await database.writeTxn(
          () => database.sects.put(
            Sect()
              ..id = 1
              ..name = 'concurrently created sect'
              ..founderId = 1
              ..createdAt = now
              ..sectLevel = 4
              ..sectReputation = 80
              ..totalWins = 12,
          ),
        );
      } finally {
        queued.release.complete();
        await startup;
      }

      final sect = (await database.sects.get(1))!;
      expect(sect.name, 'concurrently created sect');
      expect(sect.createdAt, now);
      expect(sect.sectLevel, 4);
      expect(sect.sectReputation, 80);
      expect(sect.totalWins, 12);
    },
  );
}
