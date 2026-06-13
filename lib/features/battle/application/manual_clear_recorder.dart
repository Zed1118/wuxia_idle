import '../domain/auto_play_mode.dart';
import '../domain/battle_replay.dart';
import 'battle_replay_record_service.dart';

/// 半手动战斗 P0 步骤5-D:手动场胜利后录制 `{seed+ops}`。
///
/// **不变量**:只有手动模式([AutoPlayMode.manualFirstClear] /
/// [AutoPlayMode.manualReplay])才写 record;自动模式(autoReplay /
/// autoFallback)绝不录制——否则重放产生的 recordedOps 会覆盖污染原记录。
///
/// 返回是否录制了(供调用方/测试断言)。由 `_StageBattleHost` /
/// `_TowerBattleHost` 的 onVictory 调用。
Future<bool> recordManualClearIfNeeded({
  required AutoPlayMode mode,
  required String battleKey,
  required int seed,
  required List<BattleReplayOp> ops,
  required BattleReplayRecordService service,
}) async {
  final isManual = mode == AutoPlayMode.manualFirstClear ||
      mode == AutoPlayMode.manualReplay;
  if (isManual) {
    await service.record(battleKey: battleKey, seed: seed, ops: ops);
  }
  return isManual;
}
