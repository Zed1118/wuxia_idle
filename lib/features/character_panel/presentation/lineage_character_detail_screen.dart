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
import '../../battle/domain/enum_localizations.dart';
import 'lineage_widgets.dart';

/// 门人档案（门派谱1.1 Task3）。
///
/// 祖师 / 弟子复用同一屏，按 [Character.isFounder] 分支：
///   - 祖师：纪事显「开派太祖」+ 「祖师恩泽」buff 段；
///   - 弟子：纪事按 lineageRole 反查拜入关卡，显「江湖 N 年，过「关卡」拜入」。
///
/// 纯展示层（不改数值/平衡），无中文字面量（全走 [UiStrings]/[EnumL10n]）。
///
/// [generationIndex] 为该角色所属世代序号（1=太祖代），祖师纪事据此区分
/// 「开派太祖」(1) 与「第 N 代掌门」(N>1)。默认 1 兼容单代 + 既有调用点。
class LineageCharacterDetailScreen extends ConsumerWidget {
  const LineageCharacterDetailScreen({
    super.key,
    required this.character,
    this.generationIndex = 1,
  });

  final Character character;
  final int generationIndex;

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
              _DeedsSection(
                character: character,
                generationIndex: generationIndex,
              ),
              const SizedBox(height: 16),
              _AttributesSection(character: character),
              _ConditionSection(character: character),
              _MainTechniqueSection(character: character),
              _HeritageSection(character: character),
              if (character.isFounder &&
                  GameRepository.isLoaded &&
                  GameRepository
                      .instance
                      .numbers
                      .founderAncestorBuff
                      .isActive) ...[
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
      child: LineagePanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LineageSectionTitle(
              UiStrings.lineageCharacterDetailMainTechnique,
            ),
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
    return LineagePanelCard(
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

/// 纪事段：祖师按 [generationIndex] 显「开派太祖」(1) / 「第 N 代掌门」(N>1)；
/// 弟子按 lineageRole 反查拜入关卡名，反查不到只显年份（不杜撰关卡）。
class _DeedsSection extends StatelessWidget {
  const _DeedsSection({required this.character, required this.generationIndex});

  final Character character;
  final int generationIndex;

  String _deedsText() {
    if (character.isFounder) {
      return UiStrings.lineageCharacterDetailFounderGen(generationIndex);
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
    final joins =
        GameRepository.instance.numbers.lineageOnboarding.discipleJoins;
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
    return LineagePanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LineageSectionTitle(UiStrings.lineageCharacterDetailDeeds),
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
    return LineagePanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LineageSectionTitle(UiStrings.lineageCharacterDetailAttributes),
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

/// 状态段（Task 9 + 心魔余毒表现强化）：展示心魔余毒 / 重伤 / 轻伤。
///
/// - 心魔余毒（innerDemonResidueHoursRemaining > 0）：「心魔余毒」chip +
///   来源 / 影响 / 闭关清解路径
/// - 重伤（injuryHoursRemaining > 0）：「重伤」chip + 「内伤未愈 · 调息 Nh」提示
/// - 轻伤（lightInjuryStacks > 0）：「带伤×N」chip
/// - 三者均无 → 整段隐藏
class _ConditionSection extends StatelessWidget {
  const _ConditionSection({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final hasResidue = character.innerDemonResidueHoursRemaining > 0;
    final hasHeavy = character.injuryHoursRemaining > 0;
    final hasLight = character.lightInjuryStacks > 0;
    if (!hasResidue && !hasHeavy && !hasLight) return const SizedBox.shrink();
    final residueDebuff = GameRepository.isLoaded
        ? GameRepository.instance.numbers.innerDemon.residueDebuff
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LineagePanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LineageSectionTitle(
              UiStrings.lineageCharacterDetailConditionTitle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (hasResidue) ...[
                  const _ConditionChip(
                    label: UiStrings.conditionInnerDemonResidueLabel,
                    color: WuxiaColors.hpLow,
                  ),
                  const _ConditionChip(
                    label: UiStrings.conditionInnerDemonResidueSource,
                    color: WuxiaColors.textSecondary,
                  ),
                  if (residueDebuff != null)
                    _ConditionChip(
                      label: UiStrings.conditionInnerDemonResidueEffect(
                        battleOutputPenaltyPct: _penaltyPct(
                          residueDebuff.battleOutputMultiplier,
                        ),
                        internalForceRecoveryPenaltyPct: _penaltyPct(
                          residueDebuff.internalForceRecoveryMultiplier,
                        ),
                      ),
                      color: WuxiaColors.textSecondary,
                    ),
                  _ConditionChip(
                    label: UiStrings.conditionInnerDemonResidueRecovery(
                      character.innerDemonResidueHoursRemaining,
                    ),
                    color: WuxiaColors.textSecondary,
                  ),
                ],
                if (hasHeavy) ...[
                  const _ConditionChip(
                    label: UiStrings.injuryHeavyLabel,
                    color: WuxiaColors.hpLow,
                  ),
                  _ConditionChip(
                    label: UiStrings.injuryRecoveryHint(
                      character.injuryHoursRemaining,
                    ),
                    color: WuxiaColors.textSecondary,
                  ),
                ],
                if (hasLight)
                  _ConditionChip(
                    label:
                        '${UiStrings.injuryLightLabel}×${character.lightInjuryStacks}',
                    color: WuxiaColors.textSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static int _penaltyPct(double multiplier) =>
      ((1.0 - multiplier) * 100).round();
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(color: color, fontSize: 13));
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
      child: LineagePanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LineageSectionTitle(UiStrings.lineageCharacterDetailHeritage),
            const SizedBox(height: 8),
            for (var i = 0; i < owned.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              LineageHeritageRow(equipment: owned[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// 祖师恩泽段（仅祖师态 + buff active 时显，gate 在 build 层与 sibling
/// [lineage_panel_screen] 一致）。本段渲染时 [GameRepository] 必已加载且
/// buff active，故直读真实 %。纯展示，不触数值层。
class _FounderBuffSection extends StatelessWidget {
  const _FounderBuffSection();

  @override
  Widget build(BuildContext context) {
    FounderAncestorBuff? buff;
    if (GameRepository.isLoaded) {
      final b = GameRepository.instance.numbers.founderAncestorBuff;
      if (b.isActive) buff = b;
    }
    return LineagePanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LineageSectionTitle(
            UiStrings.lineageCharacterDetailFounderBuff,
          ),
          const SizedBox(height: 8),
          LineageBuffRow(
            label: UiStrings.lineagePanelFounderBuffInternalForce,
            value: lineagePctLabel(buff?.internalForceMaxPct ?? 0),
          ),
          LineageBuffRow(
            label: UiStrings.lineagePanelFounderBuffMaxHp,
            value: lineagePctLabel(buff?.maxHpPct ?? 0),
          ),
          LineageBuffRow(
            label: UiStrings.lineagePanelFounderBuffCritRate,
            value: lineagePctLabel(buff?.critRateBonus ?? 0),
          ),
        ],
      ),
    );
  }
}
