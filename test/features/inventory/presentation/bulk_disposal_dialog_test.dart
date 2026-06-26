import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_disposal_service.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_disposal.dart';
import 'package:wuxia_idle/features/inventory/presentation/bulk_disposal_dialog.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// BulkDisposalDialog widget 测试（Task 6 TDD）。
///
/// 覆盖范围：
/// ① 对话框列出有可处置装备的品阶行（件数排除已装备/师承）
/// ② 某 tier 行有「一键出售」「一键分解」按钮
/// ③ 点「一键出售」→ 二次确认框显 sellConfirmBody(count, silver)
/// ④（test）确认后可处置装备从 isar 消失、银两增加、已装备/师承装备仍在
///    (memory feedback_isar_widget_test_deadlock: writeTxn 在 testWidgets 内死锁，
///     isar 验证走 test() 不用 testWidgets)
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
    await Isar.initializeIsarCore(download: true);
  });

  Equipment mkEq({
    required int id,
    required EquipmentTier tier,
    required EquipmentSlot slot,
    int enhanceLevel = 0,
    bool isLineageHeritage = false,
    int? ownerCharacterId,
  }) {
    return Equipment.create(
      defId: 'test_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 6, 26),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
      isLineageHeritage: isLineageHeritage,
      ownerCharacterId: ownerCharacterId,
    )..id = id;
  }

  Character mkCharacter({required int id, int? equippedWeaponId}) {
    return Character.create(
      name: '测试角色',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 26),
      equippedWeaponId: equippedWeaponId,
    )..id = id;
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    required List<Equipment> equipments,
    Character? character,
  }) async {
    // memory feedback_listview_widget_test_viewport：扩 viewport 避免
    // ListView shrinkWrap 无高度导致 findsNothing。
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => equipments),
          allInventoryItemsProvider.overrideWith((ref) async => []),
          silverBalanceProvider.overrideWith((ref) async => 0),
          activeCharacterIdsProvider.overrideWith(
            (ref) async => character == null ? [] : [character.id],
          ),
          if (character != null)
            characterByIdProvider(
              character.id,
            ).overrideWith((ref) async => character),
        ],
        child: const MaterialApp(home: BulkDisposalDialog()),
      ),
    );
    // 等待 async provider 解析
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  // ─── ① 列出有可处置品阶行 ───────────────────────────────────────────────

  testWidgets('① 对话框列出有可处置装备的品阶行，件数排除已装备/师承', (tester) async {
    // xunChang: 2 件可处置 + 1 件已装备 + 1 件师承遗物 → 显示件数 = 2
    // liQi: 1 件可处置 → 显示件数 = 1
    final equipments = [
      mkEq(id: 1, tier: EquipmentTier.xunChang, slot: EquipmentSlot.weapon),
      mkEq(id: 2, tier: EquipmentTier.xunChang, slot: EquipmentSlot.armor),
      mkEq(
        id: 3,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        ownerCharacterId: 1,
      ),
      mkEq(
        id: 4,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.armor,
        isLineageHeritage: true,
      ),
      mkEq(id: 5, tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon),
    ];
    await pumpDialog(
      tester,
      equipments: equipments,
      character: mkCharacter(id: 1, equippedWeaponId: 3),
    );

    // 寻常货行：显示 2 件（排除已装备 + 师承）
    expect(
      find.text(UiStrings.bulkTierLabel('寻常货', 2)),
      findsOneWidget,
      reason: '寻常货行件数应为 2，已装备/师承不计',
    );
    // 利器行：1 件
    expect(
      find.text(UiStrings.bulkTierLabel('利器', 1)),
      findsOneWidget,
      reason: '利器行件数应为 1',
    );
    // 只有 2 个品级行（xunChang + liQi），没有其他品级
    expect(find.textContaining('件）'), findsNWidgets(2), reason: '应只有 2 个品级行');
  });

  // ─── ② 品阶行有出售/分解按钮 ─────────────────────────────────────────────

  testWidgets('② 品阶行有「一键出售」「一键分解」按钮', (tester) async {
    final equipments = [
      mkEq(id: 1, tier: EquipmentTier.xunChang, slot: EquipmentSlot.weapon),
    ];
    await pumpDialog(tester, equipments: equipments);

    expect(
      find.text(UiStrings.bulkSellButton),
      findsOneWidget,
      reason: '应有「一键出售」按钮',
    );
    expect(
      find.text(UiStrings.bulkDisassembleButton),
      findsOneWidget,
      reason: '应有「一键分解」按钮',
    );
  });

  // ─── ③ 点「一键出售」→ 二次确认框显 sellConfirmBody ──────────────────────

  testWidgets('③ 点「一键出售」→ 二次确认框显 sellConfirmBody(count, silver)', (
    tester,
  ) async {
    // xunChang +0: sellPrice = 20；2 件合计 = 40
    final equipments = [
      mkEq(
        id: 1,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        enhanceLevel: 0,
      ),
      mkEq(
        id: 2,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.armor,
        enhanceLevel: 0,
      ),
    ];
    await pumpDialog(tester, equipments: equipments);

    await tester.tap(find.text(UiStrings.bulkSellButton));
    await tester.pumpAndSettle();

    // 二次确认框应显示 sellConfirmBody(count, silver)，银两从配置动态算，
    // 避免调 numbers.yaml 后断言变成假绿。
    final disposalCfg = GameRepository.instance.numbers.disposal;
    final expectedSilver =
        equipmentSellPrice(EquipmentTier.xunChang, 0, disposalCfg) * 2;
    final expectedBody = UiStrings.sellConfirmBody(2, expectedSilver);
    expect(
      find.text(expectedBody),
      findsOneWidget,
      reason: '确认框应显示 sellConfirmBody(2, expectedSilver)',
    );
  });

  testWidgets('历史 owner 残留但无槽位引用 → 仍计入可处置件数', (tester) async {
    final equipments = [
      mkEq(
        id: 1,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        ownerCharacterId: 1,
      ),
      mkEq(id: 2, tier: EquipmentTier.xunChang, slot: EquipmentSlot.armor),
    ];
    await pumpDialog(
      tester,
      equipments: equipments,
      character: mkCharacter(id: 1),
    );

    expect(
      find.text(UiStrings.bulkTierLabel('寻常货', 2)),
      findsOneWidget,
      reason: '批量整理只按槽位引用排除已装备，不按历史 owner 排除',
    );
  });

  // ─── ④ Isar 集成：sellAllOfTier 只删可处置件，已装备/师承仍在 ───────────────

  group('④ Isar 集成：sellAllOfTier', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'bulk_disposal_dialog_isar_',
      );
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 与对话框行为一致的配置（numbers.yaml 初值）
    const cfg = EquipmentDisposalConfig(
      sellPrice: [20, 50, 120, 280, 600, 1200, 2500],
      sellEnhanceFactor: 0.1,
      disassembleMojianshi: [1, 2, 4, 7, 12, 18, 25],
      disassembleXinxuejiejing: [0, 0, 0, 1, 2, 4, 8],
      disassembleEnhanceMojianshiPerLevel: 1,
    );

    test('确认后可处置装备消失、银两增加、已装备/师承装备仍在', () async {
      final isar = IsarSetup.instance;

      // Seed: 2 可处置 + 1 已装备 + 1 师承遗物（同 xunChang 品级）
      late int id1, id2, id3, id4;
      await isar.writeTxn(() async {
        id1 = await isar.equipments.put(
          Equipment.create(
            defId: 'e1',
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.weapon,
            obtainedAt: DateTime(2026, 6, 26),
            obtainedFrom: 'test',
          ),
        );
        id2 = await isar.equipments.put(
          Equipment.create(
            defId: 'e2',
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.armor,
            obtainedAt: DateTime(2026, 6, 26),
            obtainedFrom: 'test',
          ),
        );
        id3 = await isar.equipments.put(
          Equipment.create(
            defId: 'e3',
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.weapon,
            obtainedAt: DateTime(2026, 6, 26),
            obtainedFrom: 'test',
            ownerCharacterId: 1, // 已装备
          ),
        );
        await isar.characters.put(mkCharacter(id: 1, equippedWeaponId: id3));
        id4 = await isar.equipments.put(
          Equipment.create(
            defId: 'e4',
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.accessory,
            obtainedAt: DateTime(2026, 6, 26),
            obtainedFrom: 'test',
            isLineageHeritage: true, // 师承遗物
          ),
        );
      });

      final service = EquipmentDisposalService(isar: isar, config: cfg);
      final result = await service.sellAllOfTier(EquipmentTier.xunChang);

      // 2 件可处置删除，合计银两 = 2 × 20 = 40
      expect(result.count, 2);
      expect(result.totalSilver, 40);

      // 可处置件已从 isar 删除
      expect(await isar.equipments.get(id1), isNull, reason: '可处置件 e1 应已删除');
      expect(await isar.equipments.get(id2), isNull, reason: '可处置件 e2 应已删除');

      // 已装备 + 师承遗物仍在
      expect(await isar.equipments.get(id3), isNotNull, reason: '已装备件应保留');
      expect(await isar.equipments.get(id4), isNotNull, reason: '师承遗物应保留');

      // 银两增加
      final silver = await isar.inventoryItems.getByDefId('item_silver');
      expect(silver, isNotNull);
      expect(silver!.quantity, 40);
    });
  });
}
