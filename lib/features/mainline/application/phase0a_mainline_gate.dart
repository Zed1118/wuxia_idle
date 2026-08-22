import 'package:flutter/foundation.dart';

import '../../../data/defs/stage_def.dart';
import '../../../core/domain/enums.dart';

/// Phase 1 纵切实机接线的灰度门(拍板 α:主线入口灰度开关)。
///
/// 路线 C 默认启用 Phase 0A。`PHASE0A_MAINLINE_GRAY=false` 仅作
/// 删除旧引擎前的紧急回退保险；Windows 实机 Gate 通过后本门与
/// 旧分支会同批删除。
///
/// 门控面覆盖全部非空主线、心魔镜像、轻功地形与具备合法波次的群战关。
/// 剧情空敌主线及配置不完整的特殊关继续拒绝。
final class Phase0aMainlineGate {
  const Phase0aMainlineGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_MAINLINE_GRAY',
    defaultValue: true,
  );

  static bool? _testOverride;

  /// 灰度门当前状态:testOverride 优先,否则读编译期 dart-define。
  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 仅测试注入(null = 还原 dart-define 口径)。生产勿用。
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 本关是否走 0A:灰度门开 + 合法 cycle，并且关型已具备完整 0A 语义。
  static bool shouldUsePhase0a(StageDef stage, {required int targetCycle}) =>
      enabled &&
      targetCycle >= 1 &&
      ((stage.stageType == StageType.mainline && stage.enemyTeam.isNotEmpty) ||
          stage.stageType == StageType.innerDemon ||
          (stage.stageType == StageType.lightFoot &&
              stage.enemyTeam.isNotEmpty &&
              stage.terrainBiome != null) ||
          (stage.stageType == StageType.massBattle &&
              stage.enemyTeam.isNotEmpty &&
              (stage.massBattleEnemyCounts?.isNotEmpty ?? false)));
}
