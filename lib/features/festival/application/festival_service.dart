import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';

/// 农历节日 service（W16 GDD §12.4 接口预留 2026-05-16）。
///
/// 纯函数 service —— 内只持 [FestivalConfig] 引用，无 IO / 无 Isar 依赖。
/// **不影响数值红线**（GDD §12.4 明文）—— 仅查询当前是否为节日 + 返回 enum 用于
/// UI 显示 / encounter trigger 维度判定。
///
/// 设计取舍：
///   - clock injection：[festivalToday] 接受可选 [now] 参数，生产路径默认 `DateTime.now()`,
///     test 路径传 `DateTime(2026,2,17)` 等固定时间锁定行为。沿 `RetreatConfig.isSolarTermDay`
///     体例（接 DateTime 参数）—— provider 层无需 Clock 抽象。
///   - service 不依赖 GameRepository：caller（provider）端注入 [FestivalConfig]，
///     便于测试 fixture 隔离（沿 `EncounterService` 体例 line 82-83）。
class FestivalService {
  const FestivalService({required this.config});

  final FestivalConfig config;

  /// 给定日期 [when] 是否为节日。null 表示非节日。
  /// [when] 省略时取 `DateTime.now()`（生产路径）。
  Festival? festivalOn([DateTime? when]) =>
      config.festivalOn(when ?? DateTime.now());

  /// 今日节日（便捷方法）。等价于 `festivalOn(DateTime.now())`。
  Festival? get todayFestival => festivalOn();
}
