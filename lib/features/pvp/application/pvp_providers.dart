import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../domain/pvp_record.dart';
import 'pvp_service.dart';
import 'pvp_sync_service.dart';

/// PVP Riverpod wire(1.0 P3.3 §12.3 Phase 4 · spec p3_3_pvp_spec_2026-05-24 §5)。
///
/// **D 方案 future-proof**(沿 LeaderboardSyncService 体例):
///   - [pvpSyncServiceProvider] 默认注 [NoopPvpSync](本地 mock,0 网络)
///   - Phase 5+ 真接入 Supabase 时只 override 此 provider 注 `SupabasePvpSync`,
///     [PvpService] 与上游 UI 0 改
///
/// **当前 ELO + 历史 stub**:
///   - [currentPvpEloProvider] 默认返 `numbers.yaml pvp.elo.initial=1200`,
///     Phase 5+ 真持久化(SaveData.pvpElo)+ Isar wire 时 override
///   - [pvpRecentRecordsProvider] 默认返空 list(Phase 5+ 读 Isar pvpRecords
///     最近 20 场;本 Phase Noop 不入库,UI 显空态文案)
final pvpSyncServiceProvider = Provider<PvpSyncService>((ref) {
  return NoopPvpSync();
});

final pvpServiceProvider = Provider<PvpService>((ref) {
  final sync = ref.watch(pvpSyncServiceProvider);
  final numbers = ref.watch(numbersConfigProvider);
  return PvpService(sync: sync, numbers: numbers);
});

/// 当前玩家 ELO(默认 `numbers.yaml pvp.elo.initial`,Phase 5+ 真持久化时
/// override)。
final currentPvpEloProvider = Provider<int>((ref) {
  final numbers = ref.watch(numbersConfigProvider);
  final pvpCfg = PvpService.pvpCfgFor(numbers);
  final eloCfg = pvpCfg['elo'] as Map;
  return (eloCfg['initial'] as num).toInt();
});

/// 最近 PVP 战例列表(Phase 4 stub 返空 · Phase 5+ 读 Isar pvpRecords
/// 倒序最近 20 场)。
final pvpRecentRecordsProvider = Provider<List<PvpRecord>>((ref) {
  return const [];
});
