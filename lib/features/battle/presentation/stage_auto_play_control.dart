import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/auto_play_toggle.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../application/battle_replay_providers.dart';

/// 半手动战斗 P0 步骤5-G3:选关屏 per-stage 自动/手动开关接线 widget。
///
/// 5 类战斗选关屏(主线/爬塔/心魔/轻功/群战)共用此单元 —— 给定 [battleKey]
/// (`stage#…` / `tower#…` / `inner#…` 等),它:
/// 1. watch [stageAutoPlayStateProvider] 取该关 `autoPlayOverride` + hasRecord;
/// 2. watch [gameplaySettingsProvider] 取全局默认;
/// 3. 渲染 [AutoPlayToggle],选项回调落 `setAutoPlayOverride` + invalidate 刷新。
///
/// 数据未就绪期返回空占位(选关屏只对已通关关卡渲染本控件)。
class StageAutoPlayControl extends ConsumerWidget {
  const StageAutoPlayControl({super.key, required this.battleKey});

  /// `BattleReplayRecordService.stageBattleKey/towerBattleKey` 等构造的关卡键。
  final String battleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stageAutoPlayStateProvider(battleKey)).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    final settings = ref.watch(gameplaySettingsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    if (state == null || settings == null) {
      return const SizedBox.shrink();
    }
    return AutoPlayToggle(
      overrideMode: state.overrideMode,
      globalDefault: settings.autoPlayDefault,
      hasRecord: state.hasRecord,
      onChanged: (v) async {
        await ref
            .read(battleReplayRecordServiceProvider)
            .setAutoPlayOverride(battleKey, v);
        ref.invalidate(stageAutoPlayStateProvider(battleKey));
      },
    );
  }
}
