import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/system_clock_provider.dart';
import '../../../data/isar_provider.dart';
import '../../../data/defs/expedition_config.dart';
import 'expedition_combat.dart';
import 'expedition_combat_selector.dart';
import 'expedition_providers.dart';
import 'expedition_service.dart';
import 'phase0a_expedition_gate.dart';

/// 离线追平 active 远征的**纯依赖核心**（单测友好：combat 注入 seam，隔离
/// GameRepository/真实战斗）。用当前 [now] 循环分批结算至追平或战败；无 active
/// 远征 → no-op。返回聚合结算结果。§4.4/§9.1/§12.1（在线=离线）。
Future<ExpeditionSettlementResult> settleActiveExpeditionOnOpen({
  required ExpeditionService service,
  required ExpeditionCombat combat,
  required ExpeditionConfig config,
  DateTime? now,
}) async {
  final active = await service.activeRun();
  if (active == null) {
    return const ExpeditionSettlementResult(
      nodesSettled: 0,
      currentNode: 0,
      caughtUp: true,
      defeated: false,
    );
  }
  return service.settleToNow(combat: combat, config: config, now: now);
}

/// 路线 C 历史多人远征清场：发已落库奖励并释放成员。返回是否实际清场。
Future<bool> retireLegacyMultiplayerExpeditionOnOpen({
  required ExpeditionService service,
}) async {
  final active = await service.activeRun();
  if (active == null || active.members.length == 1) return false;
  final result = await service.recall();
  return result.returned;
}

/// 主菜单首帧调用（与 `maybeRunSectMonthlyTick` 并列，挂 `MainMenuStartupGate`
/// post-frame）。isar/service/config 任一缺失即 no-op（轻量启动 / 未加载 defs 下
/// 安全）。结算后失效 `activeExpedition`/`expeditionCandidates`，让总览屏读到最新
/// 推进（战败态由总览屏召回时兑现返程，不在此弹屏）。
Future<void> maybeSettleExpedition(WidgetRef ref, {DateTime? now}) async {
  final isar = ref.read(isarProvider);
  if (isar == null) return;
  final service = ref.read(expeditionServiceProvider);
  if (service == null) return;
  final config = ref.read(expeditionConfigProvider);
  if (config == null) return;
  final clock = ref.read(systemClockProvider);
  final active = await service.activeRun();
  if (active == null) return;
  // 路线 C：灰度全量开启后，历史 2–3 人会话不再回落旧 3v3。
  // 只兑现已落库 stagedRewards；不依赖即将删除的旧 runner 追算未结节点。
  if (Phase0aExpeditionGate.enabled && active.members.length != 1) {
    await retireLegacyMultiplayerExpeditionOnOpen(service: service);
    ref.invalidate(activeExpeditionProvider);
    ref.invalidate(expeditionCandidatesProvider);
    return;
  }
  await settleActiveExpeditionOnOpen(
    service: service,
    combat: expeditionCombatFor(isar, memberCount: active.members.length),
    config: config,
    now: now ?? clock.now(),
  );
  ref.invalidate(activeExpeditionProvider);
  ref.invalidate(expeditionCandidatesProvider);
}
