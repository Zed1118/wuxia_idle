import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/technique_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../features/cultivation/application/skill_proficiency_formatter.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/stage_progress_row.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/martial_codex_provider.dart';

/// 武学详情屏(Task7)。从武学图鉴 tab 点亮行推入,回看一招已习武学。
///
/// 纯同步展示(招式 name/description 是 [SkillDef] 同步字段,无 async):
/// 类型标(普攻/强力/大招) + 招名 + description + 倍率/内力/冷却 + 来源标 + 所属心法 +
/// 全队最高熟练阶([maxStage] 由 tab 算好传入,null=未曾习练)。
/// 纯只读,不读 provider / 不写库。
class SkillCodexDetailScreen extends StatelessWidget {
  const SkillCodexDetailScreen({
    super.key,
    required this.def,
    required this.maxStage,
  });

  final SkillDef def;
  final SkillProficiencyStageConfig? maxStage;

  /// 所属心法(正向:遍历 techDefs 找含此招的心法;非心法招 null)。
  TechniqueDef? get _belongTechnique {
    if (!GameRepository.isLoaded) return null;
    if (def.source != SkillSource.technique) return null;
    for (final td in GameRepository.instance.techniqueDefs.values) {
      if (td.skillIds.contains(def.id)) return td;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final belong = _belongTechnique;
    final proficiencySummary = !GameRepository.isLoaded
        ? null
        : SkillProficiencyFormatter.summarize(
            skill: def,
            uses: maxStage?.minUses ?? 0,
            cfg: GameRepository.instance.numbers.skillProficiency,
          );
    final school = def.style ?? belong?.school;
    final schoolInherited = def.style == null && belong?.school != null;
    final manualEntries = _manualEntries(
      school: school,
      schoolInherited: schoolInherited,
      proficiencySummary: proficiencySummary,
    );
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.skillCodexDetailTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: PaperPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TypeTag(label: EnumL10n.skillType(def.type)),
                const SizedBox(height: 12),
                SectionHeader(def.name),
                const SizedBox(height: 8),
                Text(
                  def.description,
                  style: const TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: 15,
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _StatLine(
                  label: UiStrings.skillCodexMultiplier,
                  value: '${def.powerMultiplier}',
                ),
                _StatLine(
                  label: UiStrings.skillCodexCost,
                  value: '${def.internalForceCost}',
                ),
                _StatLine(
                  label: UiStrings.skillCodexCooldown,
                  value: '${def.cooldownTurns}',
                ),
                _StatLine(
                  label: UiStrings.skillCodexSource,
                  value: labelForMartialGroupKind(martialSourceKindOf(def)),
                ),
                if (belong != null)
                  _StatLine(
                    label: UiStrings.skillCodexBelongTo,
                    value: belong.name,
                  ),
                _StatLine(
                  label: UiStrings.skillCodexProficiencyPrefix,
                  value: maxStage == null
                      ? UiStrings.skillCodexProficiencyNone
                      : UiStrings.cangjingProficiencyStageName(maxStage!.id),
                ),
                const SizedBox(height: 16),
                const SectionHeader(UiStrings.skillCodexManualSection),
                const SizedBox(height: 2),
                _ManualGrid(entries: manualEntries),
                if (proficiencySummary != null) ...[
                  const SizedBox(height: 16),
                  StageProgressRow(
                    title: UiStrings.skillProficiencyBestSkillTitle(def.name),
                    stageName: proficiencySummary.stageName,
                    ratio: proficiencySummary.ratio,
                    currentEffect: proficiencySummary.currentEffect,
                    nextEffect: proficiencySummary.nextEffect,
                    progressText: proficiencySummary.progressText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_ManualEntry> _manualEntries({
    required TechniqueSchool? school,
    required bool schoolInherited,
    required SkillProficiencySummary? proficiencySummary,
  }) {
    return [
      _ManualEntry(
        label: UiStrings.skillCodexSchool,
        value: school == null
            ? UiStrings.skillCodexSchoolUnknown
            : UiStrings.skillCodexSchoolValue(
                EnumL10n.school(school),
                schoolInherited,
              ),
      ),
      _ManualEntry(label: UiStrings.skillCodexInterrupt, value: _interruptText),
      _ManualEntry(
        label: UiStrings.skillCodexProficiencyBenefit,
        value: proficiencySummary == null
            ? UiStrings.skillCodexProficiencyNone
            : UiStrings.skillCodexProficiencyBenefitValue(
                proficiencySummary.currentEffect,
                proficiencySummary.nextEffect,
              ),
      ),
      _ManualEntry(
        label: UiStrings.skillCodexTypicalUse,
        value: _typicalUseText,
      ),
    ];
  }

  String get _interruptText {
    final opensWindow = def.defenseBreakPct > 0;
    if (def.canInterrupt && opensWindow) {
      return UiStrings.skillCodexInterruptCanBreakAndOpenWindow;
    }
    if (def.canInterrupt) return UiStrings.skillCodexInterruptCanBreak;
    if (opensWindow) return UiStrings.skillCodexInterruptOpenWindow;
    return UiStrings.skillCodexInterruptNone;
  }

  String get _typicalUseText {
    if (def.canInterrupt) return UiStrings.skillCodexUseInterrupt;
    return switch (def.type) {
      SkillType.ultimate when def.targetType == TargetType.aoe =>
        UiStrings.skillCodexUseAoeUltimate,
      SkillType.ultimate => UiStrings.skillCodexUseSingleUltimate,
      SkillType.powerSkill when def.targetType == TargetType.aoe =>
        UiStrings.skillCodexUseAoePower,
      SkillType.powerSkill => UiStrings.skillCodexUsePower,
      SkillType.jointSkill => UiStrings.skillCodexUseJoint,
      SkillType.normalAttack => UiStrings.skillCodexUseNormal,
    };
  }
}

class _ManualEntry {
  const _ManualEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _ManualGrid extends StatelessWidget {
  const _ManualGrid({required this.entries});

  final List<_ManualEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in entries)
              SizedBox(
                width: narrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2,
                child: _ManualTile(entry: entry),
              ),
          ],
        );
      },
    );
  }
}

class _ManualTile extends StatelessWidget {
  const _ManualTile({required this.entry});

  final _ManualEntry entry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.22),
        border: Border(
          left: BorderSide(
            color: WuxiaUi.ink.withValues(alpha: 0.46),
            width: 2,
          ),
          bottom: BorderSide(color: WuxiaUi.ink.withValues(alpha: 0.18)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.label,
              style: const TextStyle(
                color: WuxiaUi.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              entry.value,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 类型标(水墨小章):绛红描边 + 墨字。
class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: WuxiaUi.jiang, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WuxiaUi.jiang,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
