import 'package:flutter/foundation.dart';

import '../../../data/defs/tower_floor_def.dart';

/// Phase 0A 塔消费面灰度门。
///
/// 路线 C 默认启用 Phase 0A；`PHASE0A_TOWER_GRAY=false` 仅作
/// Windows 实机 Gate 前的紧急回退保险。
final class Phase0aTowerGate {
  const Phase0aTowerGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_TOWER_GRAY',
    defaultValue: true,
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 塔生产定义已由 preflight 保证连续且全部可映射；门开后不再按层分叉。
  static bool shouldUsePhase0a(TowerFloorDef floor) =>
      enabled && floor.floorIndex >= 1 && floor.enemyTeam.isNotEmpty;
}
