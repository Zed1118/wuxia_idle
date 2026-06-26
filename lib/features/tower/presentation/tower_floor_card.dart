import 'package:flutter/material.dart';

import '../../battle/domain/enum_localizations.dart' show EnumL10n;
import '../../loot_preview/domain/drop_rumor.dart';
import '../../loot_preview/presentation/loot_rumor_dialog.dart';
import '../../loot_preview/presentation/loot_summary_line.dart';
import '../../loot_preview/presentation/stage_preview_card.dart';
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
                      ? Align(alignment: Alignment.centerRight, child: plaque)
                      : const SizedBox.shrink(),
                ),
                _TowerStepMarker(entry: entry),
                Expanded(
                  child: isLeft
                      ? const SizedBox.shrink()
                      : Align(alignment: Alignment.centerLeft, child: plaque),
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
        builder: (ctx) => AlertDialog(
          title: const Text(UiStrings.towerReplayTitle),
          // 逐关「战斗方式」覆盖已移除(2026-06-26):全局「自动战斗」开关在设置面板,
          // 逐关覆盖冗余。首通仍强制拖招,重打按全局设置。dialog 仅留重打确认文案。
          content: const Text(UiStrings.towerReplayBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(UiStrings.towerReplayCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: WuxiaColors.resultHighlight,
              ),
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

class _FloorPlaque extends StatelessWidget {
  const _FloorPlaque({
    required this.entry,
    required this.isLocked,
    required this.isCleared,
    required this.isAvailable,
    required this.onTap,
    this.currentRealm,
  });

  final TowerFloorEntry entry;
  final bool isLocked;
  final bool isCleared;
  final bool isAvailable;
  final VoidCallback? onTap;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final def = entry.def;
    final accent = _accentFor(entry);
    final borderWidth = def.isBoss || isAvailable ? 1.8 : 1.0;
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

    // 第八阶段 C·悬停预览浮层(塔层 wholeChannel 门控:整渠道首通必得)。推荐境界
    // (B 难度判语)+ 掉落传闻。overlay 出流不占列表高度(不挤出靠后层·守 viewport 回归)。
    final previewRumor = DropRumorTable.fromDropTable(
      def.dropTable,
      gating: FirstClearGating.wholeChannel,
    );
    return StagePreviewHoverCard(
      preview: StagePreviewContent(
        recommendedRealm: def.requiredRealm,
        rumorTable: previewRumor,
        playerRealm: currentRealm,
      ),
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            constraints: BoxConstraints(minHeight: def.isBoss ? 94 : 90),
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
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
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
                    padding: const EdgeInsets.fromLTRB(18, 12, 14, 8),
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
                            _StatusBadge(status: entry.status),
                          ],
                        ),
                        // ── 掉落传闻行：独立一行，位于卡片底部，不与标签区重叠 ──
                        const SizedBox(height: 6),
                        () {
                          final rumor = DropRumorTable.fromDropTable(
                            def.dropTable,
                            gating: FirstClearGating.wholeChannel,
                          );
                          return Row(
                            children: [
                              Expanded(
                                child: LootSummaryLine(table: rumor),
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
                          );
                        }(),
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
      width: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(
              width: isBoss ? 4 : 2,
              decoration: BoxDecoration(
                color: WuxiaUi.paper2.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: isBoss ? 42 : 32,
            height: isBoss ? 42 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WuxiaColors.background,
              borderRadius: BorderRadius.circular(isBoss ? 8 : 16),
              border: Border.all(color: accent, width: isBoss ? 2 : 1.5),
              boxShadow: entry.status == TowerFloorStatus.available
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
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
  const _StatusBadge({required this.status});

  final TowerFloorStatus status;

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
