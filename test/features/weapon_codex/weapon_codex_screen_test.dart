// 兵器谱主屏 widget 测。
// 跑法:flutter test test/features/weapon_codex/weapon_codex_screen_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_providers.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/features/weapon_codex/presentation/weapon_codex_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 真实 def id（来自 data/equipment.yaml）。
const String _acquiredWeaponId = 'weapon_xunchang_tie_jian'; // 铁剑（兵器）
const String _acquiredWeaponName = '铁剑';

/// 构造一条点亮档（指向真实 def id）。
EquipmentCatalogEntry _entry(String defId) => EquipmentCatalogEntry()
  ..defId = defId
  ..firstObtainedAt = DateTime(2026, 6, 20)
  ..firstObtainedFrom = '黑风寨之战'
  ..obtainedCount = 1
  ..isPreRecord = false;

Widget _wrap(List<EquipmentCatalogEntry> entries) {
  return ProviderScope(
    overrides: [
      equipmentCatalogListProvider.overrideWith((ref) async => entries),
    ],
    child: const MaterialApp(home: WeaponCodexScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  testWidgets('部分点亮:点亮件显名,未点亮件显剪影「未得之器」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap([_entry(_acquiredWeaponId)]));
    await tester.pumpAndSettle();

    // 点亮件名可见
    expect(find.text(_acquiredWeaponName), findsOneWidget);
    // 大量未点亮件显剪影占位文案
    expect(find.text(UiStrings.weaponCodexLockedItem), findsWidgets);
  });

  testWidgets('点「护甲」筛选 chip → 兵器件(已点亮的铁剑)消失,护甲件留', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap([_entry(_acquiredWeaponId)]));
    await tester.pumpAndSettle();

    // 切到护甲前:铁剑(兵器)在全部视图里可见
    expect(find.text(_acquiredWeaponName), findsOneWidget);

    await tester.tap(find.text(UiStrings.weaponCodexFilterArmor));
    await tester.pumpAndSettle();

    // 护甲筛选后:兵器件(铁剑)不再渲染
    expect(find.text(_acquiredWeaponName), findsNothing);
    // 护甲档名(粗布衣)仍在(寻常货档进度小计里它是未点亮剪影,但分组标题存在)
    // 用 tier 进度文案断言护甲视图非空更稳妥:剪影占位文案仍在。
    expect(find.text(UiStrings.weaponCodexLockedItem), findsWidgets);
  });
}
