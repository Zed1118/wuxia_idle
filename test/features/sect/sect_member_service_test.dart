import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/sect_member_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_rank.dart';

/// P4.1 §12.2 B4 R5.1+R5.2+R5.3 测族(spec p4_1_sect_management_spec §7)。
///
/// **R5.1** 招收 e2e(success / fullCap / alreadyInSect / targetNotFound)
/// **R5.2** sectRank 三阶单向(initiate→inner / inner→elder / elder→alreadyMax / belowThreshold)
/// **R5.3** 双向 fk 一致性(recruit 后 Character.sectId == sect.id / dismiss 后字段全 null + memberCount--)
///
/// **fixture 策略**(沿 sect_isar_persistence_test + ascend_service_test 体例):
/// - 真 Isar 实例(`IsarSetup.init` + tempDir)
/// - 加载真 yaml(`GameRepository.loadAllDefs` · 用 `numbers.sectManagement.{memberCap,
///   rankPromoteThreshold}` 阈值)
/// - 不复用 Phase2SeedService(不需要 active/equipment 副作用)· minimal seed
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_sect_member_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// 创 sect(默认 sectLevel=1 cap=3)+ N 个候选 Character。
  Future<({int sectId, int founderId, List<int> candidateIds})> seed({
    int sectLevel = 1,
    int candidateCount = 3,
    int initialMemberCount = 0,
  }) async {
    final isar = IsarSetup.instance;
    late int sectId;
    final candidateIds = <int>[];
    var founderId = 0;
    await isar.writeTxn(() async {
      final founder = Character.create(
        name: '祖师',
        realmTier: RealmTier.wuSheng,
        realmLayer: RealmLayer.dengFeng,
        attributes: Attributes()
          ..constitution = 7
          ..enlightenment = 7
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.jueShi,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 5, 25),
        isFounder: true,
      );
      founderId = await isar.characters.put(founder);

      for (var i = 0; i < candidateCount; i++) {
        final c = Character.create(
          name: '候选$i',
          realmTier: RealmTier.sanLiu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.xunChang,
          lineageRole: LineageRole.disciple,
          createdAt: DateTime(2026, 5, 25),
        );
        candidateIds.add(await isar.characters.put(c));
      }

      final sect = Sect()
        ..name = '青锋门'
        ..founderId = founderId
        ..sectLevel = sectLevel
        ..sectReputation = 50
        ..totalWins = 0
        ..memberCount = initialMemberCount
        ..territoryIds = []
        ..createdAt = DateTime(2026, 5, 25);
      sectId = await isar.sects.put(sect);
    });
    return (sectId: sectId, founderId: founderId, candidateIds: candidateIds);
  }

  SectMemberService makeSvc() => SectMemberService(IsarSetup.instance);

  group('R5.1 招收 e2e', () {
    test('recruit 成功 → 三字段写入 + memberCount++', () async {
      final f = await seed(candidateCount: 1);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      late RecruitResult r;
      await isar.writeTxn(() async {
        r = await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, RecruitResult.success);
      final t = await isar.characters.get(f.candidateIds.first);
      expect(t!.isInSect, true);
      expect(t.sectId, f.sectId);
      expect(t.sectRank, SectRank.initiate);
      final sect = await isar.sects.get(f.sectId);
      expect(sect!.memberCount, 1);
    });

    test('cap 满 → RecruitResult.fullCap', () async {
      // sectLevel=1 → cap=3(numbers.yaml memberCap.bySectLevel[0]=3)
      final f = await seed(candidateCount: 1, initialMemberCount: 3);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      late RecruitResult r;
      await isar.writeTxn(() async {
        r = await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, RecruitResult.fullCap);
    });

    test('target 已入派 → alreadyInSect', () async {
      final f = await seed(candidateCount: 1);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      late RecruitResult r;
      await isar.writeTxn(() async {
        r = await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, RecruitResult.alreadyInSect);
    });

    test('target 不存在 → targetNotFound', () async {
      final f = await seed(candidateCount: 0);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      late RecruitResult r;
      await isar.writeTxn(() async {
        r = await svc.recruit(
          targetCharacterId: 99999,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, RecruitResult.targetNotFound);
    });
  });

  group('R5.2 sectRank 三阶单向升迁', () {
    Future<int> recruitOne(
      ({int sectId, int founderId, List<int> candidateIds}) f,
    ) async {
      final isar = IsarSetup.instance;
      final svc = makeSvc();
      await isar.writeTxn(() async {
        await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      return f.candidateIds.first;
    }

    test('initiate → inner 阈值达 → success', () async {
      final f = await seed(candidateCount: 1);
      final mid = await recruitOne(f);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      late PromoteResult r;
      await isar.writeTxn(() async {
        r = await svc.promoteRank(
          characterId: mid,
          contribution: 100,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, PromoteResult.success);
      final t = await isar.characters.get(mid);
      expect(t!.sectRank, SectRank.inner);
    });

    test('inner → elder 阈值达 → success', () async {
      final f = await seed(candidateCount: 1);
      final mid = await recruitOne(f);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await svc.promoteRank(
          characterId: mid,
          contribution: 100,
          numbers: GameRepository.instance.numbers,
        );
      });
      late PromoteResult r;
      await isar.writeTxn(() async {
        r = await svc.promoteRank(
          characterId: mid,
          contribution: 100,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, PromoteResult.success);
      final t = await isar.characters.get(mid);
      expect(t!.sectRank, SectRank.elder);
    });

    test('elder 顶阶 → alreadyMax(不可降阶)', () async {
      final f = await seed(candidateCount: 1);
      final mid = await recruitOne(f);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      // 升到 elder
      for (var i = 0; i < 2; i++) {
        await isar.writeTxn(() async {
          await svc.promoteRank(
            characterId: mid,
            contribution: 100,
            numbers: GameRepository.instance.numbers,
          );
        });
      }
      late PromoteResult r;
      await isar.writeTxn(() async {
        r = await svc.promoteRank(
          characterId: mid,
          contribution: 100,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, PromoteResult.alreadyMax);
    });

    test('贡献不足 → belowThreshold', () async {
      final f = await seed(candidateCount: 1);
      final mid = await recruitOne(f);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      late PromoteResult r;
      await isar.writeTxn(() async {
        r = await svc.promoteRank(
          characterId: mid,
          contribution: 0,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, PromoteResult.belowThreshold);
    });
  });

  group('R5.3 双向 fk 一致性', () {
    test('recruit 后 Character.sectId == sect.id + isInSect=true', () async {
      final f = await seed(candidateCount: 1);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      final t = await isar.characters.get(f.candidateIds.first);
      expect(t!.sectId, f.sectId);
      expect(t.isInSect, true);
      expect(t.sectRank, isNotNull);
    });

    test('dismiss 后三字段全 null + memberCount--', () async {
      final f = await seed(candidateCount: 1);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await svc.recruit(
          targetCharacterId: f.candidateIds.first,
          sectId: f.sectId,
          numbers: GameRepository.instance.numbers,
        );
      });
      late DismissResult r;
      await isar.writeTxn(() async {
        r = await svc.dismiss(characterId: f.candidateIds.first);
      });
      expect(r, DismissResult.success);
      final t = await isar.characters.get(f.candidateIds.first);
      expect(t!.isInSect, false);
      expect(t.sectId, null);
      expect(t.sectRank, null);
      final sect = await isar.sects.get(f.sectId);
      expect(sect!.memberCount, 0);
    });
  });
}
