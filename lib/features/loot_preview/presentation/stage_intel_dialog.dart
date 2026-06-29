import 'package:flutter/material.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../injury/presentation/injury_status_view.dart';
import '../domain/drop_rumor.dart';
import 'loot_rumor_dialog.dart';

/// 战前情报弹窗（opt-in 纯查看）：关卡行 info 图标触发。
///
/// 只补行内（整备条/掉落摘要）没有的「敌阵详列 + 应对要点」，并复用
/// [LootRumorContent] 显「可能收获」。不挂关卡 onTap、不返回战斗决定，
/// 守「即拖即放立即出手」——点关卡行仍直接进战斗。
Future<void> showStageIntelDialog(
  BuildContext context, {
  required StageDef stage,
  required DropRumorTable rumorTable,
  RealmTier? currentRealm,
  List<Character> activeCharacters = const [],
}) {
  return PaperDialog.show<void>(
    context,
    title: UiStrings.prebattleIntelDialogTitle(stage.name),
    body: SingleChildScrollView(
      child: StageIntelContent(
        stage: stage,
        rumorTable: rumorTable,
        currentRealm: currentRealm,
        activeCharacters: activeCharacters,
      ),
    ),
    actions: [
      PlaqueButton(
        label: UiStrings.close,
        primary: true,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

class StageIntelContent extends StatelessWidget {
  const StageIntelContent({
    super.key,
    required this.stage,
    required this.rumorTable,
    this.currentRealm,
    this.activeCharacters = const [],
  });

  final StageDef stage;
  final DropRumorTable rumorTable;
  final RealmTier? currentRealm;
  final List<Character> activeCharacters;

  @override
  Widget build(BuildContext context) {
    final responseLines = _teamPreparationLines(
      stage.enemyTeam,
      isBossStage: stage.isBossStage,
    );
    final injuryLines = activeCharacters
        .where(InjuryStatusFormatter.hasInjury)
        .map(InjuryStatusFormatter.namedStatusLine)
        .toList(growable: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntelSection(
          title: UiStrings.prebattleIntelEnemySection,
          child: _EnemyIntelList(enemies: stage.enemyTeam),
        ),
        if (injuryLines.isNotEmpty)
          _IntelSection(
            title: UiStrings.prebattleIntelAllyConditionSection,
            child: _IntelLines(lines: injuryLines),
          ),
        if (responseLines.isNotEmpty)
          _IntelSection(
            title: UiStrings.prebattleIntelResponseSection,
            child: _IntelLines(lines: responseLines),
          ),
        _IntelSection(
          title: UiStrings.prebattleIntelRiskSection,
          child: _RiskIntel(stage: stage),
        ),
        _IntelSection(
          title: UiStrings.prebattleIntelLootSection,
          child: LootRumorContent(
            table: rumorTable,
            currentRealm: currentRealm,
          ),
        ),
      ],
    );
  }
}

class _IntelSection extends StatelessWidget {
  const _IntelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: WuxiaUi.jiang,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _IntelLines extends StatelessWidget {
  const _IntelLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final line in lines) _IntelLine(line)],
    );
  }
}

class _EnemyIntelList extends StatelessWidget {
  const _EnemyIntelList({required this.enemies});

  final List<EnemyDef> enemies;

  @override
  Widget build(BuildContext context) {
    if (enemies.isEmpty) {
      return const _IntelLine(UiStrings.prebattleIntelNoEnemy);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final enemy in enemies) _IntelLine(_enemyLine(enemy))],
    );
  }

  String _enemyLine(EnemyDef enemy) {
    final tags = <String>[
      if (enemy.isBoss) UiStrings.prebattleIntelBossTag,
      if (enemy.chargeSkillId != null) UiStrings.prebattleIntelChargeTag,
    ].join(' / ');
    return UiStrings.prebattleEnemyLine(
      enemy.name,
      EnumL10n.realm(enemy.realmTier, enemy.realmLayer),
      EnumL10n.school(enemy.school),
      tags,
    );
  }
}

class _RiskIntel extends StatelessWidget {
  const _RiskIntel({required this.stage});

  final StageDef stage;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (stage.isBossStage) UiStrings.prebattleRiskBoss,
      if (stage.enemyTeam.any((e) => e.chargeSkillId != null))
        UiStrings.prebattleRiskCharge,
      if (stage.enemyTeam.length >= 3) UiStrings.prebattleRiskOutnumbered,
    ];
    if (lines.isEmpty) lines.add(UiStrings.prebattleRiskNone);
    return _IntelLines(lines: lines);
  }
}

class _IntelLine extends StatelessWidget {
  const _IntelLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}

List<String> _teamPreparationLines(
  List<EnemyDef> enemies, {
  required bool isBossStage,
}) {
  final lines = <String>[];
  if (isBossStage) lines.add(UiStrings.prebattlePrepBoss);
  if (enemies.length >= 3) lines.add(UiStrings.prebattlePrepGroup);
  if (enemies.any((e) => e.chargeSkillId != null)) {
    lines.add(UiStrings.prebattlePrepCharge);
  }
  final schools = enemies.map((e) => e.school).toSet();
  if (schools.length == 1 && schools.isNotEmpty) {
    lines.add(
      UiStrings.prebattlePrepCounterSchool(
        EnumL10n.school(_counterSchoolFor(schools.single)),
      ),
    );
  }
  return lines;
}

TechniqueSchool _counterSchoolFor(TechniqueSchool enemySchool) {
  return switch (enemySchool) {
    TechniqueSchool.gangMeng => TechniqueSchool.lingQiao,
    TechniqueSchool.lingQiao => TechniqueSchool.yinRou,
    TechniqueSchool.yinRou => TechniqueSchool.gangMeng,
  };
}
