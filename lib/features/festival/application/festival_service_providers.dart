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

/// 今日节日 provider（W16）—— UI 直接 watch 拿 `Festival?`，不必再 wrap service。
///
/// service 未就绪（GameRepository 未加载）→ null；今天不是节日 → null；
/// 是节日 → 对应 [Festival] 值。
///
/// 注意：本 provider 每次 build 都新算 `DateTime.now()`，不会 reactive 跨日刷新。
/// 跨日切换需 caller `ref.invalidate(todayFestivalProvider)`（Demo 不实现自动
/// midnight refresh，main_menu 重新打开自然刷新已够）。
@riverpod
Festival? todayFestival(Ref ref) {
  return ref.watch(festivalServiceProvider)?.todayFestival;
}
