import 'package:flutter/material.dart';

import '../../../../shared/strings.dart';
import '../../../../shared/theme/colors.dart';

/// PVP 段位 badge(1.0 P3.3 §12.3 Phase 4 · spec §5)。
///
/// 显当前 ELO + 七阶段位名(`numbers.yaml pvp.ranks` 段窗 200 默认映射):
///   - 学徒 < 1000 / 三流 1000-1199 / 二流 1200-1399(初始) / 一流 1400-1599
///   - 绝顶 1600-1799 / 宗师 1800-1999 / 武圣 2000+
///
/// 当前段进度条(右侧距下一段剩余分数 hint)。武圣段无上限 → 显「已至段位之巅」。
class RankBadgeWidget extends StatelessWidget {
  const RankBadgeWidget({super.key, required this.currentElo});

  final int currentElo;

  /// 7 阶段位边界(段窗 200)。返 `(name, lowerBound, upperBound|null)`。
  /// null upperBound 表示武圣段无上限。
  static ({String name, int lower, int? upper}) rankInfo(int elo) {
    if (elo < 1000) return (name: UiStrings.pvpRankXueTu, lower: 0, upper: 1000);
    if (elo < 1200) {
      return (name: UiStrings.pvpRankSanLiu, lower: 1000, upper: 1200);
    }
    if (elo < 1400) {
      return (name: UiStrings.pvpRankErLiu, lower: 1200, upper: 1400);
    }
    if (elo < 1600) {
      return (name: UiStrings.pvpRankYiLiu, lower: 1400, upper: 1600);
    }
    if (elo < 1800) {
      return (name: UiStrings.pvpRankJueDing, lower: 1600, upper: 1800);
    }
    if (elo < 2000) {
      return (name: UiStrings.pvpRankZongShi, lower: 1800, upper: 2000);
    }
    return (name: UiStrings.pvpRankWuSheng, lower: 2000, upper: null);
  }

  /// 下一段段位名(武圣 → null)。
  static String? nextRankName(int elo) {
    if (elo < 1000) return UiStrings.pvpRankSanLiu;
    if (elo < 1200) return UiStrings.pvpRankErLiu;
    if (elo < 1400) return UiStrings.pvpRankYiLiu;
    if (elo < 1600) return UiStrings.pvpRankJueDing;
    if (elo < 1800) return UiStrings.pvpRankZongShi;
    if (elo < 2000) return UiStrings.pvpRankWuSheng;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final info = rankInfo(currentElo);
    final next = nextRankName(currentElo);
    final progress = info.upper == null
        ? 1.0
        : ((currentElo - info.lower) / (info.upper! - info.lower))
            .clamp(0.0, 1.0);
    final remaining = info.upper == null ? 0 : info.upper! - currentElo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                info.name,
                style: const TextStyle(
                  color: WuxiaColors.resultHighlight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                UiStrings.pvpEloLabel(currentElo),
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: WuxiaColors.barTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(
                WuxiaColors.resultHighlight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? UiStrings.pvpRankTopHint
                : UiStrings.pvpRankNext(remaining, next),
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
