import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/gameplay_settings.dart';
import 'gameplay_settings_service.dart';

/// 半手动战斗 P0 步骤5-B:全局玩法设置 provider(裸 Provider,无 codegen)。

final gameplaySettingsServiceProvider = Provider<GameplaySettingsService>(
  (ref) => GameplaySettingsService(),
);

/// 当前全局玩法设置。设置面板写入后 `ref.invalidate(gameplaySettingsProvider)`
/// 触发刷新;入口决策(`_StageBattleHost` 等)读 `.future` 取 autoPlayDefault。
final gameplaySettingsProvider = FutureProvider<GameplaySettings>(
  (ref) => ref.watch(gameplaySettingsServiceProvider).load(),
);
