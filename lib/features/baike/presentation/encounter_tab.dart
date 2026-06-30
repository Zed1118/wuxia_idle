import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../application/encounter_codex_provider.dart';
import 'encounter_detail_screen.dart';

/// 奇遇录 tab(Task 4):江湖见闻录第 4 tab「奇缘」。
///
/// watch [encounterCodexProvider] → 分组列表。点亮行显标题、点击进
/// [EncounterDetailScreen] 回看;剪影行显「？？？」(不泄触发条件,守 §5.7),
/// 点击弹「尚未际遇」snackbar。
///
/// 空态保护(§5.7):一条都没触发(groups 空 或 总触发 0)→ 显「江湖路远，奇缘
/// 未至」空提示,**不甩剪影墙**。玩家先感受问题再给系统。
///
/// 纯展示层,不写库。
class EncounterTab extends ConsumerWidget {
  const EncounterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(encounterCodexProvider);
    return async.when(
      loading: () => const Center(
        child: InkLoadingIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (e, _) => const _EmptyHint(text: UiStrings.encounterCodexEmpty),
      data: (groups) => _buildBody(context, groups),
    );
  }

  Widget _buildBody(BuildContext context, List<EncounterCodexGroup> groups) {
    final totalTriggered = groups.fold<int>(0, (s, g) => s + g.triggeredCount);
    // §5.7 空态保护:一条都没际遇 → 空提示,不渲染剪影墙。
    if (groups.isEmpty || totalTriggered == 0) {
      return const _EmptyHint(text: UiStrings.encounterCodexEmpty);
    }
    final totalEntries = groups.fold<int>(0, (s, g) => s + g.entries.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          UiStrings.encounterCodexProgress(totalTriggered, totalEntries),
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final g in groups) ...[
          _GroupSection(group: g),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});

  final EncounterCodexGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labelForEncounterGroupKind(group.kind),
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                UiStrings.encounterCodexGroupProgress(
                  group.triggeredCount,
                  group.entries.length,
                ),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        for (final entry in group.entries) ...[
          entry.isTriggered
              ? _TriggeredRow(
                  entry: entry,
                  groupLabel: labelForEncounterGroupKind(group.kind),
                )
              : _SilhouetteRow(
                  groupLabel: labelForEncounterGroupKind(group.kind),
                ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// 点亮行:显标题(标题缺省回落 def.id),点击进详情屏回看。
class _TriggeredRow extends StatelessWidget {
  const _TriggeredRow({required this.entry, required this.groupLabel});

  final EncounterCodexEntry entry;
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.isNotEmpty ?? false)
        ? entry.title!
        : entry.def.id;
    return _EncounterNoteCard(
      enabled: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EncounterDetailScreen(def: entry.def),
        ),
      ),
      leading: const _NoteGlyph(icon: Icons.receipt_long_outlined),
      eyebrow: UiStrings.encounterCodexNoteLabel,
      groupLabel: groupLabel,
      status: UiStrings.encounterCodexTriggeredStatus,
      child: Text(
        title,
        style: const TextStyle(
          color: WuxiaColors.resultHighlight,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EncounterNoteCard extends StatelessWidget {
  const _EncounterNoteCard({
    required this.enabled,
    required this.leading,
    required this.eyebrow,
    required this.groupLabel,
    required this.status,
    required this.child,
    this.onTap,
  });

  final bool enabled;
  final Widget leading;
  final String eyebrow;
  final String groupLabel;
  final String status;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled ? WuxiaColors.inkPanelEdge : WuxiaColors.border;
    final fillColor = enabled ? WuxiaColors.inkPanelTop : WuxiaColors.panel;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            eyebrow,
                            style: TextStyle(
                              color: enabled
                                  ? WuxiaColors.resultHighlight
                                  : WuxiaColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            groupLabel,
                            style: const TextStyle(
                              color: WuxiaColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      child,
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  enabled ? Icons.chevron_right : Icons.help_outline,
                  color: WuxiaColors.textMuted,
                  size: enabled ? 18 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 剪影行:只显「？？？」,绝不泄触发条件(§5.7)。点击弹「尚未际遇」。
class _SilhouetteRow extends StatelessWidget {
  const _SilhouetteRow({required this.groupLabel});

  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    return _EncounterNoteCard(
      enabled: false,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.encounterCodexNotMet)),
      ),
      leading: const _NoteGlyph(icon: Icons.help_outline, muted: true),
      eyebrow: UiStrings.encounterCodexNoteLabel,
      groupLabel: groupLabel,
      status: UiStrings.encounterCodexLockedStatus,
      child: const Text(
        UiStrings.encounterCodexLocked,
        style: TextStyle(
          color: WuxiaColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NoteGlyph extends StatelessWidget {
  const _NoteGlyph({required this.icon, this.muted = false});

  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 44,
      decoration: BoxDecoration(
        color: muted ? WuxiaColors.sidebar : WuxiaUi.paper.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: muted ? WuxiaColors.border : WuxiaUi.gold),
      ),
      child: Icon(
        icon,
        size: 19,
        // paper-text-audit: allow muted branch renders on dark sidebar fill
        color: muted ? WuxiaColors.textMuted : WuxiaUi.gold,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
