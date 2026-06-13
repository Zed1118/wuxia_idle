import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isar_setup.dart';
import 'battle_replay_record_service.dart';

/// 半手动战斗 P0 步骤5-D:重放落盘 service provider。
///
/// 入口决策(`_StageBattleHost` / `_TowerBattleHost`)+ 选关屏(自动/手动
/// 开关)经此读 service。生产走 [IsarSetup.instance];测试可 override 注入。
final battleReplayRecordServiceProvider = Provider<BattleReplayRecordService>(
  (ref) => BattleReplayRecordService(isar: IsarSetup.instance),
);

/// 选关屏 per-stage 自动/手动开关态(半手动战斗 P0 步骤5-G3)。
///
/// `overrideMode` = 该 battleKey 重放记录的 `autoPlayOverride`(三态:`null`
/// 跟随全局 / `true` 强制自动 / `false` 强制手动);`hasRecord` = 是否有重放
/// 记录(无 = 未通关或迁移豁免 autoFallback,开关不可切)。
///
/// 写 override 后调用方 `invalidate(stageAutoPlayStateProvider(battleKey))` 刷新。
typedef StageAutoPlayState = ({bool? overrideMode, bool hasRecord});

final stageAutoPlayStateProvider =
    FutureProvider.family<StageAutoPlayState, String>((ref, battleKey) async {
  final rec = await ref.watch(battleReplayRecordServiceProvider).find(battleKey);
  return (overrideMode: rec?.autoPlayOverride, hasRecord: rec != null);
});
