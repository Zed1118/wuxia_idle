import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/auto_play_toggle.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../application/stage_auto_play_pref.dart';

/// 战斗交互重做 Phase 3:选关屏 per-stage「挂机自动 / 允许拖招」开关接线 widget。
///
/// 5 类战斗选关屏(主线/爬塔/心魔/轻功/群战)共用此单元 —— 给定 [battleKey]
/// (`stage#…` / `tower#…` 等,见 [stageBattleKey] / [towerBattleKey]),它:
/// 1. watch [stageAutoPlayOverrideProvider] 取该关 override(三态);
/// 2. watch [gameplaySettingsProvider] 取全局默认;
/// 3. 渲染 [AutoPlayToggle],选项回调落 `setOverride` + invalidate 刷新。
///
/// 数据未就绪期返回空占位。
class StageAutoPlayControl extends ConsumerWidget {
  const StageAutoPlayControl({super.key, required this.battleKey});

  /// `stageBattleKey` / `towerBattleKey` 等构造的关卡键。
  final String battleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override =
        ref.watch(stageAutoPlayOverrideProvider(battleKey)).maybeWhen(
              data: (d) => (value: d),
              orElse: () => null,
            );
    final settings = ref.watch(gameplaySettingsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    if (override == null || settings == null) {
      return const SizedBox.shrink();
    }
    return AutoPlayToggle(
      overrideMode: override.value,
      globalDefault: settings.autoPlayDefault,
      onChanged: (v) async {
        await ref
            .read(stageAutoPlayPrefServiceProvider)
            .setOverride(battleKey, v);
        ref.invalidate(stageAutoPlayOverrideProvider(battleKey));
      },
    );
  }
}
