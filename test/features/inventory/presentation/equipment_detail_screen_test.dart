import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/inventory/presentation/equipment_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// EquipmentDetailScreen widget 测试(W15 LoreLoader 接入下一步)。
///
/// 5 用例:
/// - 基础渲染:tier / slot / school / 攻血速 / +N / 共鸣度阶段全显
/// - lore 段渲染:fake loader 注入 3 段 → 3 段文本可见 + 分隔符
/// - placeholder 兜底:loader 返回 placeholder → "典故待补"提示
/// - presetLoreIds 为空:跳过加载 → "典故待补"
/// - 强化按钮 tap → EnhanceDialog 弹起(initialTab=0)
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Equipment mkEq({
    required EquipmentDef def,
    int enhanceLevel = 0,
    int battleCount = 0,
    bool isLineageHeritage = false,
  }) {
    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: def.baseAttackMin,
      baseHealth: def.baseHealthMin,
      baseSpeed: def.baseSpeedMin,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
      isLineageHeritage: isLineageHeritage,
    )..id = 1;
  }

  Future<LoreContent> Function(String) fakeLoader({
    required List<String> segments,
    String name = '测试装备',
  }) {
    return (loreId) async => LoreContent(
          id: loreId,
          name: name,
          defaultLore: segments.map((t) => LoreSegment(text: t)).toList(),
          isPlaceholder: false,
        );
  }

  testWidgets('基础信息卡:tier / slot / 攻血速 / +N / 共鸣度全显', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian');
    final eq = mkEq(def: def, enhanceLevel: 12, battleCount: 1240);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: const ['一段']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(def.name), findsOneWidget);
    expect(find.text('神物'), findsOneWidget);
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('战斗 1240 次'), findsOneWidget);
    expect(find.text('攻击'), findsOneWidget);
    expect(find.text('血量'), findsOneWidget);
    expect(find.text('速度'), findsOneWidget);
  });

  testWidgets('lore 3 段全渲染 + 段间分隔', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian');
    final eq = mkEq(def: def);

    const segments = [
      '段一文本',
      '段二文本',
      '段三文本',
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: segments),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('◇ 典故 ◇'), findsOneWidget);
    expect(find.text('段一文本'), findsOneWidget);
    expect(find.text('段二文本'), findsOneWidget);
    expect(find.text('段三文本'), findsOneWidget);
    expect(find.text('· · ·'), findsNWidgets(2),
        reason: '3 段之间应有 2 个 · · · 分隔符');
  });

  testWidgets('loader 返回 placeholder → "典故待补"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian');
    final eq = mkEq(def: def);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: (id) async => LoreContent.placeholder(id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('典故待补'), findsOneWidget);
  });

  testWidgets('presetLoreIds 为空 → 跳过加载 → "典故待补"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 手造 def,presetLoreIds 为空
    const def = EquipmentDef(
      id: 'test_no_lore',
      name: '无典故装备',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 10,
      baseAttackMax: 20,
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 0,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: 'placeholder',
    );
    final eq = mkEq(def: def);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: (_) async {
              fail('presetLoreIds 空时不应调 loader');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('典故待补'), findsOneWidget);
  });

  // ── W15 后波 fix:师承遗物 chip 读 equipment.isLineageHeritage 而非 def ─────
  // round2 视觉验收 #5 蟠龙刀 FAIL(closeout codex_w15_resonance_visual_check
  // _2026-05-15.md §7)暴露 def 字段误读。本批 3 条 widget test 保护语义:
  //   ① 实例标 / def 不标 → chip 必显(fixture / 奇遇 override / 师承传承 3 路径)
  //   ② 实例不标 / def 不标 → chip 必隐(确保不显默认)
  //   ③ def 自带 → chip 必显(EquipmentFactory.fromDef propagate 回归保护)
  // 红线写「约束语义」不写瞬时事实(memory feedback_red_line_test_semantics)。

  testWidgets(
      'lineage chip · 实例标 / def 不标 → chip 必显(奇遇 override 路径)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // weapon_xunchang_tie_jian def 不标 isLineageHeritage(GameRepository 加载
    // 时 yaml 默认 false),实例强制标 true
    final def = GameRepository.instance.getEquipment('weapon_xunchang_tie_jian');
    expect(def.isLineageHeritage, isFalse,
        reason: 'precondition: def 不标 isLineageHeritage');
    final eq = mkEq(def: def, isLineageHeritage: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: const ['x']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.lineageHeritageLabel), findsOneWidget,
        reason: '实例 isLineageHeritage=true 必显「遗物」chip,不依赖 def');
  });

  testWidgets('lineage chip · 实例不标 / def 不标 → chip 必隐', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_xunchang_tie_jian');
    expect(def.isLineageHeritage, isFalse);
    final eq = mkEq(def: def);
    expect(eq.isLineageHeritage, isFalse);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: const ['x']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.lineageHeritageLabel), findsNothing);
  });

  testWidgets(
      'lineage chip · def 自带 → EquipmentFactory propagate → 实例标 → chip 必显',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // weapon_liqi_long_quan def 自带 isLineageHeritage=true(equipment.yaml)
    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    expect(def.isLineageHeritage, isTrue,
        reason: 'precondition: def 自带 isLineageHeritage');
    // 生产路径走 EquipmentFactory.fromDef:isLineageHeritage 从 def propagate
    // 到实例;test fixture mkEq 模拟 propagation 后的状态。
    final eq = mkEq(def: def, isLineageHeritage: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: const ['x']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.lineageHeritageLabel), findsOneWidget);
  });

  testWidgets('强化按钮 tap → EnhanceDialog 弹起', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian');
    final eq = mkEq(def: def);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentDetailScreen(
            equipment: eq,
            def: def,
            loreLoader: fakeLoader(segments: const ['x']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 详情屏底部「强化」按钮(避免和 Tab 的「强化」混淆,详情屏 _Btn 才是 tap 目标)
    final enhanceBtn = find.widgetWithText(InkWell, '强化');
    expect(enhanceBtn, findsOneWidget);
    await tester.tap(enhanceBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // EnhanceDialog 弹起后,Dialog widget 会出现
    expect(find.byType(Dialog), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────────
  // P1.1 候选 3-d:共鸣度晋升信息透明 section
  // ────────────────────────────────────────────────────────────────────────

  group('P1.1 候选 3-d · 共鸣度晋升信息透明', () {
    Future<void> pumpScreen(WidgetTester tester, Equipment eq, EquipmentDef def) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: eq,
              def: def,
              loreLoader: fakeLoader(segments: const ['x']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shengShu(battleCount=0)→ 无加成 + 显距趁手 hint + 无解锁招',
        (tester) async {
      final def = GameRepository.instance.getEquipment('weapon_xunchang_tie_jian');
      final eq = mkEq(def: def, battleCount: 0);
      await pumpScreen(tester, eq, def);

      expect(find.text(UiStrings.equipmentDetailResonanceBonus(0)),
          findsOneWidget);
      expect(find.text(UiStrings.equipmentDetailResonanceJointSkill),
          findsNothing);
      expect(find.text(UiStrings.equipmentDetailResonanceSwordSong),
          findsNothing);
      // 距趁手尚需 100 战(chenShou.minBattleCount=100)
      expect(find.text(UiStrings.equipmentDetailResonanceNextHint(100, '趁手')),
          findsOneWidget);
    });

    testWidgets('moQi(battleCount=500)→ +20% + 解锁人剑合一 + 距心剑通灵 1500',
        (tester) async {
      final def = GameRepository.instance.getEquipment('weapon_xunchang_tie_jian');
      final eq = mkEq(def: def, battleCount: 500);
      await pumpScreen(tester, eq, def);

      expect(find.text(UiStrings.equipmentDetailResonanceBonus(20)),
          findsOneWidget);
      expect(find.text(UiStrings.equipmentDetailResonanceJointSkill),
          findsOneWidget);
      expect(find.text(UiStrings.equipmentDetailResonanceSwordSong),
          findsNothing,
          reason: 'moQi 阶 hasSwordSongEffect=false');
      expect(
          find.text(UiStrings.equipmentDetailResonanceNextHint(1500, '心剑通灵')),
          findsOneWidget);
    });

    testWidgets('xinJianTongLing(battleCount=2000)→ +30% + 两招全解锁 + 无 next hint',
        (tester) async {
      final def = GameRepository.instance.getEquipment('weapon_xunchang_tie_jian');
      final eq = mkEq(def: def, battleCount: 2000);
      await pumpScreen(tester, eq, def);

      expect(find.text(UiStrings.equipmentDetailResonanceBonus(30)),
          findsOneWidget);
      expect(find.text(UiStrings.equipmentDetailResonanceJointSkill),
          findsOneWidget);
      expect(find.text(UiStrings.equipmentDetailResonanceSwordSong),
          findsOneWidget);
      // 最高阶无下一阶 hint
      expect(find.textContaining('距'), findsNothing);
    });
  });
}
