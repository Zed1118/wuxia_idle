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
