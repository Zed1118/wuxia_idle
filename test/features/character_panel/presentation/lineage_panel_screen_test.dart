import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/character_panel/application/lineage_codex_provider.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_character_detail_screen.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_panel_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// LineagePanelScreen widget 测试（门派谱1.1 Task4 · 纵向世代卷）。
///
/// 通过 `lineageCodexProvider.overrideWith` 注入 LineageGeneration fixture，
/// 不打开 Isar、不加载 GameRepository。`_AscensionSection` 的
/// `ascensionEligibilityProvider` 无 Isar 时同步返 blocked，settle 安全。
///
/// 红线约束语义而非瞬时事实（参 feedback_red_line_test_semantics）：
/// - 进度头按 gens/members 渲染（计数自洽）
/// - 每代代标题 + 当代/退隐标签渲染（分代自洽）
/// - 点卡 push 详情屏（导航自洽）
void main() {
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
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
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
    int enhanceLevel = 0,
  }) {
    return Equipment.create(
      defId: defId,
      tier: EquipmentTier.haoJiaHuo,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 17),
      obtainedFrom: 'test',
      enhanceLevel: enhanceLevel,
      isLineageHeritage: true,
    )..id = id;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    List<LineageGeneration> gens,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lineageCodexProvider.overrideWith((ref) async => gens),
        ],
        child: const MaterialApp(home: LineagePanelScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('单代渲染进度头 + 代标题 + 祖师卡 + 当代标签', (tester) async {
    final gen = LineageGeneration(
      founder: mkCharacter(
        id: 1,
        name: '林青崖',
        lineageRole: LineageRole.founder,
        isFounder: true,
        realmTier: RealmTier.wuSheng,
      ),
      disciples: const [],
      heritageEquipments: const [],
      isCurrent: true,
    );
    await pumpScreen(tester, [gen]);

    expect(find.text(UiStrings.lineageCodexProgress(1, 0)), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexGenerationLabel(1)), findsWidgets);
    expect(find.text('林青崖'), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexCurrentTag), findsOneWidget);
  });

  testWidgets('点祖师卡 push 角色详情屏', (tester) async {
    final gen = LineageGeneration(
      founder: mkCharacter(
        id: 1,
        name: '林青崖',
        lineageRole: LineageRole.founder,
        isFounder: true,
      ),
      disciples: const [],
      heritageEquipments: const [],
      isCurrent: true,
    );
    await pumpScreen(tester, [gen]);

    await tester.tap(find.text('林青崖'));
    await tester.pumpAndSettle();
    expect(find.byType(LineageCharacterDetailScreen), findsOneWidget);
  });

  testWidgets('当代 + 弟子 + 遗物 → 弟子名 / 遗物名 / 进度头计数', (tester) async {
    final gen = LineageGeneration(
      founder: mkCharacter(
        id: 1,
        name: '祖师陈',
        lineageRole: LineageRole.founder,
        isFounder: true,
      ),
      disciples: [
        mkCharacter(id: 2, name: '大徒李', lineageRole: LineageRole.senior),
        mkCharacter(id: 3, name: '二徒王', lineageRole: LineageRole.junior),
      ],
      heritageEquipments: [
        mkHeritage(id: 100, defId: 'qing_yun_jian', enhanceLevel: 3),
      ],
      isCurrent: true,
    );
    await pumpScreen(tester, [gen]);

    expect(find.text(UiStrings.lineageCodexProgress(1, 2)), findsOneWidget);
    expect(find.text('大徒李'), findsOneWidget);
    expect(find.text('二徒王'), findsOneWidget);
    // 遗物名:GameRepository 未加载 → fallback defId
    expect(find.text('qing_yun_jian'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('多代 → 太祖在前 + 退隐/当代标签各显 + 进度头代数', (tester) async {
    final g1 = LineageGeneration(
      founder: mkCharacter(
        id: 1,
        name: '太祖',
        lineageRole: LineageRole.founder,
        isFounder: true,
      ),
      disciples: const [],
      heritageEquipments: const [],
      isCurrent: false,
    );
    final g2 = LineageGeneration(
      founder: mkCharacter(
        id: 2,
        name: '继任者',
        lineageRole: LineageRole.founder,
        isFounder: true,
      ),
      disciples: [
        mkCharacter(id: 3, name: '门人甲', lineageRole: LineageRole.disciple),
      ],
      heritageEquipments: const [],
      isCurrent: true,
    );
    await pumpScreen(tester, [g1, g2]);

    expect(find.text(UiStrings.lineageCodexProgress(2, 1)), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexGenerationLabel(1)), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexGenerationLabel(2)), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexRetiredTag), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexCurrentTag), findsOneWidget);
    expect(find.text('太祖'), findsOneWidget);
    expect(find.text('继任者'), findsOneWidget);
  });

  testWidgets('空代 → 空态文案 + 进度头 (0,0)', (tester) async {
    await pumpScreen(tester, const []);
    expect(find.text(UiStrings.lineageCodexProgress(0, 0)), findsOneWidget);
    expect(find.text(UiStrings.lineagePanelNoFounder), findsOneWidget);
  });

  testWidgets('当代无弟子无遗物 → 两段空态文案', (tester) async {
    final gen = LineageGeneration(
      founder: mkCharacter(
        id: 1,
        name: '孤身祖师',
        lineageRole: LineageRole.founder,
        isFounder: true,
      ),
      disciples: const [],
      heritageEquipments: const [],
      isCurrent: true,
    );
    await pumpScreen(tester, [gen]);
    expect(find.text(UiStrings.lineageCodexNoDisciples), findsOneWidget);
    expect(find.text(UiStrings.lineageCodexNoHeritage), findsOneWidget);
  });
}
