import 'package:flutter/foundation.dart';

/// Phase 0A 断魂庄单角色续传灰度门。
///
/// 路线 C 默认启用 Phase 0A。历史 2–3 人在途会话由入口
/// 恢复事务安全退役，不再回落旧 3v3。
final class Phase0aGauntletGate {
  const Phase0aGauntletGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_GAUNTLET_GRAY',
    defaultValue: true,
  );

  static bool? _testOverride;

  /// 灰度门当前状态：`testOverride` 优先，否则读编译期 dart-define。
  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 仅测试注入（null = 复原 dart-define 口径）。生产勿用。
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 本会话是否走 Phase 0A：门开 + 单成员。2–3 人历史会话
  /// 会在进入选择器前被恢复事务退役；
  /// 非法成员数由选择器 `gauntletCombatPathFor` fail-fast，不在此谓词兜底。
  static bool shouldUsePhase0a({required int memberCount}) =>
      enabled && memberCount == 1;
}
