import 'package:flutter/foundation.dart';

/// Phase 0A 断魂庄单角色续传灰度门。
///
/// 默认关闭时全部断魂庄会话继续走旧 3v3；通过
/// `--dart-define=PHASE0A_GAUNTLET_GRAY=true` 开启后仅单成员会话走
/// 单角色 Phase 0A，历史 2–3 人在途会话安全回落旧 3v3（避免灰度升级破坏
/// 既有会话）。正式全量切换与旧入口拆除不属于本纵切。
final class Phase0aGauntletGate {
  const Phase0aGauntletGate._();

  static const bool _enabledFromEnv = bool.fromEnvironment(
    'PHASE0A_GAUNTLET_GRAY',
  );

  static bool? _testOverride;

  /// 灰度门当前状态：`testOverride` 优先，否则读编译期 dart-define。
  static bool get enabled => _testOverride ?? _enabledFromEnv;

  /// 仅测试注入（null = 复原 dart-define 口径）。生产勿用。
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// 本会话是否走 Phase 0A：灰度门开 + 单成员。2–3 人历史会话回落旧 3v3；
  /// 非法成员数由选择器 `gauntletCombatPathFor` fail-fast，不在此谓词兜底。
  static bool shouldUsePhase0a({required int memberCount}) =>
      enabled && memberCount == 1;
}
