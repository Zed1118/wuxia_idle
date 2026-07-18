import 'package:flutter/material.dart';

import '../../../core/domain/reward_entry.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/expedition_service.dart' show ExpeditionReturnResult;

/// 百草岭远征返程行记（§4.7 · B2.4）。
///
/// 只读展示一次 [ExpeditionReturnResult]：最深节点 / 完成节点 / 主要奖获 /
/// 断魂帖数 / 伤势。数据全部来自 `ExpeditionService.recall` 返回值，屏内不做
/// 任何写入或结算（写路径已在返程事务里完成）。
///
/// 注：§4.7 的「重要战斗」明细当前 [ExpeditionReturnResult] 不承载（settle 应用
/// 恢复后即丢弃逐节点战斗详情），待 batch3 富化 result（附战斗摘要，涉 schema）后补。
class ExpeditionRecapScreen extends StatelessWidget {
  const ExpeditionRecapScreen({super.key, required this.result});

  final ExpeditionReturnResult result;

  @override
  Widget build(BuildContext context) {
    final rewards = result.grantedRewards;
    final exp = rewards.quantityOf('exp');
    final tickets = rewards.quantityOf('item_duanhuntie');
    // 物料奖励：排除 exp（单列在「战果」段）与断魂帖（单列高亮），只留可入库材料。
    final itemRewards = rewards
        .where(
          (r) =>
              r.rewardKey != 'exp' &&
              r.rewardKey != 'item_duanhuntie' &&
              r.quantity > 0,
        )
        .toList();
    final hasReward = exp > 0 || tickets > 0 || itemRewards.isNotEmpty;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.expeditionRecapTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: LightPaperPanel(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                paperOpacity: 0.32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RecapHero(result: result),
                    const SizedBox(height: 14),
                    const SectionHeader(UiStrings.expeditionRecapResultSection),
                    const SizedBox(height: 8),
                    _RecapRow(
                      icon: Icons.terrain,
                      label: UiStrings.expeditionRecapDeepest(
                        result.deepestNode,
                      ),
                    ),
                    _RecapRow(
                      icon: Icons.flag_outlined,
                      label: UiStrings.expeditionRecapCompletedNodes(
                        result.deepestNode,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SectionHeader(UiStrings.expeditionRecapRewardSection),
                    const SizedBox(height: 8),
                    if (!hasReward)
                      const _EmptyReward()
                    else ...[
                      if (exp > 0)
                        _RecapRow(
                          icon: Icons.trending_up,
                          label: UiStrings.expeditionRecapExp(exp),
                        ),
                      for (final r in itemRewards)
                        _RecapRow(
                          icon: Icons.grass,
                          label: UiStrings.expeditionRecapRewardItem(
                            _itemName(r.rewardKey),
                            r.quantity,
                          ),
                        ),
                      if (tickets > 0)
                        _RecapRow(
                          icon: Icons.confirmation_number_outlined,
                          label: UiStrings.expeditionRecapTicket(tickets),
                          highlight: true,
                        ),
                    ],
                    const SizedBox(height: 14),
                    const SectionHeader(UiStrings.expeditionRecapInjurySection),
                    const SizedBox(height: 8),
                    _InjuryRow(result: result),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: PlaqueButton(
                        label: UiStrings.expeditionRecapBack,
                        primary: true,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _itemName(String key) => GameRepository.isLoaded
      ? (GameRepository.instance.itemDefs[key]?.name ?? key)
      : key;
}

/// 返程标题头：主动召回（墨色）/ 战败返程（绛红），下附最深抵达一行。
class _RecapHero extends StatelessWidget {
  const _RecapHero({required this.result});

  final ExpeditionReturnResult result;

  @override
  Widget build(BuildContext context) {
    final defeated = result.defeated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          defeated
              ? UiStrings.expeditionRecapDefeatedTitle
              : UiStrings.expeditionRecapReturnedTitle,
          style: TextStyle(
            color: defeated ? WuxiaColors.popupCritical : WuxiaUi.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// 战果 / 奖获单行（照 retreat_result `_RewardRow` 体例）。断魂帖行 [highlight]
/// 用暖金强化描边，凸显里程碑掉落。
class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: highlight ? 0.42 : 0.32),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? WuxiaUi.gold.withValues(alpha: 0.55)
              : WuxiaUi.muted.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: WuxiaUi.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReward extends StatelessWidget {
  const _EmptyReward();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text(
        UiStrings.expeditionRecapNoReward,
        style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
      ),
    );
  }
}

/// 伤势行：战败折损（绛红）/ 有人负伤（墨灰）/ 全员安然（墨灰）。
class _InjuryRow extends StatelessWidget {
  const _InjuryRow({required this.result});

  final ExpeditionReturnResult result;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (result.defeated) {
      label = UiStrings.expeditionRecapDefeatedInjury(result.downedCount);
      color = WuxiaColors.popupCritical;
    } else if (result.downedCount > 0) {
      label = UiStrings.expeditionRecapDownedInjury(result.downedCount);
      color = WuxiaUi.ink;
    } else {
      label = UiStrings.expeditionRecapSafeReturn;
      color = WuxiaUi.ink;
    }
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
