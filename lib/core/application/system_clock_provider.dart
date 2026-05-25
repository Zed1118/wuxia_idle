import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 系统时间抽象(1.0 P3 nightshift T19b 技术债清账)。
///
/// 替代散落的 `DateTime.now()` 直调,统一走 Riverpod provider 注入;
/// 测试可 override [systemClockProvider] 注 fake clock 跑时间相关分支
/// (sect monthly tick / cooldown / reputation decay 等)。
///
/// **Scope**:本 task 只切 sect 模块相关 caller,其他模块的 `DateTime.now()`
/// 留旧路径不动(避无谓 diff,sect 系统是先头部队)。
class SystemClock {
  const SystemClock();

  /// 默认返本地时钟当前时间。子类(测试用 FakeClock)可 override。
  DateTime now() => DateTime.now();
}

/// 测试 seam:override `systemClockProvider.overrideWithValue(FakeClock(...))`。
final systemClockProvider = Provider<SystemClock>((ref) => const SystemClock());
