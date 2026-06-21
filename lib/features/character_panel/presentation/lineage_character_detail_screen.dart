import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../battle/domain/enum_localizations.dart';

/// 门人档案（门派谱1.1 Task3）。
///
/// 祖师 / 弟子复用同一屏，按 [Character.isFounder] 分支：
///   - 祖师：纪事显「开派太祖」+ 「祖师恩泽」buff 段；
///   - 弟子：纪事按 lineageRole 反查拜入关卡，显「江湖 N 年，过「关卡」拜入」。
///
/// 纯展示层（不改数值/平衡），无中文字面量（全走 [UiStrings]/[EnumL10n]）。
class LineageCharacterDetailScreen extends ConsumerWidget {
  const LineageCharacterDetailScreen({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.background,
        title: const Text(UiStrings.lineageCharacterDetailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(character: character),
              const SizedBox(height: 16),
              _DeedsSection(character: character),
              const SizedBox(height: 16),
              _AttributesSection(character: character),
              _MainTechniqueSection(character: character),
              _HeritageSection(character: character),
              if (character.isFounder) ...[
                const SizedBox(height: 16),
                const _FounderBuffSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 主修段：mainTechniqueId 是 Isar 实例 id，经 [techniqueByIdProvider] 取
/// [Technique] → defId → [GameRepository.techniqueDefs] 名（沿 character_panel
/// 既有解析链）。无主修 / 加载中 / 解析不到名时整段隐藏，不显空卡。
class _MainTechniqueSection extends ConsumerWidget {
  const _MainTechniqueSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = character.mainTechniqueId;
    if (id == null) return const SizedBox.shrink();
    final async = ref.watch(techniqueByIdProvider(id));
    final name = async.maybeWhen(
      data: (tech) {
        if (tech == null || !GameRepository.isLoaded) return null;
        return GameRepository.instance.techniqueDefs[tech.defId]?.name;
      },
      orElse: () => null,
    );
    if (name == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(UiStrings.lineageCharacterDetailMainTechnique),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 头像 80×80 + 名号 / 身份 / 境界。
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final schoolColor = character.school == null
        ? WuxiaColors.textMuted
        : WuxiaColors.schoolColor(character.school!);
    final portraitPath = character.portraitPath;
    return _PanelCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (portraitPath == null)
            Container(width: 4, height: 60, color: schoolColor)
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: schoolColor, width: 1),
                color: WuxiaColors.avatarFill,
              ),
              child: Image.asset(
                portraitPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: WuxiaColors.avatarFill),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  EnumL10n.lineageRole(character.lineageRole),
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 13,
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

/// 纪事段：祖师显「开派太祖」（单代恒为太祖，多代索引透传留 Phase 5+）；
/// 弟子按 lineageRole 反查拜入关卡名，反查不到只显年份（不杜撰关卡）。
class _DeedsSection extends StatelessWidget {
  const _DeedsSection({required this.character});

  final Character character;

  String _deedsText() {
    if (character.isFounder) {
      return UiStrings.lineageCharacterDetailFounderGen(1);
    }
    final stageName = _resolveJoinStageName();
    if (stageName == null) {
      return UiStrings.lineageCharacterDetailJoinedYearOnly(
        character.birthInGameYear,
      );
    }
    return UiStrings.lineageCharacterDetailJoinedAt(
      character.birthInGameYear,
      stageName,
    );
  }

  /// 按 lineageRole 反查拜入关卡名。未加载 / 无匹配 / 关卡名缺失时返回 null。
  String? _resolveJoinStageName() {
    if (!GameRepository.isLoaded) return null;
    final joins = GameRepository.instance.numbers.lineageOnboarding.discipleJoins;
    DiscipleJoinDef? def;
    for (final j in joins) {
      if (j.role == character.lineageRole) {
        def = j;
        break;
      }
    }
    if (def == null) return null;
    return GameRepository.instance.stageDefs[def.stageId]?.name;
  }

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineageCharacterDetailDeeds),
          const SizedBox(height: 8),
          Text(
            _deedsText(),
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 资质段：四项属性（根骨 / 悟性 / 身法 / 机缘）。
class _AttributesSection extends StatelessWidget {
  const _AttributesSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final a = character.attributes;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineageCharacterDetailAttributes),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _AttrChip('${UiStrings.attrConstitution} ${a.constitution}'),
              _AttrChip('${UiStrings.attrEnlightenment} ${a.enlightenment}'),
              _AttrChip('${UiStrings.attrAgility} ${a.agility}'),
              _AttrChip('${UiStrings.attrFortune} ${a.fortune}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 13),
    );
  }
}

/// 所持师承遗物段：watch [allEquipmentsProvider]，过滤本角色所持的师承遗物。
/// 无任何遗物（含加载中 / 出错）时整段隐藏。
class _HeritageSection extends ConsumerWidget {
  const _HeritageSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allEquipmentsProvider);
    final owned = async.maybeWhen(
      data: (list) => list
          .where(
            (e) => e.isLineageHeritage && e.ownerCharacterId == character.id,
          )
          .toList(),
      orElse: () => const <Equipment>[],
    );
    if (owned.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(UiStrings.lineageCharacterDetailHeritage),
            const SizedBox(height: 8),
            for (var i = 0; i < owned.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _HeritageRow(equipment: owned[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeritageRow extends StatelessWidget {
  const _HeritageRow({required this.equipment});

  final Equipment equipment;

  String _resolveName() {
    if (!GameRepository.isLoaded) return equipment.defId;
    return GameRepository.instance.equipmentDefs[equipment.defId]?.name ??
        equipment.defId;
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = tierColorForEquipment(equipment.tier);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle),
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
        if (equipment.previousOwnerCharacterIds.length > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: WuxiaColors.panel,
              border: Border.all(color: WuxiaColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              UiStrings.ascensionMultiGenChip.replaceFirst(
                '{0}',
                '${equipment.previousOwnerCharacterIds.length + 1}',
              ),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 祖师恩泽段（仅祖师态显）。
///
/// buff 数值防御式读取：[GameRepository] 已加载且 buff active 时显真实 %，
/// 否则（widget test 无 repo）仍显段标题 + 三行（值占位 —），保证祖师态
/// 「祖师恩泽」标题恒可见、弟子态恒隐藏。纯展示，不触数值层。
class _FounderBuffSection extends StatelessWidget {
  const _FounderBuffSection();

  String _pctLabel(double v) {
    if (v == 0) return '—';
    return '+${(v * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    FounderAncestorBuff? buff;
    if (GameRepository.isLoaded) {
      final b = GameRepository.instance.numbers.founderAncestorBuff;
      if (b.isActive) buff = b;
    }
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(UiStrings.lineageCharacterDetailFounderBuff),
          const SizedBox(height: 8),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffInternalForce,
            value: _pctLabel(buff?.internalForceMaxPct ?? 0),
          ),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffMaxHp,
            value: _pctLabel(buff?.maxHpPct ?? 0),
          ),
          _BuffRow(
            label: UiStrings.lineagePanelFounderBuffCritRate,
            value: _pctLabel(buff?.critRateBonus ?? 0),
          ),
        ],
      ),
    );
  }
}

class _BuffRow extends StatelessWidget {
  const _BuffRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
