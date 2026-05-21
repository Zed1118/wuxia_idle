import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_info_provider.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_panel_screen.dart';

/// LineagePanelScreen 边界用例（W17 候选 E · nightshift T04）。
///
/// 5 用例：大量 heritage / disciples 列表含异常 isFounder=true 数据 /
/// 多 disciples / founder + disciples 全在但 heritage 空 /
/// founder school=null 兜底色条。
///
/// 红线：约束语义而非瞬时事实——
/// - heritage 件数 == fixture 长度（计数自洽）
/// - disciple 名字字段被 chip 渲染（字段绑定自洽）
/// - 空字段触发对应空态文案（分支自洽）
/// - school=null 走 textMuted 兜底不抛错（防御性兜底自洽）
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
    TechniqueSchool? school = TechniqueSchool.gangMeng,
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
      school: school,
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
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lineageInfoProvider.overrideWith((ref) async => fixture),
        ],
        child: const MaterialApp(home: LineagePanelScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 1：大量 heritage（10 件）────────────────────────────────────────

  testWidgets('heritageEquipments 长度 10 → 「10 件」计数 + 10 个 defId 文字渲染',
      (tester) async {
    final heritages = List.generate(
      10,
      (i) => mkHeritage(id: 100 + i, defId: 'item_${i.toString().padLeft(2, '0')}'),
    );

    await pumpScreen(
      tester,
      LineageInfo(
        founder: null,
        disciples: const [],
        inactiveDisciples: const [],
        heritageEquipments: heritages,
      ),
    );

    // 计数自洽：件数文字与 fixture 长度一致
    expect(find.text('10 件'), findsOneWidget);

    // 每个 heritage row 渲染了对应 defId（GameRepository 未加载时 fallback 到 defId）
    for (var i = 0; i < 10; i++) {
      expect(
        find.text('item_${i.toString().padLeft(2, '0')}'),
        findsOneWidget,
        reason: 'heritage row $i 应渲染其 defId',
      );
    }
  });

  // ── 用例 2：disciples 列表含 isFounder=true 异常数据 ─────────────────────

  testWidgets(
      'disciples 列表含 isFounder=true 角色 → UI 仍渲染为弟子 chip，不影响 founder 段',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师岳',
      lineageRole: LineageRole.founder,
      isFounder: true,
    );
    // 第 2 个 disciple 带 isFounder=true（异常存档场景）
    // view model 已将其放入 disciples 列表；UI 不再二次过滤，直接渲染
    final d1 = mkCharacter(
      id: 2,
      name: '大徒赵',
      lineageRole: LineageRole.disciple,
    );
    final d2 = mkCharacter(
      id: 3,
      name: '二徒钱',
      lineageRole: LineageRole.disciple,
      isFounder: true,
    );

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founder,
        disciples: [d1, d2],
        inactiveDisciples: const [],
        heritageEquipments: const [],
      ),
    );

    // 祖师段：founder name 渲染
    expect(find.text('祖师岳'), findsOneWidget);
    // 弟子段：两个 disciple 均渲染，不被误判为第二个 founder
    expect(find.text('大徒赵'), findsOneWidget);
    expect(find.text('二徒钱'), findsOneWidget);
    // founder 段不出现「祖师未定」
    expect(find.text('祖师未定'), findsNothing);
    // 弟子段不出现「尚无弟子」
    expect(find.text('尚无弟子'), findsNothing);
  });

  // ── 用例 3：多 disciples（3 个） ──────────────────────────────────────────

  testWidgets('3 个 disciples → 3 个 chip 全部渲染，无空态文案', (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师孙',
      lineageRole: LineageRole.founder,
      isFounder: true,
    );
    final d1 = mkCharacter(id: 2, name: '大徒李', lineageRole: LineageRole.disciple);
    final d2 = mkCharacter(id: 3, name: '二徒周', lineageRole: LineageRole.disciple);
    final d3 = mkCharacter(id: 4, name: '三徒吴', lineageRole: LineageRole.disciple);

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founder,
        disciples: [d1, d2, d3],
        inactiveDisciples: const [],
        heritageEquipments: const [],
      ),
    );

    // 3 个弟子名字均渲染（字段绑定自洽）
    expect(find.text('大徒李'), findsOneWidget);
    expect(find.text('二徒周'), findsOneWidget);
    expect(find.text('三徒吴'), findsOneWidget);
    // 弟子段无空态文案
    expect(find.text('尚无弟子'), findsNothing);
  });

  // ── 用例 4：founder + disciples 全在，heritage 空 ─────────────────────────

  testWidgets('founder + disciples 存在，heritageEquipments=[] → 空态文案 + 无「N 件」计数',
      (tester) async {
    final founder = mkCharacter(
      id: 1,
      name: '祖师郑',
      lineageRole: LineageRole.founder,
      isFounder: true,
    );
    final d1 = mkCharacter(id: 2, name: '大徒王', lineageRole: LineageRole.disciple);

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founder,
        disciples: [d1],
        inactiveDisciples: const [],
        heritageEquipments: const [],
      ),
    );

    // 师承遗物段标题渲染
    expect(find.text('师承遗物'), findsOneWidget);
    // 空态文案渲染
    expect(find.text('尚未拥有师承遗物'), findsOneWidget);
    // 不应出现「N 件」计数（equipments.isNotEmpty 为 false）
    expect(find.textContaining('件'), findsNothing);
  });

  // ── 用例 5：founder school=null → 色条走 textMuted 兜底，不抛错 ──────────

  testWidgets('founder school=null → _CharacterChip 正常渲染，name 显示无异常',
      (tester) async {
    final founderNoSchool = mkCharacter(
      id: 1,
      name: '无派祖师',
      lineageRole: LineageRole.founder,
      isFounder: true,
      school: null,
    );

    await pumpScreen(
      tester,
      LineageInfo(
        founder: founderNoSchool,
        disciples: const [],
        inactiveDisciples: const [],
        heritageEquipments: const [],
      ),
    );

    // name 字段正常渲染（不因 school=null 抛错或跳过渲染）
    expect(find.text('无派祖师'), findsOneWidget);
    // 无 ErrorWidget
    expect(find.byType(ErrorWidget), findsNothing);
  });
}
