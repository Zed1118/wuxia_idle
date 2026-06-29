import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/lore.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/features/inventory/presentation/equipment_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

/// _LoreSection 延续典故渲染 edge 测试(P1 #42 Phase 5 新增延续 hook 0→1 覆盖)。
///
/// 5 用例(group「_LoreSection 延续典故渲染」):
///   A. 仅 preset 段:3 个卷目 + 可展开 + 0 延续 chip
///   B. 仅延续段:2 chip + 无 preset 内容
///   C. preset + 延续混排顺序:preset 文本 y < 延续 chip y
///   D. 都空:显"典故待补"占位
///   E. 延续 chip 文字颜色 ≡ WuxiaColors.internalForce
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Equipment mkEq({required EquipmentDef def, List<Lore>? lores}) {
    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: def.baseAttackMin,
      baseHealth: def.baseHealthMin,
      baseSpeed: def.baseSpeedMin,
      lores: lores,
    )..id = 1;
  }

  Future<LoreContent> Function(String) fakePresetLoader({int segCount = 1}) {
    return (loreId) async => LoreContent(
      id: loreId,
      name: 'test',
      defaultLore: List.generate(
        segCount,
        (i) => LoreSegment(text: 'preset段$i'),
      ),
      isPlaceholder: false,
    );
  }

  Lore makeContinued(String text, {DateTime? addedAt}) => Lore()
    ..text = text
    ..isPreset = false
    ..addedAt = addedAt ?? DateTime(2026, 5, 17);

  // 辅助:测试用 EquipmentDef,presetLoreIds 可注入,解耦生产 yaml id。
  EquipmentDef testDef(
    String id,
    String name, {
    List<String> presetLoreIds = const [],
  }) => EquipmentDef(
    id: id,
    name: name,
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    baseAttackMin: 10,
    baseAttackMax: 20,
    baseHealthMin: 0,
    baseHealthMax: 0,
    baseSpeedMin: 0,
    baseSpeedMax: 0,
    presetLoreIds: presetLoreIds,
    dropSourceTags: const [],
    iconPath: 'placeholder',
  );

  // 兼容旧调用 (B/D/E):无 presetLoreIds
  EquipmentDef emptyDef(String id, String name) => testDef(id, name);

  group('_LoreSection 延续典故渲染', () {
    const surfaceSize = Size(1280, 900);

    // ── A. 仅 preset 段 ────────────────────────────────────────────────────────
    testWidgets('A. 仅 preset 段:3 个卷目 + 可展开 + 0 个延续 chip', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 本地 fixture:def 注入 3 个 preset id,fake loreLoader 返回 3 段 segments
      final def = testDef(
        'test_preset_only',
        'preset 专用装备',
        presetLoreIds: const ['p_a', 'p_b', 'p_c'],
      );
      final eq = mkEq(def: def); // lores: [] 默认无延续

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: fakePresetLoader(segCount: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 preset 卷目全部可见；首段默认展开，其余按需展开。
      expect(find.text(UiStrings.loreSectionDivider), findsOneWidget);
      expect(find.text(UiStrings.lorePresetTitle(1)), findsOneWidget);
      expect(find.text(UiStrings.lorePresetTitle(2)), findsOneWidget);
      expect(find.text(UiStrings.lorePresetTitle(3)), findsOneWidget);
      expect(find.text('preset段0'), findsOneWidget);
      expect(find.text('preset段1'), findsNothing);
      expect(find.text('preset段2'), findsNothing);
      await tester.tap(find.text(UiStrings.lorePresetTitle(2)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(UiStrings.lorePresetTitle(3)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UiStrings.lorePresetTitle(3)));
      await tester.pumpAndSettle();
      expect(find.text('preset段1'), findsOneWidget);
      expect(find.text('preset段2'), findsOneWidget);
      // 无延续 chip
      expect(
        find.text(UiStrings.continuedLoreChipLabel),
        findsNothing,
        reason: '无延续 lore 时不应出现任何 _ContinuedLoreChip',
      );
    });

    // ── B. 仅延续段 ────────────────────────────────────────────────────────────
    testWidgets('B. 仅延续段:2 个 chip 存在 + 无"典故待补"', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final def = emptyDef('test_continued_only', '延续专用装备');
      final eq = mkEq(
        def: def,
        lores: [
          makeContinued('延续段甲', addedAt: DateTime(2026, 5, 17, 10)),
          makeContinued('延续段乙', addedAt: DateTime(2026, 5, 17, 11)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: (_) async {
                fail('presetLoreIds 为空时不应调 loreLoader');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 个延续 chip
      expect(find.text(UiStrings.loreHolderMemoryTitle), findsOneWidget);
      expect(
        find.text(UiStrings.continuedLoreChipLabel),
        findsNWidgets(2),
        reason: '2 条 isPreset=false lore 应各渲染 1 个延续 chip',
      );
      // 延续段文本出现
      expect(find.text('延续段甲'), findsOneWidget);
      expect(find.text('延续段乙'), findsOneWidget);
      // 有延续段时不应出现占位
      expect(find.text('典故待补'), findsNothing);
    });

    // ── C. preset + 延续混排顺序 ───────────────────────────────────────────────
    testWidgets('C. preset + 延续混排:所有 preset 文本 y 坐标 < 所有 chip y 坐标', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 本地 fixture:def 注入 2 preset id,fake loreLoader 返回 2 段(preset段A/B)
      final def = testDef(
        'test_mixed',
        '混排测试装备',
        presetLoreIds: const ['p_mix_a', 'p_mix_b'],
      );
      final eq = mkEq(
        def: def,
        lores: [
          makeContinued('延续甲', addedAt: DateTime(2026, 5, 17, 10)),
          makeContinued('延续乙', addedAt: DateTime(2026, 5, 17, 11)),
          makeContinued('延续丙', addedAt: DateTime(2026, 5, 17, 12)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: (id) async => LoreContent(
                id: id,
                name: 'test',
                defaultLore: [
                  const LoreSegment(text: 'preset段A'),
                  const LoreSegment(text: 'preset段B'),
                ],
                isPlaceholder: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 preset 段 + 3 延续 chip 全出现
      expect(find.text('preset段A'), findsOneWidget);
      await tester.tap(find.text(UiStrings.lorePresetTitle(2)));
      await tester.pumpAndSettle();
      expect(find.text('preset段B'), findsOneWidget);
      expect(find.text(UiStrings.continuedLoreChipLabel), findsNWidgets(3));

      // 顺序谓词:所有 preset 文本.topLeft.dy < 所有 chip 标签.topLeft.dy
      final presetYs = [
        tester.getTopLeft(find.text('preset段A')).dy,
        tester.getTopLeft(find.text('preset段B')).dy,
      ];
      final chipFinder = find.text(UiStrings.continuedLoreChipLabel);
      final chipYs = List.generate(
        chipFinder.evaluate().length,
        (i) => tester.getTopLeft(chipFinder.at(i)).dy,
      );

      for (final presetY in presetYs) {
        for (final chipY in chipYs) {
          expect(
            presetY,
            lessThan(chipY),
            reason: 'preset 段(y=$presetY) 必须渲染在延续 chip(y=$chipY) 之前(更靠上)',
          );
        }
      }
    });

    // ── D. 都空 → 占位提示 ─────────────────────────────────────────────────────
    testWidgets('D. 无 preset 无延续 → "典故待补"占位', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final def = emptyDef('test_all_empty', '全空典故装备');
      final eq = mkEq(def: def); // lores: [] 无延续

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: (_) async {
                fail('presetLoreIds 为空时不应调 loreLoader');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('典故待补'), findsOneWidget, reason: 'preset 和延续均无时应显示占位文本');
      expect(find.text(UiStrings.continuedLoreChipLabel), findsNothing);
    });

    // ── E. 延续 chip 文字颜色 ≡ WuxiaColors.internalForce ──────────────────────
    testWidgets('E. 延续 chip 文字颜色 ≡ WuxiaColors.internalForce', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final def = emptyDef('test_chip_color', '颜色测试装备');
      final eq = mkEq(def: def, lores: [makeContinued('延续颜色验证段')]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: (_) async {
                fail('presetLoreIds 为空时不应调 loreLoader');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chipLabel = find.text(UiStrings.continuedLoreChipLabel);
      expect(chipLabel, findsOneWidget);

      // 文字颜色必须引用常量,不写 hex 字面值
      final textWidget = tester.widget<Text>(chipLabel);
      expect(
        textWidget.style?.color,
        equals(WuxiaColors.internalForce),
        reason: '_ContinuedLoreChip 文字色必须等于 WuxiaColors.internalForce',
      );
    });
  });
}
