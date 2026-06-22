import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/martial_codex_provider.dart';
import 'skill_codex_detail_screen.dart';

/// 武学收录图鉴 tab(Task6):江湖见闻录第 5 tab「武学」。
///
/// watch [martialCodexProvider] → 5 来源大组(心法组带小节)。点亮行显招名、
/// 点击进 [SkillCodexDetailScreen] 回看;剪影行显「？？？」(不泄来源/解锁条件,守 §5.7),
/// 点击弹「尚未习得」snackbar。
///
/// 空态保护(§5.7):一招未点亮(groups空 或 总点亮0)→「武学无涯，尚需修习」,**不甩剪影墙**。
/// 纯展示层,不写库。
class MartialArtsTab extends ConsumerWidget {
  const MartialArtsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(martialCodexProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (e, _) => const _EmptyHint(text: UiStrings.skillCodexEmpty),
      data: (groups) => _buildBody(context, groups),
    );
  }

  Widget _buildBody(BuildContext context, List<MartialCodexGroup> groups) {
    final totalLit = groups.fold<int>(0, (s, g) => s + g.litCount);
    if (groups.isEmpty || totalLit == 0) {
      return const _EmptyHint(text: UiStrings.skillCodexEmpty);
    }
    final totalEntries = groups.fold<int>(0, (s, g) => s + g.totalCount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          UiStrings.skillCodexProgress(totalLit, totalEntries),
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

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});
  final MartialCodexGroup group;

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
                  labelForMartialGroupKind(group.kind),
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                UiStrings.skillCodexGroupProgress(
                    group.litCount, group.totalCount),
                style: const TextStyle(
                    color: WuxiaColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        for (final sub in group.subGroups) ...[
          if (sub.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                sub.label!,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (final entry in sub.entries)
            entry.isLit
                ? _LitRow(entry: entry)
                : const _SilhouetteRow(),
        ],
        const SizedBox(height: 8),
        const Divider(height: 1, color: WuxiaColors.border),
      ],
    );
  }
}

/// 点亮行:显招名,点击进详情屏回看。
class _LitRow extends StatelessWidget {
  const _LitRow({required this.entry});
  final MartialCodexEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SkillCodexDetailScreen(def: entry.def, maxStage: entry.maxStage),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.def.name,
                style: const TextStyle(
                    color: WuxiaColors.textSecondary, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: WuxiaColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 剪影行:只显「？？？」,绝不泄来源/解锁条件(§5.7)。点击弹「尚未习得」。
class _SilhouetteRow extends StatelessWidget {
  const _SilhouetteRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.skillCodexNotMet)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: WuxiaColors.textMuted, size: 16),
            SizedBox(width: 8),
            Text(
              UiStrings.skillCodexLocked,
              style: TextStyle(
                  color: WuxiaColors.textMuted, fontSize: 13, letterSpacing: 1),
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
              color: WuxiaColors.textMuted, fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
