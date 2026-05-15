import 'package:flutter/material.dart';

import '../../../combat/enum_localizations.dart' show EnumL10n;
import '../../../data/models/enums.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';
import '../application/tower_progress_service.dart';

/// 爬塔层卡片（Phase 3 T42）。
///
/// 三态：
///   - cleared：✓ 绿勾 + 灰底；点击弹重打确认 dialog
///   - available：主色边框 + 「挑战」chip；点击触发 [onChallenge]
///   - locked：灰色 + 锁图标；不响应点击
///
/// Boss 层额外：金（minor）/ 紫（major）outline 边框 +「小 Boss / 大 Boss」chip +
/// 推荐境界 chip。边框用 outline 不用 background，避免与 cleared 灰底冲突。
class TowerFloorCard extends StatelessWidget {
  const TowerFloorCard({
    super.key,
    required this.entry,
    required this.onChallenge,
  });

  /// 层定义 + 解锁状态。
  final TowerFloorEntry entry;

  /// 发起挑战回调（available 直接调用；cleared 用户确认重打后调用）。
  /// 屏幕层负责 T43 前的 SnackBar 占位，T43 落地后改 push。
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final def = entry.def;
    final status = entry.status;

    final isLocked = status == TowerFloorStatus.locked;
    final isCleared = status == TowerFloorStatus.cleared;
    final isAvailable = status == TowerFloorStatus.available;

    // Boss 层 outline 颜色优先；普通层按状态取色
    final Color borderColor;
    final double borderWidth;
    if (def.isBoss) {
      borderColor = def.bossKind == TowerBossKind.minor
          ? WuxiaColors.popupCritical // 金
          : WuxiaColors.yinRou; // 紫
      borderWidth = 2.0;
    } else if (isCleared) {
      borderColor = WuxiaColors.hpHigh;
      borderWidth = 1.0;
    } else if (isAvailable) {
      borderColor = WuxiaColors.resultHighlight;
      borderWidth = 1.0;
    } else {
      borderColor = WuxiaColors.border;
      borderWidth = 1.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () => _handleTap(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLocked ? WuxiaColors.avatarFill : WuxiaColors.panel,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            UiStrings.towerFloorLabel(def.floorIndex),
                            style: TextStyle(
                              color: isLocked
                                  ? WuxiaColors.textMuted
                                  : WuxiaColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SmallChip(
                            label: UiStrings.towerRequiredRealm(
                              EnumL10n.realmTier(def.requiredRealm),
                            ),
                            color: isLocked
                                ? WuxiaColors.textMuted
                                : WuxiaColors.textSecondary,
                          ),
                          if (def.isBoss) ...[
                            const SizedBox(width: 6),
                            _SmallChip(
                              label: def.bossKind == TowerBossKind.minor
                                  ? UiStrings.towerBossMinor
                                  : UiStrings.towerBossMajor,
                              color: def.bossKind == TowerBossKind.minor
                                  ? WuxiaColors.popupCritical
                                  : WuxiaColors.yinRou,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked
                            ? UiStrings.towerFloorLocked
                            : UiStrings.towerFloorEnemies(def.enemyTeam.length),
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  status: status,
                  isBoss: def.isBoss,
                  isAvailable: isAvailable,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (entry.status == TowerFloorStatus.cleared) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(UiStrings.towerReplayTitle),
          content: const Text(UiStrings.towerReplayBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(UiStrings.towerReplayCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(UiStrings.towerReplayConfirm),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        onChallenge();
      }
    } else {
      onChallenge();
    }
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isBoss,
    required this.isAvailable,
  });

  final TowerFloorStatus status;
  final bool isBoss;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      TowerFloorStatus.cleared => const Icon(
          Icons.check_circle,
          color: WuxiaColors.hpHigh,
          size: 20,
        ),
      TowerFloorStatus.available => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            UiStrings.towerFloorChallenge,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      TowerFloorStatus.locked => const Icon(
          Icons.lock,
          color: WuxiaColors.textMuted,
          size: 18,
        ),
    };
  }
}
