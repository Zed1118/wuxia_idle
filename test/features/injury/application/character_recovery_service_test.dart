import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/injury/application/character_recovery_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/isar_test_support.dart';

void main() {
  final start = DateTime(2026, 9, 2, 8);
  Character injured({int id = 1, DateTime? anchor}) => Character.create(
    name: 'injured-$id',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.disciple,
    createdAt: start.subtract(const Duration(days: 1)),
    recoverySettledAt: anchor,
    injuryHoursRemaining: 8,
    innerBreathDisorderHoursRemaining: 6,
    lightInjuryStacks: 3,
  )..id = id;

  test(
    'foreground partitions and one offline interval heal equally, retaining light stacks',
    () {
      final continuous = injured(anchor: start);
      final segmented = injured(anchor: start);
      for (var minute = 1; minute <= 120; minute++) {
        expect(
          CharacterRecoveryService.settleCharacter(
            character: segmented,
            now: start.add(Duration(minutes: minute)),
          ),
          isTrue,
        );
      }
      CharacterRecoveryService.settleCharacter(
        character: continuous,
        now: start.add(const Duration(hours: 2)),
      );
      expect(continuous.injuryHoursRemaining, 6);
      expect(continuous.innerBreathDisorderHoursRemaining, 4);
      expect(segmented.injuryHoursRemaining, closeTo(6, 1e-10));
      expect(segmented.innerBreathDisorderHoursRemaining, closeTo(4, 1e-10));
      expect(segmented.lightInjuryStacks, 3);
      expect(continuous.lightInjuryStacks, 3);
      expect(segmented.recoverySettledAt, continuous.recoverySettledAt);
    },
  );

  test(
    'same timestamp is idempotent, and explicit rest may clear light only once',
    () {
      final character = injured(anchor: start);
      expect(
        CharacterRecoveryService.settleCharacter(
          character: character,
          now: start,
        ),
        isFalse,
      );
      expect(character.lightInjuryStacks, 3);
      expect(
        CharacterRecoveryService.settleCharacter(
          character: character,
          now: start,
          clearLightInjury: true,
        ),
        isTrue,
      );
      expect(character.lightInjuryStacks, 0);
      expect(character.injuryHoursRemaining, 8);
      expect(character.innerBreathDisorderHoursRemaining, 6);
      expect(
        CharacterRecoveryService.settleCharacter(
          character: character,
          now: start,
          clearLightInjury: true,
        ),
        isFalse,
      );
    },
  );

  test('two hours of injury reach exactly zero after 120 minute ticks', () {
    final character = injured(anchor: start)
      ..injuryHoursRemaining = 2
      ..innerBreathDisorderHoursRemaining = 2;
    for (var minute = 1; minute <= 120; minute++) {
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: start.add(Duration(minutes: minute)),
      );
    }
    expect(character.injuryHoursRemaining, 0);
    expect(character.innerBreathDisorderHoursRemaining, 0);
    expect(character.lightInjuryStacks, 3);
  });

  test(
    'clock rollback does not heal, clear light, or move an established anchor',
    () {
      final character = injured(anchor: start);
      expect(
        CharacterRecoveryService.settleCharacter(
          character: character,
          now: start.subtract(const Duration(hours: 1)),
          clearLightInjury: true,
        ),
        isFalse,
      );
      expect(character.recoverySettledAt, start);
      expect(character.injuryHoursRemaining, 8);
      expect(character.innerBreathDisorderHoursRemaining, 6);
      expect(character.lightInjuryStacks, 3);
    },
  );

  test('no trustworthy fallback starts now without retroactive healing', () {
    final character = injured();
    expect(
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: start,
      ),
      isTrue,
    );
    expect(character.recoverySettledAt, start);
    expect(character.injuryHoursRemaining, 8);
    expect(character.innerBreathDisorderHoursRemaining, 6);
    CharacterRecoveryService.settleCharacter(
      character: character,
      now: start.add(const Duration(minutes: 30)),
    );
    expect(character.injuryHoursRemaining, 7.5);
    expect(character.innerBreathDisorderHoursRemaining, 5.5);
  });

  test('trusted fallback never recovers time before character creation', () {
    final character = injured()
      ..createdAt = start.add(const Duration(minutes: 30));
    CharacterRecoveryService.settleCharacter(
      character: character,
      now: start.add(const Duration(hours: 1)),
      fallbackAnchor: start,
    );
    expect(character.injuryHoursRemaining, 7.5);
    expect(character.innerBreathDisorderHoursRemaining, 5.5);
  });

  test('future fallback is not written or consumed during clock rollback', () {
    final character = injured();
    expect(
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: start,
        fallbackAnchor: start.add(const Duration(hours: 1)),
        clearLightInjury: true,
      ),
      isFalse,
    );
    expect(character.recoverySettledAt, isNull);
    expect(character.injuryHoursRemaining, 8);
    expect(character.lightInjuryStacks, 3);
  });

  test(
    'elapsed recovery precedes new injury; no prior interval is charged twice',
    () {
      final character = injured(anchor: start);
      final battleAt = start.add(const Duration(hours: 2));
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: battleAt,
      );
      character.injuryHoursRemaining = 8;
      character.innerBreathDisorderHoursRemaining += 2;
      expect(
        CharacterRecoveryService.settleCharacter(
          character: character,
          now: battleAt,
        ),
        isFalse,
      );
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: battleAt.add(const Duration(hours: 1)),
      );
      expect(character.injuryHoursRemaining, 7);
      expect(character.innerBreathDisorderHoursRemaining, 5);
    },
  );

  test(
    'long elapsed time reaches zero without modifying permanent or legacy fields',
    () {
      final character = injured(anchor: start)
        ..experience = 19
        ..internalForce = 123
        ..innerDemonResidueHoursRemaining = 4;
      CharacterRecoveryService.settleCharacter(
        character: character,
        now: start.add(const Duration(days: 100)),
      );
      expect(character.injuryHoursRemaining, 0);
      expect(character.innerBreathDisorderHoursRemaining, 0);
      expect(character.innerDemonResidueHoursRemaining, 4);
      expect(character.experience, 19);
      expect(character.internalForce, 123);
    },
  );

  group('caller-owned transaction', () {
    late Directory directory;
    late Isar isar;
    setUpAll(initializeTestIsarCore);
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('character_recovery_');
      isar = await Isar.open(
        [CharacterSchema, SaveDataSchema, RetreatSessionSchema],
        directory: directory.path,
        name: 'character_recovery',
        inspector: false,
      );
      await isar.writeTxn(() async {
        await isar.saveDatas.put(
          SaveData()
            ..id = 0
            ..slotId = 1
            ..createdAt = start.subtract(const Duration(days: 1))
            ..lastOnlineAt = start
            ..lastSavedAt = start
            ..saveVersion = '0.52.0'
            ..founderCharacterId = 2,
        );
        await isar.characters.putAll([
          injured(id: 1, anchor: start)..isFounder = true,
          injured(id: 2, anchor: start)..isFounder = true,
          injured(id: 3, anchor: start),
          injured(id: 4, anchor: start)..isAlive = false,
        ]);
      });
    });
    tearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });

    test(
      'all living characters recover, including prior leader and disciple',
      () async {
        final at = start.add(const Duration(hours: 2));
        await isar.writeTxn(
          () => CharacterRecoveryService.settleWithinTxn(isar: isar, now: at),
        );
        for (final id in [1, 2, 3]) {
          final character = (await isar.characters.get(id))!;
          expect(character.injuryHoursRemaining, 6);
          expect(character.innerBreathDisorderHoursRemaining, 4);
          expect(character.lightInjuryStacks, 3);
          expect(character.recoverySettledAt, at);
        }
        final dead = (await isar.characters.get(4))!;
        expect(dead.injuryHoursRemaining, 8);
        expect(dead.recoverySettledAt, start);
      },
    );

    test(
      'requested ids are isolated, duplicate and missing ids do not double settle',
      () async {
        await isar.writeTxn(
          () => CharacterRecoveryService.settleWithinTxn(
            isar: isar,
            now: start.add(const Duration(hours: 1)),
            characterIds: [3, 3, 4, 999],
          ),
        );
        expect((await isar.characters.get(3))!.injuryHoursRemaining, 7);
        for (final id in [1, 2, 4]) {
          expect((await isar.characters.get(id))!.injuryHoursRemaining, 8);
          expect((await isar.characters.get(id))!.recoverySettledAt, start);
        }
      },
    );

    test('outer transaction failure rolls back the recovery ledger', () async {
      await expectLater(
        isar.writeTxn(() async {
          await CharacterRecoveryService.settleWithinTxn(
            isar: isar,
            now: start.add(const Duration(hours: 1)),
          );
          throw StateError('abort caller');
        }),
        throwsStateError,
      );
      expect((await isar.characters.get(1))!.injuryHoursRemaining, 8);
      expect((await isar.characters.get(1))!.recoverySettledAt, start);
    });

    test(
      'legacy runtime fallback uses presence or the referenced active retreat start',
      () async {
        await isar.writeTxn(() async {
          final ordinary = (await isar.characters.get(1))!
            ..recoverySettledAt = null;
          final retreating = (await isar.characters.get(2))!
            ..recoverySettledAt = null
            ..isInRetreat = true
            ..currentRetreatSessionId = 77;
          await isar.characters.putAll([ordinary, retreating]);
          await isar.retreatSessions.put(
            RetreatSession()
              ..id = 77
              ..saveDataId = 1
              ..mapType = RetreatMapType.shanLin
              ..startedAt = start.subtract(const Duration(hours: 2)),
          );
          await CharacterRecoveryService.settleWithinTxn(
            isar: isar,
            now: start.add(const Duration(hours: 1)),
            characterIds: [1, 2],
          );
        });
        expect((await isar.characters.get(1))!.injuryHoursRemaining, 7);
        expect((await isar.characters.get(2))!.injuryHoursRemaining, 5);
      },
    );

    test(
      'unestablished presence cannot lend time to a character with no anchor',
      () async {
        await isar.writeTxn(() async {
          final save = (await isar.saveDatas.get(0))!;
          save.lastOnlineAt = save.createdAt;
          await isar.saveDatas.put(save);
          final character = (await isar.characters.get(3))!
            ..recoverySettledAt = null;
          await isar.characters.put(character);
          await CharacterRecoveryService.settleWithinTxn(
            isar: isar,
            now: start,
            characterIds: [3],
          );
        });
        expect((await isar.characters.get(3))!.injuryHoursRemaining, 8);
        expect((await isar.characters.get(3))!.recoverySettledAt, start);
      },
    );
  });
}
