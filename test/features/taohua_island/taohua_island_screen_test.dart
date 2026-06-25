import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_providers.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';
import 'package:wuxia_idle/features/taohua_island/presentation/taohua_island_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';

/// TaohuaIslandScreen widget 测试。
///
/// 使用 [taohuaIslandViewProvider] override 注入假 view，避免真实 Isar。
/// harvest 按钮存在但不点击（依赖 Isar 真实路径；冒烟 Task 14 覆盖，
/// 沿 feedback_battle_result_path_config_read_crashes_light_test 防御体例）。
/// ListView 扩展 viewport（feedback_listview_widget_test_viewport）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── 构造测试 view ──────────────────────────────────────────────────────────

  /// 构建 4 个建筑的 IslandBuildingState 测试快照。
  ///
  /// - tieJiangChang: level=2, stored=50（source，无 recipe）
  /// - caoYaoYuan:    level=1, stored=10（source，无 recipe）
  /// - daZaoTai:      level=1, stored=3, activeRecipeId='forge_mojianshi'（processor）
  /// - danFang:       level=1, stored=0, activeRecipeId=null（processor，停产）
  IslandView buildTestView({
    int silver = 100,
    Map<String, int>? materials,
    int founderRealmIndex = 0,
  }) {
    final tieState = IslandBuildingState()
      ..type = BuildingType.tieJiangChang
      ..level = 2
      ..stored = 50;

    final caoState = IslandBuildingState()
      ..type = BuildingType.caoYaoYuan
      ..level = 1
      ..stored = 10;

    final dzState = IslandBuildingState()
      ..type = BuildingType.daZaoTai
      ..level = 1
      ..stored = 3
      ..activeRecipeId = 'forge_mojianshi';

    final dfState = IslandBuildingState()
      ..type = BuildingType.danFang
      ..level = 1
      ..stored = 0;
    // activeRecipeId = null → 停产

    return IslandView(
      buildings: [tieState, caoState, dzState, dfState],
      founderRealmIndex: founderRealmIndex,
      silver: silver,
      materials: materials ??
          {
            // 各建筑升级材料（按 data/taohua_island.yaml 的 upgrade_material_item）
            'item_mojianshi': 100,
            'item_jingtie': 100,
            'item_yaocao': 100,
            'item_xinxuejiejing': 100,
          },
    );
  }

  Widget wrap(IslandView? view) => ProviderScope(
        overrides: [
          taohuaIslandViewProvider
              .overrideWith((ref) async => view),
        ],
        child: const MaterialApp(
          home: TaohuaIslandScreen(),
        ),
      );

  // ── 辅助：扩大 viewport ────────────────────────────────────────────────────

  Future<void> pump(WidgetTester tester, Widget widget) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  // ── 渲染测试 ──────────────────────────────────────────────────────────────

  group('TaohuaIslandScreen 渲染', () {
    testWidgets('AppBar 标题出现', (tester) async {
      await pump(tester, wrap(buildTestView()));
      expect(find.text(UiStrings.taohuaIslandTitle), findsOneWidget);
    });

    testWidgets('4 个建筑名均渲染', (tester) async {
      await pump(tester, wrap(buildTestView()));

      for (final type in BuildingType.values) {
        expect(
          find.text(EnumL10n.buildingType(type)),
          findsOneWidget,
          reason: '${EnumL10n.buildingType(type)} 应出现',
        );
      }
    });

    testWidgets('等级文本渲染（level=2 的 tieJiangChang）', (tester) async {
      await pump(tester, wrap(buildTestView()));
      // tieJiangChang level=2 → '第 2 级'
      expect(
        find.text(UiStrings.taohuaIslandLevelLabel(2)),
        findsOneWidget,
      );
    });

    testWidgets('仓储文本渲染（50/900 for tieJiangChang level=2）', (tester) async {
      await pump(tester, wrap(buildTestView()));
      // tieJiangChang: capFor(2) = capBase(450) + 1*capPerLevel(450) = 900
      //（2026-06-25 cap 对齐 72h 后 200/100 → 450/450）
      // stored = 50.floor() = 50
      expect(
        find.text(UiStrings.taohuaIslandStorageLabel(50, 900)),
        findsOneWidget,
      );
    });

    testWidgets('升级按钮存在', (tester) async {
      await pump(tester, wrap(buildTestView()));
      // 至少 1 个升级按钮可见
      expect(
        find.text(UiStrings.taohuaIslandUpgrade),
        findsWidgets,
      );
    });

    testWidgets('processor 建筑有选配方文案', (tester) async {
      await pump(tester, wrap(buildTestView()));
      // 两个 processor 各有选配方标签
      expect(
        find.text(UiStrings.taohuaIslandSelectRecipe),
        findsNWidgets(2),
      );
    });

    testWidgets('产出中 / 已停标签正确', (tester) async {
      await pump(tester, wrap(buildTestView()));
      // daZaoTai activeRecipeId 非 null → 产出中
      expect(find.text(UiStrings.taohuaIslandIdleProducing), findsOneWidget);
      // danFang activeRecipeId == null → 已停
      expect(find.text(UiStrings.taohuaIslandIdlePaused), findsOneWidget);
    });

    testWidgets('一并收取按钮存在', (tester) async {
      await pump(tester, wrap(buildTestView()));
      expect(find.text(UiStrings.taohuaIslandHarvestAll), findsOneWidget);
    });

    testWidgets('null view 显示无存档友好态', (tester) async {
      await pump(tester, wrap(null));
      expect(find.textContaining('无存档'), findsOneWidget);
    });

    testWidgets('满级建筑(level=maxLevel)渲染不崩 + 显示已至顶级', (tester) async {
      // 回归守卫(B1)：节奏 B 把升级银两改成 per-level 数组(长度 maxLevel-1)后，
      // _UpgradeSection 若在满级仍算 upgradeSilverFor(maxLevel) 会数组越界 RangeError。
      // 满级建筑须正常渲染、显示「已至顶级」、不显示升级费用文案。
      final tieMax = IslandBuildingState()
        ..type = BuildingType.tieJiangChang
        ..level = 5 // = max_level
        ..stored = 50;
      final cao = IslandBuildingState()
        ..type = BuildingType.caoYaoYuan
        ..level = 1
        ..stored = 0;
      final dz = IslandBuildingState()
        ..type = BuildingType.daZaoTai
        ..level = 1
        ..stored = 0
        ..activeRecipeId = 'forge_mojianshi';
      final df = IslandBuildingState()
        ..type = BuildingType.danFang
        ..level = 1
        ..stored = 0;
      final view = IslandView(
        buildings: [tieMax, cao, dz, df],
        founderRealmIndex: 6, // 武圣，排除 realmLocked 噪音
        silver: 999999,
        materials: const {
          'item_jingtie': 100,
          'item_yaocao': 100,
          'item_mojianshi': 100,
          'item_xinxuejiejing': 100,
        },
      );
      await pump(tester, wrap(view));

      expect(tester.takeException(), isNull,
          reason: '满级建筑渲染不应抛 RangeError');
      expect(find.text(UiStrings.taohuaIslandMaxLevel), findsOneWidget,
          reason: '满级建筑应显示已至顶级标签');
    });
  });

  // ── 灰化逻辑测试 ──────────────────────────────────────────────────────────

  group('升级按钮灰化', () {
    testWidgets('银两不足时出现银两不足提示', (tester) async {
      // silver=0 → 所有建筑银两不足
      final view = buildTestView(silver: 0);
      await pump(tester, wrap(view));

      expect(
        find.text(UiStrings.taohuaIslandNotEnoughSilver),
        findsWidgets,
        reason: '银两=0 时所有建筑应显示银两不足提示',
      );
    });

    testWidgets('材料不足时出现材料不足提示', (tester) async {
      // 银两够，材料全空
      final view = buildTestView(
        silver: 999999,
        materials: {
          'item_mojianshi': 0,
          'item_jingtie': 0,
          'item_yaocao': 0,
          'item_xinxuejiejing': 0,
        },
      );
      await pump(tester, wrap(view));

      expect(
        find.text(UiStrings.taohuaIslandNotEnoughMaterial),
        findsWidgets,
        reason: '材料全空时应显示材料不足提示',
      );
    });
  });

  group('配方境界门槛灰化', () {
    testWidgets('founderRealmIndex=0 时 realmUnlockIndex=3 配方半透（灰化）', (tester) async {
      // founderRealmIndex=0，高阶配方 realm=3 → 应灰化
      // forge_xinxue (realm=3) 和 brew_peiyuan (realm=3) 应被 Opacity 0.4 包裹
      final view = buildTestView(founderRealmIndex: 0);
      await pump(tester, wrap(view));

      // 找到所有 Opacity=0.4 的 widget，验证至少有灰化元素
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      final grayedCount = opacityWidgets
          .where((o) => (o.opacity - 0.4).abs() < 0.01)
          .length;
      expect(
        grayedCount,
        greaterThanOrEqualTo(2),
        reason: '两个高阶配方（realm=3）在 founderRealmIndex=0 时应各自灰化',
      );
    });

    testWidgets('founderRealmIndex=3 时高阶配方不灰化', (tester) async {
      // realm=3 祖师 → 高阶配方 unlock
      final view = buildTestView(founderRealmIndex: 3, silver: 999999);
      await pump(tester, wrap(view));

      // 境界已到，不应有 realmLocked 提示
      expect(find.text(UiStrings.taohuaIslandRealmLocked), findsNothing);
    });
  });
}
