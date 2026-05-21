import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_info_provider.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_panel_screen.dart';

/// LineagePanelScreen widget 测试（W17 候选 E）。
///
/// 3 用例：完整 fixture 渲染 / 全空态文案 / 仅 founder 部分态。
/// 全部通过 `lineageInfoProvider.overrideWith` 注入 fixture，不打开 Isar、
/// 不加载 GameRepository（_HeritageRow 名字解析未 load 时 fallback 到 defId，
/// 不影响计数与空态断言）。
///
/// 红线约束语义而非瞬时事实（参 feedback_red_line_test_semantics）：
/// - founder.name / 弟子 name 字段被 UI 渲染（字段绑定自洽）
/// - heritage 件数 == fixture 长度（计数自洽）
/// - 空字段触发对应空态文案（分支自洽）
void main() {
  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({
    required int id,
    required String name,
    required LineageRole lineageRole,
    bool isFounder = false,
    RealmTier realmTier = RealmTier.xueTu,
  }) {
    return Character.create(
      name: name,
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 5, 17),
      school: TechniqueSchool.gangMeng,
      isFounder: isFounder,
    )..id = id;
  }

  Equipment mkHeritage({
    required int id,
    required String defId,
    EquipmentTier tier = EquipmentTier.haoJiaHuo,
    int enhanceLevel = 0,
  }) {
    return Equipment.create(
      defId: defId,
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 17),
      obtainedFrom: 'test',
      enhanceLevel: enhanceLevel,
      isLineageHeritage: true,
    )..id = id;
  }

  Future<void> pumpScreen(WidgetTester tester, LineageInfo fixture) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lineageInfoProvider.overrideWith((ref) async => fixture),
        ],
        child: const MaterialApp(home: LineagePanelScreen()),
      ),
    );
    // 三次 pump 让 lineageInfoProvider Future 完成 + AsyncValue 翻转 + body rebuild。
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 1：完整 fixture ─────────────────────────────────────────────────

  testWidgets('founder + 2 disciples + 2 heritage → 3 角色 name 渲染 + 「2 件」 计数',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师陈',
      lineageRole: LineageRole.founder,
      isFounder: true,
    );
    final d1 = mkCharacter(
      id: 2,
      name: '大徒李',
      lineageRole: LineageRole.disciple,
    );
    final d2 = mkCharacter(
      id: 3,
      name: '二徒王',
      lineageRole: LineageRole.disciple,
    );
    final h1 = mkHeritage(id: 100, defId: 'qing_yun_jian', enhanceLevel: 3);
    final h2 = mkHeritage(id: 101, defId: 'liu_yun_pao');

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founder,
        disciples: [d1, d2],
        inactiveDisciples: const [],
        heritageEquipments: [h1, h2],
      ),
    );

    expect(find.text('祖师陈'), findsOneWidget);
    expect(find.text('大徒李'), findsOneWidget);
    expect(find.text('二徒王'), findsOneWidget);
    expect(find.text('2 件'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
  });

  // ── 用例 2：全空态 ───────────────────────────────────────────────────────

  testWidgets('founder=null + disciples=[] + heritage=[] → 3 段空态文案',
      (tester) async {
    await pumpScreen(
      tester,
      const LineageInfo(
        founder: null,
        disciples: [],
        inactiveDisciples: [],
        heritageEquipments: [],
      ),
    );

    expect(find.text('祖师未定'), findsOneWidget);
    expect(find.text('尚无弟子'), findsOneWidget);
    expect(find.text('尚未拥有师承遗物'), findsOneWidget);
  });

  // ── 用例 3：仅 founder + 1 heritage ─────────────────────────────────────

  testWidgets('founder + disciples=[] + 1 heritage → 弟子段空态 / 「1 件」计数',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师陈',
      lineageRole: LineageRole.founder,
      isFounder: true,
    );
    final h = mkHeritage(id: 100, defId: 'qing_yun_jian');

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founder,
        disciples: const [],
        inactiveDisciples: const [],
        heritageEquipments: [h],
      ),
    );

    expect(find.text('祖师陈'), findsOneWidget);
    expect(find.text('尚无弟子'), findsOneWidget);
    expect(find.text('1 件'), findsOneWidget);
  });
}
