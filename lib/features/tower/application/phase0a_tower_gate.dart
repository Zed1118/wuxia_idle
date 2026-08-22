import 'package:flutter/foundation.dart';

import '../../../data/defs/tower_floor_def.dart';

/// Phase 0A 塔消费面灰度门。
///
/// 默认关闭时全部塔层继续走旧 3v3；通过
/// `--dart-define=PHASE0A_TOWER_GRAY=true` 开启后，生产定义中的塔层走
/// 单角色 Phase 0A 宿主。正式全量切换与旧入口拆除不属于本纵切。
final class Phase0aTowerGate {
  const Phase0aTowerGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_TOWER_GRAY',
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 塔生产定义已由 preflight 保证连续且全部可映射；门开后不再按层分叉。
  static bool shouldUsePhase0a(TowerFloorDef floor) =>
      enabled && floor.floorIndex >= 1 && floor.enemyTeam.isNotEmpty;
}
