import '../../../data/numbers_config.dart';
import '../domain/sect.dart';

/// 门派声望衰减服务(1.0 P3.4 §12.1 Batch 2.2)。
///
/// **pure 函数体例**:`computeDecay` 接 Sect + now → 返 reputation 应扣数。
/// 真 mutation 在 caller 端(Phase 4 wire 到 Riverpod monthly tick callback)。
///
/// 规则(spec §4 末段 decay):
/// - `lastEventAt == null`(新建 sect)→ 0(不衰减)
/// - 距 `lastEventAt` < 30 天 → 0
/// - 距 `lastEventAt` ≥ 30 天 → -decay_per_month_idle(默认 -5)
///
/// caller 端取得 delta 后自行做 `sect.sectReputation = (sect.sectReputation + delta).clamp(0, 100)`。
class SectReputationDecayService {
  final NumbersConfig numbers;

  const SectReputationDecayService({required this.numbers});

  /// 计算 decay 增量。返 0 = 不衰减,负数 = 应扣 reputation。
  int computeDecay({required Sect sect, required DateTime now}) {
    final decayAmount = numbers.sectEvent.reputation.decayPerMonthIdle;

    final lastAt = sect.lastEventAt;
    if (lastAt == null) return 0;
    final daysSince = now.difference(lastAt).inDays;
    if (daysSince < 30) return 0;
    return -decayAmount;
  }
}
