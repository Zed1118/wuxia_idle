import 'package:flutter/material.dart';

import '../../domain/battle_log.dart';
import '../../domain/battle_state.dart';
import '../../domain/enum_localizations.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/widgets/wuxia_ui/wuxia_icon_button.dart';
import '../../../help/domain/help_topic.dart';
import '../../../help/presentation/context_help_button.dart';
import '../battle_layout_tokens.dart';
import '../battle_typography_tokens.dart';

class Header extends StatelessWidget {
  final BattleState state;
  final String? sceneTitle;
  final VoidCallback onToggleLog;
  final VoidCallback onPause;
  final bool isPaused;
  final VoidCallback onFastForward;
  final bool isFastForward;
  final bool allowPlayerIntervention;
  final VoidCallback? onSurrender;

  /// 验收路由(startPaused)专用:暂停态逐步推进。null = 生产挂机不渲染单步按钮。
  final VoidCallback? onStepOnce;
  const Header({
    super.key,
    required this.state,
    this.sceneTitle,
    required this.onToggleLog,
    required this.onPause,
    required this.isPaused,
    required this.onFastForward,
    required this.isFastForward,
    required this.allowPlayerIntervention,
    this.onSurrender,
    this.onStepOnce,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = BattleLayoutMetrics.resolve(MediaQuery.sizeOf(context));
    final aliveLeft = state.leftTeam.where((c) => c.isAlive).length;
    final aliveRight = state.rightTeam.where((c) => c.isAlive).length;

    return Container(
      height: metrics.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xF2191816),
        border: Border(bottom: BorderSide(color: Color(0xFF6D5940))),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              key: const ValueKey('battle_header_title_slip'),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF8A2B21), width: 2),
                  right: BorderSide(color: Color(0xFF8A2B21), width: 2),
                  bottom: BorderSide(color: Color(0xFF6D5940)),
                ),
              ),
              child: Text(
                UiStrings.battleTitle(aliveLeft, aliveRight),
                style: const TextStyle(
                  color: Color(0xFFE2CFAB),
                  fontFamily: BattleTypography.displayFamily,
                  fontFamilyFallback: BattleTypography.displayFallback,
                  fontSize: BattleTypography.t1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  fontFeatures: BattleTypography.tabularFigures,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 330,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sceneTitle != null)
                    Text(
                      sceneTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD8C29A),
                        fontFamilyFallback: BattleTypography.uiFallback,
                        fontSize: BattleTypography.t2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  Text(
                    '${UiStrings.tickPrefix} ${state.tick}',
                    style: TextStyle(
                      color: const Color(0xFFBFAE8D),
                      fontFamilyFallback: BattleTypography.uiFallback,
                      fontSize: sceneTitle == null
                          ? BattleTypography.t3
                          : BattleTypography.t5,
                      letterSpacing: 1,
                      fontFeatures: BattleTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.result != null) ...[
                  Text(
                    EnumL10n.battleResult(state.result!),
                    style: const TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                BattleModePill(
                  allowPlayerIntervention: allowPlayerIntervention,
                ),
                const SizedBox(width: 4),
                if (state.result == null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_fast_forward_toggle'),
                    icon: Icons.fast_forward,
                    label: UiStrings.fastForward,
                    tooltip: UiStrings.fastForward,
                    onPressed: onFastForward,
                    isActive: isFastForward,
                  ),
                if (state.result == null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_pause_toggle'),
                    icon: isPaused ? Icons.play_arrow : Icons.pause,
                    label: isPaused
                        ? UiStrings.battleResume
                        : UiStrings.battlePause,
                    tooltip: isPaused
                        ? UiStrings.battleResume
                        : UiStrings.battlePause,
                    onPressed: onPause,
                  ),
                if (state.result == null && onStepOnce != null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_step_once'),
                    icon: Icons.skip_next,
                    label: UiStrings.battleStepOnce,
                    tooltip: UiStrings.battleStepOnce,
                    onPressed: onStepOnce,
                  ),
                if (state.result == null && onSurrender != null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_surrender'),
                    icon: Icons.flag_outlined,
                    label: UiStrings.battleSurrender,
                    tooltip: UiStrings.battleSurrender,
                    onPressed: onSurrender,
                  ),
                BattleHeaderIconButton(
                  key: const ValueKey('battle_log_toggle'),
                  icon: Icons.list_alt,
                  label: UiStrings.battleLogShort,
                  tooltip: UiStrings.battleLog,
                  onPressed: onToggleLog,
                ),
                const SizedBox(width: 4),
                const ContextHelpButton(
                  topic: HelpTopic.combatAdvanced,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BattleHeaderIconButton extends StatelessWidget {
  const BattleHeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontFamilyFallback: BattleTypography.uiFallback,
                fontSize: BattleTypography.t5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        color: isActive
            ? WuxiaColors.resultHighlight
            : WuxiaColors.textSecondary,
        disabledColor: WuxiaColors.textMuted,
        constraints: const BoxConstraints(minWidth: 50, minHeight: 36),
        padding: EdgeInsets.zero,
        splashRadius: 18,
        style: IconButton.styleFrom(
          backgroundColor: isActive
              ? WuxiaColors.resultHighlight.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.28),
          hoverColor: WuxiaColors.resultHighlight.withValues(alpha: 0.10),
          highlightColor: WuxiaColors.resultHighlight.withValues(alpha: 0.14),
          shape: BeveledRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            side: BorderSide(
              color: isActive
                  ? WuxiaColors.resultHighlight
                  : const Color(0xFF6D5940),
            ),
          ),
        ),
      ),
    );
  }
}

class BattleModePill extends StatelessWidget {
  const BattleModePill({super.key, required this.allowPlayerIntervention});

  final bool allowPlayerIntervention;

  @override
  Widget build(BuildContext context) {
    final hint = allowPlayerIntervention
        ? UiStrings.battleAutoInterventionHint
        : UiStrings.battleAutoModeHint;
    return Tooltip(
      message: hint,
      child: Semantics(
        excludeSemantics: true,
        label: UiStrings.battleAutoMode,
        value: allowPlayerIntervention
            ? UiStrings.battleAutoIntervention
            : UiStrings.battleAutoMode,
        hint: hint,
        child: Container(
          key: const ValueKey('battle_auto_mode'),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF6D5940)),
          ),
          alignment: Alignment.center,
          child: Text(
            allowPlayerIntervention
                ? '${UiStrings.battleAutoModeShort}·${UiStrings.battleAutoInterventionShort}'
                : UiStrings.battleAutoModeShort,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontFamilyFallback: BattleTypography.uiFallback,
              fontSize: BattleTypography.t4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// H3 暂停遮罩:半透明罩 +「已暂停」+ 继续(轻触任意处或按钮恢复)。
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onResume,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                color: WuxiaColors.textPrimary,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                UiStrings.battlePausedTitle,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onResume,
                child: const Text(UiStrings.battleResume),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 日志折叠抽屉（P0-2 Task6）─────────────────────────────────────────────

/// 战斗日志抽屉：默认收起，点顶栏按钮命令式叠在最外层 Stack 右侧。
/// 实时反馈靠单位飘字/弹道/受击，日志只做事后查阅，不抢第一视觉。
class LogDrawer extends StatelessWidget {
  final BattleState state;
  final VoidCallback onClose;
  const LogDrawer({super.key, required this.state, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('battle_log_drawer'),
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0x99000000),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // 抽屉内点击不关闭
              child: Container(
                width: 280,
                color: WuxiaColors.sidebar.withValues(alpha: 0.96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: WuxiaColors.panel,
                        border: Border(
                          bottom: BorderSide(color: WuxiaColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            UiStrings.battleLog,
                            style: TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          WuxiaIconButton(
                            icon: Icons.close,
                            tooltip: UiStrings.close,
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.actionLog.isEmpty
                          ? const Center(
                              child: Text(
                                UiStrings.emptyLog,
                                style: TextStyle(
                                  color: WuxiaColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              reverse: true,
                              itemCount: state.actionLog.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (_, idx) {
                                final i = state.actionLog.length - 1 - idx;
                                final action = state.actionLog[i];
                                return Text(
                                  BattleLog.formatAction(action, state),
                                  style: const TextStyle(
                                    color: WuxiaColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
