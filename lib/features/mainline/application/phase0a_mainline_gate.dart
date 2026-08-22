import 'package:flutter/foundation.dart';

import '../../../data/defs/stage_def.dart';
import '../../../core/domain/enums.dart';

/// Phase 1 纵切实机接线的灰度门(拍板 α:主线入口灰度开关)。
///
/// 开关经 dart-define `PHASE0A_MAINLINE_GRAY=true` 编译期注入(沿
/// `HITBOX_DEBUG` 体例):纵切期默认关 → 主线仍走旧 3v3 引擎;验收期
/// `flutter run --dart-define=PHASE0A_MAINLINE_GRAY=true` 打开后主线
/// 关走 0A 引擎全链。正式全量切换 + 旧入口拆除仍留路线 C 第三序
/// (同次 merge,spec §5 非目标约束),本门届时整类删除。
///
/// 门控面覆盖全部非空主线与心魔镜像关。轻功(lightFoot)/群战(massBattle)
/// 在专属修正与波间契约迁完前继续走旧入口；剧情空敌主线同样拒绝。
final class Phase0aMainlineGate {
  const Phase0aMainlineGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_MAINLINE_GRAY',
  );

  static bool? _testOverride;

  /// 灰度门当前状态:testOverride 优先,否则读编译期 dart-define。
  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 仅测试注入(null = 还原 dart-define 口径)。生产勿用。
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 本关是否走 0A:灰度门开 + 合法 cycle，并且是非空主线或心魔关。
  static bool shouldUsePhase0a(StageDef stage, {required int targetCycle}) =>
      enabled &&
      targetCycle >= 1 &&
      ((stage.stageType == StageType.mainline && stage.enemyTeam.isNotEmpty) ||
          stage.stageType == StageType.innerDemon);
}
