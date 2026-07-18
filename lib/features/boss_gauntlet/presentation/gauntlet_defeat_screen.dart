import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/gauntlet_service.dart';

/// 断魂庄战败结算屏（§6.3 · #1 wiring Task 3）。战败 / 认输离庄后展示：已破精英经验 +
/// 逐弟子轻重伤摘要，底部固定「离庄」→ pop 回主菜单。settleDefeat 已由 flow 先调（删
/// 会话·发精英经验·结伤势·返还托管），本屏纯只读 [GauntletDefeatSummary]（会话已删故
/// 摘要须随结算带出，不读 provider）。深底 lineup 体例，1280×720/1440×900 一屏无溢出。
class GauntletDefeatScreen extends StatelessWidget {
  const GauntletDefeatScreen({super.key, required this.summary});

  final GauntletDefeatSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.gauntletDefeatTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(UiStrings.gauntletDefeatSection),
                        const SizedBox(height: 10),
                        const Text(
                          UiStrings.gauntletDefeatHint,
                          style: TextStyle(
                            color: WuxiaColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 精英经验行（未破精英则显未破提示）。
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: WuxiaColors.panel,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: WuxiaColors.border),
                          ),
                          child: Text(
                            summary.elitesDefeated > 0
                                ? UiStrings.gauntletDefeatEliteLine(
                                    summary.elitesDefeated,
                                    summary.eliteExpPerMember,
                                  )
                                : UiStrings.gauntletDefeatNoElite,
                            style: TextStyle(
                              color: summary.elitesDefeated > 0
                                  ? WuxiaColors.textPrimary
                                  : WuxiaColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SubLabel(UiStrings.gauntletDefeatMemberSection),
                        const SizedBox(height: 8),
                        for (final m in summary.members) ...[
                          _MemberInjuryTile(member: m),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _LeaveBar(onLeave: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}

// ── 成员伤势 tile ───────────────────────────────────────────────────────────

class _MemberInjuryTile extends StatelessWidget {
  const _MemberInjuryTile({required this.member});

  final GauntletDefeatMember member;

  @override
  Widget build(BuildContext context) {
    final heavy = member.downed;
    final tagColor = heavy ? WuxiaColors.internalForce : WuxiaColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Tag(
            heavy
                ? UiStrings.gauntletDefeatHeavyTag
                : UiStrings.gauntletDefeatLightTag,
            color: tagColor,
          ),
        ],
      ),
    );
  }
}

// ── 底部离庄栏（固定·恒可见）───────────────────────────────────────────────

class _LeaveBar extends StatelessWidget {
  const _LeaveBar({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border(top: BorderSide(color: WuxiaColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PlaqueButton(
                label: UiStrings.gauntletLeaveButton,
                primary: true,
                onTap: onLeave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 共用小组件 ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaUi.gold,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
