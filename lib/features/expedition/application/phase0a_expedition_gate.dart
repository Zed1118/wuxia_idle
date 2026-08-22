import 'package:flutter/foundation.dart';

/// Phase 0A 远征单角色续传灰度门。
final class Phase0aExpeditionGate {
  const Phase0aExpeditionGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_EXPEDITION_GRAY',
  );

  static bool? _testOverride;

  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 历史多成员在途会话继续走旧 3v3，避免灰度升级破坏既有会话。
  static bool shouldUsePhase0a({required int memberCount}) =>
      enabled && memberCount == 1;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
}
