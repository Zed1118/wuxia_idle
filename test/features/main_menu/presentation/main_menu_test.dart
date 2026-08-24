import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/image_test_helpers.dart';
import '../../../support/test_data.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/game_loop/monthly_tick.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_providers.dart';
import 'package:wuxia_idle/features/festival/application/festival_service_providers.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/jianghu_chronicle_hub_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_hub_screen.dart';
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
///   - 菜单按钮 label 匹配（继续江湖 / 宗门 / 武学与行囊 / 档案等）
///   - 7 个默认玩法入口 WuxiaInkButton（条件入口未解锁时）
///   - Tap "Phase 2 调试场景" → push Phase2TestMenu
///
/// 主线 / 问鼎九霄 / 角色 / 师徒名单 / 装备 / 心法 按钮 push 的页面依赖 Isar（师徒名单经
/// `lineageInfoProvider` 派生 Isar，未注入 fixture 时无法 settle），widget test 旁路
/// （与 T28/T31 同决策，沿用挂账 #23）；按钮可点性通过 WuxiaInkButton 计数 + label
/// 渲染断言覆盖。
void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  Widget app() => const ProviderScope(child: MaterialApp(home: MainMenu()));

  Finder assetImage(String path) =>
      find.byWidgetPredicate((w) => w is Image && assetNameOf(w.image) == path);

  Future<SectHubScreen> openSectHub(WidgetTester tester) async {
    final entry = find.text(UiStrings.mainMenuSectHub);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(SectHubScreen), findsOneWidget);
    return tester.widget<SectHubScreen>(find.byType(SectHubScreen));
  }

  Future<JianghuChronicleHubScreen> openChronicleHub(
    WidgetTester tester,
  ) async {
    final entry = find.text(UiStrings.mainMenuJianghuChronicle);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(JianghuChronicleHubScreen), findsOneWidget);
    return tester.widget<JianghuChronicleHubScreen>(
      find.byType(JianghuChronicleHubScreen),
    );
  }

  testWidgets('标题渲染：mainMenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
  });

  testWidgets('主菜单渲染 MJ 门面背景', (tester) async {
    await tester.pumpWidget(app());
    expect(assetImage(WuxiaUi.mainMenuBg), findsOneWidget);
  });

  testWidgets('主菜单挂载一次性启动钩子门', (tester) async {
    await tester.pumpWidget(app());
    expect(
      find.byKey(const ValueKey('main-menu-startup-gate')),
      findsOneWidget,
    );
  });

  testWidgets('主菜单首帧触发一次月度 tick，普通 rebuild 不重复', (tester) async {
    var tickCount = 0;
    final coordinator = MonthlyTickCoordinator()
      ..register((_) async => tickCount++);

    Widget appWithTick() => ProviderScope(
      overrides: [
        monthlyTickCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: const MaterialApp(home: MainMenu()),
    );

    await tester.pumpWidget(appWithTick());
    await tester.pump();
    expect(tickCount, 1);

    await tester.pumpWidget(appWithTick());
    await tester.pump();
    expect(tickCount, 1);
  });

  testWidgets('7 个默认玩法按钮 label 全部可见且顺序正确', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text(UiStrings.mainMenuMainline), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsNothing);
    expect(find.text(UiStrings.mainMenuJianghuMapAction), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLightFoot), findsNothing);
    expect(find.text(UiStrings.mainMenuMassBattle), findsNothing);
    expect(find.text(UiStrings.mainMenuJianghu), findsNothing);
    expect(find.text(UiStrings.mainMenuSectHub), findsOneWidget);
    expect(find.text(UiStrings.mainMenuJianghuChronicle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase2), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSectRecruit), findsOneWidget);
    expect(find.text(UiStrings.mainMenuRedlineAudit), findsOneWidget);
    expect(find.text(UiStrings.mainMenuMartialInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupJourney), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupGrowth), findsOneWidget);
    expect(find.text(UiStrings.mainMenuGroupArchive), findsOneWidget);

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

    // 江湖行程:继续江湖在前，塔/轻功/群战均已迁地图。
    expect(
      y(UiStrings.mainMenuGroupJourney) < y(UiStrings.mainMenuMainline),
      isTrue,
    );

    // 养成经营:只保留宗门/武学与行囊两个一级入口。
    expect(
      (y(UiStrings.mainMenuSectHub) - y(UiStrings.mainMenuMartialInventory))
              .abs() <
          2.0,
      isTrue,
    );
    // 档案藏卷收拢为单一江湖纪事入口。
    expect(
      y(UiStrings.mainMenuGroupArchive) < y(UiStrings.mainMenuJianghuChronicle),
      isTrue,
    );
  });

  testWidgets('7 个默认玩法按钮均为 WuxiaInkButton（可点入口）', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(WuxiaInkButton), findsNWidgets(7));
  });

  testWidgets('入口按钮显示语义图标牌', (tester) async {
    await tester.pumpWidget(app());

    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    // 主菜单只保留「武学与行囊」使用 menu_book_outlined。
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
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
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('宽屏主内容列限制最大宽度，避免入口横向摊开', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await tester.pump();

    final contentSize = tester.getSize(
      find.byKey(const ValueKey('main-menu-content')),
    );
    expect(contentSize.width, lessThanOrEqualTo(1088));
  });

  testWidgets('入口状态 chip：主线 / 爬塔 / 武学与行囊库存', (tester) async {
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
              ..highestClearedFloor = 6
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
    expect(find.text(UiStrings.mainMenuJianghuMapAction), findsOneWidget);
    expect(
      find.text(UiStrings.mainMenuInventoryStatus(2, '宝物')),
      findsOneWidget,
    );
  });

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
  // 江湖地图为“继续江湖”卡内次级动作；这里只用 NavigatorObserver 证明它
  // 独立 push，不抢占继续江湖主动作，也不新增 WuxiaInkButton 一级卡。
  //
  // 用法:NavigatorObserver 子类记录 didPush,tap 后单帧 pump(不 pumpAndSettle),
  // 验证 push 增量(initial 1 次 + tap 后 1 次 = 2 次)。子屏内部 build 即使抛错
  // 或仍在 loading 也不阻塞 test(单帧 pump 不进死循环)。

  testWidgets('tap 次级江湖地图 → Navigator.push 触发且不增加一级卡', (tester) async {
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

    // 默认 viewport 需滚动才能看到次级动作，测试扩高后直接 tap。
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();
    await tester.tap(find.text(UiStrings.mainMenuJianghuMapAction));
    await tester.pump();

    // tap 后应有 1 次新 push(JianghuMapScreen)
    expect(observer.pushedRoutes.length, 2);
    // 验证最新 push 是 MaterialPageRoute(_push 包装)
    expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
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

  // ── P1 #42 Phase 2 §10 P1.x · tutorialStep 门控透传 ──────────────────────

  group('§10 P1.x · tutorialStep 门控透传到宗门 Hub', () {
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

    testWidgets('step=0 → Hub 收到闭关锁定', (tester) async {
      await tester.pumpWidget(appWithStep(0));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isTrue);
    });

    testWidgets('step=2 → Hub 仍收到闭关锁定', (tester) async {
      await tester.pumpWidget(appWithStep(2));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isTrue);
    });

    testWidgets('step=3 → Hub 仍收到闭关锁定', (tester) async {
      await tester.pumpWidget(appWithStep(3));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isTrue);
    });

    testWidgets('step=5 → Hub 收到闭关解锁', (tester) async {
      await tester.pumpWidget(appWithStep(5));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isFalse);
    });

    testWidgets('step=8(未来值)→ Hub 保持向上兼容解锁', (tester) async {
      await tester.pumpWidget(appWithStep(8));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isFalse);
    });

    testWidgets('step=5 + character loading → 门控仍解锁，Hub 自身负责身份 fail closed', (
      tester,
    ) async {
      final neverIds = Completer<List<int>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTutorialStepProvider.overrideWith((ref) async => 5),
            activeCharacterIdsProvider.overrideWith((ref) => neverIds.future),
          ],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      expect((await openSectHub(tester)).seclusionLocked, isFalse);

      neverIds.complete(const []);
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

    testWidgets('全新存档 → 心魔不在主菜单，社交锁定且纪事不继承社交门', (tester) async {
      await tester.pumpWidget(appWithCleared([]));
      await tester.pump();
      await tester.pump();
      expect(find.text(UiStrings.mainMenuInnerDemon), findsNothing);
      expect(opacityOf(tester, UiStrings.mainMenuJianghuChronicle), 1.0);
      expect(find.text('论剑对决'), findsNothing);
      expect((await openSectHub(tester)).sectLocked, isTrue);
    });

    testWidgets('通关 Ch1 末关 → 社交解锁且 Hub 收到门派事务解锁', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_01_05']));
      await tester.pump();
      await tester.pump();
      // 社交声望已迁地图；纪事入口始终可进。
      expect(find.text(UiStrings.mainMenuJianghu), findsNothing);
      expect(opacityOf(tester, UiStrings.mainMenuJianghuChronicle), 1.0);
      expect(find.text(UiStrings.mainMenuInnerDemon), findsNothing);
      expect((await openSectHub(tester)).sectLocked, isFalse);
    });

    testWidgets('通关 Ch6 末关 → 心魔/轻功/群战均不在主菜单', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_06_05']));
      await tester.pump();
      await tester.pump();
      expect(find.text(UiStrings.mainMenuInnerDemon), findsNothing);
      expect(find.text(UiStrings.mainMenuLightFoot), findsNothing);
      expect(find.text(UiStrings.mainMenuMassBattle), findsNothing);
    });
  });

  // ── P4 Task10 §5.7 战绩册入口门控（首胜后解锁） ──────────────────────────
  //
  // §5.7：主菜单始终只有「江湖纪事」；首次击败任一 Boss 后，Hub 内才显敌手。

  group('§5.7 战绩册入口门控', () {
    testWidgets('0 纪念 → 主菜单不平铺战绩册且 Hub 收到关闭门', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bossMemoryCountProvider.overrideWith((ref) async => 0)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuBattleRecord), findsNothing);
      expect((await openChronicleHub(tester)).battleRecordUnlocked, isFalse);
    });

    testWidgets('≥1 纪念 → 主菜单仍不平铺且 Hub 收到开放门', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bossMemoryCountProvider.overrideWith((ref) async => 1)],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuBattleRecord), findsNothing);
      expect((await openChronicleHub(tester)).battleRecordUnlocked, isTrue);
    });

    testWidgets('≥1 纪念 → tap 江湖纪事 → Navigator.push 触发', (tester) async {
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

      await tester.tap(find.text(UiStrings.mainMenuJianghuChronicle));
      await tester.pump();

      expect(observer.pushedRoutes.length, 2);
      expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
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

  // ── 桃花生产 · 第二章通关门控透传到宗门 Hub ──────────────────────────────
  //
  // unlock_chapter_index=1(0-based) → chapterIndex=2(1-based stages.yaml)通关解锁。
  // 用 mainlineProgressProvider override 注入 clearedStageIds 模拟两态：
  //   ① 空进度 → taohuaLocked=true
  //   ② 第二章所有关卡(stage_02_01~stage_02_05)通关 → taohuaLocked=false

  group('§5.7 桃花生产门控透传', () {
    Widget appWithCleared(List<String> cleared) => ProviderScope(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
      ],
      child: const MaterialApp(home: MainMenu()),
    );

    testWidgets('空进度 → Hub 收到桃花生产锁定', (tester) async {
      await tester.pumpWidget(appWithCleared([]));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).taohuaLocked, isTrue);
    });

    testWidgets('仅通关第一章末关 → Hub 仍收到桃花生产锁定', (tester) async {
      await tester.pumpWidget(appWithCleared(['stage_01_05']));
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).taohuaLocked, isTrue);
    });

    testWidgets('通关第二章所有关(stage_02_01~05) → Hub 收到桃花生产解锁', (tester) async {
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
      expect((await openSectHub(tester)).taohuaLocked, isFalse);
    });
  });

  // ── 江湖远行门控透传到宗门 Hub（Phase B2.4 · §7.1 Lv100）───────────────
  group('§5.7 江湖远行门控透传', () {
    SaveData save({required bool unlocked}) {
      final now = DateTime(2026, 7, 16);
      return SaveData()
        ..id = 0
        ..saveVersion = '0.38.0'
        ..createdAt = now
        ..lastSavedAt = now
        ..lastOnlineAt = now
        ..jianghuJourneyUnlocked = unlocked;
    }

    testWidgets('jianghuJourneyUnlocked=false → Hub 收到远征隐藏门', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainMenuSaveSnapshotProvider.overrideWith(
              (ref) async => save(unlocked: false),
            ),
          ],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).expeditionUnlocked, isFalse);
    });

    testWidgets('jianghuJourneyUnlocked=true → Hub 收到远征开放门', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainMenuSaveSnapshotProvider.overrideWith(
              (ref) async => save(unlocked: true),
            ),
          ],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect((await openSectHub(tester)).expeditionUnlocked, isTrue);
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
