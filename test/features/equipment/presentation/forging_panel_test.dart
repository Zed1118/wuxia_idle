import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/features/equipment/presentation/forging_panel.dart';

/// T30 ForgingPanel widget 测试（phase2_tasks.md §458-459）。
///
/// 4 用例：
/// - 3 槽锁定状态：enhanceLevel=0 → 显示「强化到 +10/+15/+19 解锁」
/// - 槽 2 互斥过滤：enhanceLevel=15 + 槽 1 已开 attack → 槽 2 无攻击按钮
/// - 槽 3 specialSkill 候选为空 → 显示专属锋意空状态
/// - 已开锋显示「攻击 +X%」+「已开锋」标签
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  EquipmentDef mkDef({List<String> specialSkillCandidates = const []}) {
    return EquipmentDef(
      id: 'test_def',
      name: 'test',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 50,
      baseAttackMax: 50,
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 0,
      presetLoreIds: const [],
      dropSourceTags: const [],
      iconPath: 'test.png',
      specialSkillCandidates: specialSkillCandidates,
    );
  }

  Equipment mkEq({int enhanceLevel = 0, List<ForgingSlot>? slots}) {
    return Equipment.create(
      defId: 'test_def',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      enhanceLevel: enhanceLevel,
      forgingSlots: slots,
    )..id = 1;
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Equipment eq,
    required EquipmentDef def,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuantityByDefIdProvider(
            'item_kaifeng_fucai',
          ).overrideWith((ref) async => 100),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ForgingPanel(equipment: eq, def: def),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('3 槽锁定（enhanceLevel=0）→ 3 个解锁提示', (tester) async {
    final eq = mkEq(enhanceLevel: 0);
    final def = mkDef();
    await pumpPanel(tester, eq: eq, def: def);

    expect(find.text('强化到 +10 解锁'), findsOneWidget);
    expect(find.text('强化到 +15 解锁'), findsOneWidget);
    expect(find.text('强化到 +19 解锁'), findsOneWidget);
    expect(find.text('槽 1'), findsOneWidget);
    expect(find.text('槽 2'), findsOneWidget);
    expect(find.text('槽 3'), findsOneWidget);
  });

  testWidgets('槽 1 已开 attack + enhanceLevel=15 → 槽 2 词条不含「攻击」', (tester) async {
    final slots = [
      ForgingSlot()
        ..slotIndex = 1
        ..unlocked = true
        ..type = ForgingSlotType.attack
        ..bonusValue = 15,
      ForgingSlot()..slotIndex = 2,
      ForgingSlot()..slotIndex = 3,
    ];
    final eq = mkEq(enhanceLevel: 15, slots: slots);
    final def = mkDef();
    await pumpPanel(tester, eq: eq, def: def);

    // 槽 1 已开锋显示「攻击 +15%」+「已开锋」
    expect(find.text('攻击 +15%'), findsOneWidget);
    expect(find.text('已开锋'), findsOneWidget);

    // 槽 2 词条 button：应有 速度 / 吸血 / 破甲，不含「攻击」
    expect(find.widgetWithText(OutlinedButton, '攻击'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '速度'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, '吸血'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, '破甲'), findsWidgets);
  });

  testWidgets('槽 3 enhanceLevel=19 + specialSkillCandidates 空 → 专属锋意空状态', (
    tester,
  ) async {
    final eq = mkEq(enhanceLevel: 19);
    final def = mkDef(); // specialSkillCandidates 默认空
    await pumpPanel(tester, eq: eq, def: def);

    expect(find.text('此装备尚未记载专属锋意'), findsOneWidget);
    expect(find.text('换一件武器,或先打磨前两道锋意。'), findsOneWidget);
  });

  testWidgets('槽 3 specialSkill 候选非空 → 可选择并写入 specialSkillId', (tester) async {
    const specialSkillId = 'skill_edge_xunchang_lingqiao';
    final skillName = GameRepository.instance.skillDefs[specialSkillId]!.name;
    final eq = mkEq(enhanceLevel: 19);
    final def = mkDef(specialSkillCandidates: const [specialSkillId]);
    await pumpPanel(tester, eq: eq, def: def);

    await tester.tap(find.widgetWithText(OutlinedButton, '专属技能'));
    await tester.pumpAndSettle();
    expect(find.text('选择专属技能'), findsOneWidget);
    expect(find.text(skillName), findsOneWidget);
    expect(find.text('灵巧 · 第1阶 · 威力 1250'), findsOneWidget);

    await tester.tap(find.text(skillName));
    await tester.pumpAndSettle();
    expect(find.text('确认开锋'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(eq.forgingSlots[2].specialSkillId, specialSkillId);
    expect(eq.forgingSlots[2].type, ForgingSlotType.specialSkill);
    expect(find.text('专属技能：$skillName'), findsOneWidget);
  });

  testWidgets('已开锋槽显示「<类型> +X%」+「已开锋」灰色标签', (tester) async {
    final slots = [
      ForgingSlot()
        ..slotIndex = 1
        ..unlocked = true
        ..type = ForgingSlotType.speed
        ..bonusValue = 20,
      ForgingSlot()
        ..slotIndex = 2
        ..unlocked = true
        ..type = ForgingSlotType.lifesteal
        ..bonusValue = 10,
      ForgingSlot()..slotIndex = 3,
    ];
    final eq = mkEq(enhanceLevel: 15, slots: slots);
    final def = mkDef();
    await pumpPanel(tester, eq: eq, def: def);

    expect(find.text('速度 +20%'), findsOneWidget);
    expect(find.text('吸血 +10%'), findsOneWidget);
    expect(find.text('已开锋'), findsNWidgets(2));
  });
}
