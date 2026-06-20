import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/features/weapon_codex/presentation/equipment_catalog_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 手构 minimal def（imagePath 故意指向不存在资源以验 errorBuilder 不崩）。
EquipmentDef _makeDef() => const EquipmentDef(
      id: 'test_blade',
      name: '测试·断水刃',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      schoolBias: TechniqueSchool.gangMeng,
      baseAttackMin: 100,
      baseAttackMax: 200,
      baseHealthMin: 50,
      baseHealthMax: 80,
      baseSpeedMin: 10,
      baseSpeedMax: 12,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: 'assets/__nonexistent__.png',
      specialSkillCandidates: ['skill_a', 'skill_b'],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(EquipmentDef def, EquipmentCatalogEntry entry) {
    return MaterialApp(
      home: EquipmentCatalogDetailScreen(def: def, entry: entry),
    );
  }

  testWidgets('正常态：显示首得来源，不显「来历已不可考」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final entry = EquipmentCatalogEntry()
      ..defId = 'test_blade'
      ..firstObtainedAt = DateTime(2026, 6, 20)
      ..firstObtainedFrom = '黑风寨之战'
      ..obtainedCount = 3
      ..isPreRecord = false;

    await tester.pumpWidget(wrap(_makeDef(), entry));
    await tester.pump();

    expect(
      find.text(UiStrings.weaponCodexFirstObtainedFrom('黑风寨之战')),
      findsOneWidget,
    );
    expect(find.text(UiStrings.weaponCodexHistoryUnknown), findsNothing);
    // 历得次数始终显示
    expect(find.text(UiStrings.weaponCodexObtainedCount(3)), findsOneWidget);
  });

  testWidgets('回填态：显示「来历已不可考」，不显日期', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final entry = EquipmentCatalogEntry()
      ..defId = 'test_blade'
      ..firstObtainedAt = null
      ..firstObtainedFrom = UiStrings.weaponCodexBackfillSource
      ..obtainedCount = 1
      ..isPreRecord = true;

    await tester.pumpWidget(wrap(_makeDef(), entry));
    await tester.pump();

    expect(
      find.text(UiStrings.weaponCodexHistoryUnknown),
      findsOneWidget,
    );
    // 不应渲染任何首得来源 / 日期
    expect(
      find.text(UiStrings.weaponCodexFirstObtainedFrom(
        UiStrings.weaponCodexBackfillSource,
      )),
      findsNothing,
    );
    expect(find.text(UiStrings.weaponCodexObtainedCount(1)), findsOneWidget);
  });
}
