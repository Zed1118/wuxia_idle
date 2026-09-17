import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_clock_provider.g.dart';

/// 系统时间抽象(1.0 P3 nightshift T19b 技术债清账)。
///
/// 替代散落的 `DateTime.now()` 直调,统一走 Riverpod provider 注入;
/// 测试可 override [systemClockProvider] 注 fake clock 跑时间相关分支
/// (sect monthly tick / cooldown / reputation decay 等)。
///
/// 当前覆盖门派与已接线的结算写路径，其余调用点仍按残留登记逐步处理。
class SystemClock {
  const SystemClock() : _fixedAt = null;

  /// 将一次结算已确定的时刻传给下游，避免同笔写入重新读取系统时间。
  const SystemClock.fixed(DateTime at) : _fixedAt = at;

  final DateTime? _fixedAt;

  /// 默认返本地时钟当前时间。子类(测试用 FakeClock)可 override。
  DateTime now() => _fixedAt ?? DateTime.now();
}

/// 测试 seam:override `systemClockProvider.overrideWithValue(FakeClock(...))`。
@riverpod
SystemClock systemClock(Ref ref) => const SystemClock();
