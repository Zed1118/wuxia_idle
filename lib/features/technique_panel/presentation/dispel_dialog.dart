import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/technique.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

/// 散功二次确认 dialog（phase2_tasks.md T31 §477-479）。
///
/// 显示 [DispelService.dispel] 的真实代价（v1.34）：
///   - 永久内力不变
///   - 内息紊乱增加 [InnerBreathDisorderConfig.dispelHours]，累计不超过
///     [InnerBreathDisorderConfig.maxHours]
///   - 旧主修修炼度 Y → Y×0.5（[NumbersConfig.dispersionCultivationPenalty]）
///   - 换入主修原为辅修，修炼度不变
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
    final disorder = n.innerBreathDisorder;
    final disorderBefore = character.innerBreathDisorderHoursRemaining;
    final disorderAfter = (disorderBefore + disorder.dispelHours)
        .clamp(0.0, disorder.maxHours)
        .toDouble();
    final cultBefore = mainTech.cultivationProgress;
    final cultAfter = (cultBefore * (1 - n.dispersionCultivationPenalty))
        .toInt();

    return PaperDialog(
      title: UiStrings.dispelDialogTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UiStrings.dispelCostInternalForce(ifBefore, ifBefore),
            style: const TextStyle(color: WuxiaUi.muted),
          ),
          const SizedBox(height: 6),
          Text(
            UiStrings.dispelCostInnerBreathDisorder(
              disorderBefore,
              disorderAfter,
              disorder.maxHours,
            ),
            style: const TextStyle(color: WuxiaUi.muted),
          ),
          const SizedBox(height: 6),
          Text(
            UiStrings.dispelCostCultivation(cultBefore, cultAfter),
            style: const TextStyle(color: WuxiaUi.muted),
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.dispelIncomingCultivationUnchanged,
            style: TextStyle(color: WuxiaUi.muted),
          ),
          const SizedBox(height: 6),
          const Text(
            UiStrings.dispelLayerWarning,
            style: TextStyle(color: WuxiaColors.hpLow, fontSize: 12),
          ),
        ],
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.forgingConfirmCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
        PlaqueButton(
          label: UiStrings.dispelConfirm,
          destructive: true,
          autofocus: true,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
