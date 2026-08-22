import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../application/gauntlet_providers.dart';
import '../application/gauntlet_service.dart';
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
/// - **inBattle**：现场跑一关 Phase 0A 单角色战斗 → 战末检查点经
///   [GauntletService.settlePhase0aStageResult] 单事务原子推进（快照继承 + Boss 胜固化三选一
///   候选）→ 胜则回循环按新相位路由、败则 [GauntletService.settleDefeat] + 战败屏（终局）。
/// - **interlude**：推整备屏（用药 / 继续闯关 / 认输），屏内各自写路径 + pop，回循环。
/// - **awaitingRewardChoice**：推三选一奖励屏，屏内 chooseReward + pop → 回主菜单（终局）。
///
/// widget 内零直接 Isar 写——全经 [GauntletService]；config 经 provider read（不构造期
/// 定死·`feedback_flutter_async_config_race_controller_final`）。
///
/// [runStageBattleForTest] 仅供 widget test 注入带完整 HP/真气检查点的
/// Phase 0A headless 结果；生产端勿传。
Future<void> runGauntletFlow({
  required BuildContext context,
  required WidgetRef ref,
  @visibleForTesting
  Future<GauntletStageSettlement> Function()? runStageBattleForTest,
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

    if (run.members.length != 1) {
      final retired = await service.retireLegacyMultiplayer(
        config: config,
        numbers: numbers,
      );
      if (!context.mounted) return;
      if (retired != GauntletLegacyRetirement.preservedRewardChoice) {
        ref.invalidate(activeGauntletProvider);
        ref.invalidate(gauntletCandidatesProvider);
        ref.invalidate(gauntletLoadoutInfoProvider);
        return;
      }
    }

    switch (run.sessionPhase) {
      case GauntletPhase.inBattle:
        // ① live 与测试均产出同一引擎中立检查点。
        final GauntletStageSettlement settlement;
        if (runStageBattleForTest != null) {
          settlement = await runStageBattleForTest();
        } else {
          final result = await _runPhase0aStageBattleUI(
            context: context,
            config: config,
          );
          if (result == null) return;
          settlement = result.settlement;
        }
        await service.settlePhase0aStageResult(
          result: settlement,
          config: config,
        );
        final won = settlement.leftWin;
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
