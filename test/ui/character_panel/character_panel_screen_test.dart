import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/technique.dart';
import 'package:wuxia_idle/providers/character_providers.dart';
import 'package:wuxia_idle/ui/character_panel/character_panel_screen.dart';

/// T28 角色面板 widget 测试（phase2_tasks.md §407）。
///
/// 4 用例：3 装备槽渲染 / 未装备占位 / 共鸣阶段中文 / 修炼度进度条 value。
/// 全部走 ProviderScope.overrides 注入 fixture，不打开真实 Isar。
/// setUpAll 加载真实 GameRepository（numbers.yaml）供派生数值公式使用。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── fixtures ──────────────────────────────────────────────────────────────

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int? weaponId,
    int? armorId,
    int? accessoryId,
  }) {
    final now = DateTime(2026, 5, 11);
    return Character.create(
      name: '测试者',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: now,
      internalForce: 200,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
      equippedWeaponId: weaponId,
      equippedArmorId: armorId,
      equippedAccessoryId: accessoryId,
    )..id = 1;
  }

  Equipment mkEquipment({
    required int id,
    required EquipmentSlot slot,
    int enhanceLevel = 0,
    int battleCount = 0,
    EquipmentTier tier = EquipmentTier.xunChang,
  }) {
    return Equipment.create(
      defId: 'test_eq_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      baseHealth: 100,
      baseSpeed: 10,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
    )..id = id;
  }

  Technique mkTechnique({
    required int id,
    required int ownerId,
    required TechniqueRole role,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
  }) {
    return Technique.create(
      defId: 'test_tech_$id',
      ownerCharacterId: ownerId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: role,
      learnedAt: DateTime(2026, 5, 11),
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
    )..id = id;
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Character character,
    Map<int, Equipment> equipments = const {},
    Map<int, Technique> techniques = const {},
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterByIdProvider(character.id).overrideWith(
            (ref) async => character,
          ),
          for (final entry in equipments.entries)
            equipmentByIdProvider(entry.key).overrideWith(
              (ref) async => entry.value,
            ),
          for (final entry in techniques.entries)
            techniqueByIdProvider(entry.key).overrideWith(
              (ref) async => entry.value,
            ),
        ],
        child: MaterialApp(
          home: CharacterPanelScreen(characterId: character.id),
        ),
      ),
    );
    // 三次 pump 让 family Future 完成 + AsyncValue 翻转 + 子 Consumer rebuild。
    // 不用 pumpAndSettle：CircularProgressIndicator 是无限动画会卡。
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 1：3 装备槽全显示 ─────────────────────────────────────────────

  testWidgets('3 装备槽全装备时，+N 强化等级全部渲染', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final weapon = mkEquipment(
      id: 10,
      slot: EquipmentSlot.weapon,
      enhanceLevel: 5,
    );
    final armor = mkEquipment(
      id: 11,
      slot: EquipmentSlot.armor,
      enhanceLevel: 3,
    );
    final acc = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      enhanceLevel: 7,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: weapon, 11: armor, 12: acc},
    );

    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('护甲'), findsOneWidget);
    expect(find.text('饰品'), findsOneWidget);
  });

  // ── 用例 2：未装备占位 ─────────────────────────────────────────────────

  testWidgets('三个装备槽 id 全 null 时，渲染 3 个「未装备」占位', (tester) async {
    final character = mkCharacter();
    await pumpPanel(tester, character: character);

    expect(find.text('未装备'), findsNWidgets(3));
    expect(find.text('未修主修'), findsOneWidget);
    expect(find.text('未学'), findsNWidgets(3));
  });

  // ── 用例 3：共鸣阶段中文 ──────────────────────────────────────────────

  testWidgets('battleCount 跨阶 30 / 300 / 1000 → 生疏 / 趁手 / 默契', (tester) async {
    final character = mkCharacter(weaponId: 10, armorId: 11, accessoryId: 12);
    final w = mkEquipment(id: 10, slot: EquipmentSlot.weapon, battleCount: 30);
    final a = mkEquipment(id: 11, slot: EquipmentSlot.armor, battleCount: 300);
    final c = mkEquipment(
      id: 12,
      slot: EquipmentSlot.accessory,
      battleCount: 1000,
    );

    await pumpPanel(
      tester,
      character: character,
      equipments: {10: w, 11: a, 12: c},
    );

    expect(find.text('生疏'), findsOneWidget);
    expect(find.text('趁手'), findsOneWidget);
    expect(find.text('默契'), findsOneWidget);
  });

  // ── 用例 4：修炼度进度条 ──────────────────────────────────────────────

  testWidgets('主修 progress=50 / toNext=100 → LinearProgressIndicator.value=0.5',
      (tester) async {
    final character = mkCharacter(mainTechniqueId: 20);
    final main = mkTechnique(
      id: 20,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 50,
      cultivationProgressToNext: 100,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {20: main},
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.5, 1e-9));
    expect(find.text('50 / 100'), findsOneWidget);
    expect(find.text('主修'), findsOneWidget);
  });
}
