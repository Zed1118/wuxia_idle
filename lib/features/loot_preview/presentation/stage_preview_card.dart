import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../battle/domain/enum_localizations.dart';
import '../domain/drop_rumor.dart';
import '../domain/stage_difficulty.dart';
import 'loot_rumor_dialog.dart';

/// 第八阶段 B/C·悬停预览浮层内容(纯 widget,可独立测)。
///
/// 顶部:推荐境界 + 难度判语徽章(B `StageDifficultyAssessor`);
/// 下方:掉落传闻清单(复用 [LootRumorContent] · 守 §2.1 不显概率%/无 SSR 词)。
///
/// [playerRealm] 为 null(无在战角色)时不显难度徽章,仅显推荐境界。
class StagePreviewContent extends StatelessWidget {
  const StagePreviewContent({
    super.key,
    required this.recommendedRealm,
    required this.rumorTable,
    this.playerRealm,
  });

  final RealmTier recommendedRealm;
  final DropRumorTable rumorTable;
  final RealmTier? playerRealm;

  @override
  Widget build(BuildContext context) {
    final verdict = playerRealm == null
        ? null
        : StageDifficultyAssessor.assess(
            recommended: recommendedRealm,
            playerTier: playerRealm!,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${UiStrings.previewRecommendedRealmLabel}：'
              '${EnumL10n.realmTier(recommendedRealm)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WuxiaUi.muted,
              ),
            ),
            if (verdict != null) ...[
              const SizedBox(width: 8),
              _DifficultyBadge(verdict: verdict),
            ],
          ],
        ),
        const SizedBox(height: 6),
        LootRumorContent(table: rumorTable, currentRealm: playerRealm),
      ],
    );
  }
}

/// 难度判语徽章:碾压(青)/适中(墨)/偏高(金)/送死(绛红)。
class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.verdict});

  final DifficultyVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final (label, color) = difficultyLabelColor(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 难度判语 → (显示串, 水墨色)。供徽章 + 调用方复用。
(String, Color) difficultyLabelColor(DifficultyVerdict v) => switch (v) {
      DifficultyVerdict.comfortable => (
          UiStrings.difficultyComfortable,
          WuxiaUi.qing,
        ),
      DifficultyVerdict.suitable => (UiStrings.difficultySuitable, WuxiaUi.ink),
      DifficultyVerdict.risky => (UiStrings.difficultyRisky, WuxiaUi.gold),
      DifficultyVerdict.deadly => (UiStrings.difficultyDeadly, WuxiaUi.jiang),
    };

/// 第八阶段 C·桌面悬停预览浮层包装。
///
/// 鼠标悬停 [child] → 在其下方弹 [preview] 浮层(OverlayPortal,**出流不占列表
/// 高度**,故不挤出 ListView 靠后 item · 守 feedback_listview_widget_test_viewport)。
/// 移出即收。浮层本身也是 MouseRegion,指针移入浮层时保持展开(便于看长清单)。
class StagePreviewHoverCard extends StatefulWidget {
  const StagePreviewHoverCard({
    super.key,
    required this.child,
    required this.preview,
    this.width = 280,
  });

  final Widget child;
  final Widget preview;
  final double width;

  @override
  State<StagePreviewHoverCard> createState() => _StagePreviewHoverCardState();
}

class _StagePreviewHoverCardState extends State<StagePreviewHoverCard> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _controller = OverlayPortalController();

  void _show() {
    if (!_controller.isShowing) _controller.show();
  }

  void _hide() {
    if (_controller.isShowing) _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: OverlayPortal(
          controller: _controller,
          overlayChildBuilder: (context) {
            return Positioned(
              width: widget.width,
              child: CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 6),
                child: MouseRegion(
                  onEnter: (_) => _show(),
                  onExit: (_) => _hide(),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WuxiaUi.paper,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: WuxiaUi.ink.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: WuxiaUi.ink.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: widget.preview,
                    ),
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
