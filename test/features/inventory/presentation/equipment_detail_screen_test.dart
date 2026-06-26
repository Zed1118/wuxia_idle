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
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_ui.dart';

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
    bool isLocked = false,
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
      isLocked: isLocked,
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

    final def = GameRepository.instance.getEquipment(
      'weapon_shenwu_tian_wen_jian',
    );
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
    // D：共鸣度战斗进度 hero 化（moQi 500-2000 阶内 → N/下一阶阈值）。
    expect(find.text('战斗 1240/2000'), findsOneWidget);
    expect(find.text('攻击'), findsOneWidget);
    expect(find.text('血量'), findsOneWidget);
    expect(find.text('速度'), findsOneWidget);
    expect(find.byType(WuxiaTitleBar), findsOneWidget);
    expect(find.byType(PaperPanel), findsWidgets);
    // T8:info 区前移强化/开锋入口(2)+ 底部 ActionBar 兜底(强化/开锋/锁定 3)
    // Task5:背包态追加出售/分解(2)→ 合计 7
    expect(find.byType(PlaqueButton), findsNWidgets(7));
    // 首屏 info 区可见带强化等级的入口（不必滚到底部）
    expect(find.text('强化 +12'), findsOneWidget);
  });

  testWidgets('T8 修复:窄屏小高度下强化/开锋入口仍在首屏内(不被裁出)', (tester) async {
    // Codex 验收在 ~800×632 默认窗口下 FAIL:大图 + 属性把信息卡养成入口挤出首屏。
    // 窄布局(<900 宽)+ 矮窗高,断言信息卡「强化 +N」入口在 viewport 内(免滚动可见)。
    const h = 640.0;
    await tester.binding.setSurfaceSize(const Size(820, h));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_shenwu_tian_wen_jian',
    );
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

    final enhanceEntry = find.text('强化 +12');
    expect(enhanceEntry, findsOneWidget);
    // 信息卡养成入口底边应落在首屏可见区内(不必滚动)。
    expect(
      tester.getRect(enhanceEntry).bottom,
      lessThanOrEqualTo(h),
      reason: '强化/开锋入口必须在首屏可见,不被大图挤出 viewport',
    );
  });

  testWidgets('lore 3 段全渲染 + 段间分隔', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_shenwu_tian_wen_jian',
    );
    final eq = mkEq(def: def);

    const segments = ['段一文本', '段二文本', '段三文本'];

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
    expect(
      find.text('· · ·'),
      findsNWidgets(2),
      reason: '3 段之间应有 2 个 · · · 分隔符',
    );
  });

  testWidgets('loader 返回 placeholder → "典故待补"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_shenwu_tian_wen_jian',
    );
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

  testWidgets('lineage chip · 实例标 / def 不标 → chip 必显(奇遇 override 路径)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // weapon_xunchang_tie_jian def 不标 isLineageHeritage(GameRepository 加载
    // 时 yaml 默认 false),实例强制标 true
    final def = GameRepository.instance.getEquipment(
      'weapon_xunchang_tie_jian',
    );
    expect(
      def.isLineageHeritage,
      isFalse,
      reason: 'precondition: def 不标 isLineageHeritage',
    );
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

    expect(
      find.text(UiStrings.lineageHeritageLabel),
      findsOneWidget,
      reason: '实例 isLineageHeritage=true 必显「遗物」chip,不依赖 def',
    );
  });

  testWidgets('lineage chip · 实例不标 / def 不标 → chip 必隐', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_xunchang_tie_jian',
    );
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

  testWidgets('locked chip · 实例 isLocked=true → chip 必显', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_xunchang_tie_jian',
    );
    final eq = mkEq(def: def, isLocked: true);

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

    expect(find.text(UiStrings.equipmentLockedLabel), findsOneWidget);
  });

  testWidgets(
    'lineage chip · def 自带 → EquipmentFactory propagate → 实例标 → chip 必显',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // weapon_liqi_long_quan def 自带 isLineageHeritage=true(equipment.yaml)
      final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
      expect(
        def.isLineageHeritage,
        isTrue,
        reason: 'precondition: def 自带 isLineageHeritage',
      );
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
    },
  );

  testWidgets('强化按钮 tap → EnhanceDialog 弹起', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment(
      'weapon_shenwu_tian_wen_jian',
    );
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

    // 详情屏底部「强化」按钮(PlaqueButton)。按钮在详情滚动页底部，先滚到可见。
    final enhanceBtn = find.text('强化');
    await tester.scrollUntilVisible(
      enhanceBtn,
      300,
      scrollable: find.byType(Scrollable),
    );
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
    Future<void> pumpScreen(
      WidgetTester tester,
      Equipment eq,
      EquipmentDef def,
    ) async {
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

    testWidgets('shengShu(battleCount=0)→ 无加成 + 显距趁手 hint + 无解锁招', (
      tester,
    ) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_xunchang_tie_jian',
      );
      final eq = mkEq(def: def, battleCount: 0);
      await pumpScreen(tester, eq, def);

      expect(
        find.text(UiStrings.equipmentDetailResonanceBonus(0)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.equipmentDetailResonanceJointSkill),
        findsNothing,
      );
      expect(
        find.text(UiStrings.equipmentDetailResonanceSwordSong),
        findsNothing,
      );
      // D：五要素「下一阶效果」= 趁手 +10%；战斗进度 0/100。
      expect(
        find.text(UiStrings.equipmentResonanceNextBonus(10)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.equipmentResonanceBattleProgress(0, 100)),
        findsOneWidget,
      );
    });

    testWidgets('moQi(battleCount=500)→ +20% + 解锁人剑合一 + 距心剑通灵 1500', (
      tester,
    ) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_xunchang_tie_jian',
      );
      final eq = mkEq(def: def, battleCount: 500);
      await pumpScreen(tester, eq, def);

      expect(
        find.text(UiStrings.equipmentDetailResonanceBonus(20)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.equipmentDetailResonanceJointSkill),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.equipmentDetailResonanceSwordSong),
        findsNothing,
        reason: 'moQi 阶 hasSwordSongEffect=false',
      );
      // D：五要素「下一阶效果」= 心剑通灵 +30%；战斗进度 500/2000。
      expect(
        find.text(UiStrings.equipmentResonanceNextBonus(30)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.equipmentResonanceBattleProgress(500, 2000)),
        findsOneWidget,
      );
    });

    testWidgets(
      'xinJianTongLing(battleCount=2000)→ +30% + 两招全解锁 + 无 next hint',
      (tester) async {
        final def = GameRepository.instance.getEquipment(
          'weapon_xunchang_tie_jian',
        );
        final eq = mkEq(def: def, battleCount: 2000);
        await pumpScreen(tester, eq, def);

        expect(
          find.text(UiStrings.equipmentDetailResonanceBonus(30)),
          findsOneWidget,
        );
        expect(
          find.text(UiStrings.equipmentDetailResonanceJointSkill),
          findsOneWidget,
        );
        expect(
          find.text(UiStrings.equipmentDetailResonanceSwordSong),
          findsOneWidget,
        );
        // 最高阶无下一阶 hint
        expect(find.textContaining('距'), findsNothing);
      },
    );
  });

  // H2 小套餐 E2:effective 实战值可见(换装判优基础)。
  // 此前 _StatRow 只显裸 base,强化/共鸣/开锋乘法后的真实战力 UI 不展示。
  group('E2 · effective 数值可见', () {
    Future<void> pump(
      WidgetTester tester,
      Equipment eq,
      EquipmentDef def,
    ) async {
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

    testWidgets('强化+12 共鸣装备 → 显实战值 + 「基 N」副标', (tester) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_shenwu_tian_wen_jian',
      );
      final eq = mkEq(def: def, enhanceLevel: 12, battleCount: 1240);
      await pump(tester, eq, def);
      expect(
        find.textContaining('基 ${eq.baseAttack}'),
        findsOneWidget,
        reason: 'effective≠base 时显原始 base 副标,玩家看得到实战值来源',
      );
    });

    testWidgets('裸装备(+0/0 战)effective==base → 无冗余副标', (tester) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_xunchang_tie_jian',
      );
      final eq = mkEq(def: def);
      await pump(tester, eq, def);
      expect(
        find.textContaining('基 '),
        findsNothing,
        reason: 'effective==base 时不显冗余副标',
      );
    });
  });

  // P2 补盲:isHighTreasureTier 纯函数已测,但「detail 屏据它切换边框/题字」
  // 这一 wiring 此前无覆盖(memory feedback_strategy_immutable_vs_ui_tick
  // 「配置测了消费没测」)。此组直接断言渲染分支。
  group('神物/宝物差异化 wiring(§5.4 出版美术)', () {
    Future<void> pumpDetail(WidgetTester tester, EquipmentDef def) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EquipmentDetailScreen(
              equipment: mkEq(def: def),
              def: def,
              loreLoader: fakeLoader(segments: const ['x']),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // 详情大图(detailPath)所在 Container 的 border(高阶 Border.all / 普通仅底边)。
    Border coverBorder(WidgetTester tester, EquipmentDef def) {
      final img = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == def.detailPath,
      );
      final container = tester.widget<Container>(
        find.ancestor(of: img, matching: find.byType(Container)).first,
      );
      return (container.decoration as BoxDecoration).border! as Border;
    }

    Text titleBarText(WidgetTester tester, EquipmentDef def) =>
        tester.widget<Text>(
          find.descendant(
            of: find.byType(WuxiaTitleBar),
            matching: find.text(def.name),
          ),
        );

    testWidgets('神物 → 全周粗边框(width3) + 题字 fontSize22', (tester) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_shenwu_tian_wen_jian',
      );
      await pumpDetail(tester, def);

      expect(titleBarText(tester, def).style?.fontSize, 22, reason: '高阶题字加大');
      final b = coverBorder(tester, def);
      expect(b.top.width, 3, reason: '神物全周粗边框 Border.all(width3)');
      expect(b.left.width, 3);
    });

    testWidgets('寻常货 → 仅底边(width2) + 题字默认字号', (tester) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_xunchang_tie_jian',
      );
      await pumpDetail(tester, def);

      expect(
        titleBarText(tester, def).style?.fontSize,
        19,
        reason: '普通装备题字默认字号',
      );
      final b = coverBorder(tester, def);
      expect(b.top, BorderSide.none, reason: '普通装备无顶边');
      expect(b.bottom.width, 2, reason: '普通装备仅底边 width2');
    });

    // P0 #3(§5.4):详情大图从 BoxFit.cover → contain,细长兵器完整展示不裁切。
    testWidgets('详情大图用 BoxFit.contain(不裁切细长兵器)', (tester) async {
      final def = GameRepository.instance.getEquipment(
        'weapon_shenwu_tian_wen_jian',
      );
      await pumpDetail(tester, def);

      final img = tester.widget<Image>(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == def.detailPath,
        ),
      );
      expect(img.fit, BoxFit.contain, reason: '细长兵器需完整展示,不能 cover 裁切');
    });
  });
}
