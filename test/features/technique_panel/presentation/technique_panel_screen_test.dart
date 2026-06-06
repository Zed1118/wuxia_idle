import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/features/technique_panel/presentation/technique_panel_screen.dart';

/// T31 心法面板 widget 测试（phase2_tasks.md §483）。
///
/// 4 用例：分组渲染 / 主修-辅修「设为主修」按钮可见性 / 散功 dialog 双代价文案 /
/// 二次确认取消不触发 dispel。全部走 ProviderScope.overrides 注入 fixture，
/// 不打开真实 Isar；setUpAll 加载真实 GameRepository（散功代价系数走 numbers.yaml）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int internalForce = 1000,
    int insightPoints = 0,
  }) {
    return Character.create(
      name: '测试者',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForce: internalForce,
      internalForceMax: 5000,
      school: TechniqueSchool.gangMeng,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
      insightPoints: insightPoints,
    )..id = 1;
  }

  Technique mkTechnique({
    required int id,
    required int ownerId,
    required TechniqueRole role,
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
    int cultivationProgress = 0,
    int cultivationProgressToNext = 100,
    CultivationLayer cultivationLayer = CultivationLayer.chuKui,
  }) {
    return Technique.create(
      defId: 'test_tech_$id',
      ownerCharacterId: ownerId,
      tier: tier,
      school: school,
      role: role,
      learnedAt: DateTime(2026, 5, 11),
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
      cultivationLayer: cultivationLayer,
    )..id = id;
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Character character,
    required Map<int, Technique> techniques,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterByIdProvider(
            character.id,
          ).overrideWith((ref) async => character),
          for (final entry in techniques.entries)
            techniqueByIdProvider(
              entry.key,
            ).overrideWith((ref) async => entry.value),
        ],
        child: MaterialApp(
          home: TechniquePanelScreen(characterId: character.id),
        ),
      ),
    );
    // 三次 pump 让 character + techniques 两个 family 异步链全部翻转完。
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // ── 用例 1：分组渲染 ──────────────────────────────────────────────────

  testWidgets('已学心法按 tier 分组渲染 + 主修 1 / 辅修 2', (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 100,
      assistTechniqueIds: [101, 102],
    );
    final main = mkTechnique(
      id: 100,
      ownerId: 1,
      role: TechniqueRole.main,
      tier: TechniqueTier.ruMenGong,
    );
    final assist1 = mkTechnique(
      id: 101,
      ownerId: 1,
      role: TechniqueRole.assist,
      tier: TechniqueTier.ruMenGong,
    );
    final assist2 = mkTechnique(
      id: 102,
      ownerId: 1,
      role: TechniqueRole.assist,
      tier: TechniqueTier.changLianGong,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {100: main, 101: assist1, 102: assist2},
    );

    expect(find.text('入门功'), findsOneWidget);
    expect(find.text('常练功'), findsOneWidget);
    expect(find.text(UiStrings.techniqueSchoolMatrixTitle), findsOneWidget);
    expect(find.text('主修'), findsOneWidget);
    expect(find.text('辅修'), findsNWidgets(2));
  });

  // ── 用例 2：主修-辅修按钮可见性 ───────────────────────────────────────

  testWidgets('「设为主修」按钮仅在辅修 tile 出现，主修 tile 不出现', (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 100,
      assistTechniqueIds: [101, 102],
    );
    final main = mkTechnique(id: 100, ownerId: 1, role: TechniqueRole.main);
    final assist1 = mkTechnique(
      id: 101,
      ownerId: 1,
      role: TechniqueRole.assist,
    );
    final assist2 = mkTechnique(
      id: 102,
      ownerId: 1,
      role: TechniqueRole.assist,
    );

    await pumpPanel(
      tester,
      character: character,
      techniques: {100: main, 101: assist1, 102: assist2},
    );

    expect(find.text(UiStrings.setAsMainButton), findsNWidgets(2));
  });

  // ── 用例 3：散功 dialog 双重代价文案 ──────────────────────────────────

  testWidgets('点击辅修「设为主修」→ dialog 显示内力/修炼度/层回退三行', (tester) async {
    final character = mkCharacter(
      mainTechniqueId: 100,
      assistTechniqueIds: [101],
      internalForce: 1000,
    );
    final main = mkTechnique(
      id: 100,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 800,
    );
    final assist = mkTechnique(id: 101, ownerId: 1, role: TechniqueRole.assist);

    await pumpPanel(
      tester,
      character: character,
      techniques: {100: main, 101: assist},
    );

    await tester.ensureVisible(find.text(UiStrings.setAsMainButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.setAsMainButton));
    await tester.pump();
    await tester.pump();

    // numbers.yaml dispersion 系数 = 0.5 → 1000→500, 800→400
    expect(find.text('内力 1000 → 500'), findsOneWidget);
    expect(find.text('修炼度 800 → 400'), findsOneWidget);
    expect(find.text(UiStrings.dispelLayerWarning), findsOneWidget);
    expect(find.text(UiStrings.dispelDialogTitle), findsOneWidget);
  });

  // ── 用例 4：二次确认取消不触发 dispel ────────────────────────────────

  testWidgets('dispel dialog 取消 → character 和两条 technique 状态全部不变', (
    tester,
  ) async {
    final character = mkCharacter(
      mainTechniqueId: 100,
      assistTechniqueIds: [101],
      internalForce: 1000,
    );
    final main = mkTechnique(
      id: 100,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationProgress: 800,
    );
    final assist = mkTechnique(id: 101, ownerId: 1, role: TechniqueRole.assist);

    await pumpPanel(
      tester,
      character: character,
      techniques: {100: main, 101: assist},
    );

    await tester.ensureVisible(find.text(UiStrings.setAsMainButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.setAsMainButton));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(UiStrings.forgingConfirmCancel));
    await tester.pump();
    await tester.pump();

    expect(character.mainTechniqueId, 100);
    expect(character.internalForce, 1000);
    expect(main.role, TechniqueRole.main);
    expect(main.cultivationProgress, 800);
    expect(assist.role, TechniqueRole.assist);
  });

  // ── 用例 5：凝练领悟入口常驻态（H1 批3）─────────────────────────────────

  testWidgets('insightPoints>0 → 主修凝练入口显点数且可点', (tester) async {
    final character = mkCharacter(mainTechniqueId: 100, insightPoints: 5);
    final main = mkTechnique(id: 100, ownerId: 1, role: TechniqueRole.main);

    await pumpPanel(tester, character: character, techniques: {100: main});

    final label = UiStrings.refineInsightButtonWithPoints(5); // '凝练领悟 · 5 点'
    expect(find.text(label), findsOneWidget);
    expect(find.text(UiStrings.refineInsightButtonEmpty), findsNothing);
    // 可点：onPressed 非 null。
    final btn = tester.widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('insightPoints=0 → 主修凝练入口灰显常驻且不可点', (tester) async {
    final character = mkCharacter(mainTechniqueId: 100, insightPoints: 0);
    final main = mkTechnique(id: 100, ownerId: 1, role: TechniqueRole.main);

    await pumpPanel(tester, character: character, techniques: {100: main});

    expect(find.text(UiStrings.refineInsightButtonEmpty), findsOneWidget);
    // 不可点：onPressed == null（§5.7 状态常驻而非靠点击后 SnackBar 才知）。
    final btn = tester.widget<TextButton>(
      find.ancestor(
        of: find.text(UiStrings.refineInsightButtonEmpty),
        matching: find.byType(TextButton),
      ),
    );
    expect(btn.onPressed, isNull);
  });

  // ── 用例 6/7：B4 主修 hero 区（出版美术）──────────────────────────────

  testWidgets('主修存在 → hero 区显「主修心法」label + 段位阶梯 n/9 层', (tester) async {
    final character = mkCharacter(mainTechniqueId: 100);
    final main = mkTechnique(
      id: 100,
      ownerId: 1,
      role: TechniqueRole.main,
      cultivationLayer: CultivationLayer.daCheng,
    );
    await pumpPanel(tester, character: character, techniques: {100: main});
    expect(find.text(UiStrings.techniquePanelMainHeroLabel), findsOneWidget);
    // daCheng = index 3 → 第 4 / 9 层。
    expect(find.text(UiStrings.layerProgressLabel(4, 9)), findsOneWidget);
  });

  testWidgets('仅辅修无主修 → 不显 hero', (tester) async {
    final character = mkCharacter(assistTechniqueIds: [101]);
    final assist = mkTechnique(id: 101, ownerId: 1, role: TechniqueRole.assist);
    await pumpPanel(tester, character: character, techniques: {101: assist});
    expect(find.text(UiStrings.techniquePanelMainHeroLabel), findsNothing);
  });
}
