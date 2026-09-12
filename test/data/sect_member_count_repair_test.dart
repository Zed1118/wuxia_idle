import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/sect_rank.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/sect_member_count_repair.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';

import '../fixtures/legacy_sect_member_count.dart';
import '../support/isar_test_support.dart';
import '../support/test_data.dart';

const _missingLong = -9223372036854775808;
final _createdAt = DateTime.utc(2026, 9, 7);

Character _character(
  int id, {
  bool joined = true,
  int sectId = 1,
  bool isFounder = false,
  bool isAlive = true,
  bool isActive = false,
  LineageRole lineageRole = LineageRole.disciple,
}) =>
    Character.create(
        name: 'Character $id',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: lineageRole,
        createdAt: _createdAt,
        isFounder: isFounder,
        isActive: isActive,
      )
      ..id = id
      ..isAlive = isAlive
      ..isInSect = joined
      ..sectId = joined ? sectId : null
      ..sectRank = joined ? SectRank.initiate : null;

Character _founder({bool joined = false}) => _character(
  1,
  joined: joined,
  isFounder: true,
  lineageRole: LineageRole.founder,
);

Sect _sect({int id = 1, int founderId = 1, int count = _missingLong}) => Sect()
  ..id = id
  ..name = 'Sect $id'
  ..founderId = founderId
  ..sectLevel = 1
  ..sectReputation = 37
  ..totalWins = 5
  ..createdAt = _createdAt
  ..memberCount = count;

SaveData _save({int slotId = 1, int? founderId = 1}) => SaveData()
  ..slotId = slotId
  ..saveVersion = '0.48.0'
  ..createdAt = _createdAt
  ..lastSavedAt = _createdAt
  ..lastOnlineAt = _createdAt
  ..founderCharacterId = founderId;

void main() {
  late Directory dir;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sect_count_repair_');
  });

  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    await dir.delete(recursive: true);
  });

  Future<void> seed({
    required List<Character> characters,
    List<Sect>? sects,
    int slotId = 1,
    int? founderId = 1,
  }) async {
    final raw = await Isar.open(
      [SaveDataSchema, CharacterSchema, SectSchema],
      directory: dir.path,
      name: 'wuxia_save_slot$slotId',
      inspector: false,
    );
    try {
      await raw.writeTxn(() async {
        await raw.saveDatas.put(_save(slotId: slotId, founderId: founderId));
        await raw.characters.putAll(characters);
        await raw.sects.putAll(sects ?? [_sect()]);
      });
    } finally {
      await raw.close();
    }
  }

  Future<void> seedLegacy(List<Character> characters) async {
    final old = await Isar.open(
      [SaveDataSchema, CharacterSchema, LegacySectWithoutMemberCountSchema],
      directory: dir.path,
      name: 'wuxia_save_slot1',
      inspector: false,
    );
    try {
      expect(
        LegacySectWithoutMemberCountSchema.properties,
        isNot(contains('memberCount')),
      );
      await old.writeTxn(() async {
        await old.saveDatas.put(_save());
        await old.characters.putAll(characters);
        await old.collection<LegacySectWithoutMemberCount>().put(
          LegacySectWithoutMemberCount(),
        );
      });
    } finally {
      await old.close();
    }
  }

  Future<void> open({int slotId = 1}) =>
      IsarSetup.init(slotId: slotId, directory: dir, inspector: false);

  Future<int> count([int sectId = 1]) async =>
      (await IsarSetup.instance.sects.get(sectId))!.memberCount;

  void expectIssue({int sectId = 1, int? characterId}) {
    final issues = IsarSetup.sectMemberCountRepairIssues;
    expect(issues, isNotEmpty);
    expect(
      issues.any(
        (issue) =>
            issue.sectId == sectId &&
            (characterId == null || issue.characterId == characterId),
      ),
      isTrue,
    );
  }

  test(
    'real missing property is rebuilt through init and survives reopening',
    () async {
      await seedLegacy([_founder(joined: true), _character(2), _character(3)]);
      final raw = await Isar.open(
        [SaveDataSchema, CharacterSchema, SectSchema],
        directory: dir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        expect((await raw.sects.get(1))!.memberCount, _missingLong);
      } finally {
        await raw.close();
      }

      await open();
      expect(await count(), 2);
      expect((await IsarSetup.currentSaveData())!.saveVersion, '0.50.0');
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
      await IsarSetup.close();
      await open();
      expect(await count(), 2);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
    },
  );

  test('0.48 sentinel plus prior recruitment increments is rebuilt', () async {
    await seed(
      characters: [_founder(), _character(2), _character(3)],
      sects: [
        _sect(count: _missingLong + 3)..territoryIds = ['kept'],
      ],
    );
    await open();
    final repaired = (await IsarSetup.instance.sects.get(1))!;
    expect(repaired.memberCount, 2);
    expect(repaired.name, 'Sect 1');
    expect(repaired.founderId, 1);
    expect(repaired.sectReputation, 37);
    expect(repaired.totalWins, 5);
    expect(repaired.territoryIds, ['kept']);
    expect(repaired.createdAt, _createdAt.toLocal());
  });

  test(
    'existing nonnegative cache is preserved even when associations differ',
    () async {
      await seed(characters: [_founder()], sects: [_sect(count: 7)]);
      await open();
      expect(await count(), 7);
      await IsarSetup.instance.writeTxn(() async {
        final sect = (await IsarSetup.instance.sects.get(1))!..memberCount = 0;
        await IsarSetup.instance.sects.put(sect);
        await IsarSetup.instance.characters.put(_character(2));
      });
      await IsarSetup.close();
      await open();
      expect(await count(), 0);
    },
  );

  test(
    'empty associations repair to zero with a confirmed unjoined founder',
    () async {
      await seed(characters: [_founder()]);
      await open();
      expect(await count(), 0);
      final founder = (await IsarSetup.instance.characters.get(1))!;
      expect(founder.isInSect, isFalse);
      expect(founder.sectId, isNull);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
    },
  );

  test(
    'only exact current founder is excluded; former dead and inactive count',
    () async {
      await seed(
        characters: [
          _founder(joined: true),
          _character(2, isFounder: true, lineageRole: LineageRole.founder),
          _character(3, isAlive: false),
          _character(4),
          _character(5, isActive: true, lineageRole: LineageRole.grandDisciple),
        ],
      );
      await open();
      expect(await count(), 4);
      final dead = (await IsarSetup.instance.characters.get(3))!;
      expect(dead.isAlive, isFalse);
      expect(dead.isInSect, isTrue);
      expect((await IsarSetup.instance.characters.get(4))!.isActive, isFalse);
    },
  );

  test(
    'confirmed successor with disciple role supplies current founder identity',
    () async {
      await seed(
        founderId: 42,
        sects: [_sect(founderId: 42)],
        characters: [_founder(joined: true), _character(42, isFounder: true)],
      );
      await open();
      expect(await count(), 1);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
    },
  );

  test(
    'consistent members of another existing sect do not inflate local count',
    () async {
      await seed(
        sects: [_sect(), _sect(id: 2, founderId: 9, count: 8)],
        characters: [
          _founder(),
          _character(2),
          _character(9, sectId: 2, isFounder: true),
          _character(10, sectId: 2),
        ],
      );
      await open();
      expect(await count(), 1);
      expect(await count(2), 8);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
    },
  );

  final conflicts =
      <
        ({
          String name,
          int? founderId,
          List<Character> Function() characters,
          List<Sect> Function()? sects,
          int? characterId,
        })
      >[
        (
          name: 'missing save founder pointer',
          founderId: null,
          characters: () => [_founder(), _character(2)],
          sects: null,
          characterId: null,
        ),
        (
          name: 'save and sect founder pointers disagree',
          founderId: 2,
          characters: () => [_founder(), _character(2, isFounder: true)],
          sects: null,
          characterId: null,
        ),
        (
          name: 'referenced founder does not exist',
          founderId: 1,
          characters: () => [_character(2)],
          sects: null,
          characterId: null,
        ),
        (
          name: 'numeric founder reference lacks confirmed founder flag',
          founderId: 1,
          characters: () => [_character(1, joined: false), _character(2)],
          sects: null,
          characterId: null,
        ),
        (
          name: 'current founder is associated with a different sect',
          founderId: 1,
          characters: () => [_character(1, sectId: 2, isFounder: true)],
          sects: () => [_sect(), _sect(id: 2, count: 0)],
          characterId: null,
        ),
        (
          name: 'false membership flag retains the target sect foreign key',
          founderId: 1,
          characters: () => [_founder(), _character(2)..isInSect = false],
          sects: null,
          characterId: 2,
        ),
        (
          name: 'true membership has no rank',
          founderId: 1,
          characters: () => [_founder(), _character(2)..sectRank = null],
          sects: null,
          characterId: 2,
        ),
      ];
  for (final conflict in conflicts) {
    test(
      '${conflict.name}: original negative value and diagnostic survive',
      () async {
        await seed(
          founderId: conflict.founderId,
          characters: conflict.characters(),
          sects: conflict.sects?.call(),
        );
        await open();
        expect(await count(), _missingLong);
        expectIssue(characterId: conflict.characterId);
        await IsarSetup.close();
        await open();
        expect(await count(), _missingLong);
        expectIssue(characterId: conflict.characterId);
      },
    );
  }

  test(
    'unassigned and dangling membership prevent guessing an apparently empty sect',
    () async {
      await seed(
        characters: [
          _founder(),
          _character(2)..sectId = null,
          _character(3, sectId: 999),
        ],
      );
      await open();
      expect(await count(), _missingLong);
      expectIssue();
      expect(
        IsarSetup.sectMemberCountRepairIssues
            .map((issue) => issue.characterId)
            .whereType<int>(),
        containsAll([2, 3]),
      );
    },
  );

  test(
    'unsupported sect identity keeps its negative count and reports separately',
    () async {
      await seed(
        sects: [
          _sect(),
          _sect(id: 2, founderId: 9, count: _missingLong + 1),
        ],
        characters: [_founder(), _character(2)],
      );
      await open();
      expect(await count(), 1);
      expect(await count(2), _missingLong + 1);
      expectIssue(sectId: 2);
    },
  );

  test(
    'same version retries corrected relationships after retaining prior issues',
    () async {
      await seed(characters: [_founder(), _character(2)..isInSect = false]);
      await open();
      expect((await IsarSetup.currentSaveData())!.saveVersion, '0.50.0');
      expect(await count(), _missingLong);
      expectIssue(characterId: 2);
      await IsarSetup.close();
      await open();
      expectIssue(characterId: 2);
      await IsarSetup.instance.writeTxn(() async {
        final member = (await IsarSetup.instance.characters.get(2))!
          ..isInSect = true;
        await IsarSetup.instance.characters.put(member);
      });
      await IsarSetup.close();
      await open();
      expect((await IsarSetup.currentSaveData())!.saveVersion, '0.50.0');
      expect(await count(), 1);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
    },
  );

  test(
    'slot files and repair diagnostics remain isolated across switching',
    () async {
      await seed(founderId: null, characters: [_founder()]);
      await seed(slotId: 2, characters: [_founder(), _character(2)]);
      final untouched = File('${dir.path}/wuxia_save_slot2.isar');
      final before = await untouched.readAsBytes();
      await open();
      expect(await count(), _missingLong);
      expectIssue();
      await IsarSetup.close();
      expect(await untouched.readAsBytes(), before);
      await open(slotId: 2);
      expect(await count(), 1);
      expect((await IsarSetup.currentSaveData())!.slotId, 2);
      expect(IsarSetup.sectMemberCountRepairIssues, isEmpty);
      await IsarSetup.close();
      await open();
      expect(await count(), _missingLong);
      expectIssue();
    },
  );

  test(
    'repaired count enforces real recruitment cap and supports dismissal',
    () async {
      final numbers = GameRepository.instance.numbers;
      final cap = SectMemberService.memberCapFor(numbers, 1);
      expect(cap, greaterThan(0));
      await seedLegacy([
        _founder(),
        for (var index = 0; index < cap; index++) _character(index + 2),
        _character(1000, joined: false),
      ]);
      await open();
      final isar = IsarSetup.instance;
      final service = SectMemberService(isar);
      expect(await count(), cap);
      expect(
        await isar.writeTxn(
          () => service.recruit(
            targetCharacterId: 1000,
            sectId: 1,
            numbers: numbers,
          ),
        ),
        RecruitResult.fullCap,
      );
      expect((await isar.characters.get(1000))!.isInSect, isFalse);
      expect(await count(), cap);
      expect(
        await isar.writeTxn(() => service.dismiss(characterId: 2)),
        DismissResult.success,
      );
      expect(await count(), cap - 1);
      expect(
        await isar.writeTxn(
          () => service.recruit(
            targetCharacterId: 1000,
            sectId: 1,
            numbers: numbers,
          ),
        ),
        RecruitResult.success,
      );
      expect(await count(), cap);
      expect((await isar.characters.get(1000))!.sectId, 1);
    },
  );

  test(
    'direct recruitment rejects every invalid negative cache without writes',
    () async {
      await seed(
        characters: [_founder(), _character(2, joined: false)],
        sects: [_sect(count: 0)],
      );
      await open();
      final isar = IsarSetup.instance;
      final service = SectMemberService(isar);
      for (final invalid in [_missingLong, _missingLong + 1, -1]) {
        await isar.writeTxn(() async {
          final sect = (await isar.sects.get(1))!..memberCount = invalid;
          await isar.sects.put(sect);
        });
        expect(
          await isar.writeTxn(
            () => service.recruit(
              targetCharacterId: 2,
              sectId: 1,
              numbers: GameRepository.instance.numbers,
            ),
          ),
          RecruitResult.invalidMemberCount,
        );
        expect(await count(), invalid);
        final candidate = (await isar.characters.get(2))!;
        expect(candidate.isInSect, isFalse);
        expect(candidate.sectId, isNull);
        expect(candidate.sectRank, isNull);
        expect(await isar.characters.count(), 2);
        expect(await isar.sects.count(), 1);
      }
    },
  );

  test(
    'caller transaction rolls back repair and version when later work fails',
    () async {
      await seed(characters: [_founder(), _character(2)]);
      final raw = await Isar.open(
        [SaveDataSchema, CharacterSchema, SectSchema],
        directory: dir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        await expectLater(
          raw.writeTxn(() async {
            final save = (await raw.saveDatas.get(0))!;
            final issues = await SectMemberCountRepair.repairInTxn(raw, save);
            expect(issues, isEmpty);
            expect((await raw.sects.get(1))!.memberCount, 1);
            save.saveVersion = '0.49.0';
            await raw.saveDatas.put(save);
            throw StateError('failure after staged repair and version update');
          }),
          throwsStateError,
        );
        expect((await raw.sects.get(1))!.memberCount, _missingLong);
        expect((await raw.saveDatas.get(0))!.saveVersion, '0.48.0');
        expect((await raw.characters.get(2))!.isInSect, isTrue);
      } finally {
        await raw.close();
      }
    },
  );
}
