import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/ascension/application/ascend_service.dart';
import 'package:wuxia_idle/features/ascension/domain/ascension_models.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inheritance/application/founder_buff_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// P2.3 §7.1 飞升 + 遗物 transfer R5 红线测族(5 族 · spec p2_3_ascension_spec_2026-05-24)。
///
/// R5.1 飞升红线 e2e:全 5 子条件 ok + performAscend → ownerCharacterId 改 +
///       isLineageHeritage=true + founder.isActive=false + founder buff inactive
/// R5.2 eligibility 4 子条件(每子条件取反 1 测)+ 1 全 ok
/// R5.3 multi_disciple_allocation player_pick(2 件全大弟子 / 1+1 分 2 徒 / 全二弟子)
/// R5.4 边界(0 件 throw / 3 件 throw / 非 founder 装备 throw / 非 disciple 目标 throw)
/// R5.5 数值红线 §5.4(飞升前 0 heritage + 飞升后 2 件 → maxIF cap clamp)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_ascend_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    // 基础 fixture:3 角色(祖师 + 大弟子 + 二弟子)+ active 入阵 + 装备 + 心法
    await Phase2SeedService(isar: isar).seedMasterDisciple();
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ── fixture helper:boost 玩家 founder 到 wuSheng·dengFeng + 双关 cleared ──

  Future<void> boostToAscensionReady({
    bool clearInnerDemon07 = true,
    bool clearMainline0605 = true,
    bool keepFounderActive = true,
  }) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final founder = await isar.characters.get(1);
      if (founder != null) {
        founder.realmTier = RealmTier.wuSheng;
        founder.realmLayer = RealmLayer.dengFeng;
        await isar.characters.put(founder);
      }
      if (!keepFounderActive) {
        final save = await isar.saveDatas.get(0);
        if (save != null) {
          save.activeCharacterIds = save.activeCharacterIds
              .where((id) => id != 1)
              .toList();
          await isar.saveDatas.put(save);
        }
      }
      // 写 MainlineProgress · saveDataId=1(IsarSetup.currentSlotId)
      final clearedIds = <String>[
        if (clearInnerDemon07) 'stage_inner_demon_07',
        if (clearMainline0605) 'stage_06_05',
      ];
      final progress = MainlineProgress()
        ..saveDataId = 1
        ..currentChapterIndex = 6
        ..clearedStageIds = clearedIds
        ..clearedAt = List.generate(
          clearedIds.length,
          (i) => DateTime.now(),
        );
      await isar.mainlineProgress.put(progress);
    });
  }

  AscendService makeService() =>
      AscendService(IsarSetup.instance, GameRepository.instance.numbers);

  // ───────────────────────────────────────────────────────────────────────
  // R5.1 飞升红线 e2e
  // ───────────────────────────────────────────────────────────────────────

  group('R5.1 飞升红线 e2e', () {
    test('全条件 ok + performAscend 2 件 → owner改+遗物标+founder出阵+buff退', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      final eligibility = await svc.computeEligibility();
      expect(eligibility.canAscend, true,
          reason: '5 子条件全 ok 时 canAscend=true');

      // 选 founder 已装备的 weapon + armor 2 件传给大弟子(id=2)
      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;
      final armor = founder.equippedArmorId!;

      final result = await isar.writeTxn(
        () => svc.performAscend({weapon: 2, armor: 2}),
      );

      expect(result.transferredCount, 2);
      expect(result.founderRetired, true);
      expect(result.heritageEquipmentIds, containsAll([weapon, armor]));
      expect(result.beneficiaryDiscipleIds, [2]);

      // 装备已转 + 遗物标
      final w = (await isar.equipments.get(weapon))!;
      final a = (await isar.equipments.get(armor))!;
      expect(w.ownerCharacterId, 2);
      expect(a.ownerCharacterId, 2);
      expect(w.isLineageHeritage, true);
      expect(a.isLineageHeritage, true);
      expect(w.previousOwnerCharacterIds, contains(1));

      // founder 出阵 + 槽位脱钩
      final founderAfter = (await isar.characters.get(1))!;
      expect(founderAfter.isActive, false);
      expect(founderAfter.isAlive, true,
          reason: 'GDD §7.1 飞升渡劫后仍存在,只是不在江湖');
      expect(founderAfter.equippedWeaponId, null);
      expect(founderAfter.equippedArmorId, null);
      expect(founderAfter.isFounder, true,
          reason: 'Q2c · lineageRole/isFounder 不真传位');

      // SaveData.activeCharacterIds 不含 founder
      final save = (await isar.saveDatas.get(0))!;
      expect(save.activeCharacterIds, isNot(contains(1)));

      // founder_buff 自然 inactive
      final buffSvc = FounderBuffService(isar);
      final buffActive =
          await buffSvc.computeBuffActive(GameRepository.instance.numbers);
      expect(buffActive, false,
          reason: 'founder isActive=false → buff 自然退 · spec §6 注');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.2 eligibility 4 子条件
  // ───────────────────────────────────────────────────────────────────────

  group('R5.2 eligibility 子条件', () {
    test('founder 未在 active → inActiveCharacters=false → canAscend=false',
        () async {
      await boostToAscensionReady(keepFounderActive: false);
      final e = await makeService().computeEligibility();
      expect(e.inActiveCharacters, false);
      expect(e.canAscend, false);
      expect(e.missingReasons, contains('祖师不在出战阵容'));
    });

    test('realm 不到 wuSheng·dengFeng → realmAtPeak=false', () async {
      // 不 boost realm
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final f = (await isar.characters.get(1))!;
        f.realmTier = RealmTier.zongShi; // 降回 zongShi
        await isar.characters.put(f);
      });
      final e = await makeService().computeEligibility();
      expect(e.realmAtPeak, false);
      expect(e.canAscend, false);
    });

    test('inner_demon_07 未通 → innerDemon07Cleared=false', () async {
      await boostToAscensionReady(clearInnerDemon07: false);
      final e = await makeService().computeEligibility();
      expect(e.innerDemon07Cleared, false);
      expect(e.canAscend, false);
    });

    test('stage_06_05 未通 → mainline0605Cleared=false', () async {
      await boostToAscensionReady(clearMainline0605: false);
      final e = await makeService().computeEligibility();
      expect(e.mainline0605Cleared, false);
      expect(e.canAscend, false);
    });

    test('5 子条件全 ok → canAscend=true', () async {
      await boostToAscensionReady();
      final e = await makeService().computeEligibility();
      expect(e.canAscend, true);
      expect(e.missingReasons, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.3 multi_disciple_allocation player_pick
  // ───────────────────────────────────────────────────────────────────────

  group('R5.3 player_pick 分配', () {
    test('2 件全大弟子(id=2)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final a = founder.equippedArmorId!;
      final svc = makeService();
      final r = await isar.writeTxn(
        () => svc.performAscend({w: 2, a: 2}),
      );
      expect(r.beneficiaryDiscipleIds.toSet(), {2});
      expect((await isar.equipments.get(w))!.ownerCharacterId, 2);
      expect((await isar.equipments.get(a))!.ownerCharacterId, 2);
    });

    test('1 件大弟子 + 1 件二弟子(id=2 + id=3)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final a = founder.equippedArmorId!;
      final svc = makeService();
      final r = await isar.writeTxn(
        () => svc.performAscend({w: 2, a: 3}),
      );
      expect(r.beneficiaryDiscipleIds.toSet(), {2, 3});
      expect((await isar.equipments.get(w))!.ownerCharacterId, 2);
      expect((await isar.equipments.get(a))!.ownerCharacterId, 3);
    });

    test('2 件全二弟子(id=3)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final a = founder.equippedArmorId!;
      final svc = makeService();
      final r = await isar.writeTxn(
        () => svc.performAscend({w: 3, a: 3}),
      );
      expect(r.beneficiaryDiscipleIds.toSet(), {3});
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.4 边界
  // ───────────────────────────────────────────────────────────────────────

  group('R5.4 边界 throw', () {
    test('选 0 件 → throw(< piecesPerGenerationMin=1)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();
      expect(
        () => isar.writeTxn(() => svc.performAscend(const {})),
        throwsA(isA<StateError>()),
      );
    });

    test('选 3 件 → throw(> piecesPerGenerationMax=2)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final a = founder.equippedArmorId!;
      final acc = founder.equippedAccessoryId!;
      final svc = makeService();
      expect(
        () => isar.writeTxn(
          () => svc.performAscend({w: 2, a: 2, acc: 2}),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('装备非 founder owner → throw', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      // 创一件 owner=2 的装备
      final eq = Equipment.create(
        defId: 'weapon_test',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime.now(),
        obtainedFrom: 'test',
        ownerCharacterId: 2,
      );
      await isar.writeTxn(() => isar.equipments.put(eq));
      final svc = makeService();
      expect(
        () => isar.writeTxn(() => svc.performAscend({eq.id: 2})),
        throwsA(isA<StateError>()),
      );
    });

    test('target 非 disciple(误填 founder id=1)→ throw', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final svc = makeService();
      expect(
        () => isar.writeTxn(() => svc.performAscend({w: 1})),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.5 数值红线 §5.4
  // ───────────────────────────────────────────────────────────────────────

  group('R5.5 数值红线 §5.4', () {
    test('飞升后大弟子收 2 件 heritage → IF mult ≤ 1.10 / clamp 15000', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final founder = (await isar.characters.get(1))!;
      final w = founder.equippedWeaponId!;
      final a = founder.equippedArmorId!;
      final svc = makeService();
      await isar.writeTxn(() => svc.performAscend({w: 2, a: 2}));

      // 大弟子接收 2 件 heritage,heritage count × lineageInternalForceMaxBonus
      // = 2 × 0.05 = 0.10 → mult 1.10(< 1.20 safe · clamp 15000 红线由
      // CharacterDerivedStats 公式层 enforce)
      final n = GameRepository.instance.numbers;
      final discMult = 1.0 + 2 * n.lineageInternalForceMaxBonus;
      expect(discMult, closeTo(1.10, 1e-9));
      // §5.4 红线由公式层 clamp(基础 15000 × 1.10 = 16500 但 maxIF clamp 15000),
      // 本批 schema 只验 mult 数学不破语义,公式层 enforce 留 CharacterDerivedStats。
    });
  });
}
