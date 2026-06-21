import 'package:flutter/material.dart';

import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';

/// 门派谱共享展示组件（门派谱1.1 M1 去重）。
///
/// 由 [LineagePanelScreen] 与 [LineageCharacterDetailScreen] 共用，
/// 抽自两屏原各自私有的 `_PanelCard` / `_SectionTitle` / `_HeritageRow` /
/// `_BuffRow` / `_pctLabel`。纯展示，无数值/平衡逻辑，无中文字面量。

/// 百分比标签：0 显「—」，否则「+N%」。
String lineagePctLabel(double v) {
  if (v == 0) return '—';
  return '+${(v * 100).toStringAsFixed(0)}%';
}

/// 卡片容器：宣纸底 + 描边。
class LineagePanelCard extends StatelessWidget {
  const LineagePanelCard({super.key, required this.child});

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

/// 段标题。
class LineageSectionTitle extends StatelessWidget {
  const LineageSectionTitle(this.text, {super.key});

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

/// buff 行：左标签 + 右高亮值。
class LineageBuffRow extends StatelessWidget {
  const LineageBuffRow({super.key, required this.label, required this.value});

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

/// 师承遗物行：阶色点 + 名 + 强化等级 + 多代传承 chip。
///
/// 名解析沿现有链：未加载 [GameRepository] 时 fallback 到 defId。
class LineageHeritageRow extends StatelessWidget {
  const LineageHeritageRow({super.key, required this.equipment});

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
        // P5+ 多代传承 chip:prev len > 1 时显「{N} 代传承」(N = prev len + 1)。
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
