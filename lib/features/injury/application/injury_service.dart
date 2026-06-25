import '../../../core/domain/character.dart';

/// 双层伤势设值纯函数（全静态，仿 InnerDemonService 体例）。
///
/// 只改传入 Character 的字段，不碰 Isar/persistence。
/// 持久化由 Task 7 caller 负责。
class InjuryService {
  InjuryService._();

  /// 重伤：设疗养剩余 = recoveryHours（再伤刷新不叠加，仿余毒）。
  static void applyHeavyInjury(Character c, {required double recoveryHours}) {
    c.injuryHoursRemaining = recoveryHours;
  }

  /// 轻伤：连战 +1，clamp maxStacks。
  static void accumulateLightInjury(Character c, {required int maxStacks}) {
    final n = c.lightInjuryStacks + 1;
    c.lightInjuryStacks = n > maxStacks ? maxStacks : n;
  }
}
