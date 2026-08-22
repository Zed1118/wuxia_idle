import 'package:flutter/foundation.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/tower_floor_def.dart';

/// Phase 0A 扫荡 headless 直结灰度门。
///
/// 默认关闭时继续走旧 3v3 快进连播；显式开启后，仅支持 0A 的生产扫荡单位
/// 走同核 headless runner。正式切换与旧扫荡屏拆除不属于本纵切。
final class Phase0aSweepGate {
  const Phase0aSweepGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_SWEEP_HEADLESS_GRAY',
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 与手动 Phase 0A 主线纵切保持同一范围：一周目 Ch1 五关。
  static bool shouldUseMainline(StageDef stage, {required int cycle}) =>
      enabled &&
      cycle == 1 &&
      stage.stageType == StageType.mainline &&
      RegExp(r'^stage_01_0[1-5]$').hasMatch(stage.id) &&
      stage.enemyTeam.isNotEmpty;

  /// 与塔手动灰度面一致：全部合法生产塔层。
  static bool shouldUseTower(TowerFloorDef floor) =>
      enabled && floor.floorIndex >= 1 && floor.enemyTeam.isNotEmpty;
}
