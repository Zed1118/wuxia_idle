import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
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

  /// 所属心法名(正向:遍历 techDefs 找含此招的心法;非心法招 null)。
  String? get _belongTechniqueName {
    if (!GameRepository.isLoaded) return null;
    if (def.source != SkillSource.technique) return null;
    for (final td in GameRepository.instance.techniqueDefs.values) {
      if (td.skillIds.contains(def.id)) return td.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final belong = _belongTechniqueName;
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
                    value: '${def.powerMultiplier}'),
                _StatLine(
                    label: UiStrings.skillCodexCost,
                    value: '${def.internalForceCost}'),
                _StatLine(
                    label: UiStrings.skillCodexCooldown,
                    value: '${def.cooldownTurns}'),
                _StatLine(
                  label: UiStrings.skillCodexSource,
                  value: labelForMartialGroupKind(martialSourceKindOf(def)),
                ),
                if (belong != null)
                  _StatLine(
                      label: UiStrings.skillCodexBelongTo, value: belong),
                _StatLine(
                  label: UiStrings.skillCodexProficiencyPrefix,
                  value: maxStage == null
                      ? UiStrings.skillCodexProficiencyNone
                      : UiStrings.cangjingProficiencyStageName(maxStage!.id),
                ),
              ],
            ),
          ),
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
          Text(label,
              style: const TextStyle(color: WuxiaUi.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
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
