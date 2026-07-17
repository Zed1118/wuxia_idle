import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_entry_flow.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// #1 wiring Task 4 断魂庄战斗驱动全链编排器端到端（spec §3.1/§4）。走真 Isar + seedP3
/// 真角色 + 确定性 seed 战斗（注入 headless 驱动·经 `notifier.advance` 非 strategy.tick），
/// 弱敌必胜 / 强敌必败驱动三条路由：胜→整备→续战→Boss 胜→奖励屏；Boss 关胜→奖励三选一屏；
/// 败→战败结算屏 + 删会话。widget 内零直接 Isar 写（全经 GauntletService）。
///
/// testWidgets fake-async 与真 Isar future 死锁按仓内配方处理（team_lineup_screen_test
/// 体例）：真 async 包 [WidgetTester.runAsync]，UI 同步点用 runAsync+pump 交替轮询
/// [pumpUntilFound]，不用 pumpAndSettle。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_flow_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ActivityMemberSnapshot snap(int id) => ActivityMemberSnapshot()
    ..characterId = id
    ..maxHp = 0
    ..currentHp = 0
    ..isDowned = false;

  Future<void> putRun(int currentStage) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = GauntletPhase.inBattle
          ..members = [snap(1)],
      );
    });
  }

  Future<BossGauntletRun?> activeRun() async {
    final runs = await IsarSetup.instance.bossGauntletRuns.where().findAll();
    for (final r in runs) {
      if (r.saveDataId == 0) return r;
    }
    return null;
  }

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

  Future<BossGauntletRun?> readRun(WidgetTester tester) async {
    BossGauntletRun? r;
    await tester.runAsync(() async {
      r = await activeRun();
    });
    return r;
  }

  EnemyDef enemy({required int baseHp, required int baseAttack}) => EnemyDef(
    id: 'e',
    name: '弱敌',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: baseHp,
    baseAttack: baseAttack,
    baseSpeed: 1,
    skillIds: const [],
    iconPath: '',
  );

  const rewardIds = [
    'weapon_haojiahuo_qing_feng_jian',
    'armor_haojiahuo_jin_pao',
    'accessory_haojiahuo_yu_pei_lao',
  ];

  BossGauntletConfig singleBoss({
    required int baseHp,
    required int baseAttack,
  }) => BossGauntletConfig(
    stages: const [GauntletStageConfig(role: 'boss', enemyTeamId: 't')],
    supplyCap: 3,
    firstClearRewardSkillId: 'skill_suo_mai_zhen',
    rewardCandidateEquipmentIds: rewardIds,
    enemyTeams: {
      't': [enemy(baseHp: baseHp, baseAttack: baseAttack)],
    },
  );

  // 精英关 + Boss 关（均弱敌必胜）→ 胜1→整备→续战→胜2→奖励。
  BossGauntletConfig eliteThenBoss() => BossGauntletConfig(
    stages: const [
      GauntletStageConfig(role: 'elite', enemyTeamId: 't'),
      GauntletStageConfig(role: 'boss', enemyTeamId: 't'),
    ],
    supplyCap: 3,
    firstClearRewardSkillId: 'skill_suo_mai_zhen',
    rewardCandidateEquipmentIds: rewardIds,
    eliteRewardExp: 50,
    enemyTeams: {
      't': [enemy(baseHp: 1, baseAttack: 1)],
    },
  );

  /// 注入的确定性 headless 战斗驱动：prepareStage → startBattle（混关次 seed）→
  /// notifier.advance 排到战斗结束 → 返回是否取胜（finalState 落 battleProvider·同 live 路）。
  Future<bool> Function() driveBattle(
    WidgetRef ref,
    BossGauntletConfig config,
  ) => () async {
    final service = ref.read(gauntletServiceProvider)!;
    final plan = await service.prepareStage(config: config);
    final notifier = ref.read(battleProvider.notifier);
    notifier.startBattle(
      plan.playerTeam,
      StageBattleSetup.buildEnemyTeam(plan.enemyDefs),
      seed: plan.seed,
    );
    var guard = 0;
    while (!ref.read(battleProvider).isFinished && guard++ < 2000) {
      notifier.advance();
    }
    return ref.read(battleProvider).result == BattleResult.leftWin;
  };

  Widget host(BossGauntletConfig config) => ProviderScope(
    overrides: [gauntletConfigProvider.overrideWithValue(config)],
    child: MaterialApp(
      home: _FlowHost(battle: (ref) => driveBattle(ref, config)),
    ),
  );

  testWidgets('全链：单 Boss 关弱敌 → 胜 → 奖励三选一屏', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await putRun(1);
    });
    final config = singleBoss(baseHp: 1, baseAttack: 1);

    await tester.pumpWidget(host(config));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletRewardSection));

    expect(find.text(UiStrings.gauntletRewardSection), findsOneWidget);
    expect(find.text(UiStrings.gauntletRewardFirstClearBadge), findsOneWidget);
    final run = await readRun(tester);
    expect(run?.sessionPhase, GauntletPhase.awaitingRewardChoice);
  });

  testWidgets('全链：精英关胜 → 整备屏 → 继续闯关 → Boss 关胜 → 奖励屏', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await putRun(1);
    });
    final config = eliteThenBoss();

    await tester.pumpWidget(host(config));
    // 精英关胜 → interlude → 整备屏。
    await pumpUntilFound(tester, find.text(UiStrings.gauntletContinueButton));
    var run = await readRun(tester);
    expect(run?.sessionPhase, GauntletPhase.interlude);
    expect(run?.currentStage, 2);

    // 继续闯关 → Boss 关胜 → 奖励屏。
    await tester.tap(find.text(UiStrings.gauntletContinueButton));
    await pumpUntilFound(tester, find.text(UiStrings.gauntletRewardSection));
    expect(find.text(UiStrings.gauntletRewardSection), findsOneWidget);
    run = await readRun(tester);
    expect(run?.sessionPhase, GauntletPhase.awaitingRewardChoice);
  });

  testWidgets('全链：败 → 战败结算屏 + 删会话', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      await putRun(1);
    });
    final config = singleBoss(baseHp: 1, baseAttack: 1);

    // 战败路由不依赖战斗平衡：注入 fake 败（战末空态由 settleStageResult 优雅处理·
    // advance 记败不推进）→ settleDefeat → 战败屏。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gauntletConfigProvider.overrideWithValue(config)],
        child: MaterialApp(
          home: _FlowHost(
            battle: (ref) =>
                () async => false,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text(UiStrings.gauntletDefeatSection));

    expect(find.text(UiStrings.gauntletDefeatSection), findsOneWidget);
    expect(await readRun(tester), isNull);
  });

  testWidgets('无 Isar：service null → flow 旁路不推屏不崩', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isarProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: _FlowHost(
            battle: (ref) =>
                () async => true,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('flow-root'));
    expect(find.text('flow-root'), findsOneWidget);
    expect(find.text(UiStrings.gauntletRewardSection), findsNothing);
    expect(find.text(UiStrings.gauntletDefeatSection), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// 测试宿主：postFrame 起 runGauntletFlow（注入确定性战斗驱动）。
class _FlowHost extends ConsumerStatefulWidget {
  const _FlowHost({required this.battle});

  final Future<bool> Function() Function(WidgetRef ref) battle;

  @override
  ConsumerState<_FlowHost> createState() => _FlowHostState();
}

class _FlowHostState extends ConsumerState<_FlowHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runGauntletFlow(
        context: context,
        ref: ref,
        runStageBattleForTest: widget.battle(ref),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('flow-root')));
}
