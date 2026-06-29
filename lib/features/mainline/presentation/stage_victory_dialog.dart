import 'package:flutter/material.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../battle/domain/battle_stats.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/application/equipment_source_lookup.dart';
import '../../equipment/domain/equipment_source.dart';
import '../../injury/presentation/injury_status_view.dart';
import '../../inventory/presentation/post_battle_healing_panel.dart';

typedef EquipmentDropLockHandler =
    Future<bool> Function(Equipment equipment, bool locked);

/// 主线 victory dialog(W15 #30 P3 后续 A 任务)。
///
/// 体例对齐塔 `_showVictoryDialog`,但主线 victory 此前完全无 dialog,本批新建。
/// content = drop 列表 + [AdvancementSummary](升层多角色 banner)
/// + 共鸣度晋阶 sub-row(P1.1 候选 3-a)。
/// dialog 关闭后由 caller 继续 push `NarrativeReaderScreen` 显胜利剧情。
Future<void> showStageVictoryDialog({
  required BuildContext context,
  required StageDef stage,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  String? firstClearTitle,
  String? firstClearSubtitle,
  BattleStatsSummary? stats,
  List<Character> injurySummaryCharacters = const [],
  List<Character> equipmentHintCharacters = const [],
  String? skillFragmentLine,
  EquipmentDropLockHandler? onEquipmentLockToggle,
}) async {
  // 结算 jingle:跨 tier 大境界突破响 realmAdvance(爆装备音已移到 playTreasureDropIfAny
  // 动画层 + 门槛化,2026-06-11)。
  if (advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: PaperPanel(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          paperOpacity: 0.22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stage.name} · ${UiStrings.stageVictoryTitle}',
                          style: const TextStyle(
                            color: WuxiaUi.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          UiStrings.stageVictoryReportTitle,
                          style: TextStyle(
                            color: WuxiaUi.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset(
                      WuxiaUi.sealRed,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DefaultTextStyle.merge(
                style: const TextStyle(color: WuxiaUi.ink, fontSize: 13),
                child: StageVictoryContent(
                  drops: drops,
                  advancements: advancements,
                  resonanceUpgrades: resonanceUpgrades,
                  firstClearTitle: firstClearTitle,
                  firstClearSubtitle: firstClearSubtitle,
                  stats: stats,
                  injurySummaryCharacters: injurySummaryCharacters,
                  equipmentHintCharacters: equipmentHintCharacters,
                  skillFragmentLine: skillFragmentLine,
                  onEquipmentLockToggle: onEquipmentLockToggle,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: WuxiaUi.jiang,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(UiStrings.stageVictoryConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// dialog content widget(公开便于 widget test 直接 pump,无需走 showDialog)。
class StageVictoryContent extends StatelessWidget {
  const StageVictoryContent({
    super.key,
    required this.drops,
    required this.advancements,
    this.resonanceUpgrades = const [],
    this.firstClearTitle,
    this.firstClearSubtitle,
    this.stats,
    this.injurySummaryCharacters = const [],
    this.equipmentHintCharacters = const [],
    this.skillFragmentLine,
    this.onEquipmentLockToggle,
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;
  final String? firstClearTitle;
  final String? firstClearSubtitle;
  final BattleStatsSummary? stats;
  final List<Character> injurySummaryCharacters;
  final List<Character> equipmentHintCharacters;

  /// 第七阶段批二④:残页轻提示行(掉残页未集齐时,非重仪式)。
  /// null=本场未掉残页或已走重仪式;非空时在 drop 段末尾追一行小字。
  final String? skillFragmentLine;
  final EquipmentDropLockHandler? onEquipmentLockToggle;

  @override
  Widget build(BuildContext context) {
    final didAdvance = advancements.any((e) => e.result.didAdvance);
    final didLevelUp = advancements.any((e) => e.levelUp?.didLevelUp ?? false);
    final materialItems = drops.items
        .where(
          (item) => ItemType.fromDefId(item.defId) != ItemType.techniqueScroll,
        )
        .toList(growable: false);
    final manualItems = drops.items
        .where(
          (item) => ItemType.fromDefId(item.defId) == ItemType.techniqueScroll,
        )
        .toList(growable: false);
    final hasTechniqueSection =
        manualItems.isNotEmpty || skillFragmentLine != null;
    final hasDropSection = materialItems.isNotEmpty || drops.isEmpty;
    final hasEquipmentSection =
        resonanceUpgrades.isNotEmpty || drops.equipments.isNotEmpty;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = (viewportHeight * 0.66).clamp(320.0, 620.0).toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (firstClearTitle != null) ...[
                FirstClearBanner(
                  title: firstClearTitle!,
                  subtitle:
                      firstClearSubtitle ??
                      UiStrings.firstClearCeremonySubtitle,
                ),
                const SizedBox(height: 12),
              ],
              if (didAdvance || didLevelUp)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryExperienceSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (didAdvance) AdvancementSummary(entries: advancements),
                      if (didAdvance && didLevelUp) const SizedBox(height: 10),
                      // 第八阶段 D·角色等级 Lv 升级反馈(与境界突破并列独立一格)。
                      if (didLevelUp) LevelUpSummary(entries: advancements),
                    ],
                  ),
                ),
              if (hasEquipmentSection)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryEquipmentSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resonanceUpgrades.isNotEmpty)
                        ResonanceUpgradeBanner(notices: resonanceUpgrades),
                      if (resonanceUpgrades.isNotEmpty &&
                          drops.equipments.isNotEmpty)
                        const SizedBox(height: 10),
                      if (drops.equipments.isNotEmpty)
                        for (final eq in drops.equipments)
                          _EquipmentDropRow(
                            equipment: eq,
                            hintCharacters: equipmentHintCharacters,
                            onLockToggle: onEquipmentLockToggle,
                          ),
                    ],
                  ),
                ),
              if (hasDropSection)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryDropLabel,
                  child: drops.isEmpty
                      ? const _VictoryMutedLine(UiStrings.stageVictoryNoDrop)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in materialItems)
                              _VictoryItemRow(item: item),
                          ],
                        ),
                ),
              if (hasTechniqueSection)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryManualSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in manualItems)
                        _VictoryItemRow(item: item),
                      // 第七阶段批二④:残页轻提示行(掉残页未集齐 → 卷宗单列)。
                      // skillFragmentLine 自带「得残页 · …」前缀,不再加列表点。
                      if (skillFragmentLine != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            skillFragmentLine!,
                            style: const TextStyle(
                              color: WuxiaUi.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (stats != null)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryBattleSection,
                  child: Text(
                    UiStrings.battleSummary(
                      stats!.totalDamage,
                      stats!.critCount,
                      stats!.totalTicks,
                    ),
                    style: const TextStyle(
                      color: WuxiaUi.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (injurySummaryCharacters.isNotEmpty)
                _VictoryReportSection(
                  title: UiStrings.stageVictoryInjurySection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InjurySummaryLines(characters: injurySummaryCharacters),
                      const PostBattleHealingPanel(),
                    ],
                  ),
                )
              else
                const PostBattleHealingPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictoryReportSection extends StatelessWidget {
  const _VictoryReportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [SectionHeader(title), child],
      ),
    );
  }
}

class _VictoryMutedLine extends StatelessWidget {
  const _VictoryMutedLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: const TextStyle(color: WuxiaUi.muted, fontSize: 13),
      ),
    );
  }
}

class _VictoryItemRow extends StatelessWidget {
  const _VictoryItemRow({required this.item});

  final ItemDropResult item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        '· ${EnumL10n.itemType(ItemType.fromDefId(item.defId))} '
        '×${item.quantity}',
        style: const TextStyle(color: WuxiaUi.ink2, fontSize: 13),
      ),
    );
  }
}

class _InjurySummaryLines extends StatelessWidget {
  const _InjurySummaryLines({required this.characters});

  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final injured = characters
        .where(InjuryStatusFormatter.hasInjury)
        .map(InjuryStatusFormatter.namedStatusLine)
        .toList(growable: false);
    final text = injured.isEmpty
        ? UiStrings.injuryBattleSummaryNone
        : injured.join('\n');
    return Text(
      '${UiStrings.injuryBattleSummaryTitle}$text',
      style: TextStyle(
        color: injured.isEmpty ? WuxiaColors.textMuted : WuxiaColors.hpLow,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

class FirstClearBanner extends StatelessWidget {
  const FirstClearBanner({
    super.key,
    required this.title,
    this.subtitle = UiStrings.firstClearCeremonySubtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return CeremonyImagePanel(
      assetPath: WuxiaUi.ceremonyBossFirstVictory,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      borderColor: WuxiaColors.resultHighlight.withValues(alpha: 0.58),
      imageOpacity: 0.35,
      paperVeilOpacity: 0.7,
      child: Row(
        children: [
          const Icon(
            Icons.military_tech,
            color: WuxiaColors.resultHighlight,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: 0.07,
            child: Image.asset(
              WuxiaUi.ceremonyRedSeal,
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单件装备掉落行(H1 批3 仪式感):品阶色勋章图标 + 名 + 品阶标签。
///
/// 品阶色取 [tierColorForEquipment](寻常货暗灰 → 神物高亮金),让稀有掉落
/// 一眼跳出(§10 仪式感)。GameRepository 未加载时降级纯 defId(沿原兜底)。
/// 公开省略 —— 仅本 dialog 内部用。
class _EquipmentDropRow extends StatefulWidget {
  const _EquipmentDropRow({
    required this.equipment,
    required this.hintCharacters,
    this.onLockToggle,
  });

  final Equipment equipment;
  final List<Character> hintCharacters;
  final EquipmentDropLockHandler? onLockToggle;

  @override
  State<_EquipmentDropRow> createState() => _EquipmentDropRowState();
}

class _EquipmentDropRowState extends State<_EquipmentDropRow> {
  late bool _locked = widget.equipment.isLocked;
  bool _deferred = false;

  Future<void> _setLocked(bool locked) async {
    if (widget.onLockToggle == null) {
      setState(() => _locked = locked);
      return;
    }
    final ok = await widget.onLockToggle!(widget.equipment, locked);
    if (!mounted || !ok) return;
    setState(() => _locked = locked);
  }

  void _showSources(List<EquipmentSource> sources) {
    PaperDialog.show<void>(
      context,
      title: UiStrings.equipmentDropSourceTitle,
      body: _EquipmentSourceBody(sources: sources),
      actions: [
        PlaqueButton(
          label: UiStrings.stageVictoryConfirm,
          primary: true,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!GameRepository.isLoaded) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text('· ${widget.equipment.defId}'),
      );
    }
    final def = GameRepository.instance.getEquipment(widget.equipment.defId);
    final color = tierColorForEquipment(def.tier);
    final sources = EquipmentSourceLookup(
      GameRepository.instance,
    ).sourcesFor(def.id);
    final protected =
        widget.equipment.isLineageHeritage ||
        widget.equipment.ownerCharacterId != null ||
        _locked;
    final sourceSummary = sources.isEmpty
        ? UiStrings.equipmentSourceUnknown
        : _sourceLabel(sources.first);
    final detailLines = _detailLines(def);
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6, right: 2),
      child: AnimatedOpacity(
        opacity: _deferred ? 0.58 : 1,
        duration: const Duration(milliseconds: 160),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 15, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        def.name,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      EnumL10n.equipmentTier(def.tier),
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                    if (_locked) ...[
                      const SizedBox(width: 6),
                      const _DropBadge(
                        text: UiStrings.equipmentLockedLabel,
                        color: WuxiaColors.bossFrame,
                      ),
                    ],
                    if (widget.equipment.isLineageHeritage) ...[
                      const SizedBox(width: 6),
                      const _DropBadge(
                        text: UiStrings.lineageHeritageLabel,
                        color: WuxiaColors.hpLow,
                      ),
                    ],
                    if (widget.equipment.ownerCharacterId != null) ...[
                      const SizedBox(width: 6),
                      const _DropBadge(
                        text: UiStrings.equipmentDropActionEquipped,
                        color: WuxiaColors.textSecondary,
                      ),
                    ],
                    if (_deferred) ...[
                      const SizedBox(width: 6),
                      const _DropBadge(
                        text: UiStrings.equipmentDropActionDone,
                        color: WuxiaColors.textMuted,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sourceSummary,
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                for (final line in detailLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TinyActionButton(
                      label: _locked
                          ? UiStrings.equipmentUnlock
                          : UiStrings.equipmentLock,
                      icon: _locked ? Icons.lock_open : Icons.lock_outline,
                      onTap: () => _setLocked(!_locked),
                    ),
                    _TinyActionButton(
                      label: _locked
                          ? UiStrings.equipmentDropFavoriteLabel
                          : UiStrings.equipmentDropActionFavorite,
                      icon: Icons.bookmark_border,
                      onTap: _locked ? null : () => _setLocked(true),
                    ),
                    _TinyActionButton(
                      label: UiStrings.equipmentDropActionSource,
                      icon: Icons.travel_explore,
                      onTap: () => _showSources(sources),
                    ),
                    _TinyActionButton(
                      label: UiStrings.equipmentDropActionLater,
                      icon: Icons.schedule,
                      onTap: () => setState(() => _deferred = true),
                    ),
                    if (protected)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          UiStrings.equipmentDropActionProtected,
                          style: TextStyle(
                            color: WuxiaColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!_locked)
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      UiStrings.equipmentDropFavoriteHint,
                      style: TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _detailLines(EquipmentDef def) {
    final requiredRealm = RealmTier.values[def.tier.index];
    final usable = widget.hintCharacters
        .where((c) => widget.equipment.isEquippableAtRealm(c.realmTier))
        .map((c) => c.name)
        .toList(growable: false);
    final school = widget.equipment.school ?? def.schoolBias;
    return [
      UiStrings.equipmentDropRealmGate(EnumL10n.realmTier(requiredRealm)),
      usable.isEmpty
          ? UiStrings.equipmentDropNoUsableCharacters
          : UiStrings.equipmentDropUsableCharacters(usable.take(3).join(' / ')),
      school == null
          ? UiStrings.equipmentDropSchoolFitAny
          : UiStrings.equipmentDropSchoolFit(EnumL10n.school(school)),
      _lockAdvice(usable.isNotEmpty, def.tier),
    ];
  }

  String _lockAdvice(bool hasUsableCharacter, EquipmentTier tier) {
    if (tier.index >= EquipmentTier.baoWu.index) {
      return UiStrings.equipmentDropLockAdviceRare;
    }
    if (hasUsableCharacter) {
      return UiStrings.equipmentDropLockAdviceFit;
    }
    if (tier.index > RealmTier.xueTu.index) {
      return UiStrings.equipmentDropLockAdviceWait;
    }
    return UiStrings.equipmentDropLockAdviceCommon;
  }
}

class _DropBadge extends StatelessWidget {
  const _DropBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: WuxiaColors.textSecondary,
        disabledForegroundColor: WuxiaColors.textMuted,
        side: BorderSide(
          color: onTap == null
              ? WuxiaColors.textMuted.withValues(alpha: 0.22)
              : WuxiaColors.textMuted.withValues(alpha: 0.48),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: const Size(0, 30),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
    );
  }
}

class _EquipmentSourceBody extends StatelessWidget {
  const _EquipmentSourceBody({required this.sources});

  final List<EquipmentSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Text(
        UiStrings.equipmentDropSourceEmpty,
        style: TextStyle(color: WuxiaUi.ink, height: 1.7),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '· ${_sourceLabel(source)}',
              style: const TextStyle(color: WuxiaUi.ink, height: 1.6),
            ),
          ),
      ],
    );
  }
}

String _sourceLabel(EquipmentSource source) {
  return switch (source.kind) {
    EquipmentSourceKind.mainline => UiStrings.equipmentSourceMainline(
      source.chapterIndex ?? 0,
      source.name ?? UiStrings.equipmentSourceUnknown,
      source.isBoss,
    ),
    EquipmentSourceKind.stage => UiStrings.equipmentSourceStage(
      source.name ?? UiStrings.equipmentSourceUnknown,
      source.isBoss,
    ),
    EquipmentSourceKind.tower => UiStrings.equipmentSourceTower(
      source.floorIndex ?? 0,
      source.isBoss,
    ),
    EquipmentSourceKind.seclusion => UiStrings.equipmentSourceSeclusion(
      source.name ?? UiStrings.equipmentSourceUnknown,
    ),
    EquipmentSourceKind.shop => UiStrings.equipmentSourceShop,
    EquipmentSourceKind.tag => UiStrings.equipmentSourceTag(source.tag ?? ''),
  };
}

/// 单条共鸣度晋阶通知(P1.1 候选 3-a)。
///
/// caller(stage_entry_flow / tower_entry_flow)在 GameEvent 写入循环中
/// 同步 cache 一份,传 victory dialog 显「装备 X 共鸣度晋至 Y 阶」。
class ResonanceUpgradeNotice {
  final String equipmentName;
  final ResonanceStage newStage;

  const ResonanceUpgradeNotice({
    required this.equipmentName,
    required this.newStage,
  });

  @override
  String toString() =>
      'ResonanceUpgradeNotice($equipmentName → ${newStage.name})';
}

/// 共鸣度晋阶 banner(P1.1 候选 3-a)。
///
/// 体例对齐 [AdvancementSummary]:label + 每行 icon + 文字。
/// 公开便于 widget test 直接 pump。
class ResonanceUpgradeBanner extends StatelessWidget {
  const ResonanceUpgradeBanner({super.key, required this.notices});

  final List<ResonanceUpgradeNotice> notices;

  @override
  Widget build(BuildContext context) {
    return CeremonyImagePanel(
      assetPath: WuxiaUi.ceremonyEquipmentResonance,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      borderRadius: 8,
      borderColor: WuxiaColors.popupCritical.withValues(alpha: 0.52),
      imageOpacity: 0.34,
      paperVeilOpacity: 0.78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ResonanceCeremonyTitle(),
          const SizedBox(height: 8),
          for (final n in notices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WuxiaColors.popupCritical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: WuxiaColors.popupCritical.withValues(
                          alpha: 0.48,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: WuxiaColors.popupCritical,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      UiStrings.stageVictoryResonanceUpgrade(
                        n.equipmentName,
                        EnumL10n.resonanceStage(n.newStage),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WuxiaUi.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
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

class _ResonanceCeremonyTitle extends StatelessWidget {
  const _ResonanceCeremonyTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.sports_martial_arts,
          color: WuxiaColors.popupCritical,
          size: 16,
        ),
        const SizedBox(width: 8),
        const Text(
          UiStrings.stageVictoryResonanceCeremonyTitle,
          style: TextStyle(
            color: WuxiaUi.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: WuxiaUi.ink.withValues(alpha: 0.28),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          UiStrings.stageVictoryResonanceLabel,
          style: TextStyle(
            color: WuxiaColors.popupCritical,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
