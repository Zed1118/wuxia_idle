import 'package:flutter/material.dart';

import '../../battle/domain/enum_localizations.dart' show EnumL10n;
import '../../loot_preview/domain/drop_rumor.dart';
import '../../loot_preview/presentation/loot_rumor_dialog.dart';
import '../../loot_preview/presentation/loot_summary_line.dart';
import '../../loot_preview/presentation/weakness_hint_line.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../application/tower_progress_service.dart';

enum TowerFloorStepSide { left, right }

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
    this.stepSide = TowerFloorStepSide.left,
    this.currentRealm,
  });

  /// 层定义 + 解锁状态。
  final TowerFloorEntry entry;

  /// 发起挑战回调（available 直接调用；cleared 用户确认重打后调用）。
  /// 屏幕层据此 push 进入 TowerEntryFlow。
  final VoidCallback onChallenge;

  /// 宽屏塔身布局中的石阶方向；窄屏会自动退回单列。
  final TowerFloorStepSide stepSide;

  /// 主战角色当前境界（用于掉落传闻弹窗 above-realm 提示）。可空。
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final status = entry.status;

    final isLocked = status == TowerFloorStatus.locked;
    final isCleared = status == TowerFloorStatus.cleared;
    final isAvailable = status == TowerFloorStatus.available;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTimeline = constraints.maxWidth >= 760;
          final plaque = _FloorPlaque(
            entry: entry,
            isLocked: isLocked,
            isCleared: isCleared,
            isAvailable: isAvailable,
            onTap: isLocked ? null : () => _handleTap(context),
            currentRealm: currentRealm,
            compactStatus: constraints.maxWidth < 420,
          );
          if (!useTimeline) {
            return plaque;
          }

          final isLeft = stepSide == TowerFloorStepSide.left;
          // 2026-06-25:改 IntrinsicHeight 让石阶 marker 随 plaque 自然高度伸展,
          // 去掉旧的固定 SizedBox(100/96)——已通关 Boss 层多渲染弱点行时会超出固定高
          // → "BOTTOM OVERFLOWED" 黄黑条纹。Row(stretch) 下 marker 自动等高,无溢出。
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: isLeft
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.92,
                            child: plaque,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                _TowerStepMarker(entry: entry),
                Expanded(
                  child: isLeft
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.92,
                            child: plaque,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (entry.status == TowerFloorStatus.cleared) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => PaperDialog(
          title: UiStrings.towerReplayTitle,
          body: const Text(UiStrings.towerReplayBody),
          actions: [
            PlaqueButton(
              label: UiStrings.towerReplayCancel,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            PlaqueButton(
              label: UiStrings.towerReplayConfirm,
              primary: true,
              autofocus: true,
              onTap: () => Navigator.of(ctx).pop(true),
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

class _FloorPlaque extends StatelessWidget {
  const _FloorPlaque({
    required this.entry,
    required this.isLocked,
    required this.isCleared,
    required this.isAvailable,
    required this.onTap,
    required this.compactStatus,
    this.currentRealm,
  });

  final TowerFloorEntry entry;
  final bool isLocked;
  final bool isCleared;
  final bool isAvailable;
  final VoidCallback? onTap;
  final bool compactStatus;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final def = entry.def;
    final accent = _accentFor(entry);
    final borderWidth = def.isBoss || isAvailable ? 2.0 : 1.0;
    final titleColor = isLocked
        ? WuxiaColors.textMuted
        : WuxiaColors.textPrimary;
    final fillTop = isLocked
        ? const Color(0xFF1A1C1F)
        : def.isBoss
        ? WuxiaColors.panel
        : const Color(0xFF20262B);
    final fillBottom = isLocked
        ? const Color(0xFF151618)
        : const Color(0xFF171B20);

    final rumor = DropRumorTable.fromDropTable(
      def.dropTable,
      gating: FirstClearGating.wholeChannel,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            constraints: BoxConstraints(minHeight: def.isBoss ? 98 : 92),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: accent, width: borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fillTop.withValues(alpha: isLocked ? 0.74 : 1),
                  fillBottom.withValues(alpha: isLocked ? 0.82 : 1),
                ],
              ),
              boxShadow: [
                if (isAvailable)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.24),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                if (def.isBoss)
                  BoxShadow(
                    color: accent.withValues(alpha: isLocked ? 0.08 : 0.13),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: def.isBoss ? 0.16 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: def.isBoss ? 7 : 4,
                      color: accent.withValues(alpha: isLocked ? 0.34 : 0.82),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 主信息行：印章 + 标题/敌人文本 + 状态徽标 ──
                        Row(
                          children: [
                            _FloorSeal(entry: entry, accent: accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          UiStrings.towerFloorLabel(
                                            def.floorIndex,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: def.isBoss ? 16 : 14,
                                            fontWeight: FontWeight.w800,
                                          ),
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
                                          label:
                                              def.bossKind ==
                                                  TowerBossKind.minor
                                              ? UiStrings.towerBossMinor
                                              : UiStrings.towerBossMajor,
                                          color: accent,
                                          filled: true,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLocked
                                        ? UiStrings.towerFloorLocked
                                        : UiStrings.towerFloorEnemies(
                                            def.enemyTeam.length,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isLocked
                                          ? WuxiaColors.textMuted
                                          : WuxiaColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StatusBadge(
                              status: entry.status,
                              accent: accent,
                              compact: compactStatus,
                            ),
                          ],
                        ),
                        // ── 掉落传闻行：独立一行，位于卡片底部，不与标签区重叠 ──
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InlineLootSummaryLine(
                                table: rumor,
                                showRecommendedRealm: false,
                                alignment: WrapAlignment.start,
                              ),
                            ),
                            Tooltip(
                              message: UiStrings.lootRumorDialogTitle,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => showLootRumorDialog(
                                  context,
                                  table: rumor,
                                  currentRealm: currentRealm,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: WuxiaColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 批二②:通关后战前可查 Boss 弱点/抗性(未通关 / 无配置 → shrink)。
                        WeaknessHintLine(
                          enemyTeam: def.enemyTeam,
                          cleared: isCleared,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(TowerFloorEntry entry) {
    if (entry.def.bossKind == TowerBossKind.major) return WuxiaColors.yinRou;
    if (entry.def.bossKind == TowerBossKind.minor) return WuxiaUi.gold;
    return switch (entry.status) {
      TowerFloorStatus.cleared => WuxiaColors.hpHigh,
      TowerFloorStatus.available => WuxiaColors.resultHighlight,
      TowerFloorStatus.locked => WuxiaColors.border,
    };
  }
}

class _TowerStepMarker extends StatelessWidget {
  const _TowerStepMarker({required this.entry});

  final TowerFloorEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = _markerAccent(entry);
    final isBoss = entry.def.isBoss;
    return SizedBox(
      width: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(
              width: isBoss ? 4 : 2,
              decoration: BoxDecoration(
                color: WuxiaUi.paper2.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: isBoss ? 44 : 34,
            height: isBoss ? 44 : 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WuxiaColors.background,
              borderRadius: BorderRadius.circular(isBoss ? 8 : 16),
              border: Border.all(color: accent, width: isBoss ? 2 : 1.5),
              boxShadow: [
                if (entry.status == TowerFloorStatus.available)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              '${entry.def.floorIndex}',
              style: TextStyle(
                color: accent,
                fontSize: isBoss ? 13 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _markerAccent(TowerFloorEntry entry) {
    if (entry.def.bossKind == TowerBossKind.major) return WuxiaColors.yinRou;
    if (entry.def.bossKind == TowerBossKind.minor) return WuxiaUi.gold;
    return switch (entry.status) {
      TowerFloorStatus.cleared => WuxiaColors.hpHigh,
      TowerFloorStatus.available => WuxiaColors.resultHighlight,
      TowerFloorStatus.locked => WuxiaUi.muted,
    };
  }
}

class _FloorSeal extends StatelessWidget {
  const _FloorSeal({required this.entry, required this.accent});

  final TowerFloorEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isLocked = entry.status == TowerFloorStatus.locked;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isLocked ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(entry.def.isBoss ? 5 : 19),
        border: Border.all(color: accent.withValues(alpha: isLocked ? 0.5 : 1)),
      ),
      child: Text(
        entry.def.bossKind == TowerBossKind.major
            ? UiStrings.towerFloorGlyphMajor
            : entry.def.bossKind == TowerBossKind.minor
            ? UiStrings.towerFloorGlyphMinor
            : '${entry.def.floorIndex}',
        style: TextStyle(
          color: accent.withValues(alpha: isLocked ? 0.68 : 1),
          fontSize: entry.def.isBoss ? 15 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.16) : null,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.accent,
    required this.compact,
  });

  final TowerFloorStatus status;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      TowerFloorStatus.cleared => _StatusPill(
        Icons.check_circle,
        label: compact ? null : UiStrings.towerReplayTitle,
        color: WuxiaColors.hpHigh,
        filled: false,
      ),
      TowerFloorStatus.available => _StatusPill(
        Icons.sports_martial_arts_outlined,
        label: compact ? null : UiStrings.towerFloorChallenge,
        color: accent,
        filled: true,
      ),
      TowerFloorStatus.locked => const _StatusPill(
        Icons.lock,
        label: null,
        color: WuxiaColors.textMuted,
        filled: false,
      ),
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
    this.icon, {
    required this.label,
    required this.color,
    required this.filled,
  });

  final IconData icon;
  final String? label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.20 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.72 : 0.48),
          width: 0.9,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 7 : 9,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
