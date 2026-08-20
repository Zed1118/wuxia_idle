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
/// 门控面只含主线([StageType.mainline]):塔/远征/断魂庄/群战/轻功等
/// 其余消费面绑内容迁移 ADR,纵切不触碰。
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

  /// 本关是否走 0A 主线战斗:灰度门开 + 主线关型。
  static bool shouldUsePhase0a(StageDef stage) =>
      enabled && stage.stageType == StageType.mainline;
}
