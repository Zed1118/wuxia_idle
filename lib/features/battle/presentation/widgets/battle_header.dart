import 'package:flutter/material.dart';

import '../../../../data/defs/stage_win_condition.dart';
import '../../domain/battle_log.dart';
import '../../domain/battle_state.dart';
import '../../domain/enum_localizations.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/widgets/wuxia_ui/wuxia_icon_button.dart';
import '../battle_layout_tokens.dart';
import '../battle_typography_tokens.dart';

/// surviveTicks 型胜负条件的需撑拍数；非该型（含未配 winCondition）返回 null，
/// 调用点据此整行不渲染 —— 前 20 章全是 defeatAll 型，零影响。
int? _surviveRequired(BattleState state) {
  final wc = state.winCondition;
  if (wc == null || wc.type != StageWinConditionType.surviveTicks) return null;
  return wc.surviveTicksRequired;
}

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
    final surviveRequired = _surviveRequired(state);

    return Container(
      height: metrics.headerHeight,
      padding: const EdgeInsets.only(
        left: BattleLayoutTokens.headerHorizontalPadding,
        right: BattleLayoutTokens.headerRightPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF2191816),
        border: Border(bottom: BorderSide(color: Color(0xB36D5940))),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              key: const ValueKey('battle_header_title_slip'),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              child: Text(
                UiStrings.battleTitle(aliveLeft, aliveRight),
                style: const TextStyle(
                  color: Color(0xFFE2CFAB),
                  fontFamily: BattleTypography.displayFamily,
                  fontFamilyFallback: BattleTypography.displayFallback,
                  fontSize: 28,
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
                        fontFamily: BattleTypography.displayFamily,
                        fontFamilyFallback: BattleTypography.displayFallback,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  Semantics(
                    label: '${UiStrings.tickPrefix} ${state.tick}',
                    child: const SizedBox.shrink(),
                  ),
                  // surviveTicks 型胜负条件的条件条(2026-07-29 Ch21 主线首用补)。
                  // 不配 winCondition 或 defeatAll 型时整行不渲染,前 20 章零影响。
                  if (surviveRequired case final int required)
                    Text(
                      state.tick >= required
                          ? UiStrings.surviveConditionMet(required)
                          : UiStrings.surviveConditionRemaining(
                              required,
                              required - state.tick,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: state.tick >= required
                            ? WuxiaColors.resultHighlight
                            : const Color(0xFFBFAE8D),
                        fontFamilyFallback: BattleTypography.uiFallback,
                        fontSize: BattleTypography.t5,
                        letterSpacing: 1,
                        fontWeight: state.tick >= required
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                const SizedBox(width: BattleLayoutTokens.headerSealGap),
                if (state.result == null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_fast_forward_toggle'),
                    icon: Icons.fast_forward,
                    label: isFastForward
                        ? UiStrings.battleSpeedFast
                        : UiStrings.battleSpeedNormal,
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
                BattleHeaderIconButton(
                  key: const ValueKey('battle_log_toggle'),
                  icon: Icons.list_alt,
                  label: UiStrings.battleLogShort,
                  tooltip: UiStrings.battleLog,
                  onPressed: onToggleLog,
                ),
                if (state.result == null && onSurrender != null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_surrender'),
                    icon: Icons.flag_outlined,
                    label: UiStrings.surrenderConfirmAction,
                    tooltip: UiStrings.battleSurrender,
                    onPressed: onSurrender,
                  ),
                if (state.result == null && onStepOnce != null)
                  BattleHeaderIconButton(
                    key: const ValueKey('battle_step_once'),
                    icon: Icons.skip_next,
                    label: UiStrings.battleStepOnce,
                    tooltip: UiStrings.battleStepOnce,
                    onPressed: onStepOnce,
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
      padding: const EdgeInsets.symmetric(
        horizontal: BattleLayoutTokens.headerSealGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            BattleLayoutTokens.headerSealHeight / 2 + 2,
          ),
          border: Border.all(
            color: const Color(0xFF8A704B).withValues(alpha: 0.52),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            color: isActive
                ? WuxiaColors.resultHighlight
                : const Color(0xFFCBB992),
            disabledColor: WuxiaColors.textMuted,
            constraints: const BoxConstraints(
              minWidth: BattleLayoutTokens.headerSealMinWidth,
              minHeight: BattleLayoutTokens.headerSealHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            splashRadius: 18,
            style: IconButton.styleFrom(
              backgroundColor: isActive
                  ? WuxiaColors.resultHighlight.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.22),
              hoverColor: WuxiaColors.resultHighlight.withValues(alpha: 0.10),
              highlightColor: WuxiaColors.resultHighlight.withValues(
                alpha: 0.14,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isActive
                      ? WuxiaColors.resultHighlight
                      : const Color(0xFF6D5940),
                ),
              ),
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
        child: DecoratedBox(
          key: const ValueKey('battle_auto_mode'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              BattleLayoutTokens.headerSealHeight / 2 + 2,
            ),
            border: Border.all(
              color: const Color(0xFF8A704B).withValues(alpha: 0.52),
            ),
          ),
          child: Container(
            height: BattleLayoutTokens.headerSealHeight + 4,
            constraints: const BoxConstraints(
              minWidth: BattleLayoutTokens.headerSealMinWidth + 4,
            ),
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(
                BattleLayoutTokens.headerSealHeight / 2,
              ),
              border: Border.all(color: const Color(0xFF6D5940)),
            ),
            alignment: Alignment.center,
            child: const Text(
              UiStrings.battleAutoModeShort,
              style: TextStyle(
                color: Color(0xFFCBB992),
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
