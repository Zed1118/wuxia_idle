import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../application/codex_providers.dart';
import '../domain/codex_category.dart';
import 'codex_entry_detail.dart';

/// P1 #42 Phase 2 §10 P1.z BaikeScreen 第 3 tab「机制」(GDD §10.2 第 3 方式)。
///
/// 永久可见。**P2 扩段后**结构分两段:
/// - **机制段**(8 档 + 4 A 组补充阅读 = 12 条):未达 tutorialStep 灰显「待解锁」+
///   锁图标 + 解锁后 InkWell push [CodexEntryDetail]
/// - **江湖背景段**(7 lore):永久可查(GDD §10.2),无 gating,直接 push detail
///
/// 顶部 chip 分母固定 8(8 档机制解锁节奏),lore 不计入分子分母。
class CodexTab extends ConsumerWidget {
  const CodexTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(codexListItemsProvider);
    if (items.isEmpty) {
      return const _EmptyHint(text: UiStrings.baikeCodexEmpty);
    }
    final asyncStep = ref.watch(currentTutorialStepProvider);
    return asyncStep.when(
      data: (step) => _CodexListView(items: items, step: step),
      loading: () => const Center(
        child: InkLoadingIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (_, _) => _CodexListView(items: items, step: 0),
    );
  }
}

class _CodexListView extends ConsumerWidget {
  const _CodexListView({required this.items, required this.step});

  final List<CodexListItem> items;
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 分两段:机制 (isMechanic) + lore (isLore)。entries 登记顺序已保证前 12 机制 + 后 7 lore。
    final mechanicItems = items
        .where((it) => it.indexEntry.category.isMechanic)
        .toList(growable: false);
    final loreItems = items
        .where((it) => it.indexEntry.category.isLore)
        .toList(growable: false);
    // 顶部 chip = 「已解锁 N / 8」,分子走 [unlockedCodexCountProvider](派生于 tutorialStep clamp [0,8]);
    // loading/error fallback 用 inline step.clamp 保旧行为不破。A 组 4 补充阅读不计入分子。
    final unlockedMechanic =
        ref.watch(unlockedCodexCountProvider).value ?? step.clamp(0, 8);

    final hasLore = loreItems.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _ArchiveProgressBanner(unlocked: unlockedMechanic),
        const SizedBox(height: 14),
        const _ArchiveSectionHeader(
          title: UiStrings.codexMechanicSectionTitle,
          subtitle: UiStrings.codexMechanicSectionSubtitle,
        ),
        const SizedBox(height: 8),
        for (final item in mechanicItems) ...[
          _CodexListTile(
            item: item,
            unlocked: (item.indexEntry.step ?? 0) <= step && item.isLoaded,
          ),
          const SizedBox(height: 10),
        ],
        if (hasLore) ...[
          const SizedBox(height: 14),
          const _ArchiveSectionHeader(
            title: UiStrings.codexLoreSectionTitle,
            subtitle: UiStrings.codexLoreSectionSubtitle,
            progress: UiStrings.codexLoreVolumeLabel,
          ),
          const SizedBox(height: 8),
          for (final item in loreItems) ...[
            _CodexListTile(item: item, unlocked: item.isLoaded),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _ArchiveProgressBanner extends StatelessWidget {
  const _ArchiveProgressBanner({required this.unlocked});

  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.inkPanelBottom,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.inkPanelEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: WuxiaColors.resultHighlight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                UiStrings.codexUnlockedHint(unlocked, 8),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveSectionHeader extends StatelessWidget {
  const _ArchiveSectionHeader({
    required this.title,
    required this.subtitle,
    this.progress,
  });

  final String title;
  final String subtitle;
  final String? progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: WuxiaUi.jiang,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (progress != null)
          Text(
            progress!,
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _CodexListTile extends StatelessWidget {
  const _CodexListTile({required this.item, required this.unlocked});

  final CodexListItem item;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final volumeLabel = item.indexEntry.category.isLore
        ? UiStrings.codexLoreVolumeLabel
        : UiStrings.codexMechanicVolumeLabel(item.indexEntry.step ?? 0);
    if (!unlocked) {
      return _ArchiveCard(
        enabled: false,
        leading: const _ArchiveGlyph(icon: Icons.lock_outline, muted: true),
        label: volumeLabel,
        status: UiStrings.codexLockedStatus,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiStrings.codexLockedTitle,
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              UiStrings.codexLockedBody,
              style: TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }
    final entry = item.entry!;
    final preview = entry.paragraphs.first;
    return _ArchiveCard(
      enabled: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CodexEntryDetail(entry: entry)),
      ),
      leading: _ArchiveGlyph(
        icon: item.indexEntry.category.isLore
            ? Icons.auto_stories_outlined
            : Icons.article_outlined,
      ),
      label: volumeLabel,
      status: UiStrings.codexUnlockedStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.enabled,
    required this.leading,
    required this.label,
    required this.status,
    required this.child,
    this.onTap,
  });

  final bool enabled;
  final Widget leading;
  final String label;
  final String status;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled ? WuxiaColors.inkPanelEdge : WuxiaColors.border;
    final fillColor = enabled ? WuxiaColors.inkPanelTop : WuxiaColors.panel;
    return Semantics(
      button: enabled,
      enabled: enabled,
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
                Expanded(child: child),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled
                            ? WuxiaColors.resultHighlight
                            : WuxiaColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.chevron_right,
                        color: WuxiaColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveGlyph extends StatelessWidget {
  const _ArchiveGlyph({required this.icon, this.muted = false});

  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 48,
      decoration: BoxDecoration(
        color: muted ? WuxiaColors.sidebar : WuxiaUi.paper.withAlpha(28),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: muted ? WuxiaColors.border : WuxiaUi.gold,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
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
