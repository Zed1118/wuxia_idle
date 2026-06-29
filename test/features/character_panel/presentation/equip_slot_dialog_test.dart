import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/character_panel/presentation/equip_slot_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// EquipSlotDialog widget 测（2026-06-26 · 一步到位 + 全量对比两栏）。
///
/// 走 ProviderScope.overrides 注入 allEquipmentsProvider fixture，不开真 Isar；
/// 仅验渲染 + 选中态（不触发真 equip，故不需 isarProvider）。
/// setUpAll 加载真实 GameRepository 供 effective 派生公式 + getEquipment 名。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Character mkCharacter({RealmTier realmTier = RealmTier.wuSheng}) {
    final attrs = Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5;
    return Character.create(
      name: '测试者',
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: attrs,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026),
      internalForce: 200,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
    )..id = 1;
  }

  Equipment mkWeapon({
    required int id,
    int atk = 50,
    EquipmentTier tier = EquipmentTier.xunChang,
  }) => Equipment.create(
    defId: 'weapon_xunchang_tie_jian',
    tier: tier,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026),
    obtainedFrom: 'test',
    baseAttack: atk,
    baseHealth: 100,
    baseSpeed: 10,
  )..id = id;

  Future<void> pump(
    WidgetTester tester, {
    required int? currentId,
    required List<Equipment> all,
    RealmTier realmTier = RealmTier.wuSheng,
    Size surfaceSize = const Size(1280, 720),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [allEquipmentsProvider.overrideWith((ref) async => all)],
        child: MaterialApp(
          home: Scaffold(
            body: EquipSlotDialog(
              character: mkCharacter(realmTier: realmTier),
              slot: EquipmentSlot.weapon,
              currentId: currentId,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('已装备态:渲染操作图标 + 选候选出确认更换', (tester) async {
    await pump(
      tester,
      currentId: 10,
      all: [mkWeapon(id: 10, atk: 50), mkWeapon(id: 11, atk: 120)],
    );
    // 顶部操作图标(by tooltip)
    expect(find.byTooltip(UiStrings.tabEnhance), findsOneWidget);
    expect(find.byTooltip(UiStrings.tabForging), findsOneWidget);
    expect(find.byTooltip(UiStrings.equipUnequip), findsOneWidget);
    // 右栏初始占位、未现"确认更换"
    expect(find.text(UiStrings.equipSlotDialogConfirm), findsNothing);
    // 选中候选(非当前件 id=11)→ 右栏出确认更换
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.equipSlotDialogConfirm), findsOneWidget);
    expect(find.text(UiStrings.equipmentCompareAttack), findsOneWidget);
    expect(find.text(UiStrings.equipmentDeltaValue(70)), findsOneWidget);
  });

  testWidgets('空槽态:无卸下图标 + 初始占位 + 选后显装备', (tester) async {
    await pump(tester, currentId: null, all: [mkWeapon(id: 11, atk: 120)]);
    expect(find.byTooltip(UiStrings.equipUnequip), findsNothing);
    expect(find.text(UiStrings.equipSlotDialogPickHint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    // 空槽 → 按钮文案是"装备"非"确认更换"
    expect(find.text(UiStrings.equipSlotDialogEquip), findsOneWidget);
    expect(find.text(UiStrings.equipSlotDialogConfirm), findsNothing);
  });

  testWidgets('§5.3 灰显候选不可选(锁图标 + 点不刷右栏)', (tester) async {
    // 角色学徒(idx0),候选像样货(idx1)→ 不达境界锁。
    await pump(
      tester,
      currentId: null,
      all: [mkWeapon(id: 11, tier: EquipmentTier.xiangYang)],
      realmTier: RealmTier.xueTu,
    );
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    expect(find.text(UiStrings.equipRealmLockedPill), findsOneWidget);
    expect(find.text(UiStrings.equipRealmLockHint('三流')), findsOneWidget);
    // 点锁定行不应刷出对比(右栏仍占位)
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.equipSlotDialogPickHint), findsOneWidget);
    expect(find.text(UiStrings.equipSlotDialogEquip), findsNothing);
  });

  testWidgets('1440x900 桌面视口 smoke:选择候选后无布局异常', (tester) async {
    await pump(
      tester,
      currentId: 10,
      all: [mkWeapon(id: 10, atk: 80), mkWeapon(id: 11, atk: 160)],
      surfaceSize: const Size(1440, 900),
    );
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.equipSlotDialogCompareTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
