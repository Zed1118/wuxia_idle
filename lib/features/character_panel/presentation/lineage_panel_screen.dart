import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/domain/enum_localizations.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../application/lineage_info_provider.dart';

/// 师徒名单（W17 候选 E，独立 sub-screen）。
///
/// 主菜单「师徒名单」按钮进入；与 [CharacterPanelScreen] 角色级 Tab 视图
/// 互补，提供「全局关系视图」：祖师 chip / 弟子 chip / 师承遗物列表。
///
/// 预研：`docs/handoff/wuxia_phase5_master_disciple_prep_2026-05-17.md`。
class LineagePanelScreen extends ConsumerWidget {
  const LineagePanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lineageInfoProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.lineagePanelTitle),
        leading: Navigator.of(context).canPop()
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              'load error: $e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (info) => _Body(info: info),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.info});

  final LineageInfo info;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FounderSection(founder: info.founder),
          const SizedBox(height: 16),
          _DisciplesSection(disciples: info.disciples),
          const SizedBox(height: 16),
          _HeritageSection(equipments: info.heritageEquipments),
        ],
      ),
    );
  }
}

class _FounderSection extends StatelessWidget {
  const _FounderSection({required this.founder});

  final Character? founder;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(UiStrings.lineageTabLabels[0]),
          const SizedBox(height: 8),
          if (founder == null)
            const _EmptyText(UiStrings.lineagePanelNoFounder)
          else
            _CharacterChip(character: founder!),
        ],
      ),
    );
  }
}

class _DisciplesSection extends StatelessWidget {
  const _DisciplesSection({required this.disciples});

  final List<Character> disciples;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineagePanelDisciplesSection),
          const SizedBox(height: 8),
          if (disciples.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoDisciples)
          else
            for (var i = 0; i < disciples.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _CharacterChip(character: disciples[i]),
            ],
        ],
      ),
    );
  }
}

class _HeritageSection extends StatelessWidget {
  const _HeritageSection({required this.equipments});

  final List<Equipment> equipments;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(UiStrings.lineagePanelHeritageSection),
              if (equipments.isNotEmpty)
                Text(
                  UiStrings.lineagePanelHeritageCount(equipments.length),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (equipments.isEmpty)
            const _EmptyText(UiStrings.lineagePanelNoHeritage)
          else
            for (var i = 0; i < equipments.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _HeritageRow(equipment: equipments[i]),
            ],
        ],
      ),
    );
  }
}

class _CharacterChip extends StatelessWidget {
  const _CharacterChip({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WuxiaColors.avatarFill,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 28, color: schoolColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EnumL10n.realm(character.realmTier, character.realmLayer),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeritageRow extends StatelessWidget {
  const _HeritageRow({required this.equipment});

  final Equipment equipment;

  String _resolveName() {
    if (!GameRepository.isLoaded) return equipment.defId;
    final def = GameRepository.instance.equipmentDefs[equipment.defId];
    return def?.name ?? equipment.defId;
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = tierColorForEquipment(equipment.tier);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: tierColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _resolveName(),
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (equipment.enhanceLevel > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+${equipment.enhanceLevel}',
            style: TextStyle(
              color: tierColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WuxiaColors.textMuted,
        fontSize: 13,
      ),
    );
  }
}
