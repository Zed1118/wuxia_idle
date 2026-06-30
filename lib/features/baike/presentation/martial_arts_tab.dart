import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/martial_codex_provider.dart';
import 'skill_codex_detail_screen.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 武学收录图鉴 tab(Task6):江湖见闻录第 5 tab「武学」。
///
/// watch [martialCodexProvider] → 5 来源大组(心法组带小节)。点亮行显招名、
/// 点击进 [SkillCodexDetailScreen] 回看;剪影行显「？？？」(不泄来源/解锁条件,守 §5.7),
/// 点击弹「尚未习得」snackbar。
///
/// 空态保护(§5.7):一招未点亮(groups空 或 总点亮0)→「武学无涯，尚需修习」,**不甩剪影墙**。
/// 纯展示层,不写库。
class MartialArtsTab extends ConsumerStatefulWidget {
  const MartialArtsTab({super.key});

  @override
  ConsumerState<MartialArtsTab> createState() => _MartialArtsTabState();
}

enum _ManualSection { skills, techniques }

class _MartialArtsTabState extends ConsumerState<MartialArtsTab> {
  _ManualSection _section = _ManualSection.skills;
  TechniqueTier? _tierFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kCodexMaxWidth),
        child: Column(
          children: [
            _ManualSwitch(
              selected: _section,
              onSelect: (section) => setState(() => _section = section),
            ),
            Expanded(
              child: _section == _ManualSection.skills
                  ? _SkillCodexBody(ref: ref)
                  : _TechniqueCodexBody(
                      tierFilter: _tierFilter,
                      onTierFilterChanged: (tier) =>
                          setState(() => _tierFilter = tier),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图鉴列表内容最大宽度,与藏经阁(ZangjuangeScreen)等同类典藏页对齐,
/// 宽屏(1280/1440/1920)下居中,消除右侧大片空黑。
const double _kCodexMaxWidth = 760;

class _SkillCodexBody extends StatelessWidget {
  const _SkillCodexBody({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(martialCodexProvider);
    return async.when(
      loading: () => const Center(
        child: InkLoadingIndicator(color: WuxiaColors.resultHighlight),
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

class _TechniqueCodexBody extends ConsumerWidget {
  const _TechniqueCodexBody({
    required this.tierFilter,
    required this.onTierFilterChanged,
  });

  final TechniqueTier? tierFilter;
  final ValueChanged<TechniqueTier?> onTierFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(techniqueCodexProvider(tierFilter: tierFilter));
    return async.when(
      loading: () => const Center(
        child: InkLoadingIndicator(color: WuxiaColors.resultHighlight),
      ),
      error: (e, _) => const _EmptyHint(text: UiStrings.techniqueCodexEmpty),
      data: (groups) {
        if (groups.isEmpty) {
          return const _EmptyHint(text: UiStrings.techniqueCodexEmpty);
        }
        final total = groups.fold<int>(0, (s, g) => s + g.entries.length);
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            _TechniqueTierFilter(
              selected: tierFilter,
              onSelect: onTierFilterChanged,
            ),
            const SizedBox(height: 12),
            Text(
              UiStrings.techniqueCodexProgress(total),
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 13,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final group in groups) ...[
              _TechniqueGroupSection(group: group),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _TechniqueGroupSection extends StatelessWidget {
  const _TechniqueGroupSection({required this.group});

  final TechniqueCodexGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            EnumL10n.techniqueTier(group.tier),
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final entry in group.entries) _TechniqueRow(entry: entry),
        const SizedBox(height: 8),
        const Divider(height: 1, color: WuxiaColors.border),
      ],
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({required this.entry});

  final TechniqueCodexEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TechniqueCodexDetailScreen(entry: entry),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.def.name,
                    style: const TextStyle(
                      color: WuxiaColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    UiStrings.techniqueCodexRowMeta(
                      EnumL10n.school(entry.def.school),
                      EnumL10n.realmTier(entry.requiredRealmTier),
                    ),
                    style: const TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                  group.litCount,
                  group.totalCount,
                ),
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
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
            entry.isLit ? _LitRow(entry: entry) : const _SilhouetteRow(),
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

/// 剪影行:只显「？？？」,绝不泄来源/解锁条件(§5.7)。点击弹「尚未习得」。
class _SilhouetteRow extends StatelessWidget {
  const _SilhouetteRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(UiStrings.skillCodexNotMet))),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: WuxiaColors.textMuted, size: 16),
            SizedBox(width: 8),
            Text(
              UiStrings.skillCodexLocked,
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

class _ManualSwitch extends StatelessWidget {
  const _ManualSwitch({required this.selected, required this.onSelect});

  final _ManualSection selected;
  final ValueChanged<_ManualSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
      child: Row(
        children: [
          _ToggleChip(
            label: UiStrings.skillCodexSectionSkills,
            active: selected == _ManualSection.skills,
            onTap: () => onSelect(_ManualSection.skills),
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: UiStrings.skillCodexSectionTechniques,
            active: selected == _ManualSection.techniques,
            onTap: () => onSelect(_ManualSection.techniques),
          ),
        ],
      ),
    );
  }
}

class _TechniqueTierFilter extends StatelessWidget {
  const _TechniqueTierFilter({required this.selected, required this.onSelect});

  final TechniqueTier? selected;
  final ValueChanged<TechniqueTier?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToggleChip(
            label: UiStrings.techniqueCodexFilterAll,
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final tier in TechniqueTier.values) ...[
            const SizedBox(width: 8),
            _ToggleChip(
              label: EnumL10n.techniqueTier(tier),
              active: selected == tier,
              onTap: () => onSelect(tier),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? WuxiaColors.resultHighlight.withValues(alpha: 0.18)
              : WuxiaColors.panel,
          border: Border.all(
            color: active ? WuxiaColors.resultHighlight : WuxiaColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? WuxiaColors.resultHighlight : WuxiaColors.textMuted,
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class TechniqueCodexDetailScreen extends StatelessWidget {
  const TechniqueCodexDetailScreen({super.key, required this.entry});

  final TechniqueCodexEntry entry;

  @override
  Widget build(BuildContext context) {
    final source = entry.def.acquireSourceTags.isEmpty
        ? UiStrings.codexUnknownOrPending
        : entry.def.acquireSourceTags
              .map(UiStrings.techniqueCodexSourceTag)
              .join(UiStrings.codexValueSeparator);
    final skillNames = entry.skills.isEmpty
        ? UiStrings.codexUnknownOrPending
        : entry.skills.map((s) => s.name).join(UiStrings.codexValueSeparator);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        foregroundColor: WuxiaColors.resultHighlight,
        title: const Text(UiStrings.techniqueCodexDetailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.def.name,
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.def.description,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              _DetailLine(
                label: UiStrings.techniqueCodexTier,
                value: EnumL10n.techniqueTier(entry.def.tier),
              ),
              _DetailLine(
                label: UiStrings.techniqueCodexSchool,
                value: EnumL10n.school(entry.def.school),
              ),
              _DetailLine(
                label: UiStrings.techniqueCodexRealmRequirement,
                value: UiStrings.techniqueCodexRealmRequirementValue(
                  EnumL10n.realmTier(entry.requiredRealmTier),
                ),
              ),
              _DetailLine(label: UiStrings.techniqueCodexSource, value: source),
              _DetailLine(
                label: UiStrings.techniqueCodexSkills,
                value: skillNames,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
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
