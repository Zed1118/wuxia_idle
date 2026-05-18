import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/features/festival/application/festival_service_providers.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/features/tutorial/presentation/tutorial_banner_card.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T32 子提交 3b：[MainMenu] widget 测试（T42 加「问鼎九霄」T49 加「闭关修炼」+ W17 候选 E 加「师徒名单」+ P0.2 #40 加「排行榜」后扩 10 个）。
///
/// 用例覆盖：
///   - 标题 mainMenuTitle 渲染
///   - 10 个菜单按钮 label + 顺序匹配（主线 / 问鼎九霄 / 排行榜 / 闭关修炼 / Phase1 / Phase2 / 角色 / 师徒名单 / 装备 / 心法）
///   - 共 10 个 InkWell（按钮全部可点）
///   - Tap "Phase 1 战斗测试" → push BattleTestMenu
///   - Tap "Phase 2 调试场景" → push Phase2TestMenu
///
/// 主线 / 问鼎九霄 / 角色 / 师徒名单 / 装备 / 心法 按钮 push 的页面依赖 Isar（师徒名单经
/// `lineageInfoProvider` 派生 Isar，未注入 fixture 时无法 settle），widget test 旁路
/// （与 T28/T31 同决策，沿用挂账 #23）；按钮可点性通过 InkWell 计数 + label
/// 渲染断言覆盖。
void main() {
  Widget app() => const ProviderScope(
        child: MaterialApp(home: MainMenu()),
      );

  testWidgets('标题渲染：mainMenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
  });

  testWidgets('11 个菜单按钮 label 全部可见且顺序正确', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text(UiStrings.mainMenuMainline), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLeaderboard), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSeclusion), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase1), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase2), findsOneWidget);
    expect(find.text(UiStrings.mainMenuCharacterPanel), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLineage), findsOneWidget);
    expect(find.text(UiStrings.mainMenuBaike), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTechniques), findsOneWidget);

    // 顺序：主线 / 问鼎九霄 / 排行榜 / 闭关修炼 / Phase1 / Phase2 / 角色 / 师徒名单 / 江湖见闻录 / 装备 / 心法
    final mainY = tester.getCenter(find.text(UiStrings.mainMenuMainline)).dy;
    final towY = tester.getCenter(find.text(UiStrings.mainMenuTower)).dy;
    final lbY = tester.getCenter(find.text(UiStrings.mainMenuLeaderboard)).dy;
    final secY = tester.getCenter(find.text(UiStrings.mainMenuSeclusion)).dy;
    final p1Y = tester.getCenter(find.text(UiStrings.mainMenuPhase1)).dy;
    final p2Y = tester.getCenter(find.text(UiStrings.mainMenuPhase2)).dy;
    final chY = tester.getCenter(find.text(UiStrings.mainMenuCharacterPanel)).dy;
    final linY = tester.getCenter(find.text(UiStrings.mainMenuLineage)).dy;
    final bkY = tester.getCenter(find.text(UiStrings.mainMenuBaike)).dy;
    final invY = tester.getCenter(find.text(UiStrings.mainMenuInventory)).dy;
    final tcY = tester.getCenter(find.text(UiStrings.mainMenuTechniques)).dy;
    expect(mainY < towY, isTrue);
    expect(towY < lbY, isTrue);
    expect(lbY < secY, isTrue);
    expect(secY < p1Y, isTrue);
    expect(p1Y < p2Y, isTrue);
    expect(p2Y < chY, isTrue);
    expect(chY < linY, isTrue);
    expect(linY < bkY, isTrue);
    expect(bkY < invY, isTrue);
    expect(invY < tcY, isTrue);
  });

  testWidgets('11 个菜单按钮均为 InkWell（可点）', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(InkWell), findsNWidgets(11));
  });

  testWidgets('tap Phase 1 战斗测试 → 进入 BattleTestMenu（找到 testMenuTitle / scenarioA）',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text(UiStrings.mainMenuPhase1));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.testMenuTitle), findsOneWidget);
    expect(find.text(UiStrings.scenarioA), findsOneWidget);
  });

  testWidgets('tap Phase 2 调试场景 → 进入 Phase2TestMenu（找到 scenarioP1 等 4 场景）',
      (tester) async {
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

  testWidgets('tap 问鼎九霄 → Navigator.push 触发(不 settle 子屏,#31 销账)',
      (tester) async {
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

    await tester.tap(find.text(UiStrings.mainMenuTower));
    await tester.pump(); // 单帧,不 settle:子屏 TowerFloorListScreen 内部
                        // towerProgressProvider AsyncValue.loading 不阻塞断言

    // tap 后应有 1 次新 push(TowerFloorListScreen)
    expect(observer.pushedRoutes.length, 2);
    // 验证最新 push 是 MaterialPageRoute(_push 包装)
    expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
  });

  // ── T56 销账 #26：闭关入口 FutureBuilder 化 ────────────────────────────

  testWidgets('闭关按钮：activeCharacterIds 加载完成 → Opacity=1.0 enabled',
      (tester) async {
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

  testWidgets('闭关按钮：activeCharacterIds 仍 loading → Opacity=0.4 disabled',
      (tester) async {
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

  testWidgets('节日 chip：todayFestival=null（非节日）→ 不显示「今日：」前缀',
      (tester) async {
    // 默认 ProviderScope 无 override → festivalServiceProvider 返 null（test
    // 不加载 GameRepository）→ todayFestivalProvider 返 null → chip 不渲染。
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MainMenu()),
      ),
    );
    expect(find.textContaining('今日：'), findsNothing);
  });

  testWidgets('节日 chip：todayFestival=chunJie → 显示「今日：春节」',
      (tester) async {
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

  testWidgets('节日 chip：todayFestival=zhongQiu → 显示「今日：中秋」',
      (tester) async {
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
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MainMenu()),
      ),
    );
    return ProviderScope.containerOf(
      tester.element(find.byType(MainMenu)),
    );
  }

  testWidgets('debug override · apply yuanXiao → chip 显示「今日：元宵」',
      (tester) async {
    final container = await pumpAndContainer(tester);
    container.read(debugFestivalOverrideProvider.notifier).apply(Festival.yuanXiao);
    await tester.pump();
    expect(find.text('今日：元宵'), findsOneWidget);
  });

  testWidgets('debug override · apply duanWu → chip 显示「今日：端午」',
      (tester) async {
    final container = await pumpAndContainer(tester);
    container.read(debugFestivalOverrideProvider.notifier).apply(Festival.duanWu);
    await tester.pump();
    expect(find.text('今日：端午'), findsOneWidget);
  });

  testWidgets('debug override · apply qiXi → chip 显示「今日：七夕」',
      (tester) async {
    final container = await pumpAndContainer(tester);
    container.read(debugFestivalOverrideProvider.notifier).apply(Festival.qiXi);
    await tester.pump();
    expect(find.text('今日：七夕'), findsOneWidget);
  });

  testWidgets('debug override · apply chongYang → chip 显示「今日：重阳」',
      (tester) async {
    final container = await pumpAndContainer(tester);
    container.read(debugFestivalOverrideProvider.notifier).apply(Festival.chongYang);
    await tester.pump();
    expect(find.text('今日：重阳'), findsOneWidget);
  });

  testWidgets('debug override · apply chunJie 后 clear → chip 不显示',
      (tester) async {
    final container = await pumpAndContainer(tester);
    final notifier = container.read(debugFestivalOverrideProvider.notifier);
    notifier.apply(Festival.chunJie);
    await tester.pump();
    expect(find.text('今日：春节'), findsOneWidget);
    notifier.clear();
    await tester.pump();
    expect(find.textContaining('今日：'), findsNothing);
  });

  testWidgets('debug override · apply chunJie 后 apply yuanXiao → 覆盖切到「今日：元宵」',
      (tester) async {
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

    testWidgets(
        '闭关 step=5 + character 仍 loading → 仍 disabled(loading 优先级保留)',
        (tester) async {
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
          attributes: Attributes()..constitution = 5..enlightenment = 5
            ..agility = 5..fortune = 5,
          rarity: RarityTier.tianCai,
          lineageRole: LineageRole.founder,
          createdAt: now,
        )..id = 1;

    Widget appWith({required int step, required List<int> hintsRead}) {
      final ch = founder(DateTime(2026, 5, 18));
      return ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => step),
          currentTutorialHintsReadProvider
              .overrideWith((ref) async => hintsRead),
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

    testWidgets('step=5 → 不显 banner(< 6 不入 hint 表)', (tester) async {
      await tester.pumpWidget(appWith(step: 5, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });

    testWidgets('step=6 + hintsRead=[] → 显 step 6 banner', (tester) async {
      await tester.pumpWidget(appWith(step: 6, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep6Title), findsOneWidget);
    });

    testWidgets('step=6 + hintsRead=[6] → 不显 banner(已读)', (tester) async {
      await tester.pumpWidget(appWith(step: 6, hintsRead: [6]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
    });

    testWidgets('step=8 + hintsRead=[] → 显 step 6 banner(取第 1 unread)',
        (tester) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: []));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep6Title), findsOneWidget,
          reason: 'R3 风险处置:同时多 unread 取最早 step');
      expect(find.text(UiStrings.tutorialHintStep7Title), findsNothing);
      expect(find.text(UiStrings.tutorialHintStep8Title), findsNothing);
    });

    testWidgets('step=8 + hintsRead=[6,7] → 显 step 8 banner', (tester) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: [6, 7]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep8Title), findsOneWidget);
    });

    testWidgets('step=8 + hintsRead=[6,7,8] → 不显 banner(全已读)',
        (tester) async {
      await tester.pumpWidget(appWith(step: 8, hintsRead: [6, 7, 8]));
      await tester.pump();
      await tester.pump();
      expect(find.byType(TutorialBannerCard), findsNothing);
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
