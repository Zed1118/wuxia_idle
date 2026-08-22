import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/application/battle_providers.dart';
import '../../../data/game_repository.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/strings.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/presentation/battle_screen.dart';
import '../application/gauntlet_providers.dart';
import '../application/gauntlet_service.dart';
import '../application/gauntlet_combat_selector.dart';
import '../application/phase0a_gauntlet_stage_runner.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../domain/boss_gauntlet_run.dart';
import 'gauntlet_defeat_screen.dart';
import 'gauntlet_interlude_screen.dart';
import 'gauntlet_reward_screen.dart';
import 'phase0a_gauntlet_battle_host.dart';

/// 断魂庄逐关战斗驱动编排器（#1 wiring Task 4 · spec §3.1）。装载入庄后由 loadout
/// `_enter` 调起，按会话相位循环驱动三连战：
///
/// - **inBattle**：现场跑一关 [BattleScreen]（设计 A·守战斗爽感主旋律）→ 战末态经
///   [GauntletService.settleStageResult] 单事务原子推进（快照继承 + Boss 胜固化三选一
///   候选）→ 胜则回循环按新相位路由、败则 [GauntletService.settleDefeat] + 战败屏（终局）。
/// - **interlude**：推整备屏（用药 / 继续闯关 / 认输），屏内各自写路径 + pop，回循环。
/// - **awaitingRewardChoice**：推三选一奖励屏，屏内 chooseReward + pop → 回主菜单（终局）。
///
/// widget 内零直接 Isar 写——全经 [GauntletService]；config 经 provider read（不构造期
/// 定死·`feedback_flutter_async_config_race_controller_final`）。BattleScreen 不 await
/// push（胜利留栈由 flow 推进后再 pop，镜像 `tower_entry_flow`）。
///
/// [runStageBattleForTest] 仅供 widget test 注入确定性 headless 战斗驱动
/// （seed + `notifier.advance`），绕过真 [BattleScreen]；生产端勿传。
Future<void> runGauntletFlow({
  required BuildContext context,
  required WidgetRef ref,
  @visibleForTesting Future<bool> Function()? runStageBattleForTest,
}) async {
  final service = ref.read(gauntletServiceProvider);
  if (service == null) return; // 无 Isar 旁路（测试 / 未初始化）
  final numbers = GameRepository.instanceOrNull?.numbers;
  if (numbers == null) return; // 配置未加载

  while (true) {
    if (!context.mounted) return;
    final config = ref.read(gauntletConfigProvider);
    if (config == null) return; // 配置未加载
    final run = await service.activeRun();
    if (run == null) return; // 会话已结束（选奖 / 离庄 / 认输）
    if (!context.mounted) return;

    switch (run.sessionPhase) {
      case GauntletPhase.inBattle:
        // ① 驱动本关战斗（live BattleScreen 或测试注入的确定性 headless 驱动）。
        final bool won;
        if (runStageBattleForTest != null) {
          won = await runStageBattleForTest();
          final finalState = ref.read(battleProvider);
          await service.settleStageResult(
            finalState: finalState,
            config: config,
          );
        } else if (gauntletCombatPathFor(memberCount: run.members.length) ==
            GauntletCombatPath.phase0a) {
          final result = await _runPhase0aStageBattleUI(
            context: context,
            config: config,
          );
          if (result == null) return;
          won = result.leftWin;
          await service.settlePhase0aStageResult(
            result: result,
            config: config,
          );
        } else {
          won = await _runStageBattleUI(
            context: context,
            ref: ref,
            config: config,
          );
          final finalState = ref.read(battleProvider);
          await service.settleStageResult(
            finalState: finalState,
            config: config,
          );
        }
        if (!context.mounted) return;
        ref.invalidate(activeGauntletProvider);
        // ③ 收起战斗屏（仅 live 路径推了屏；测试注入路径无屏）。
        if (runStageBattleForTest == null &&
            context.mounted &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // ④ 败 → 失败结算 + 战败屏（终局）；胜 → 回循环按新相位路由。
        if (!won) {
          final summary = await service.settleDefeat(
            config: config,
            numbers: numbers,
          );
          ref.invalidate(activeGauntletProvider);
          ref.invalidate(gauntletCandidatesProvider);
          ref.invalidate(gauntletLoadoutInfoProvider);
          if (!context.mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => GauntletDefeatScreen(summary: summary),
            ),
          );
          return;
        }
      case GauntletPhase.interlude:
        // 整备屏内 继续闯关（continueToNextStage→inBattle）/ 认输（settleDefeat→删会话）
        // 各自 pop；回循环按新相位路由（inBattle 续战 / null 认输结束）。
        ref.invalidate(gauntletInterludeViewProvider);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const GauntletInterludeScreen()),
        );
        if (!context.mounted) return;
        ref.invalidate(activeGauntletProvider);
      case GauntletPhase.awaitingRewardChoice:
        // 三选一奖励屏内 chooseReward→删会话→pop；回主菜单（终局）。
        ref.invalidate(gauntletRewardViewProvider);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const GauntletRewardScreen()),
        );
        return;
      case GauntletPhase.settled:
        return;
    }
  }
}

Future<Phase0aGauntletStageResult?> _runPhase0aStageBattleUI({
  required BuildContext context,
  required BossGauntletConfig config,
}) {
  final completer = Completer<Phase0aGauntletStageResult?>();
  Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          builder: (_) => Phase0aGauntletBattleHost(
            config: config,
            onCompleted: (result) {
              if (!completer.isCompleted) completer.complete(result);
            },
          ),
        ),
      )
      .then((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
  return completer.future;
}

/// 推 [BattleScreen] 并 wait 胜/败回调；返回玩家是否取胜。BattleScreen 留栈由
/// [runGauntletFlow] 战末推进后统一 pop（镜像 `tower_entry_flow._runTowerBattle`）。
Future<bool> _runStageBattleUI({
  required BuildContext context,
  required WidgetRef ref,
  required BossGauntletConfig config,
}) async {
  final completer = Completer<bool>();
  Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          builder: (_) => _GauntletBattleHost(
            config: config,
            onVictory: () {
              if (!completer.isCompleted) completer.complete(true);
            },
            onDefeat: () {
              if (!completer.isCompleted) completer.complete(false);
            },
          ),
        ),
      )
      .then((_) {
        // 系统返回等意外出栈 → 未决则按败处理（放弃即止）。
        if (!completer.isCompleted) completer.complete(false);
      });
  return completer.future;
}

/// 断魂庄单关战斗 setup 容器（镜像主线 `_StageBattleHost` / 塔 `_TowerBattleHost`）。
/// postFrame `prepareStage`（事务外纯建队）→ `startBattle`（混 currentStage 的确定性
/// seed）→ [BattleScreen]（deferVictoryToCaller·胜负回调交 flow）。先挂空团、后
/// postFrame startBattle：靠 BattleScreen 的 empty→非空边沿起 timer。
class _GauntletBattleHost extends ConsumerStatefulWidget {
  const _GauntletBattleHost({
    required this.config,
    required this.onVictory,
    required this.onDefeat,
  });

  final BossGauntletConfig config;
  final VoidCallback onVictory;
  final VoidCallback onDefeat;

  @override
  ConsumerState<_GauntletBattleHost> createState() =>
      _GauntletBattleHostState();
}

class _GauntletBattleHostState extends ConsumerState<_GauntletBattleHost> {
  String? _setupError;
  int _stage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final service = ref.read(gauntletServiceProvider);
        if (service == null) {
          setState(() => _setupError = UiStrings.gauntletSessionNotReady);
          return;
        }
        final run = await service.activeRun();
        final plan = await service.prepareStage(config: widget.config);
        if (!mounted) return;
        // 批 B：断魂庄属境界段推进入口，live 路与 headless runner 同口径。
        final enemyTeam = StageBattleSetup.buildEnemyTeam(
          plan.enemyDefs,
          cycleIndex: plan.cycleIndex,
          advanceRealmPerCycle: true,
        );
        setState(() => _stage = run?.currentStage ?? 1);
        ref
            .read(battleProvider.notifier)
            .startBattle(plan.playerTeam, enemyTeam, seed: plan.seed);
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_setupError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(UiStrings.gauntletName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(UiStrings.battleSetupFailed(_setupError!)),
          ),
        ),
      );
    }
    return BattleScreen(
      hint:
          '${UiStrings.gauntletName} · ${UiStrings.gauntletStageOrdinal(_stage)}',
      bgmTrack: BgmTrack.boss,
      deferVictoryToCaller: true,
      onVictory: widget.onVictory,
      onDefeat: widget.onDefeat,
    );
  }
}
