import 'package:flutter/material.dart';

import '../../domain/battle_log.dart';
import '../../domain/battle_state.dart';
import '../../domain/enum_localizations.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';
import '../../../help/domain/help_topic.dart';
import '../../../help/presentation/context_help_button.dart';

class Header extends StatelessWidget {
  final BattleState state;
  final VoidCallback onToggleLog;
  final VoidCallback onPause;
  final bool isPaused;
  final VoidCallback? onSurrender;

  /// 验收路由(startPaused)专用:暂停态逐步推进。null = 生产挂机不渲染单步按钮。
  final VoidCallback? onStepOnce;
  const Header({
    super.key,
    required this.state,
    required this.onToggleLog,
    required this.onPause,
    required this.isPaused,
    this.onSurrender,
    this.onStepOnce,
  });

  @override
  Widget build(BuildContext context) {
    final aliveLeft = state.leftTeam.where((c) => c.isAlive).length;
    final aliveRight = state.rightTeam.where((c) => c.isAlive).length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        children: [
          Text(
            UiStrings.battleTitle(aliveLeft, aliveRight),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (state.result != null) ...[
            Text(
              EnumL10n.battleResult(state.result!),
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '${UiStrings.tickPrefix} ${state.tick}',
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          if (state.result == null)
            BattleHeaderIconButton(
              key: const ValueKey('battle_pause_toggle'),
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              tooltip: isPaused
                  ? UiStrings.battleResume
                  : UiStrings.battlePause,
              onPressed: onPause,
            ),
          // 验收路由(startPaused)专用单步键:仅 onStepOnce 非空时渲染,生产挂机不出现。
          if (state.result == null && onStepOnce != null)
            BattleHeaderIconButton(
              key: const ValueKey('battle_step_once'),
              icon: Icons.skip_next,
              tooltip: UiStrings.battleStepOnce,
              onPressed: onStepOnce,
            ),
          if (state.result == null && onSurrender != null)
            BattleHeaderIconButton(
              key: const ValueKey('battle_surrender'),
              icon: Icons.flag_outlined,
              tooltip: UiStrings.battleSurrender,
              onPressed: onSurrender,
            ),
          BattleHeaderIconButton(
            key: const ValueKey('battle_log_toggle'),
            icon: Icons.list_alt,
            tooltip: UiStrings.battleLog,
            onPressed: onToggleLog,
          ),
          const SizedBox(width: 4),
          const ContextHelpButton(topic: HelpTopic.combatAdvanced, size: 20),
        ],
      ),
    );
  }
}

class BattleHeaderIconButton extends StatelessWidget {
  const BattleHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        color: WuxiaColors.textSecondary,
        disabledColor: WuxiaColors.textMuted,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        splashRadius: 18,
        style: IconButton.styleFrom(
          backgroundColor: WuxiaColors.sidebar.withValues(alpha: 0.58),
          hoverColor: WuxiaColors.resultHighlight.withValues(alpha: 0.10),
          highlightColor: WuxiaColors.resultHighlight.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: WuxiaColors.border.withValues(alpha: 0.78)),
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
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: WuxiaColors.textSecondary,
                              size: 18,
                            ),
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
