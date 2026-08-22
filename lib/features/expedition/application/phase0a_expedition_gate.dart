import 'package:flutter/foundation.dart';

/// Phase 0A 远征单角色续传灰度门。
final class Phase0aExpeditionGate {
  const Phase0aExpeditionGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_EXPEDITION_GRAY',
    defaultValue: true,
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 单成员会话走 Phase 0A；历史多成员会话由启动恢复事务
  /// 安全召回，不再进入任何战斗 runner。
  static bool shouldUsePhase0a({required int memberCount}) =>
      enabled && memberCount == 1;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
}
