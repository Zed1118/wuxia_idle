import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import 'festival_service.dart';

part 'festival_service_providers.g.dart';

/// [FestivalService] provider（W16 GDD §12.4 接口预留 2026-05-16）。
///
/// 从 [GameRepository.instance.numbers.festivals] 取 [FestivalConfig]。
/// **不依赖 Isar**（festival 是纯数值/日期表查询，不入库）—— 沿用 rng_provider
/// 同等"纯函数 service"体例。
///
/// GameRepository 未加载（test 不初始化 fixture）时返回 null，沿
/// [encounterServiceProvider] 等"基础设施未就绪 → null"体例。caller
/// `?.todayFestival` 或 `?.festivalOn(...)` 取值。
@riverpod
FestivalService? festivalService(Ref ref) {
  if (!GameRepository.isLoaded) return null;
  final config = GameRepository.instance.numbers.festivals;
  return FestivalService(config: config);
}

/// DEBUG 节日覆盖 NotifierProvider（W16 Mac 端视觉验收用 2026-05-16）。
///
/// 非节日日（全年 357 天）`_TodayFestivalChip` 默认不显，无法在 Mac 端
/// debug build 现场验证 chip 8 节日各自显示效果。本 Notifier 持可变
/// `Festival?` 覆盖值，[todayFestival] 读 override 优先于 `FestivalService`。
///
/// 设计：
///   - 默认 `null` = 不覆盖，走真实日期路径
///   - `apply(Festival.X)` = 强制今日为 X 节日（不写 Isar，不影响数值）
///   - `clear()` = 恢复真实日期路径
///
/// **作用域**：仅 Phase2TestMenu DEBUG 入口 + widget test 路径。生产路径
/// (release 包) 不暴露入口，但 provider 本身存在 (无 build flag 隔离)，
/// 因为 GDD §12.4 明文「不影响数值」—— 玩家就算通过 Pen 反编译触发也
/// 仅影响 UI chip + encounter 触发维度，无数值红线风险。
@riverpod
class DebugFestivalOverride extends _$DebugFestivalOverride {
  @override
  Festival? build() => null;

  void apply(Festival? value) => state = value;

  void clear() => state = null;
}

/// 今日节日 provider（W16）—— UI 直接 watch 拿 `Festival?`，不必再 wrap service。
///
/// 读取优先级：
///   1. [debugFestivalOverride] 非 null → 直接返回（DEBUG 路径）
///   2. service 未就绪（GameRepository 未加载）→ null
///   3. 今天不是节日 → null
///   4. 是节日 → 对应 [Festival] 值
///
/// 注意：本 provider 每次 build 都新算 `DateTime.now()`，不会 reactive 跨日刷新。
/// 跨日切换需 caller `ref.invalidate(todayFestivalProvider)`（Demo 不实现自动
/// midnight refresh，main_menu 重新打开自然刷新已够）。
@riverpod
Festival? todayFestival(Ref ref) {
  final override = ref.watch(debugFestivalOverrideProvider);
  if (override != null) return override;
  return ref.watch(festivalServiceProvider)?.todayFestival;
}
