import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_recruit_transaction_service.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sect_recruit_txn_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('默认门派、角色创建与入派由 caller 单事务提交', () async {
    final isar = IsarSetup.instance;
    final candidate =
        GameRepository.instance.sectCandidates['bamboo_swordsman']!;
    late SectRecruitTransactionResult result;

    await isar.writeTxn(() async {
      result = await SectRecruitTransactionService(isar).recruitInTxn(
        candidate: candidate,
        defaultSectName: 'test-sect',
        now: DateTime.utc(2026, 8, 25),
      );
    });

    expect(result, SectRecruitTransactionResult.success);
    final character = (await isar.characters.where().findAll()).single;
    expect(character.name, candidate.name);
    expect(character.isInSect, isTrue);
    final sect = (await isar.sects.where().findAll()).single;
    expect(sect.name, 'test-sect');
    expect(sect.memberCount, 1);
  });

  test('玩家婉拒时仍可在 claim 事务内保留旧的默认门派懒初始化', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await SectRecruitTransactionService(isar).ensureDefaultSectInTxn(
        defaultSectName: 'test-sect',
        now: DateTime.utc(2026, 8, 25),
      );
    });

    expect(await isar.characters.count(), 0);
    expect((await isar.sects.get(1))!.name, 'test-sect');
  });

  test('caller 后续注入失败时默认门派、角色与成员计数整体回滚', () async {
    final isar = IsarSetup.instance;
    final candidate =
        GameRepository.instance.sectCandidates['bamboo_swordsman']!;

    await expectLater(
      isar.writeTxn(() async {
        await SectRecruitTransactionService(isar).recruitInTxn(
          candidate: candidate,
          defaultSectName: 'test-sect',
          now: DateTime.utc(2026, 8, 25),
        );
        throw StateError('injected after business write');
      }),
      throwsStateError,
    );

    expect(await isar.characters.count(), 0);
    expect(await isar.sects.count(), 0);
  });

  test('满员时不遗留孤儿角色且不改变成员计数', () async {
    final isar = IsarSetup.instance;
    final cap = SectMemberService.memberCapFor(
      GameRepository.instance.numbers,
      1,
    );
    await isar.writeTxn(() async {
      await isar.sects.put(
        Sect()
          ..id = 1
          ..name = 'full-sect'
          ..founderId = 1
          ..sectLevel = 1
          ..sectReputation = 50
          ..totalWins = 0
          ..memberCount = cap
          ..territoryIds = []
          ..createdAt = DateTime.utc(2026, 8, 25),
      );
    });

    late SectRecruitTransactionResult result;
    await isar.writeTxn(() async {
      result = await SectRecruitTransactionService(isar).recruitInTxn(
        candidate: GameRepository.instance.sectCandidates['bamboo_swordsman']!,
        defaultSectName: 'unused',
        now: DateTime.utc(2026, 8, 25),
      );
    });

    expect(result, SectRecruitTransactionResult.fullCap);
    expect(await isar.characters.count(), 0);
    expect((await isar.sects.get(1))!.memberCount, cap);
  });
}
