import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/image_test_helpers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_providers.dart';
import 'package:wuxia_idle/features/festival/application/festival_service_providers.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/features/tutorial/presentation/tutorial_banner_card.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

/// T32 子提交 3b：[MainMenu] widget 测试（T42 加「问鼎九霄」T49 加「闭关修炼」+ W17 候选 E 加「师徒名单」+ P0.2 #40 加「排行榜」+ P1b Task10 加「藏经阁」+ 桃花岛 P1 Task13 后扩 10 个+1 个）。
///
/// 用例覆盖：
///   - 标题 mainMenuTitle 渲染
///   - 菜单按钮 label 匹配（主线 / 问鼎九霄 / 排行榜 / 闭关修炼 / Phase1 / Phase2 / 角色 / 师徒名单 / 装备 / 心法 / 藏经阁 / 桃花岛）
///   - 23 个菜单入口 WuxiaInkButton（按钮全部可点）+ 右上角退出键 = 24 InkWell
///   - Tap "Phase 1 战斗测试" → push BattleTestMenu
///   - Tap "Phase 2 调试场景" → push Phase2TestMenu
///
/// 主线 / 问鼎九霄 / 角色 / 师徒名单 / 装备 / 心法 按钮 push 的页面依赖 Isar（师徒名单经
/// `lineageInfoProvider` 派生 Isar，未注入 fixture 时无法 settle），widget test 旁路
/// （与 T28/T31 同决策，沿用挂账 #23）；按钮可点性通过 InkWell 计数 + label
/// 渲染断言覆盖。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs();
  });

  Widget app() => const ProviderScope(child: MaterialApp(home: MainMenu()));

  Finder assetImage(String path) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        assetNameOf(w.image) == path,
  );

  testWidgets('标题渲染：mainMenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
  });

  testWidgets('主菜单渲染 MJ 门面背景', (tester) async {
    await tester.pumpWidget(app());
    expect(assetImage(WuxiaUi.mainMenuBg), findsOneWidget);
  });

  testWidgets('23 个菜单按钮 label 全部可见且顺序正确', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text(UiStrings.mainMenuMainline), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInnerDemon), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLightFoot), findsOneWidget);
    expect(find.text(UiStrings.mainMenuMassBattle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTaohuaIsland), findsOneWidget);
    expect(find.text(UiStrings.mainMenuJianghu), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSect), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLeaderboard), findsOneWidget);
    expect(find.text(UiStrings.mainMenuZangjuange), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSeclusion), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase1), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase2), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSectRecruit), findsOneWidget);
    expect(find.text(UiStrings.mainMenuCharacterPanel), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLineage), findsOneWidget);
    expect(find.text(UiStrings.mainMenuBaike), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuResourceOverview), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTechniques), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSettings), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSkillLibrary), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupJourney), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupGrowth), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupArchive), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupSettings), findsOneWidget);

    // 顺序(视觉批次水墨版式):江湖行程 / 养成经营 / 档案藏卷 / 设置。
    // 900 宽触发窄屏两列堆叠,便于断言分区纵向顺序。
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();

    double y(String label) => tester.getCenter(find.text(label)).dy;

    // 分区顺序。
    expect(
      y(UiStrings.mainMenuGroupJourney) < y(UiStrings.mainMenuGroupGrowth),
      isTrue,
    );
    expect(
      y(UiStrings.mainMenuGroupGrowth) < y(UiStrings.mainMenuGroupArchive),
      isTrue,
    );
    expect(
      y(UiStrings.mainMenuGroupArchive) < y(UiStrings.mainMenuGroupSettings),
      isTrue,
    );

    // 江湖行程:主线 / 爬塔同排,再进入晚期试炼。
    expect(
      (y(UiStrings.mainMenuMainline) - y(UiStrings.mainMenuTower)).abs() < 2.0,
      isTrue,
    );
    expect(y(UiStrings.mainMenuTower) < y(UiStrings.mainMenuLightFoot), isTrue);

    // 养成经营:角色/装备在前,心法与闭关/桃花岛承接。
    expect(
      y(UiStrings.mainMenuCharacterPanel) < y(UiStrings.mainMenuTechniques),
      isTrue,
    );
    expect(
      y(UiStrings.mainMenuSeclusion) < y(UiStrings.mainMenuTaohuaIsland),
      isTrue,
    );

    // 档案藏卷:谱牒/榜单先于藏卷/百科。
    expect(
      y(UiStrings.mainMenuLineage) < y(UiStrings.mainMenuZangjuange),
      isTrue,
    );
    expect(
      (y(UiStrings.mainMenuZangjuange) - y(UiStrings.mainMenuBaike)).abs() <
          2.0,
      isTrue,
    );
  });

  testWidgets('23 个菜单按钮均为 InkWell（可点）', (tester) async {
    await tester.pumpWidget(app());
    // 23 个菜单入口(WuxiaInkButton·含 debug 数值红线审计)+ 右上角退出键(IconButton)= 24 个 InkWell。
    expect(find.byType(WuxiaInkButton), findsNWidgets(23));
    expect(find.byType(InkWell), findsNWidgets(24));
  });

  testWidgets('入口按钮显示语义图标牌', (tester) async {
    await tester.pumpWidget(app());

    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
    expect(find.byIcon(Icons.filter_hdr_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
    expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);
    // 百科 + 藏经阁共 2 个 menu_book_outlined 图标
    expect(find.byIcon(Icons.menu_book_outlined), findsNWidgets(2));
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('常规桌面视口 smoke：${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text(UiStrings.mainMenuGroupJourney), findsOneWidget);
      expect(find.text(UiStrings.mainMenuGroupGrowth), findsOneWidget);
      expect(find.text(UiStrings.mainMenuGroupArchive), findsOneWidget);
      expect(find.text(UiStrings.mainMenuGroupSettings), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('入口状态 chip：主线 / 爬塔 / 装备 / 心法 / 闭关', (tester) async {
    final now = DateTime(2026, 6, 7);
    final mainTechnique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: 1,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: now,
    )..id = 7;
    final founder = Character.create(
      name: '祖师',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.tianCai,
      lineageRole: LineageRole.founder,
      createdAt: now,
      insightPoints: 12,
      mainTechniqueId: mainTechnique.id,
    )..id = 1;
    final equipments = [
      Equipment.create(
        defId: 'weapon_xunchang_tie_jian',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        obtainedAt: now,
        obtainedFrom: 'test',
      ),
      Equipment.create(
        defId: 'weapon_baowu_zhen_yue_jian',
        tier: EquipmentTier.baoWu,
        slot: EquipmentSlot.weapon,
        obtainedAt: now,
        obtainedFrom: 'test',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async => MainlineProgress()
              ..saveDataId = 1
              ..currentChapterIndex = 1
              ..clearedStageIds = ['stage_01_01']
              ..clearedAt = [now],
          ),
          towerProgressProvider.overrideWith(
            (ref) async => TowerProgress()
              ..saveDataId = 1
              ..highestClearedFloor = 9
              ..createdAt = now,
          ),
          allEquipmentsProvider.overrideWith((ref) async => equipments),
          currentTutorialStepProvider.overrideWith((ref) async => 5),
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => founder),
          techniqueByIdProvider(
            mainTechnique.id,
          ).overrideWith((ref) async => mainTechnique),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text(UiStrings.mainMenuMainlineStatus(1, '荒山野店')),
      findsOneWidget,
    );
    expect(find.textContaining('目标：打第1章第2关「荒山野店」'), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTowerBossStatus(9, 10)), findsOneWidget);
    expect(
      find.text(UiStrings.mainMenuInventoryStatus(2, '宝物')),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.mainMenuTechniquesInsightStatus(12)),
      findsOneWidget,
    );
    expect(find.text(UiStrings.mainMenuSeclusionReadyStatus), findsOneWidget);
  });

  testWidgets(
    'tap Phase 1 战斗测试 → 进入 BattleTestMenu（找到 testMenuTitle / scenarioA）',
    (tester) async {
      await tester.pumpWidget(app());
      // P2.2 Batch 2.5.B 加心魔境按钮后 Phase 1 下移,800x600 viewport 临界
      // 需 ensureVisible scroll 进可见区再 tap(沿 Phase 2 测同体例)
      await tester.ensureVisible(find.text(UiStrings.mainMenuPhase1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UiStrings.mainMenuPhase1));
      await tester.pumpAndSettle();

      expect(find.text(UiStrings.testMenuTitle), findsOneWidget);
      expect(find.text(UiStrings.scenarioA), findsOneWidget);
    },
  );

  testWidgets('tap Phase 2 调试场景 → 进入 Phase2TestMenu（找到 scenarioP1 等 4 场景）', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    // P0.2 #40 加排行榜按钮后 Phase 2 下移到第 6 位,默认 800x600 viewport 临界
    // 需 ensureVisible scroll 进可见区再 tap(SingleChildScrollView 体例)
    await tester.ensureVisible(find.text(UiStrings.mainMenuPhase2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.mainMenuPhase2));
    await tester.pumpAndSettle();

    // Phase2TestMenu AppBar title 与 MainMenu 按钮 label 同字符串，
    // 用 4 场景按钮 label 区分（这些只在 Phase2TestMenu 出现）。
    expect(find.text(UiStrings.scenarioP1), findsOneWidget);
    expect(find.text(UiStrings.scenarioP2), findsOneWidget);
    expect(find.text(UiStrings.scenarioP3), findsOneWidget);
    expect(find.text(UiStrings.scenarioP4), findsOneWidget);
  });

  // ── W17 长期挂账 #31 销账探路:NavigatorObserver mock 套路 ──────────────
  //
  // W6 drift 5 轮探路无解的「main_menu 问鼎九霄 widget test pumpAndSettle 死循环」
  // 根因:tap 后 push TowerFloorListScreen,其内部 watch towerProgressProvider +
  // Isar 异步 future + CircularProgressIndicator 无限动画,pumpAndSettle 永不
  // 完成。Phase 5 #2 销账 #28 用 Consumer 化 + provider override 套路绕过同类
  // 边界,本批用更轻量套路:**不 settle 子屏 build,只验 Navigator.push 触发**。
  //
  // 用法:NavigatorObserver 子类记录 didPush,tap 后单帧 pump(不 pumpAndSettle),
  // 验证 push 增量(initial 1 次 + tap 后 1 次 = 2 次)。子屏内部 build 即使抛错
  // 或仍在 loading 也不阻塞 test(单帧 pump 不进死循环)。

  testWidgets('tap 问鼎九霄 → Navigator.push 触发(不 settle 子屏,#31 销账)', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const MainMenu(),
        ),
      ),
    );
    // 验证 initial push(MainMenu 自身)已记录
    expect(observer.pushedRoutes.length, 1);

    // Phase A 重排后爬塔下移到「演武」组,默认 viewport 装不下 → 扩高再 tap。
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();
    await tester.tap(find.text(UiStrings.mainMenuTower));
    await tester.pump(); // 单帧,不 settle:子屏 TowerFloorListScreen 内部
    // towerProgressProvider AsyncValue.loading 不阻塞断言

    // tap 后应有 1 次新 push(TowerFloorListScreen)
    expect(observer.pushedRoutes.length, 2);
    // 验证最新 push 是 MaterialPageRoute(_push 包装)
    expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
  });

  // ── T56 销账 #26：闭关入口 FutureBuilder 化 ────────────────────────────

  testWidgets('闭关按钮：activeCharacterIds 加载完成 → Opacity=1.0 enabled', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 13);
    final founder = Character.create(
      name: '祖师',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.tianCai,
      lineageRole: LineageRole.founder,
      createdAt: now,
    )..id = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => founder),
          // P1 #42 Phase 2 §10 P1.x:闭关 enabled 需 step ≥ 5
          currentTutorialStepProvider.overrideWith((ref) async => 5),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 闭关按钮可见
    expect(find.text(UiStrings.mainMenuSeclusion), findsOneWidget);

    // 找到闭关 label 文本所在子树中的 Opacity widget
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text(UiStrings.mainMenuSeclusion),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 1.0);
  });

  testWidgets('闭关按钮：activeCharacterIds 仍 loading → Opacity=0.4 disabled', (
    tester,
  ) async {
    final never = Completer<List<int>>();
    final neverCh = Completer<Character?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) => never.future),
          characterByIdProvider(1).overrideWith((ref) => neverCh.future),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.mainMenuSeclusion), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text(UiStrings.mainMenuSeclusion),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.4);
  });

  // ── W16 GDD §12.4 节日活动 · 今日节日 chip ──────────────────────────

  testWidgets('节日 chip：todayFestival=null（非节日）→ 不显示「今日：」前缀', (tester) async {
    // hermetic:显式 override todayFestivalProvider=null,直证「null→不渲染 chip」
    // 契约,与墙钟日期无关(否则真实日期撞节气/节日时此断言会按日期 flake)。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayFestivalProvider.overrideWith((ref) => null)],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    expect(find.textContaining('今日：'), findsNothing);
  });

  testWidgets('节日 chip：todayFestival=chunJie → 显示「今日：春节」', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFestivalProvider.overrideWith((ref) => Festival.chunJie),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    expect(
      find.text(
        UiStrings.mainMenuTodayFestival(EnumL10n.festival(Festival.chunJie)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('节日 chip：todayFestival=zhongQiu → 显示「今日：中秋」', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFestivalProvider.overrideWith((ref) => Festival.zhongQiu),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    expect(find.text('今日：中秋'), findsOneWidget);
  });

  // ── W16 DEBUG · debugFestivalOverride 路径 widget test ──────────────────
  //
  // 上面 3 个测试走 `todayFestivalProvider.overrideWith`（widget test 直接
  // 注入）。下面 6 个测试走 `debugFestivalOverrideProvider.notifier.apply / clear`
  // 真实生产路径，覆盖 4 个上面未测节日（元宵/端午/七夕/重阳）+ clear 路径 +
  // 二次 apply 覆盖路径。
  //
  // 测路径：NotifierProvider state 变 → todayFestival 读 override 优先 →
  // _TodayFestivalChip rebuild 显应景中文。

  Future<ProviderContainer> pumpAndContainer(WidgetTester tester) async {
    // hermetic:真实日期基线 override 为 null(festivalService=null),使 clear()
    // 后 todayFestival 确定回落 null,不被墙钟日期撞节日影响;debug override
    // 优先级仍在,apply 路径照样被真实测到。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [festivalServiceProvider.overrideWith((ref) => null)],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    return ProviderScope.containerOf(tester.element(find.byType(MainMenu)));
  }

  testWidgets('debug override · apply yuanXiao → chip 显示「今日：元宵」', (
    tester,
  ) async {
    final container = await pumpAndContainer(tester);
    container
        .read(debugFestivalOverrideProvider.notifier)
        .apply(Festival.yuanXiao);
    await tester.pump();
    expect(find.text('今日：元宵'), findsOneWidget);
  });

  testWidgets('debug override · apply duanWu → chip 显示「今日：端午」', (tester) async {
    final container = await pumpAndContainer(tester);
    container
        .read(debugFestivalOverrideProvider.notifier)
        .apply(Festival.duanWu);
    await tester.pump();
    expect(find.text('今日：端午'), findsOneWidget);
  });

  testWidgets('debug override · apply qiXi → chip 显示「今日：七夕」', (tester) async {
    final container = await pumpAndContainer(tester);
    container.read(debugFestivalOverrideProvider.notifier).apply(Festival.qiXi);
    await tester.pump();
    expect(find.text('今日：七夕'), findsOneWidget);
  });

  testWidgets('debug override · apply chongYang → chip 显示「今日：重阳」', (
    tester,
  ) async {
    final container = await pumpAndContainer(tester);
    container
        .read(debugFestivalOverrideProvider.notifier)
        .apply(Festival.chongYang);
    await tester.pump();
    expect(find.text('今日：重阳'), findsOneWidget);
  });

  testWidgets('debug override · apply chunJie 后 clear → chip 不显示', (
    tester,
  ) async {
    final container = await pumpAndContainer(tester);
    final notifier = container.read(debugFestivalOverrideProvider.notifier);
    notifier.apply(Festival.chunJie);
    await tester.pump();
    expect(find.text('今日：春节'), findsOneWidget);
    notifier.clear();
    await tester.pump();
    expect(find.textContaining('今日：'), findsNothing);
  });

  testWidgets('debug override · apply chunJie 后 apply yuanXiao → 覆盖切到「今日：元宵」', (
    tester,
  ) async {
    final container = await pumpAndContainer(tester);
    final notifier = container.read(debugFestivalOverrideProvider.notifier);
    notifier.apply(Festival.chunJie);
    await tester.pump();
    expect(find.text('今日：春节'), findsOneWidget);
    notifier.apply(Festival.yuanXiao);
    await tester.pump();
    expect(find.text('今日：元宵'), findsOneWidget);
    expect(find.text('今日：春节'), findsNothing);
  });

  // ── P1 #42 Phase 2 §10 P1.x · tutorialStep 灰显门槛 ──────────────────────

  group('§10 P1.x · tutorialStep 灰显门槛', () {
    Character founder(DateTime now) => Character.create(
      name: '祖师',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.tianCai,
      lineageRole: LineageRole.founder,
      createdAt: now,
    )..id = 1;

    Widget appWithStep(int step) {
      final ch = founder(DateTime(2026, 5, 18));
      return ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => step),
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => ch),
        ],
        child: const MaterialApp(home: MainMenu()),
      );
    }

    testWidgets('step=0 → 心法 + 闭关 显锁定文案(灰显)', (tester) async {
      await tester.pumpWidget(appWithStep(0));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTechniquesLockedHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuSeclusionLockedHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuTechniquesHint), findsNothing);
      expect(find.text(UiStrings.mainMenuSeclusionHint), findsNothing);
    });

    testWidgets('step=2 → 心法 + 闭关 仍灰显(均未到门槛)', (tester) async {
      await tester.pumpWidget(appWithStep(2));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTechniquesLockedHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuSeclusionLockedHint), findsOneWidget);
    });

    testWidgets('step=3 → 心法解锁(普通 hint),闭关仍灰', (tester) async {
      await tester.pumpWidget(appWithStep(3));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTechniquesHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuTechniquesLockedHint), findsNothing);
      expect(find.text(UiStrings.mainMenuSeclusionLockedHint), findsOneWidget);
    });

    testWidgets('step=5 → 心法 + 闭关 全解锁(普通 hint)', (tester) async {
      await tester.pumpWidget(appWithStep(5));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTechniquesHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuSeclusionHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuTechniquesLockedHint), findsNothing);
      expect(find.text(UiStrings.mainMenuSeclusionLockedHint), findsNothing);
    });

    testWidgets('step=8(未来值)→ 全解锁(向上兼容)', (tester) async {
      await tester.pumpWidget(appWithStep(8));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTechniquesHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuSeclusionHint), findsOneWidget);
    });

    testWidgets('闭关 step=5 + character 仍 loading → 仍 disabled(loading 优先级保留)', (
      tester,
    ) async {
      final neverIds = Completer<List<int>>();
      final neverCh = Completer<Character?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTutorialStepProvider.overrideWith((ref) async => 5),
            activeCharacterIdsProvider.overrideWith((ref) => neverIds.future),
            characterByIdProvider(1).overrideWith((ref) => neverCh.future),
          ],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();

      // 闭关 step=5 已过门槛,但 character loading → 仍 Opacity 0.4 disabled
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text(UiStrings.mainMenuSeclusion),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.4);
    });
  });

  // ── P1 #42 Phase 2 §10 P1.y · TutorialBannerCard 顶部 banner 渲染 ──────

  group('§10 P1.y · banner 顶部渲染', () {
    Character founder(DateTime now) => Character.create(
      name: '祖师',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.tianCai,
      lineageRole: LineageRole.founder,
      createdAt: now,
    )..id = 1;

    Widget appWith({required int step, required List<int> hintsRead}) {
      final ch = founder(DateTime(2026, 5, 18));
      return ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => step),
          currentTutorialHintsReadProvider.overrideWith(
            (ref) async => hintsRead,
          ),
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => ch),
        ],
        child: const MaterialApp(home: MainMenu()),
      );
    }

    testWidgets('step=0 → 不显 banner', (tester) async {
      await tester.pumpWidget(appWith(step: 0, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });

    testWidgets('step=2 → 不显 banner(§5.7 step 1/2/4 无系统解锁锚点)', (tester) async {
      await tester.pumpWidget(appWith(step: 2, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });

    testWidgets('step=3 + hintsRead=[] → 显 step 3 banner(心法解锁锚点)', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(step: 3, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep3Title), findsOneWidget);
    });

    testWidgets('step=3 + hintsRead=[3] → 不显 banner(已读)', (tester) async {
      await tester.pumpWidget(appWith(step: 3, hintsRead: [3]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });

    testWidgets('step=5 + hintsRead=[3] → 显 step 5 banner(Ch1 通关锚点)', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(step: 5, hintsRead: [3]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep5Title), findsOneWidget);
    });

    testWidgets('step=8 + hintsRead=[] → 显 step 3 banner(取最低未读 step)', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(
        find.text(UiStrings.tutorialHintStep3Title),
        findsOneWidget,
        reason: 'R3 风险处置:同时多 unread 取最低 step',
      );
      expect(find.text(UiStrings.tutorialHintStep6Title), findsNothing);
    });

    testWidgets('step=6 + hintsRead=[3,5] → 显 step 6 banner', (tester) async {
      await tester.pumpWidget(appWith(step: 6, hintsRead: [3, 5]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep6Title), findsOneWidget);
    });

    testWidgets('step=8 + hintsRead=[3,5,6,7] → 显 step 8 banner', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: [3, 5, 6, 7]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep8Title), findsOneWidget);
    });

    testWidgets('step=8 + hintsRead=[3,5,6,7,8] → 不显 banner(全已读)', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: [3, 5, 6, 7, 8]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });
  });

  // H1 批1 §5.7:未解锁系统按钮门控(镜像各屏 clearedStageIds prereq)。
  group('§5.7 未解锁系统门控', () {
    double opacityOf(WidgetTester tester, String label) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    Widget appWithCleared(List<String> cleared) => ProviderScope(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
      ],
      child: const MaterialApp(home: MainMenu()),
    );

    testWidgets('全新存档(clearedStageIds 空)→ 心魔/门派 disabled 且无 PVP 入口', (
      tester,
    ) async {
      await tester.pumpWidget(appWithCleared([]));
      await tester.pump();
      await tester.pump();
      // 后期系统(Ch6 prereq)、社交(Ch1)在空进度全灰显;PVP 已切除不再显示。
      expect(opacityOf(tester, UiStrings.mainMenuInnerDemon), 0.4);
      expect(opacityOf(tester, UiStrings.mainMenuSect), 0.4);
      expect(opacityOf(tester, UiStrings.mainMenuZangjuange), 0.4);
      expect(find.text('论剑对决'), findsNothing);
    });

    testWidgets('通关 Ch1 末关(stage_01_05)→ 社交系统解锁、后期仍锁', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_01_05']));
      await tester.pump();
      await tester.pump();
      // 社交(江湖/门派/排行榜/藏卷阁)Ch1 prereq 满足 → enabled。
      expect(opacityOf(tester, UiStrings.mainMenuSect), 1.0);
      expect(opacityOf(tester, UiStrings.mainMenuJianghu), 1.0);
      expect(opacityOf(tester, UiStrings.mainMenuZangjuange), 1.0);
      // 心魔仍需 Ch6 末关 → 仍 disabled。
      expect(opacityOf(tester, UiStrings.mainMenuInnerDemon), 0.4);
    });

    testWidgets('通关 Ch6 末关(stage_06_05)→ 后期系统解锁', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_06_05']));
      await tester.pump();
      await tester.pump();
      expect(opacityOf(tester, UiStrings.mainMenuInnerDemon), 1.0);
      expect(opacityOf(tester, UiStrings.mainMenuLightFoot), 1.0);
      expect(opacityOf(tester, UiStrings.mainMenuMassBattle), 1.0);
    });
  });

  // ── P4 Task10 §5.7 战绩册入口门控（首胜后解锁） ──────────────────────────
  //
  // §5.7：首次击败任一 Boss 前隐藏入口；bossMemoryCount>0 才显「战绩册」按钮。
  // 隐藏式 gating（与灰显不同，按钮整体不渲染）。

  group('§5.7 战绩册入口门控', () {
    testWidgets('0 纪念 → 无战绩册入口（隐藏）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bossMemoryCountProvider.overrideWith((ref) async => 0)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuBattleRecord), findsNothing);
    });

    testWidgets('≥1 纪念 → 有战绩册入口', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bossMemoryCountProvider.overrideWith((ref) async => 1)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuBattleRecord), findsOneWidget);
    });

    testWidgets('≥1 纪念 → tap 战绩册 → Navigator.push 触发', (tester) async {
      final observer = _RecordingNavigatorObserver();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bossMemoryCountProvider.overrideWith((ref) async => 3)],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const MainMenu(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      // 扩 viewport 防 off-screen
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pump();

      await tester.tap(find.text(UiStrings.mainMenuBattleRecord));
      await tester.pump(); // 单帧，不 settle（子屏依赖 Isar）

      expect(observer.pushedRoutes.length, 2);
      expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
    });
  });

  // ── P1b Task10 §5.7 藏经阁门控 ──────────────────────────────────────────
  //
  // §5.7：修了心法才能装备技能 → 复用 _techniquesUnlockStep(=3) 门控：
  //   step < 3 → skillLibLocked=true → disabled/locked → Opacity=0.4 + LockedHint
  //   step ≥ 3 → skillLibLocked=false → enabled → Opacity=1.0 + 普通 Hint

  group('§5.7 藏经阁入口门控', () {
    Widget appWithStep(int step) => ProviderScope(
      overrides: [
        currentTutorialStepProvider.overrideWith((ref) async => step),
      ],
      child: const MaterialApp(home: MainMenu()),
    );

    double opacityOf(WidgetTester tester, String label) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    testWidgets('step=0 → 藏经阁 disabled(Opacity=0.4) + LockedHint', (
      tester,
    ) async {
      await tester.pumpWidget(appWithStep(0));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuSkillLibrary), findsOneWidget);
      expect(opacityOf(tester, UiStrings.mainMenuSkillLibrary), 0.4);
      expect(
        find.text(UiStrings.mainMenuSkillLibraryLockedHint),
        findsOneWidget,
      );
      expect(find.text(UiStrings.mainMenuSkillLibraryHint), findsNothing);
    });

    testWidgets('step=2 → 藏经阁仍灰显(未到门槛)', (tester) async {
      await tester.pumpWidget(appWithStep(2));
      await tester.pump();
      await tester.pump();

      expect(opacityOf(tester, UiStrings.mainMenuSkillLibrary), 0.4);
      expect(
        find.text(UiStrings.mainMenuSkillLibraryLockedHint),
        findsOneWidget,
      );
    });

    testWidgets('step=3 → 藏经阁解锁(Opacity=1.0) + 普通 Hint', (tester) async {
      await tester.pumpWidget(appWithStep(3));
      await tester.pump();
      await tester.pump();

      expect(opacityOf(tester, UiStrings.mainMenuSkillLibrary), 1.0);
      expect(find.text(UiStrings.mainMenuSkillLibraryHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuSkillLibraryLockedHint), findsNothing);
    });

    testWidgets('step=5 → 藏经阁仍解锁(向上兼容)', (tester) async {
      await tester.pumpWidget(appWithStep(5));
      await tester.pump();
      await tester.pump();

      expect(opacityOf(tester, UiStrings.mainMenuSkillLibrary), 1.0);
      expect(find.text(UiStrings.mainMenuSkillLibraryHint), findsOneWidget);
    });
  });

  // ── 材料经济 P1 Task 9 · 江湖商店入口门控（§5.7 隐藏式） ──────────────────

  group('§5.7 江湖商店入口门控', () {
    testWidgets('shopUnlocked=false → 无江湖商店入口（隐藏）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shopUnlockedProvider.overrideWith((ref) async => false)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuShop), findsNothing);
    });

    testWidgets('shopUnlocked=true → 有江湖商店入口', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shopUnlockedProvider.overrideWith((ref) async => true)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuShop), findsOneWidget);
    });

    testWidgets('shopUnlocked=true → tap 江湖商店 → Navigator.push 触发', (
      tester,
    ) async {
      final observer = _RecordingNavigatorObserver();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shopUnlockedProvider.overrideWith((ref) async => true)],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const MainMenu(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pump();

      await tester.tap(find.text(UiStrings.mainMenuShop));
      await tester.pump(); // 单帧，不 settle

      expect(observer.pushedRoutes.length, 2);
      expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
    });
  });

  // ── 桃花岛 P1 Task13 · 第二章通关门控（§5.7 灰显式）────────────────────────
  //
  // unlock_chapter_index=1(0-based) → chapterIndex=2(1-based stages.yaml)通关解锁。
  // 用 mainlineProgressProvider override 注入 clearedStageIds 模拟两态：
  //   ① 空进度 → taohuaLocked=true → Opacity=0.4 + LockedHint
  //   ② 第二章所有关卡(stage_02_01~stage_02_05)通关 → taohuaLocked=false → Opacity=1.0 + Hint

  group('§5.7 桃花岛入口门控', () {
    double opacityOf(WidgetTester tester, String label) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    Widget appWithCleared(List<String> cleared) => ProviderScope(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
      ],
      child: const MaterialApp(home: MainMenu()),
    );

    testWidgets('空进度 → 桃花岛 disabled(Opacity=0.4) + LockedHint', (tester) async {
      await tester.pumpWidget(appWithCleared([]));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTaohuaIsland), findsOneWidget);
      expect(opacityOf(tester, UiStrings.mainMenuTaohuaIsland), 0.4);
      expect(
        find.text(UiStrings.mainMenuTaohuaIslandLockedHint),
        findsOneWidget,
      );
      expect(find.text(UiStrings.mainMenuTaohuaIslandHint), findsNothing);
    });

    testWidgets('仅通关第一章末关 → 桃花岛仍灰显', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_01_05']));
      await tester.pump();
      await tester.pump();

      expect(opacityOf(tester, UiStrings.mainMenuTaohuaIsland), 0.4);
      expect(
        find.text(UiStrings.mainMenuTaohuaIslandLockedHint),
        findsOneWidget,
      );
    });

    testWidgets('通关第二章所有关(stage_02_01~05) → 桃花岛解锁(Opacity=1.0) + Hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        appWithCleared([
          'stage_02_01',
          'stage_02_02',
          'stage_02_03',
          'stage_02_04',
          'stage_02_05',
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(opacityOf(tester, UiStrings.mainMenuTaohuaIsland), 1.0);
      expect(find.text(UiStrings.mainMenuTaohuaIslandHint), findsOneWidget);
      expect(find.text(UiStrings.mainMenuTaohuaIslandLockedHint), findsNothing);
    });

    testWidgets('解锁态 → tap 桃花岛 → Navigator.push 触发', (tester) async {
      final observer = _RecordingNavigatorObserver();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainlineProgressProvider.overrideWith(
              (ref) async => MainlineProgress()
                ..clearedStageIds = [
                  'stage_02_01',
                  'stage_02_02',
                  'stage_02_03',
                  'stage_02_04',
                  'stage_02_05',
                ],
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const MainMenu(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pump();

      expect(observer.pushedRoutes.length, 1);
      await tester.tap(find.text(UiStrings.mainMenuTaohuaIsland));
      await tester.pump(); // 单帧，不 settle（子屏依赖 Isar）

      expect(observer.pushedRoutes.length, 2);
      expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
    });
  });
}

/// 记录 Navigator.push 调用的 observer(W17 #31 销账):
/// 测试 tap 按钮触发 push 时使用,代替对子屏的真实 build/settle。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
