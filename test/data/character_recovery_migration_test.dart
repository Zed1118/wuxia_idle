import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../fixtures/legacy_character_recovery.dart';
import '../support/isar_test_support.dart';

void main() {
  final createdAt = DateTime(2026, 9, 1);
  final lastOnlineAt = DateTime(2026, 9, 2, 12);
  final retreatStartedAt = DateTime(2026, 9, 2, 8);
  late Directory directory;

  setUpAll(initializeTestIsarCore);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recovery_migration_');
  });
  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<List<Map<String, dynamic>>> seedLegacy({
    bool establishedPresence = true,
    bool activeRetreat = false,
  }) async {
    final old = await Isar.open(
      [SaveDataSchema, LegacyCharacterRecoverySchema, RetreatSessionSchema],
      directory: directory.path,
      name: 'wuxia_save_slot1',
      inspector: false,
    );
    try {
      await old.writeTxn(() async {
        await old.saveDatas.put(
          SaveData()
            ..id = 0
            ..slotId = 1
            ..saveVersion = '0.51.0'
            ..createdAt = createdAt
            ..lastSavedAt = lastOnlineAt
            ..lastOnlineAt = establishedPresence ? lastOnlineAt : createdAt
            ..founderCharacterId = 2
            ..activeCharacterIds = [2],
        );
        await old.collection<LegacyCharacterRecovery>().putAll([
          for (final id in [1, 2, 3])
            LegacyCharacterRecovery()
              ..id = id
              ..name = 'legacy-$id'
              ..realmTier = RealmTier.xueTu
              ..realmLayer = RealmLayer.qiMeng
              ..attributes = Attributes()
              ..lineageRole = LineageRole.disciple
              ..isFounder = id != 3
              ..isActive = id == 2
              ..isAlive = id != 3
              ..isInRetreat = activeRetreat && id == 2
              ..currentRetreatSessionId = activeRetreat && id == 2 ? 77 : null
              ..createdAt = id == 3
                  ? lastOnlineAt.add(const Duration(minutes: 30))
                  : createdAt
              ..experience = id * 13
              ..passiveExperienceRemainder = 0.25
              ..injuryHoursRemaining = 8.5
              ..innerBreathDisorderHoursRemaining = 6.25
              ..lightInjuryStacks = 3,
        ]);
        if (activeRetreat) {
          await old.retreatSessions.put(
            RetreatSession()
              ..id = 77
              ..saveDataId = 1
              ..mapType = RetreatMapType.shanLin
              ..realmTierAtStart = RealmTier.xueTu
              ..startedAt = retreatStartedAt
              ..status = RetreatStatus.active,
          );
        }
      });
      return await old
          .collection<LegacyCharacterRecovery>()
          .where()
          .exportJson();
    } finally {
      await old.close();
    }
  }

  Future<List<Map<String, dynamic>>> currentRows() =>
      IsarSetup.instance.characters.where().exportJson();

  List<Map<String, dynamic>> withoutAnchor(List<Map<String, dynamic>> rows) => [
    for (final row in rows)
      Map<String, dynamic>.from(row)..remove('recoverySettledAt'),
  ];

  test('frozen 0.51 schema omits only the recovery timestamp', () {
    expect(LegacyCharacterRecoverySchema.name, CharacterSchema.name);
    expect(LegacyCharacterRecoverySchema.id, CharacterSchema.id);
    expect(
      LegacyCharacterRecoverySchema.properties.keys.toSet(),
      CharacterSchema.properties.keys.toSet()..remove('recoverySettledAt'),
    );
    expect(
      LegacyCharacterRecoverySchema.properties,
      isNot(contains('recoverySettledAt')),
    );
    for (final property in LegacyCharacterRecoverySchema.properties.values) {
      final current = CharacterSchema.properties[property.name]!;
      expect(current.type, property.type, reason: property.name);
      expect(current.target, property.target, reason: property.name);
      expect(current.enumMap, property.enumMap, reason: property.name);
    }
  });

  test(
    'real missing field is initialized without healing or changing old data',
    () async {
      final before = await seedLegacy();
      final raw = await Isar.open(
        IsarSetup.schemasForTesting,
        directory: directory.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        final rows = await raw.characters.where().exportJson();
        expect(rows.every((row) => row['recoverySettledAt'] == null), isTrue);
        expect(withoutAnchor(rows), before);
      } finally {
        await raw.close();
      }

      await IsarSetup.init(directory: directory, inspector: false);
      final migrated = await currentRows();
      expect(
        migrated.every((row) => row['recoverySettledAt'] != null),
        isTrue,
        reason: 'The real missing timestamp must be initialized by migration',
      );
      expect(withoutAnchor(migrated), before);
      expect(IsarSetup.currentSaveVersion, '0.52.0');
      for (final id in [1, 2]) {
        expect(
          (await IsarSetup.instance.characters.get(id))!.recoverySettledAt,
          lastOnlineAt,
        );
      }
      expect(
        (await IsarSetup.instance.characters.get(3))!.recoverySettledAt,
        lastOnlineAt.add(const Duration(minutes: 30)),
        reason: 'A trusted presence boundary cannot predate this character',
      );
      final save = (await IsarSetup.currentSaveData())!;
      expect(save.lastOnlineAt, lastOnlineAt);
      expect(save.lastSavedAt, lastOnlineAt);
      for (var reopen = 0; reopen < 2; reopen++) {
        await IsarSetup.close();
        await IsarSetup.init(directory: directory, inspector: false);
        expect(await currentRows(), migrated);
      }
    },
  );

  test(
    'active retreat keeps its full start-time entitlement for the actual owner',
    () async {
      final before = await seedLegacy(activeRetreat: true);
      await IsarSetup.init(directory: directory, inspector: false);
      expect(
        (await IsarSetup.instance.characters.get(1))!.recoverySettledAt,
        lastOnlineAt,
        reason: 'Historical founder status does not identify the retreat owner',
      );
      expect(
        (await IsarSetup.instance.characters.get(2))!.recoverySettledAt,
        retreatStartedAt,
      );
      expect(withoutAnchor(await currentRows()), before);
      final session = (await IsarSetup.instance.retreatSessions.get(77))!;
      expect(session.startedAt, retreatStartedAt);
      expect(session.status, RetreatStatus.active);
      expect(session.completedAt, isNull);
    },
  );

  test(
    'unestablished presence starts at migration time without inventing prior recovery',
    () async {
      final before = await seedLegacy(establishedPresence: false);
      final beforeMigration = DateTime.now();
      await IsarSetup.init(directory: directory, inspector: false);
      final afterMigration = DateTime.now();
      for (final character
          in await IsarSetup.instance.characters.where().findAll()) {
        expect(character.recoverySettledAt!.isBefore(beforeMigration), isFalse);
        expect(character.recoverySettledAt!.isAfter(afterMigration), isFalse);
      }
      expect(withoutAnchor(await currentRows()), before);
    },
  );

  test(
    'existing anchor survives migration replay and current-version nulls stay null',
    () async {
      await seedLegacy();
      final raw = await Isar.open(
        IsarSetup.schemasForTesting,
        directory: directory.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      final existingAnchor = lastOnlineAt.add(const Duration(hours: 3));
      try {
        await raw.writeTxn(() async {
          final character = (await raw.characters.get(1))!
            ..recoverySettledAt = existingAnchor;
          await raw.characters.put(character);
        });
      } finally {
        await raw.close();
      }
      await IsarSetup.init(directory: directory, inspector: false);
      expect(
        (await IsarSetup.instance.characters.get(1))!.recoverySettledAt,
        existingAnchor,
      );
      await IsarSetup.instance.writeTxn(() async {
        final character = (await IsarSetup.instance.characters.get(2))!
          ..recoverySettledAt = null;
        await IsarSetup.instance.characters.put(character);
      });
      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false);
      expect(
        (await IsarSetup.instance.characters.get(1))!.recoverySettledAt,
        existingAnchor,
      );
      expect(
        (await IsarSetup.instance.characters.get(2))!.recoverySettledAt,
        isNull,
      );
    },
  );

  for (final defect in ['missing owner', 'duplicate owners', 'wrong slot']) {
    test(
      'ambiguous retreat $defect rolls back anchors and version atomically',
      () async {
        await seedLegacy(activeRetreat: true);
        var raw = await Isar.open(
          IsarSetup.schemasForTesting,
          directory: directory.path,
          name: 'wuxia_save_slot1',
          inspector: false,
        );
        try {
          await raw.writeTxn(() async {
            if (defect == 'wrong slot') {
              final session = (await raw.retreatSessions.get(77))!
                ..saveDataId = 2;
              await raw.retreatSessions.put(session);
            } else {
              final character =
                  (await raw.characters.get(defect == 'missing owner' ? 2 : 1))!
                    ..currentRetreatSessionId = defect == 'missing owner'
                        ? null
                        : 77;
              await raw.characters.put(character);
            }
          });
        } finally {
          await raw.close();
        }
        await expectLater(
          IsarSetup.init(directory: directory, inspector: false),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'diagnostic session id',
              contains('77'),
            ),
          ),
        );
        expect(IsarSetup.instanceOrNull, isNull);
        raw = await Isar.open(
          IsarSetup.schemasForTesting,
          directory: directory.path,
          name: 'wuxia_save_slot1',
          inspector: false,
        );
        try {
          expect((await raw.saveDatas.get(0))!.saveVersion, '0.51.0');
          expect(
            (await raw.characters.where().findAll()).every(
              (character) => character.recoverySettledAt == null,
            ),
            isTrue,
          );
          expect((await raw.characters.get(2))!.injuryHoursRemaining, 8.5);
        } finally {
          await raw.close();
        }
      },
    );
  }
}
