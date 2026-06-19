import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
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
  String? skillFragmentLine,
}) async {
  // 结算 jingle:跨 tier 大境界突破响 realmAdvance(爆装备音已移到 playTreasureDropIfAny
  // 动画层 + 门槛化,2026-06-11)。
  if (advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('${stage.name} · ${UiStrings.stageVictoryTitle}'),
      content: StageVictoryContent(
        drops: drops,
        advancements: advancements,
        resonanceUpgrades: resonanceUpgrades,
        firstClearTitle: firstClearTitle,
        firstClearSubtitle: firstClearSubtitle,
        stats: stats,
        skillFragmentLine: skillFragmentLine,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: WuxiaColors.resultHighlight,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(UiStrings.stageVictoryConfirm),
        ),
      ],
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
    this.skillFragmentLine,
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;
  final String? firstClearTitle;
  final String? firstClearSubtitle;
  final BattleStatsSummary? stats;

  /// 第七阶段批二④:残页轻提示行(掉残页未集齐时,非重仪式)。
  /// null=本场未掉残页或已走重仪式;非空时在 drop 段末尾追一行小字。
  final String? skillFragmentLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstClearTitle != null) ...[
          FirstClearBanner(
            title: firstClearTitle!,
            subtitle:
                firstClearSubtitle ?? UiStrings.firstClearCeremonySubtitle,
          ),
          const SizedBox(height: 12),
        ],
        const Text(UiStrings.stageVictoryDropLabel),
        const SizedBox(height: 4),
        if (drops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              UiStrings.stageVictoryNoDrop,
              style: TextStyle(color: WuxiaColors.textMuted),
            ),
          )
        else ...[
          // H1 批3:装备掉落按品阶上色 + 勋章图标,神物/寻常货一眼可辨(§10
          // 仪式感),消除「磨剑石与神物视觉同」的零反馈。道具仍走朴素列。
          for (final eq in drops.equipments) _EquipmentDropRow(defId: eq.defId),
          for (final item in drops.items)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '· ${EnumL10n.itemType(ItemType.fromDefId(item.defId))} '
                '×${item.quantity}',
              ),
            ),
        ],
        // 第七阶段批二④:残页轻提示行(掉残页未集齐 → drop 段末追一行)。
        // skillFragmentLine 自带「得残页 · …」前缀,不再加列表点。
        if (skillFragmentLine != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              skillFragmentLine!,
              style: const TextStyle(color: WuxiaColors.resultHighlight),
            ),
          ),
        if (advancements.any((e) => e.result.didAdvance)) ...[
          const SizedBox(height: 12),
          AdvancementSummary(entries: advancements),
        ],
        if (resonanceUpgrades.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResonanceUpgradeBanner(notices: resonanceUpgrades),
        ],
        if (stats != null) ...[
          const SizedBox(height: 12),
          Text(
            UiStrings.battleSummary(
                stats!.totalDamage, stats!.critCount, stats!.totalTicks),
            style: const TextStyle(
                color: WuxiaColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
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
class _EquipmentDropRow extends StatelessWidget {
  const _EquipmentDropRow({required this.defId});

  final String defId;

  @override
  Widget build(BuildContext context) {
    if (!GameRepository.isLoaded) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text('· $defId'),
      );
    }
    final def = GameRepository.instance.getEquipment(defId);
    final color = tierColorForEquipment(def.tier);
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              def.name,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            EnumL10n.equipmentTier(def.tier),
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
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
