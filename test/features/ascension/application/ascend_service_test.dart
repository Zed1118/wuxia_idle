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
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inheritance/application/founder_buff_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';

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

  // ───────────────────────────────────────────────────────────────────────
  // R5.6 多代飞升 + 真传位 e2e(spec p5_lineage_full_spec §Q1+Q2 · ④+⑤ 合并)
  // ───────────────────────────────────────────────────────────────────────

  group('R5.6 多代飞升 e2e', () {
    test('gen1 → gen2 完整链 · 装备 prev 累加 + 各代 buff 接管', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();
      final buffSvc = FounderBuffService(isar);
      final n = GameRepository.instance.numbers;

      // gen1: founder=1 → promoted=2 传 weapon
      final founder1 = (await isar.characters.get(1))!;
      final weapon = founder1.equippedWeaponId!;
      final r1 = await isar.writeTxn(
        () => svc.performAscend({weapon: 2}, promotedDiscipleId: 2),
      );
      expect(r1.promotedDiscipleId, 2);
      expect(r1.founderRetired, true);

      // weapon prev=[1] · disciple 2 接任 founder 身份
      expect(
        (await isar.equipments.get(weapon))!.previousOwnerCharacterIds,
        [1],
      );
      final d2Gen1 = (await isar.characters.get(2))!;
      expect(d2Gen1.isFounder, true, reason: 'promoted 接任');
      expect(d2Gen1.equippedWeaponId, weapon, reason: 'auto_swap 自动装备');

      // founder=1 出阵 · isFounder 保 true 「太祖」语义
      final founder1After = (await isar.characters.get(1))!;
      expect(founder1After.isActive, false);
      expect(founder1After.isFounder, true, reason: '太祖保留语义');

      // gen1 buff 接管:active 中 d2.isFounder=true → 激活
      expect(await buffSvc.computeBuffActive(n), true);

      // H3 A2 防回退:gen1 飞升后 founderCharacterId 自动切到接任者(无需手动 setup)·
      // 多代循环命门 — 删掉 production 那行会让本断言 + 下方 gen2 链直接 fail。
      expect((await isar.saveDatas.get(0))!.founderCharacterId, 2,
          reason: 'H3 A2: performAscend 切 founderCharacterId → promotedDiscipleId');

      // gen2 setup: founder=2 升 wuSheng·dengFeng(founderCharacterId 由 gen1
      // performAscend 自动切到 2 · H3 A2 修复后不再手动 setup)
      await isar.writeTxn(() async {
        final d2 = (await isar.characters.get(2))!;
        d2.realmTier = RealmTier.wuSheng;
        d2.realmLayer = RealmLayer.dengFeng;
        await isar.characters.put(d2);
      });

      // gen2: founder=2 → promoted=3 传同一 weapon(已装在 d2 · auto_swap 接 d3)
      final r2 = await isar.writeTxn(
        () => svc.performAscend({weapon: 3}, promotedDiscipleId: 3),
      );
      expect(r2.promotedDiscipleId, 3);

      // weapon prev 累加 [1, 2] · owner=3 · isLineageHeritage=true
      final wAfter2 = (await isar.equipments.get(weapon))!;
      expect(wAfter2.previousOwnerCharacterIds, [1, 2]);
      expect(wAfter2.ownerCharacterId, 3);
      expect(wAfter2.isLineageHeritage, true);

      // disciple 3 接任 · disciple 2 退 active · isFounder 保 true(「太祖」)
      final d3 = (await isar.characters.get(3))!;
      expect(d3.isFounder, true);
      expect(d3.equippedWeaponId, weapon, reason: 'gen2 auto_swap');

      final d2Retired = (await isar.characters.get(2))!;
      expect(d2Retired.isActive, false);
      expect(d2Retired.isFounder, true, reason: '太祖保留');

      // gen2 buff 接管:active 中 d3.isFounder=true → 激活
      expect(await buffSvc.computeBuffActive(n), true);
    });

    test('promotedDiscipleId=null 兼容 P2.3 一代飞升 · 无 promoted 接管', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();
      final buffSvc = FounderBuffService(isar);
      final n = GameRepository.instance.numbers;

      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;

      // 不传 promotedDiscipleId(默认 null · P2.3 兼容路径)
      final r = await isar.writeTxn(
        () => svc.performAscend({weapon: 2}),
      );
      expect(r.promotedDiscipleId, null);
      expect(r.founderRetired, true);

      // disciple 2 isFounder=false(无 promoted) · auto_swap 仍执行
      final d2 = (await isar.characters.get(2))!;
      expect(d2.isFounder, false, reason: '无 promoted · disciple 不接任');
      expect(d2.equippedWeaponId, weapon,
          reason: 'auto_swap 与 promoted 解耦');

      // founder buff 全退(无 active isFounder=true · founder 已退 active)
      expect(await buffSvc.computeBuffActive(n), false);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.7 conflict_slot_resolution=auto_swap(spec p5_lineage_full_spec §Q3)
  // ───────────────────────────────────────────────────────────────────────

  group('R5.7 conflict_slot_resolution=auto_swap', () {
    test('disciple 已戴 weapon Y + armor Z → 传 weapon X + armor X2 → '
        'swap 新遗物 · 旧装 owner 不变', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;

      // setup: disciple 2 已戴 weapon Y + armor Z(原装 owner=2)
      late int yId;
      late int zId;
      await isar.writeTxn(() async {
        final y = Equipment.create(
          defId: 'weapon_test_y',
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.weapon,
          obtainedAt: DateTime.now(),
          obtainedFrom: 'test',
          ownerCharacterId: 2,
        );
        final z = Equipment.create(
          defId: 'armor_test_z',
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.armor,
          obtainedAt: DateTime.now(),
          obtainedFrom: 'test',
          ownerCharacterId: 2,
        );
        yId = await isar.equipments.put(y);
        zId = await isar.equipments.put(z);
        final d2 = (await isar.characters.get(2))!;
        d2.equippedWeaponId = yId;
        d2.equippedArmorId = zId;
        await isar.characters.put(d2);
      });

      final founder = (await isar.characters.get(1))!;
      final weaponX = founder.equippedWeaponId!;
      final armorX = founder.equippedArmorId!;

      await isar.writeTxn(
        () => makeService().performAscend(
          {weaponX: 2, armorX: 2},
          promotedDiscipleId: 2,
        ),
      );

      // disciple 2 端 equipped*Id 指向新遗物
      final d2After = (await isar.characters.get(2))!;
      expect(d2After.equippedWeaponId, weaponX,
          reason: 'weapon auto_swap');
      expect(d2After.equippedArmorId, armorX, reason: 'armor auto_swap');

      // 旧 weapon Y + armor Z owner 不变(disciple 2 仍持入背包语义 · §Q3)
      expect(
        (await isar.equipments.get(yId))!.ownerCharacterId,
        2,
        reason: '旧 weapon Y 仍归 disciple 2',
      );
      expect(
        (await isar.equipments.get(zId))!.ownerCharacterId,
        2,
        reason: '旧 armor Z 仍归 disciple 2',
      );
    });

    test('accessory enum 分支单独覆盖 · 防 switch 漏分支', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;

      // setup: disciple 2 已戴 accessory T
      late int tId;
      await isar.writeTxn(() async {
        final t = Equipment.create(
          defId: 'accessory_test_t',
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.accessory,
          obtainedAt: DateTime.now(),
          obtainedFrom: 'test',
          ownerCharacterId: 2,
        );
        tId = await isar.equipments.put(t);
        final d2 = (await isar.characters.get(2))!;
        d2.equippedAccessoryId = tId;
        await isar.characters.put(d2);
      });

      final founder = (await isar.characters.get(1))!;
      final accessoryX = founder.equippedAccessoryId!;

      await isar.writeTxn(
        () => makeService().performAscend(
          {accessoryX: 2},
          promotedDiscipleId: 2,
        ),
      );

      final d2After = (await isar.characters.get(2))!;
      expect(d2After.equippedAccessoryId, accessoryX,
          reason: 'accessory enum 分支 auto_swap');
      expect((await isar.equipments.get(tId))!.ownerCharacterId, 2,
          reason: '旧 accessory T 仍归 disciple 2');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.8 stack_across_generations=false enforce(spec p5_lineage_full_spec §Q4)
  // ───────────────────────────────────────────────────────────────────────

  group('R5.8 stack_across_generations=false enforce', () {
    test('disciple 装多代 heritage · 按 instance count 不按 prev len 累加(防回退)',
        () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      // gen1: founder=1 → promoted=2 传 weapon(prev=[1])
      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;
      await isar.writeTxn(
        () => svc.performAscend({weapon: 2}, promotedDiscipleId: 2),
      );

      // gen2 setup: founder=2 升 wuSheng·dengFeng(founderCharacterId 由 gen1
      // performAscend 自动切到 2 · H3 A2 修复后不再手动 setup)
      await isar.writeTxn(() async {
        final d2 = (await isar.characters.get(2))!;
        d2.realmTier = RealmTier.wuSheng;
        d2.realmLayer = RealmLayer.dengFeng;
        await isar.characters.put(d2);
      });

      // gen2: founder=2 → promoted=3 传同一 weapon(prev=[1,2])
      await isar.writeTxn(
        () => svc.performAscend({weapon: 3}, promotedDiscipleId: 3),
      );

      // weapon prev len=2(多代追加) · isLineageHeritage=true · owner=3
      final wAfter = (await isar.equipments.get(weapon))!;
      expect(wAfter.previousOwnerCharacterIds, [1, 2]);
      expect(wAfter.isLineageHeritage, true);

      // disciple 3 持 1 件 heritage · derived_stats §244 按 instance count 不按
      // prev len 累加 · 即使 prev len=2 也只算 1 件 +5%(不破 §5.4 红线)
      final heritageOf3 = await isar.equipments
          .filter()
          .ownerCharacterIdEqualTo(3)
          .isLineageHeritageEqualTo(true)
          .findAll();
      expect(heritageOf3.length, 1,
          reason: 'stack_across=false enforce:1 件 heritage 不因 prev len 累加');
      // §Q4 防回退:未来 derived_stats 改算法(如改 by prev len)能立即捕获回归。
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.10 isLineageContinuation 多代 narrative 路由(P5+ UI 接入)
  // ───────────────────────────────────────────────────────────────────────

  group('R5.10 isLineageContinuation 多代 narrative 路由', () {
    test('gen0 founder(def 自带 heritage 但 prev=[])→ false · 走 ascension_complete',
        () async {
      // 初始 fixture seedMasterDisciple 给 founder 装 yaml-def-自带 isLineageHeritage=true
      // 的装备(weapon_liqi_long_quan 等祖师装),但 prev=[](创世 · 无前任持有者)→
      // isLineageContinuation 应返 false(本批判定标准:prev.isNotEmpty 而非 isLineageHeritage)
      final svc = makeService();
      final result = await svc.isLineageContinuation();
      expect(result, false,
          reason: 'gen0 一代飞升 · founder 装 prev=[] 创世遗物 · UI 路径 ascension_complete');
    });

    test('gen1 飞升后 founder=2 持 heritage weapon → true · 走 ascension_lineage_chant',
        () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      // gen1: founder=1 → promoted=2 传 weapon · d2 自动 equip 新 heritage weapon
      final founder1 = (await isar.characters.get(1))!;
      final weapon = founder1.equippedWeaponId!;
      await isar.writeTxn(
        () => svc.performAscend({weapon: 2}, promotedDiscipleId: 2),
      );

      // gen1 performAscend 已自动把 founderCharacterId 切到 2(H3 A2 修复 ·
      // 删手动 setup 暴露真实路径),此时 founder=2 持 heritage weapon(prev=[1])
      // → isLineageContinuation=true
      final result = await svc.isLineageContinuation();
      expect(result, true,
          reason: 'gen2+ 多代续传 · UI 路径 ascension_lineage_chant');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.9 listDiscipleTargets 排除已 promoted(`isFounder=true`)防循环传位
  // ───────────────────────────────────────────────────────────────────────

  group('R5.9 listDiscipleTargets 排除已 promoted', () {
    test('gen0 baseline:无 promoted · 全 disciple 都在 target list', () async {
      // 初始 fixture(Phase2SeedService.seedMasterDisciple)= 祖师 1 + 大弟子 2 +
      // 二弟子 3 全 active · 无 promoted → listDiscipleTargets = [d2, d3]
      final svc = makeService();
      final targets = await svc.listDiscipleTargets();
      final ids = targets.map((c) => c.id).toSet();
      expect(ids, {2, 3},
          reason: 'gen0 无 promoted · 全 disciple(且 active + alive)都在 target');
    });

    test('gen1 promote=2 后 · d2 排除(已接任 isFounder=true) · d3 仍在', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      // gen1: founder=1 → promoted=2 传 weapon · d2.isFounder=true
      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;
      await isar.writeTxn(
        () => svc.performAscend({weapon: 2}, promotedDiscipleId: 2),
      );

      // 校验 d2 已 isFounder=true(R5.6 已测,本测顺手 sanity check 防 setup 漂移)
      expect((await isar.characters.get(2))!.isFounder, true);

      // listDiscipleTargets 不再包含 d2(防循环传位 · 主断言)· d3 仍可作 next gen target
      final targets = await svc.listDiscipleTargets();
      final ids = targets.map((c) => c.id).toSet();
      expect(ids.contains(2), false,
          reason: 'gen1 promoted d2 已 isFounder=true · UI 下拉不应再列(防循环传位)');
      expect(ids.contains(3), true,
          reason: 'd3 仍是普通 disciple · 可作 gen2 promoted target');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // R5.7 P4.1 §12.2 sect.founderId rewire hook(spec p4_1 §5)
  // ───────────────────────────────────────────────────────────────────────

  group('R5.7 真传位 sect 接管', () {
    test('performAscend(promotedDiscipleId=2) 后 sect.founderId 自动 rewire', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      // seed Sect with founderId = 1(原 founder)
      late int sectId;
      await isar.writeTxn(() async {
        final sect = Sect()
          ..name = '青锋门'
          ..founderId = 1
          ..sectLevel = 1
          ..sectReputation = 50
          ..totalWins = 0
          ..memberCount = 0
          ..territoryIds = []
          ..createdAt = DateTime(2026, 5, 25);
        sectId = await isar.sects.put(sect);
      });

      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;
      await isar.writeTxn(
        () => svc.performAscend({weapon: 2}, promotedDiscipleId: 2),
      );

      final sectAfter = await isar.sects.get(sectId);
      expect(sectAfter, isNotNull);
      expect(sectAfter!.founderId, 2,
          reason: 'sect.founderId rewire 到 promotedDiscipleId');

      final founderAfter = (await isar.characters.get(1))!;
      expect(founderAfter.isFounder, true,
          reason: '旧 founder 保 isFounder=true「太祖」语义');
      expect(founderAfter.isActive, false,
          reason: '旧 founder 退 active');
    });

    test('performAscend(promotedDiscipleId=null)·sect.founderId 不动(P2.3 兼容)', () async {
      await boostToAscensionReady();
      final isar = IsarSetup.instance;
      final svc = makeService();

      late int sectId;
      await isar.writeTxn(() async {
        final sect = Sect()
          ..name = '青锋门'
          ..founderId = 1
          ..sectLevel = 1
          ..sectReputation = 50
          ..totalWins = 0
          ..memberCount = 0
          ..territoryIds = []
          ..createdAt = DateTime(2026, 5, 25);
        sectId = await isar.sects.put(sect);
      });

      final founder = (await isar.characters.get(1))!;
      final weapon = founder.equippedWeaponId!;
      await isar.writeTxn(
        () => svc.performAscend({weapon: 2}), // promotedDiscipleId 默认 null
      );

      final sectAfter = await isar.sects.get(sectId);
      expect(sectAfter!.founderId, 1,
          reason: 'promotedDiscipleId=null 时 sect.founderId 不动(rewire hook 跳过)');
    });
  });
}
