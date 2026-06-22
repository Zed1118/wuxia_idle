import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
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
        child: CircularProgressIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (e, _) => const _EmptyHint(text: UiStrings.encounterCodexEmpty),
      data: (groups) => _buildBody(context, groups),
    );
  }

  Widget _buildBody(BuildContext context, List<EncounterCodexGroup> groups) {
    final totalTriggered =
        groups.fold<int>(0, (s, g) => s + g.triggeredCount);
    // §5.7 空态保护:一条都没际遇 → 空提示,不渲染剪影墙。
    if (groups.isEmpty || totalTriggered == 0) {
      return const _EmptyHint(text: UiStrings.encounterCodexEmpty);
    }
    final totalEntries =
        groups.fold<int>(0, (s, g) => s + g.entries.length);

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
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _groupLabel(EncounterGroupKind kind) => switch (kind) {
      EncounterGroupKind.insight => UiStrings.encounterCodexGroupInsight,
      EncounterGroupKind.fortune => UiStrings.encounterCodexGroupFortune,
      EncounterGroupKind.festival => UiStrings.encounterCodexGroupFestival,
    };

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
                  _groupLabel(group.kind),
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
        for (final entry in group.entries)
          entry.isTriggered
              ? _TriggeredRow(entry: entry)
              : const _SilhouetteRow(),
        const SizedBox(height: 8),
        const Divider(height: 1, color: WuxiaColors.border),
      ],
    );
  }
}

/// 点亮行:显标题(标题缺省回落 def.id),点击进详情屏回看。
class _TriggeredRow extends StatelessWidget {
  const _TriggeredRow({required this.entry});

  final EncounterCodexEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.isNotEmpty ?? false)
        ? entry.title!
        : entry.def.id;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EncounterDetailScreen(def: entry.def),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: WuxiaColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 剪影行:只显「？？？」,绝不泄触发条件(§5.7)。点击弹「尚未际遇」。
class _SilhouetteRow extends StatelessWidget {
  const _SilhouetteRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.encounterCodexNotMet)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: WuxiaColors.textMuted,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              UiStrings.encounterCodexLocked,
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
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
