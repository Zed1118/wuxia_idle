import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/features/inventory/presentation/equipment_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// Task 5 widget 测：出售/分解按钮可见性（背包/已装备/师承）。
///
/// 只测按钮渲染逻辑，不在 widget 层跑完整 service 动作
/// （service 已在 Task 2/3 单测覆盖）。
///
/// ListView viewport 扩大（memory: feedback_listview_widget_test_viewport）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  /// 快速 fake loader，旁路 rootBundle。
  Future<LoreContent> fakeLore(String id) async => LoreContent.placeholder(id);

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({required int id, int? equippedWeaponId}) {
    return Character.create(
      name: '测试角色',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 26),
      equippedWeaponId: equippedWeaponId,
    )..id = id;
  }

  const testDef = EquipmentDef(
    id: 'test_eq',
    name: '测试剑',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    baseAttackMin: 50,
    baseAttackMax: 50,
    baseHealthMin: 0,
    baseHealthMax: 0,
    baseSpeedMin: 0,
    baseSpeedMax: 0,
    presetLoreIds: [],
    dropSourceTags: [],
    iconPath: '',
  );

  Equipment mkEq({int? ownerCharacterId, bool isLineageHeritage = false}) {
    return Equipment.create(
      defId: 'test_eq',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 6, 26),
      obtainedFrom: 'test',
      baseAttack: 50,
      ownerCharacterId: ownerCharacterId,
      isLineageHeritage: isLineageHeritage,
    )..id = 1;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Equipment eq, {
    Character? character,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final activeIds = character == null ? const <int>[] : <int>[character.id];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => activeIds),
          if (character != null)
            characterByIdProvider(
              character.id,
            ).overrideWith((ref) async => character),
        ],
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: testDef,
            loreLoader: fakeLore,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('自由装备(无槽位引用, !isLineageHeritage) → 出售/分解按钮可见', (tester) async {
    final eq = mkEq();
    await pumpScreen(tester, eq);
    expect(
      find.text(UiStrings.equipmentSell),
      findsOneWidget,
      reason: '背包装备应显示出售按钮',
    );
    expect(
      find.text(UiStrings.equipmentDisassemble),
      findsOneWidget,
      reason: '背包装备应显示分解按钮',
    );
  });

  testWidgets('已装备(角色槽位引用) → 出售/分解按钮不显', (tester) async {
    final eq = mkEq(ownerCharacterId: 99);
    final character = mkCharacter(id: 99, equippedWeaponId: eq.id);
    await pumpScreen(tester, eq, character: character);
    expect(
      find.text(UiStrings.equipmentSell),
      findsNothing,
      reason: '已装备时出售按钮不应出现',
    );
    expect(
      find.text(UiStrings.equipmentDisassemble),
      findsNothing,
      reason: '已装备时分解按钮不应出现',
    );
  });

  testWidgets('历史 owner 残留但无槽位引用 → 出售/分解按钮可见', (tester) async {
    final eq = mkEq(ownerCharacterId: 99);
    await pumpScreen(tester, eq);
    expect(
      find.text(UiStrings.equipmentSell),
      findsOneWidget,
      reason: '旧 owner 残留不应阻止出售',
    );
    expect(
      find.text(UiStrings.equipmentDisassemble),
      findsOneWidget,
      reason: '旧 owner 残留不应阻止分解',
    );
  });

  testWidgets('师承遗物(isLineageHeritage=true) → 出售/分解按钮不显', (tester) async {
    final eq = mkEq(isLineageHeritage: true);
    await pumpScreen(tester, eq);
    expect(
      find.text(UiStrings.equipmentSell),
      findsNothing,
      reason: '师承遗物出售按钮不应出现',
    );
    expect(
      find.text(UiStrings.equipmentDisassemble),
      findsNothing,
      reason: '师承遗物分解按钮不应出现',
    );
  });
}
