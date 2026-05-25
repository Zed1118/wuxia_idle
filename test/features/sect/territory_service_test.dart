import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/sect/application/territory_service.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';

/// P4.1 §12.2 B4 R5.4 territory claim e2e 测族(spec p4_1_sect_management_spec §7)。
///
/// **R5.4** territory claim/release/availableForClaim/cap 校验。
///
/// **fixture 策略**:
/// - 真 Isar(`IsarSetup.init` + tempDir)+ 真 yaml(`GameRepository.loadAllDefs` 取
///   territoryDefs 6 territory 池 + `numbers.sectManagement.territory.maxPerSectByLevel` cap)
/// - minimal sect seed(单 Sect · 不需要 Character)
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_territory_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<int> seedSect({int sectLevel = 1}) async {
    final isar = IsarSetup.instance;
    late int sectId;
    await isar.writeTxn(() async {
      final s = Sect()
        ..name = '青锋门'
        ..founderId = 1
        ..sectLevel = sectLevel
        ..sectReputation = 50
        ..totalWins = 0
        ..memberCount = 0
        ..territoryIds = []
        ..createdAt = DateTime(2026, 5, 25);
      sectId = await isar.sects.put(s);
    });
    return sectId;
  }

  TerritoryService makeSvc() => TerritoryService(IsarSetup.instance);

  group('R5.4 territory claim e2e', () {
    test('claim 后 sect.territoryIds 含 id + availableForClaim 不再含', () async {
      final sectId = await seedSect();
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      final defs = TerritoryService.allDefs();
      expect(defs.isNotEmpty, true, reason: 'territories.yaml 加载非空');
      final targetId = defs.first.id;

      late ClaimResult r;
      await isar.writeTxn(() async {
        r = await svc.claim(
          sectId: sectId,
          territoryId: targetId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, ClaimResult.success);

      final sect = await isar.sects.get(sectId);
      expect(sect!.territoryIds.contains(targetId), true);

      final available = await svc.availableForClaim();
      expect(available.any((d) => d.id == targetId), false);
    });

    test('cap 满 → fullCap(sectLevel=1 max=1)', () async {
      // sectLevel=1 cap=1(numbers.yaml territory.maxPerSectByLevel[0]=1)
      final sectId = await seedSect(sectLevel: 1);
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      final defs = TerritoryService.allDefs();
      // 第一块成功
      await isar.writeTxn(() async {
        await svc.claim(
          sectId: sectId,
          territoryId: defs[0].id,
          numbers: GameRepository.instance.numbers,
        );
      });
      // 第二块满 cap
      late ClaimResult r;
      await isar.writeTxn(() async {
        r = await svc.claim(
          sectId: sectId,
          territoryId: defs[1].id,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, ClaimResult.fullCap);
    });

    test('release 后 sect.territoryIds 不再含 + availableForClaim 复出', () async {
      final sectId = await seedSect();
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      final defs = TerritoryService.allDefs();
      final targetId = defs.first.id;

      await isar.writeTxn(() async {
        await svc.claim(
          sectId: sectId,
          territoryId: targetId,
          numbers: GameRepository.instance.numbers,
        );
      });
      late ReleaseResult r;
      await isar.writeTxn(() async {
        r = await svc.release(sectId: sectId, territoryId: targetId);
      });
      expect(r, ReleaseResult.success);

      final sect = await isar.sects.get(sectId);
      expect(sect!.territoryIds.contains(targetId), false);

      final available = await svc.availableForClaim();
      expect(available.any((d) => d.id == targetId), true);
    });

    test('alreadyOwned → 重复 claim 返 alreadyOwned', () async {
      final sectId = await seedSect(sectLevel: 7); // 升 cap 防 fullCap 干扰
      final svc = makeSvc();
      final isar = IsarSetup.instance;
      final defs = TerritoryService.allDefs();
      final targetId = defs.first.id;
      await isar.writeTxn(() async {
        await svc.claim(
          sectId: sectId,
          territoryId: targetId,
          numbers: GameRepository.instance.numbers,
        );
      });
      late ClaimResult r;
      await isar.writeTxn(() async {
        r = await svc.claim(
          sectId: sectId,
          territoryId: targetId,
          numbers: GameRepository.instance.numbers,
        );
      });
      expect(r, ClaimResult.alreadyOwned);
    });
  });
}
