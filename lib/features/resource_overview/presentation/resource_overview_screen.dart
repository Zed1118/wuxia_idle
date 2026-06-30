import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/item_source.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../application/resource_overview_providers.dart';
import '../domain/resource_overview_item.dart';

class ResourceOverviewScreen extends ConsumerWidget {
  const ResourceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resourceOverviewProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.resourceOverviewTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              UiStrings.resourceOverviewLoadFailed(e),
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (sections) => _ResourceOverviewBody(sections: sections),
        ),
      ),
    );
  }
}

class _ResourceOverviewBody extends StatelessWidget {
  const _ResourceOverviewBody({required this.sections});

  final List<ResourceOverviewSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          UiStrings.resourceOverviewIntro,
          style: TextStyle(
            color: WuxiaColors.textMuted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          SectionHeader(_categoryTitle(section.category)),
          const SizedBox(height: 4),
          if (section.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                UiStrings.resourceOverviewEmpty,
                style: TextStyle(color: WuxiaColors.textMuted),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in section.items)
                        SizedBox(
                          width: wide
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth,
                          child: _ResourceCard(item: item),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  String _categoryTitle(ResourceOverviewCategory category) {
    return switch (category) {
      ResourceOverviewCategory.currency =>
        UiStrings.resourceOverviewCategoryCurrency,
      ResourceOverviewCategory.equipmentMaterial =>
        UiStrings.resourceOverviewCategoryEquipmentMaterial,
      ResourceOverviewCategory.islandProduct =>
        UiStrings.resourceOverviewCategoryIslandProduct,
      ResourceOverviewCategory.pill => UiStrings.resourceOverviewCategoryPill,
      ResourceOverviewCategory.scroll =>
        UiStrings.resourceOverviewCategoryScroll,
    };
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.item});

  final ResourceOverviewItem item;

  @override
  Widget build(BuildContext context) {
    final usage = UiStrings.materialUsageSummary(item.usages);
    final source = UiStrings.materialSourceSummary(item.sources);
    final showSourceDetails =
        item.category != ResourceOverviewCategory.scroll &&
        item.sources.isNotEmpty;
    return PaperPanel(
      padding: const EdgeInsets.all(12),
      paperOpacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WuxiaUi.slotFill,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: WuxiaUi.ink, width: 1.5),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 22,
                  color: WuxiaUi.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      UiStrings.resourceOverviewQuantity(item.quantity),
                      style: const TextStyle(
                        color: WuxiaColors.resultHighlight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${UiStrings.resourceOverviewDirectionLabel}'
                      '${UiStrings.resourceConsumptionDirectionLabel(item.consumptionDirection)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WuxiaUi.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.usageGroups.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final group in item.usageGroups)
                  _UsageChip(label: UiStrings.resourceUsageGroupLabel(group)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _MetaLine(
            label: UiStrings.resourceOverviewUsageLabel,
            value: usage.isEmpty ? UiStrings.resourceOverviewNoUsage : usage,
          ),
          const SizedBox(height: 5),
          _MetaLine(
            label: UiStrings.resourceOverviewSourceLabel,
            value: source.isEmpty ? UiStrings.resourceOverviewNoSource : source,
          ),
          if (showSourceDetails) ...[
            const SizedBox(height: 8),
            _SourceDetails(sources: item.sources),
          ],
        ],
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  const _UsageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: WuxiaUi.qing.withValues(alpha: 0.1),
        border: Border.all(color: WuxiaUi.qing.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: WuxiaUi.qing, fontSize: 11),
      ),
    );
  }
}

class _SourceDetails extends StatelessWidget {
  const _SourceDetails({required this.sources});

  final List<ItemSource> sources;

  @override
  Widget build(BuildContext context) {
    final labels = <String>{
      for (final source in sources) UiStrings.itemSourceLabel(source),
    }..remove('');
    if (labels.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.2),
        border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: WuxiaUi.ink2,
          collapsedIconColor: WuxiaUi.muted,
          title: const Text(
            UiStrings.resourceOverviewSourceDetailTitle,
            style: TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in labels.take(6)) _UsageChip(label: label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: WuxiaColors.textMuted),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, height: 1.35),
    );
  }
}
