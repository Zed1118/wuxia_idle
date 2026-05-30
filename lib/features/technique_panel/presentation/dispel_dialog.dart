import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/technique.dart';
import '../../../core/application/battle_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 散功二次确认 dialog（phase2_tasks.md T31 §477-479）。
///
/// 显示双重代价（GDD §6 散功代价底线）：
///   - 内力 X → X×0.5（[NumbersConfig.dispersionInternalForcePenalty]）
///   - 旧主修修炼度 Y → Y×0.5（[dispersionCultivationPenalty]）
///   - cultivationLayer 可能回退（仅 warning，实际回退量散功后由
///     [DispelService.dispel] 内的 _recalcLayerByRollback 算）
///
/// 计算只读 [NumbersConfig]，**不直接调 [DispelService]**——dialog 仅返回
/// `true/false` 表示用户是否确认；调用方拿到 true 后自己执行 dispel + invalidate
/// providers + SnackBar 反馈，与 [ForgingPanel] 二确风格一致。
class DispelConfirmDialog extends ConsumerWidget {
  const DispelConfirmDialog({
    super.key,
    required this.character,
    required this.mainTech,
  });

  final Character character;
  final Technique mainTech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(numbersConfigProvider);
    final ifBefore = character.internalForce;
    final ifAfter =
        (ifBefore * (1 - n.dispersionInternalForcePenalty)).toInt();
    final cultBefore = mainTech.cultivationProgress;
    final cultAfter =
        (cultBefore * (1 - n.dispersionCultivationPenalty)).toInt();

    return AlertDialog(
      backgroundColor: WuxiaColors.panel,
      title: const Text(
        UiStrings.dispelDialogTitle,
        style: TextStyle(color: WuxiaColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UiStrings.dispelCostInternalForce(ifBefore, ifAfter),
            style: const TextStyle(color: WuxiaColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            UiStrings.dispelCostCultivation(cultBefore, cultAfter),
            style: const TextStyle(color: WuxiaColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.dispelLayerWarning,
            style: TextStyle(color: WuxiaColors.hpLow, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(UiStrings.forgingConfirmCancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: WuxiaColors.gangMeng,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(UiStrings.dispelConfirm),
        ),
      ],
    );
  }
}
