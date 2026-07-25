import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/lineup/presentation/team_lineup_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// 编成屏三态 + 点选交换 e2e + 常规桌面视口 smoke(spec §5)。
///
/// 走真 Isar 生产链路(providers 经 isarProvider 读真库,交互经
/// LineupService.apply 真写)——PR #37 T4 教训:fixture 挂载会绕过生产接线。
/// testWidgets fake-async 与真 Isar future 的死锁按仓内配方处理:
/// 真 async(seed / 服务写 / 读回)包 [WidgetTester.runAsync],
/// UI 同步点用 runAsync+pump 交替轮询(沿 disciple_join_hook_test._pumpUntilFound
/// 体例),不用 pumpAndSettle(会撞 SnackBar auto-dismiss timer 且真 async 不推进)。
void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineup_ui_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  Character makeChar({
    required int id,
    required String name,
    RealmTier tier = RealmTier.xueTu,
    RealmLayer layer = RealmLayer.qiMeng,
    bool isFounder = false,
    bool isActive = false,
    int? currentRetreatSessionId,
    int? mainTechniqueId,
    LineageRole lineageRole = LineageRole.disciple,
  }) {
    final realm = repository.getRealm(tier, layer);
    return Character.create(
      name: name,
      realmTier: tier,
      realmLayer: layer,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 7, 14),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: isFounder,
      isActive: isActive,
      currentRetreatSessionId: currentRetreatSessionId,
      mainTechniqueId: mainTechniqueId,
    )..id = id;
  }

  /// 主修 Technique 行(加入出战的硬前置,LineupService 校验行在库)。
  Technique makeMainTech({required int id, required int ownerId}) {
    return Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: ownerId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 14),
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
      cultivationLayer: CultivationLayer.chuKui,
    )..id = id;
  }

  /// 默认棋盘:祖师1+大弟子2+二弟子3 出战;可选替补。
  Future<void> seed({List<Character>? reserves}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        makeChar(
          id: 1,
          name: '祖师',
          isFounder: true,
          isActive: true,
          lineageRole: LineageRole.founder,
          tier: RealmTier.erLiu,
          layer: RealmLayer.shuLian,
        ),
        makeChar(
          id: 2,
          name: '大弟子',
          isActive: true,
          lineageRole: LineageRole.senior,
          tier: RealmTier.sanLiu,
          layer: RealmLayer.ruMen,
        ),
        makeChar(
          id: 3,
          name: '二弟子',
          isActive: true,
          lineageRole: LineageRole.junior,
        ),
        ...?reserves,
      ]);
      // 替补甲已修主修(可上场);替补乙无主修(带「未修主修」标,入口拦截)。
      await isar.techniques.put(makeMainTech(id: 904, ownerId: 4));
      final save = SaveData()
        ..saveVersion = '0.36'
        ..createdAt = DateTime(2026, 7, 14)
        ..lastSavedAt = DateTime(2026, 7, 14)
        ..lastOnlineAt = DateTime(2026, 7, 14)
        ..founderCharacterId = 1
        ..activeCharacterIds = [1, 2, 3];
      await isar.saveDatas.put(save);
    });
  }

  List<Character> defaultReserves() => [
    makeChar(
      id: 4,
      name: '替补甲',
      tier: RealmTier.sanLiu,
      layer: RealmLayer.ruMen,
      mainTechniqueId: 904,
    ),
    makeChar(id: 5, name: '替补乙'),
  ];

  /// runAsync 推进真 async(Isar 读写)+ pump(step) 推进虚拟时钟,轮询到
  /// [finder] 出现;找到后再走 settleRounds 轮让在途真 async 落定。
  /// 沿 disciple_join_hook_test 体例,不用 pumpAndSettle。
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 50),
    int maxTries = 120,
    int settleRounds = 4,
  }) async {
    for (var i = 0; i < maxTries; i++) {
      if (finder.evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
    for (var i = 0; i < settleRounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1280, 720),
    required Finder waitFor,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TeamLineupScreen())),
    );
    await pumpUntilFound(tester, waitFor);
  }

  Future<List<int>> readActiveIds(WidgetTester tester) async {
    late List<int> ids;
    await tester.runAsync(() async {
      final save = await IsarSetup.instance.saveDatas.get(0);
      ids = List<int>.from(save!.activeCharacterIds);
    });
    return ids;
  }

  /// 冲掉 SnackBar auto-dismiss 残余 timer,防 testWidgets 收尾 pending timer 报错。
  Future<void> flushSnackBarTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('正常态:三席+替补池渲染,前排标注,AI 倾向与装备攻击可见', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(tester, waitFor: find.text('替补乙'));

    expect(find.text('祖师'), findsOneWidget);
    expect(find.text('大弟子'), findsOneWidget);
    expect(find.text('替补甲'), findsOneWidget);
    expect(find.text(UiStrings.lineupFrontRowTag), findsOneWidget);
    expect(find.text(UiStrings.lineupReserveSection(2)), findsOneWidget);
    // AI 倾向:二弟子(junior)=控场,其余(祖师/大弟子/两替补)=破绽集火。
    expect(find.text(UiStrings.lineupAiControl), findsOneWidget);
    expect(find.text(UiStrings.lineupAiFocus), findsNWidgets(4));
    // 装备攻击行(全员裸装 = 0)。
    expect(find.text(UiStrings.lineupEquipAttack(0)), findsNWidgets(5));
    expect(
      find.byKey(const ValueKey('portraitFrame.inkSilhouette')),
      findsNWidgets(5),
    );
    // 未修主修标:仅替补乙(替补甲已种主修行)。
    expect(find.text(UiStrings.lineupNoMainTag), findsOneWidget);
    expect(find.byKey(const ValueKey('lineup.formationStage')), findsOneWidget);
    final slotRects = [
      for (var i = 0; i < 3; i++)
        tester.getRect(find.byKey(ValueKey('lineup.formationSlot.$i'))),
    ];
    expect(slotRects[0].left, greaterThan(slotRects[1].left));
    expect(slotRects[1].left, greaterThan(slotRects[2].left));
    expect(slotRects[0].overlaps(slotRects[1]), isFalse);
    expect(slotRects[1].overlaps(slotRects[2]), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未修主修替补:点击仅提示不弹换防(研习立为主修引导)', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(tester, waitFor: find.text('替补乙'));

    await tester.tap(find.text('替补乙'));
    await pumpUntilFound(tester, find.text(UiStrings.lineupNoMainSnack));

    expect(find.text(UiStrings.lineupNoMainSnack), findsOneWidget);
    expect(find.text(UiStrings.lineupChooseSlotBody), findsNothing);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('替补空态:引导文案,不弹教程', (tester) async {
    await tester.runAsync(() => seed());
    await pumpScreen(
      tester,
      waitFor: find.text(UiStrings.lineupReserveEmptyGuide),
    );

    expect(find.text(UiStrings.lineupReserveEmptyGuide), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('弱势提示:境界低于出战最低者的替补带「境界偏低」标签', (tester) async {
    // 出战下限抬到三流(二弟子升三流启蒙)后:替补甲(三流入门)≥ 下限无标,
    // 替补乙(学徒启蒙)< 下限 → 唯一「境界偏低」标。
    await tester.runAsync(() async {
      await seed(reserves: defaultReserves());
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final junior = await isar.characters.get(3);
        junior!.realmTier = RealmTier.sanLiu;
        junior.realmLayer = RealmLayer.qiMeng;
        await isar.characters.put(junior);
      });
    });
    await pumpScreen(tester, waitFor: find.text(UiStrings.lineupWeakTag));

    expect(find.text(UiStrings.lineupWeakTag), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('闭关锁定:替补带「闭关中」标签,点击仅提示不弹换防', (tester) async {
    await tester.runAsync(
      () => seed(
        reserves: [makeChar(id: 6, name: '闭关者', currentRetreatSessionId: 99)],
      ),
    );
    await pumpScreen(
      tester,
      waitFor: find.text(UiStrings.lineupRetreatLockedTag),
    );

    await tester.tap(find.text('闭关者'));
    await pumpUntilFound(tester, find.text(UiStrings.lineupRetreatLockedSnack));

    expect(find.text(UiStrings.lineupRetreatLockedSnack), findsOneWidget);
    expect(find.text(UiStrings.lineupChooseSlotBody), findsNothing);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('换人 e2e:点替补→换下第二席→列表序落库+镜像+UI 刷新', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(tester, waitFor: find.text('替补甲'));

    await tester.tap(find.text('替补甲'));
    await pumpUntilFound(tester, find.text(UiStrings.lineupChooseSlotBody));
    expect(find.text(UiStrings.lineupChooseSlotBody), findsOneWidget);

    await tester.tap(
      find.text(
        UiStrings.lineupReplaceSlot(UiStrings.lineupSlotLabel(1), '大弟子'),
      ),
    );
    await pumpUntilFound(tester, find.text(UiStrings.lineupApplySuccess));
    // snackbar 断言紧跟其轮询(后续再推假时钟会触发 4s auto-dismiss)。
    expect(find.text(UiStrings.lineupApplySuccess), findsOneWidget);

    expect(await readActiveIds(tester), [1, 4, 3]);
    late Character swappedOut;
    await tester.runAsync(() async {
      swappedOut = (await IsarSetup.instance.characters.get(2))!;
    });
    expect(swappedOut.isActive, isFalse);
    // UI:大弟子落入替补区。慢跑器(CI)上替补池 provider 重算可迟于成功
    // snackbar 出现,对终态本身轮询到位再断言,不依赖固定 settle 轮数
    // (2026-07-15 PR #39 首轮 CI 实锚:本地绿/ubuntu 慢机 0 widget)。
    await pumpUntilFound(tester, find.text('大弟子'));
    expect(find.text('大弟子'), findsOneWidget);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('祖师调度:无「下场歇息」选项;弟子下场成功', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(tester, waitFor: find.text('替补甲'));

    await tester.tap(find.text('祖师'));
    await pumpUntilFound(
      tester,
      find.text(UiStrings.lineupActiveActionBodySwapOnly),
    );
    expect(find.text(UiStrings.lineupActionRetire), findsNothing);
    // 说明行不得提「下场歇息」——祖师无该按钮,文案须同步(观察 #1)。
    expect(find.text(UiStrings.lineupActiveActionBody), findsNothing);
    await tester.tap(find.text(UiStrings.commonCancel));
    await pumpUntilFound(tester, find.text('替补甲'));

    await tester.tap(find.text('二弟子'));
    await pumpUntilFound(tester, find.text(UiStrings.lineupActionRetire));
    await tester.tap(find.text(UiStrings.lineupActionRetire));
    await pumpUntilFound(tester, find.text(UiStrings.lineupApplySuccess));

    expect(await readActiveIds(tester), [1, 2]);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('槽序互换:出战卡间交换落库(闭关成员重排亦放行)', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(tester, waitFor: find.text('替补甲'));

    await tester.tap(find.text('大弟子'));
    await pumpUntilFound(tester, find.text(UiStrings.lineupActiveActionBody));
    await tester.tap(
      find.text(
        UiStrings.lineupActionSwapWith(UiStrings.lineupSlotLabel(0), '祖师'),
      ),
    );
    await pumpUntilFound(tester, find.text(UiStrings.lineupApplySuccess));

    expect(await readActiveIds(tester), [2, 1, 3]);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440×900 视口 smoke:满棋盘渲染无异常', (tester) async {
    await tester.runAsync(() => seed(reserves: defaultReserves()));
    await pumpScreen(
      tester,
      size: const Size(1440, 900),
      waitFor: find.text('替补甲'),
    );

    expect(find.text(UiStrings.lineupTitle), findsOneWidget);
    expect(find.text('替补甲'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
