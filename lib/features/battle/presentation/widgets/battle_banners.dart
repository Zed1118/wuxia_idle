import 'package:flutter/material.dart';

import '../../domain/battle_log.dart';
import '../../domain/battle_state.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';

class HintBanner extends StatelessWidget {
  final String hint;
  const HintBanner({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: WuxiaColors.hintBannerBg,
      child: Text(
        hint,
        style: const TextStyle(color: WuxiaColors.hintBannerText, fontSize: 13),
      ),
    );
  }
}

// ─── 江湖记招提示横幅（P1 周目进化 E2）───────────────────────────────────────

class CycleHintBanner extends StatelessWidget {
  final String hint;
  const CycleHintBanner({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: WuxiaColors.cycleHintBg,
      child: Text(
        hint,
        style: const TextStyle(color: WuxiaColors.cycleHintText, fontSize: 12),
      ),
    );
  }
}

// ─── 破绽窗口指令栏提示（第六阶段 Task 5）─────────────────────────────────

/// 指令栏上方薄提示条：右队（敌方）有存活角色处于破绽窗口（staggerTicksRemaining > 0）
/// 时显示「破绽 · 该爆发了」，引导玩家拖招释放爆发技。
///
/// **只读 state**：不触碰 interveneNow / AP / 逻辑速度（红线 §5.5）。
/// 窗口关闭（所有敌方 stagger=0）后自然消失（SizedBox.shrink）。
class CoopBurstPromptBar extends StatelessWidget {
  final BattleState state;
  const CoopBurstPromptBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasBreakWindow = state.rightTeam.any(
      (e) => e.isAlive && e.staggerTicksRemaining > 0,
    );
    if (!hasBreakWindow) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('coop_burst_prompt_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.12), // 浅金底，水墨克制
        border: const Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 13,
            color: WuxiaColors.resultHighlight,
          ),
          SizedBox(width: 5),
          Text(
            UiStrings.coopBurstPrompt,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 蓄力危险条（T2）──────────────────────────────────────────────────────

/// 敌人蓄力大招时的顶部警示条。纯读 [BattleState.rightTeam]：取最临近发动
/// （[BattleCharacter.chargeTicksRemaining] 最小）的存活蓄力敌人，显示招名 + 剩余节拍，提示玩家
/// 看准时机破招。无敌人蓄力时返回 [SizedBox.shrink]（不占高度、不渲染 key）。
class DangerBar extends StatelessWidget {
  final BattleState state;
  const DangerBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    BattleCharacter? imminent;
    for (final e in state.rightTeam) {
      if (!e.isAlive || e.chargingSkill == null) continue;
      if (imminent == null ||
          e.chargeTicksRemaining < imminent.chargeTicksRemaining) {
        imminent = e;
      }
    }
    if (imminent == null) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('battle_danger_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: WuxiaColors.danger.withValues(alpha: 0.18),
        border: const Border(bottom: BorderSide(color: WuxiaColors.danger)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: WuxiaColors.danger,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              UiStrings.battleDangerCharging(
                imminent.name,
                imminent.chargingSkill!.name,
                imminent.chargeTicksRemaining,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 最近战报条（T3）──────────────────────────────────────────────────────

/// 底部常驻的最近关键战报（大招/破招/暴击/击杀），最多 3 条，最新在上。
/// 纯读 [BattleLog.recentKeyActions]；无关键战报时返回 [SizedBox.shrink]。
/// 点击整条 → [onTap]（打开完整日志抽屉）。实时反馈仍靠飘字/弹道，
/// 本条只做"刚刚发生了什么大事"的常驻速览。
class BattleReportStrip extends StatelessWidget {
  final BattleState state;
  final VoidCallback onTap;
  const BattleReportStrip({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final keys = BattleLog.recentKeyActions(state);
    if (keys.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('battle_report_strip'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            color: WuxiaColors.sidebar,
            border: Border(top: BorderSide(color: WuxiaColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 14, color: WuxiaColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < keys.length; i++)
                      Text(
                        BattleLog.formatActionCompact(keys[i], state),
                        key: ValueKey('battle_report_line_$i'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == 0
                              ? WuxiaColors.textSecondary
                              : WuxiaColors.textMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: WuxiaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
