import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 心魔关突破拦截提示 widget(1.0 P2.2 §12.1,Batch 2.3 占位 UI)。
///
/// 玩家 wuSheng 各 layer 升前被 [InnerDemonService.isLayerLocked] 拦截时,
/// character_panel / cultivation 面板可显示本 widget,告知玩家当前境界升不
/// 上去是因为哪一关心魔未通。
///
/// **集成状态**:本 widget 已集成于 character_panel(见
/// `character_panel_screen.dart` `_BreakthroughBlockerSection`),由 Riverpod
/// provider 拉 MainlineProgress.clearedStageIds + InnerDemonDef + 计算
/// advancement 是否被拦后 reactive 显示。本 widget 保持纯渲染职责。
class InnerDemonBreakthroughBlocker extends StatelessWidget {
  const InnerDemonBreakthroughBlocker({
    super.key,
    required this.nextTier,
    required this.nextLayer,
    required this.blockingStageId,
    required this.blockingStageName,
    this.onNavigate,
  });

  /// 玩家想升入的下一 tier(几乎总是 [RealmTier.wuSheng])。
  final RealmTier nextTier;

  /// 玩家想升入的下一 layer。
  final RealmLayer nextLayer;

  /// 拦截关 stage_id(如 `stage_inner_demon_01`)。
  final String blockingStageId;

  /// 拦截关展示名(如「心魔·贪」)。
  final String blockingStageName;

  /// 点击「前往挑战」回调(可选;集成时由 caller 推 [InnerDemonScreen] 或
  /// 直接 [runStageFlow])。
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WuxiaColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: WuxiaColors.textMuted),
                SizedBox(width: 6),
                Text(
                  '突破被拦',
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '想升 ${nextTier.name}·${nextLayer.name},'
              '心魔关「$blockingStageName」未通,经验留账。',
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
            if (onNavigate != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onNavigate,
                  child: const Text(UiStrings.breakthroughGoToInnerDemon),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
