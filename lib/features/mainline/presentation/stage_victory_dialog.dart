import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
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
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('${stage.name} · ${UiStrings.stageVictoryTitle}'),
      content: StageVictoryContent(
        drops: drops,
        advancements: advancements,
        resonanceUpgrades: resonanceUpgrades,
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
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (advancements.any((e) => e.result.didAdvance)) ...[
          const SizedBox(height: 12),
          AdvancementSummary(entries: advancements),
        ],
        if (resonanceUpgrades.isNotEmpty) ...[
          const SizedBox(height: 12),
          ResonanceUpgradeBanner(notices: resonanceUpgrades),
        ],
      ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          UiStrings.stageVictoryResonanceLabel,
          style: TextStyle(
            color: WuxiaColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        for (final n in notices)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: WuxiaColors.popupCritical,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    UiStrings.stageVictoryResonanceUpgrade(
                      n.equipmentName,
                      EnumL10n.resonanceStage(n.newStage),
                    ),
                    style: const TextStyle(color: WuxiaColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
