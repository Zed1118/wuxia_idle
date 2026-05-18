import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../application/codex_providers.dart';
import 'codex_entry_detail.dart';

/// P1 #42 Phase 2 §10 P1.z BaikeScreen 第 3 tab「机制」(GDD §10.2 第 3 方式)。
///
/// 永久可见 + 未达 [tutorialStepProvider] 的条目灰显占位「待解锁」;
/// 已解锁条目 InkWell push [CodexEntryDetail]。
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
        child: CircularProgressIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (_, _) => _CodexListView(items: items, step: 0),
    );
  }
}

class _CodexListView extends StatelessWidget {
  const _CodexListView({required this.items, required this.step});

  final List<CodexListItem> items;
  final int step;

  @override
  Widget build(BuildContext context) {
    final unlocked = items.where((it) => it.indexEntry.step <= step).length;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: WuxiaColors.border),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              UiStrings.codexUnlockedHint(unlocked, items.length),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          );
        }
        final item = items[index - 1];
        final unlockedItem = item.indexEntry.step <= step && item.isLoaded;
        return _CodexListTile(item: item, unlocked: unlockedItem);
      },
    );
  }
}

class _CodexListTile extends StatelessWidget {
  const _CodexListTile({required this.item, required this.unlocked});

  final CodexListItem item;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: WuxiaColors.textMuted,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UiStrings.codexLockedTitle,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    UiStrings.codexLockedBody,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final entry = item.entry!;
    final preview = entry.paragraphs.first;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CodexEntryDetail(entry: entry),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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
                height: 1.6,
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
