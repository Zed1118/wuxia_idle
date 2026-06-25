import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../application/island_settle_service.dart';

/// 桃花岛收获汇总卡。
///
/// 展示本次收取的各类物品及数量，每行数量以 count-up 动画增强爽感。
/// 空收获时显示友好提示文案，不弹尴尬的空卡。
///
/// 纯展示 widget，不碰逻辑/Isar，所有中文走 [UiStrings]。
/// 使用 [StatelessWidget] + [GameRepository.instance] 直取 itemDefs。
class IslandRecapCard extends StatelessWidget {
  const IslandRecapCard({super.key, required this.harvest});

  final IslandHarvest harvest;

  /// 便捷展示：showDialog 包装此卡 + 「知道了」关闭按钮。
  ///
  /// 供 Task 11 主屏收取后调用。
  static Future<void> show(BuildContext context, IslandHarvest harvest) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: IslandRecapCard(harvest: harvest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: PaperPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            const Text(
              UiStrings.taohuaIslandRecapTitle,
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 14),

            // 内容区
            if (harvest.isEmpty)
              _buildEmptyState()
            else
              _buildItemList(),

            const SizedBox(height: 18),

            // 关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlaqueButton(
                  label: UiStrings.skillInfoClose,
                  onTap: () => Navigator.of(context, rootNavigator: true)
                      .pop(),
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Text(
      UiStrings.taohuaIslandRecapEmpty,
      style: TextStyle(
        color: WuxiaUi.muted,
        fontSize: 13,
        height: 1.7,
      ),
    );
  }

  Widget _buildItemList() {
    final itemDefs = GameRepository.instance.itemDefs;
    final entries = harvest.gained.entries.toList();

    // 条目多时可滚动；StackFit.expand 无界高度踩坑：IntrinsicHeight 包裹
    return IntrinsicHeight(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: entries.map((e) {
              final defId = e.key;
              final qty = e.value;
              final name = itemDefs[defId]?.name ?? defId;

              return _ItemRow(name: name, qty: qty);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 单行物品条目：物品名 + count-up 数量动画。
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.name, required this.qty});

  final String name;
  final int qty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // 物品图标：当前道具多无图标资产，用 Icon glyph 规避缺图踩坑
          const Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: WuxiaUi.qing,
          ),
          const SizedBox(width: 8),

          // 物品名
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 14,
              ),
            ),
          ),

          // 数量 count-up 动画（0 → qty, 600ms, easeOut）
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: qty),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, value, _) => Text(
              '×$value',
              style: const TextStyle(
                color: WuxiaUi.jiang,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
