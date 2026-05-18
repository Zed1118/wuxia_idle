import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
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
    // 分两段:机制 (isMechanic) + lore (isLore)。entries 登记顺序已保证前 12 机制 + 后 7 lore。
    final mechanicItems = items
        .where((it) => it.indexEntry.category.isMechanic)
        .toList(growable: false);
    final loreItems = items
        .where((it) => it.indexEntry.category.isLore)
        .toList(growable: false);
    // 顶部 chip = 「已解锁 N / 8」,分子 = 当前 step 解锁的「机制档数」,分母固定 8。
    // A 组 4 补充阅读虽挂相同档但不增加分子(8 档节奏是核心叙事,见 unlockedCodexCount provider)。
    final unlockedMechanic = step.clamp(0, 8);

    // index 布局:
    //   0                                   → headerText (已解锁 N/8)
    //   1..mechanicItems.length             → 机制 tile
    //   mechanicItems.length + 1            → lore SectionHeader (若 loreItems 非空)
    //   后续                                 → lore tile
    final hasLore = loreItems.isNotEmpty;
    final loreHeaderIndex = mechanicItems.length + 1;
    final itemCount = 1 + mechanicItems.length + (hasLore ? 1 : 0) + loreItems.length;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: itemCount,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: WuxiaColors.border),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              UiStrings.codexUnlockedHint(unlockedMechanic, 8),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          );
        }
        if (index <= mechanicItems.length) {
          final item = mechanicItems[index - 1];
          final s = item.indexEntry.step ?? 0;
          final unlockedItem = s <= step && item.isLoaded;
          return _CodexListTile(item: item, unlocked: unlockedItem);
        }
        if (hasLore && index == loreHeaderIndex) {
          return const _LoreSectionHeader();
        }
        final loreIndex = index - loreHeaderIndex - 1;
        final item = loreItems[loreIndex];
        // lore 永远 unlocked;若 md 缺失(item.isLoaded == false)仍显 locked 占位(graceful)。
        return _CodexListTile(item: item, unlocked: item.isLoaded);
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

class _LoreSectionHeader extends StatelessWidget {
  const _LoreSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        UiStrings.codexLoreSectionTitle,
        style: TextStyle(
          color: WuxiaColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
