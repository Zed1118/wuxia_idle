import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_reward_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// P0 断线续战：装载屏恢复分支 UI 接线（§5.6/§10 · C2.5）。走真 Isar + 真
/// GameRepository（recover/chooseReward/settleDefeat 真写路径），覆盖四条链路：
/// 续战 tap(resumed) → runGauntletFlow 按相位路由进奖励屏；续战 tap(refundedTicket)
/// → SnackBar + 删会话 + 退帖；续战 tap(concedeRequired) → 认输结算 + 战败屏；奖励屏
/// PopScope 择取确认后显式 pop 正常出栈。真 async 轮询体例沿 entry_flow_test
/// （runAsync + pump 交替，不用 pumpAndSettle）。
void main() {
  late Directory tempDir;

  // 真配置三选一候选（好家伙占位·同 entry_flow_test）。
  const rewardIds = [
    'weapon_haojiahuo_qing_feng_jian',
    'armor_haojiahuo_jin_pao',
    'accessory_haojiahuo_yu_pei_lao',
  ];

  // 三关配置但 enemyTeams 空 → enemiesForTeam 返回空 → recover 判「配置损坏」。
  const brokenConfig = BossGauntletConfig(
    stages: [
      GauntletStageConfig(role: 'elite', enemyTeamId: 't1'),
      GauntletStageConfig(role: 'elite', enemyTeamId: 't2'),
      GauntletStageConfig(role: 'boss', enemyTeamId: 't3'),
    ],
    supplyCap: 3,
  );

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_resume_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ActivityMemberSnapshot snap(int id, {int maxHp = 0}) =>
      ActivityMemberSnapshot()
        ..characterId = id
        ..maxHp = maxHp
        ..currentHp = 0
        ..isDowned = false;

  Future<void> seedSave() async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17),
      );
    });
  }

  Future<void> putRun({
    required GauntletPhase phase,
    required int currentStage,
    required List<ActivityMemberSnapshot> members,
    List<String> rewardCandidateDefIds = const [],
    bool isFirstClearPending = false,
  }) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = phase
          ..members = members
          ..rewardCandidateDefIds = List.of(rewardCandidateDefIds)
          ..isFirstClearPending = isFirstClearPending,
      );
    });
  }

  Future<void> putInventory(String defId, ItemType type, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = type
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 17)
          ..lastObtainedAt = DateTime(2026, 7, 17),
      );
    });
  }

  Future<int> runCount() async => IsarSetup.instance.bossGauntletRuns.count();

  Future<int?> ticketQty() async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(
        'item_duanhuntie',
      ))?.quantity;

  /// runAsync 推进真 async（Isar 读写）+ pump 推进虚拟时钟，轮询到 [finder] 出现；
  /// 找到后再走 settleRounds 让在途真 async 落定。不用 pumpAndSettle。
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 50),
    int maxTries = 160,
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

  /// 轮询到 [finder] 消失（provider 失效重取后重建）。
  Future<void> pumpUntilGone(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 50),
    int maxTries = 80,
  }) async {
    for (var i = 0; i < maxTries && finder.evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
  }

  /// 冲掉 SnackBar auto-dismiss 残余 timer，防 testWidgets 收尾 pending timer 报错。
  Future<void> flushSnackBarTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
  }

  void fixViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// 装载屏（真 service/active provider；候选/装载信息 override 减负）。
  Future<void> pumpLoadout(
    WidgetTester tester, {
    BossGauntletConfig? configOverride,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gauntletCandidatesProvider.overrideWith((ref) async => const []),
          gauntletLoadoutInfoProvider.overrideWith(
            (ref) async =>
                const GauntletLoadoutInfo(ticketCount: 0, supplies: []),
          ),
          if (configOverride != null)
            gauntletConfigProvider.overrideWithValue(configOverride),
        ],
        child: const MaterialApp(home: GauntletLoadoutScreen()),
      ),
    );
  }

  testWidgets('续战 tap（resumed · awaitingRewardChoice 相位）→ 按相位路由进奖励屏', (
    tester,
  ) async {
    fixViewport(tester);
    await tester.runAsync(() async {
      await seedSave();
      await putRun(
        phase: GauntletPhase.awaitingRewardChoice,
        currentStage: 3,
        members: [snap(1, maxHp: 1000)],
        rewardCandidateDefIds: rewardIds,
        isFirstClearPending: true,
      );
    });

    await pumpLoadout(tester);
    await pumpUntilFound(tester, find.text(UiStrings.gauntletResumeButton));

    await tester.tap(find.text(UiStrings.gauntletResumeButton));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletRewardSection));

    // recover(resumed) 不改会话 → runGauntletFlow 按相位路由进奖励屏。
    expect(find.text(UiStrings.gauntletRewardSection), findsOneWidget);
    expect(find.text(UiStrings.gauntletRewardFirstClearBadge), findsOneWidget);
    expect(await tester.runAsync(runCount), 1, reason: 'resumed 不删会话（待择战利）');
    expect(tester.takeException(), isNull);
  });

  testWidgets('续战 tap（refundedTicket）→ SnackBar + 删会话 + 退帖 + 恢复区消失', (
    tester,
  ) async {
    fixViewport(tester);
    await tester.runAsync(() async {
      await seedSave();
      await putRun(
        phase: GauntletPhase.inBattle,
        currentStage: 1,
        members: [snap(1)], // maxHp=0 未开战
      );
      await putInventory('item_duanhuntie', ItemType.ticket, 0); // 入场已扣
    });

    await pumpLoadout(tester, configOverride: brokenConfig);
    await pumpUntilFound(tester, find.text(UiStrings.gauntletResumeButton));

    await tester.tap(find.text(UiStrings.gauntletResumeButton));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletResumeRefunded));

    expect(find.text(UiStrings.gauntletResumeRefunded), findsOneWidget);
    expect(await tester.runAsync(runCount), 0, reason: '退帖闭局删会话');
    expect(await tester.runAsync(ticketQty), 1, reason: '断魂帖 +1');
    // 会话已删 → provider 失效重取 → 恢复区消失回新建态。
    await pumpUntilGone(tester, find.text(UiStrings.gauntletResumeTitle));
    expect(find.text(UiStrings.gauntletResumeTitle), findsNothing);
    await flushSnackBarTimers(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('续战 tap（concedeRequired）→ 认输结算 + 战败屏 + 删会话', (tester) async {
    fixViewport(tester);
    await tester.runAsync(() async {
      await seedSave();
      await putRun(
        phase: GauntletPhase.interlude,
        currentStage: 2,
        members: [snap(1, maxHp: 1000)], // maxHp>0 已开战
      );
    });

    await pumpLoadout(tester, configOverride: brokenConfig);
    await pumpUntilFound(tester, find.text(UiStrings.gauntletResumeButton));

    await tester.tap(find.text(UiStrings.gauntletResumeButton));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletDefeatSection));

    expect(find.text(UiStrings.gauntletDefeatSection), findsOneWidget);
    expect(await tester.runAsync(runCount), 0, reason: '认输结算删会话');
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励屏：择取确认后正常出栈（PopScope 不挡显式 pop）', (tester) async {
    fixViewport(tester);
    await tester.runAsync(() async {
      await seedSave();
      await putRun(
        phase: GauntletPhase.awaitingRewardChoice,
        currentStage: 3,
        members: [snap(1, maxHp: 1000)],
        rewardCandidateDefIds: rewardIds,
        isFirstClearPending: true,
      );
    });

    // 奖励屏压在 home 之上（验证出栈回落 home）。全真 provider（view/service/config）。
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const GauntletRewardScreen(),
                    ),
                  ),
                  child: const Text('open-reward'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('open-reward'));
    await tester.tap(find.text('open-reward'));

    final firstName = GameRepository.instance
        .getEquipment(rewardIds.first)
        .name;
    await pumpUntilFound(tester, find.text(firstName));
    expect(find.text(firstName), findsOneWidget);

    // 点卡 → 择取确认 → chooseReward 真写 → 显式 pop 出栈。
    await tester.tap(find.text(firstName));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletRewardConfirm));
    await tester.tap(find.text(UiStrings.gauntletRewardConfirm));
    // 出栈动画期间旧路由短暂在树（home 先可找）：等奖励屏彻底离场再断言。
    await pumpUntilGone(tester, find.text(UiStrings.gauntletRewardSection));

    expect(find.text(UiStrings.gauntletRewardSection), findsNothing);
    expect(find.text('open-reward'), findsOneWidget, reason: '出栈回落 home');
    expect(await tester.runAsync(runCount), 0, reason: '择取结算关会话');
    expect(
      await tester.runAsync(() => IsarSetup.instance.equipments.count()),
      1,
      reason: '选中命名装备入背包',
    );
    expect(tester.takeException(), isNull);
  });
}
