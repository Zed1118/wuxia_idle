import 'package:flutter/foundation.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/tower_floor_def.dart';

/// Phase 0A 扫荡 headless 直结灰度门。
///
/// 路线 C 默认启用同核 headless runner；
/// `PHASE0A_SWEEP_HEADLESS_GRAY=false` 仅作 Windows 实机 Gate 前的
/// 紧急回退保险。
final class Phase0aSweepGate {
  const Phase0aSweepGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_SWEEP_HEADLESS_GRAY',
    defaultValue: true,
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 主线扫荡范围与手动 Phase 0A 主线门对齐：全部主线 + 非空敌队 + 合法 cycle(>=1)。
  static bool shouldUseMainline(StageDef stage, {required int cycle}) =>
      enabled &&
      cycle >= 1 &&
      stage.stageType == StageType.mainline &&
      stage.enemyTeam.isNotEmpty;

  /// 与塔手动灰度面一致：全部合法生产塔层。
  static bool shouldUseTower(TowerFloorDef floor) =>
      enabled && floor.floorIndex >= 1 && floor.enemyTeam.isNotEmpty;
}
