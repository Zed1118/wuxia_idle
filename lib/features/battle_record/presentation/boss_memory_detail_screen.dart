import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../domain/boss_memory.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';

/// Boss 纪念详情屏（T9）。
///
/// 展示单条 [BossMemory] 的完整首胜回忆。
/// 支持 pre-record 降级：[BossMemory.isPreRecord] == true 时战绩数字区
/// 整块替换为「此役不详·记录之前」，不渲染任何 null 数字。
///
/// 纯只读展示，不写库/不碰战斗数值。
class BossMemoryDetailScreen extends StatelessWidget {
  const BossMemoryDetailScreen({super.key, required this.memory});

  final BossMemory memory;

  /// 从 GameRepository 解析 Boss 立绘路径（同 T8 _VictoryTile._resolvePortrait）。
  static String? _resolvePortrait(String bossKey) {
    if (!GameRepository.isLoaded) return null;
    final repo = GameRepository.instance;
    if (bossKey.startsWith('tower_floor_')) {
      final floorStr = bossKey.substring('tower_floor_'.length);
      final floor = int.tryParse(floorStr);
      if (floor == null) return null;
      final floors = repo.towerFloors;
      if (floor < 1 || floor > floors.length) return null;
      final team = floors[floor - 1].enemyTeam;
      return team.isNotEmpty ? team.last.iconPath : null;
    } else {
      final def = repo.stageDefs[bossKey];
      if (def == null) return null;
      final team = def.enemyTeam;
      return team.isNotEmpty ? team.last.iconPath : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portraitPath = _resolvePortrait(memory.bossKey);
    final cleared = memory.firstClearedAt;
    final dateStr = cleared != null
        ? '${cleared.year}.${cleared.month}.${cleared.day}'
        : null;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: memory.bossName,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Boss 立绘 ────────────────────────────────────────────────
            _BossPortraitHero(imagePath: portraitPath),
            const SizedBox(height: 16),

            // ── 首胜战绩区 ───────────────────────────────────────────────
            PaperPanel(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(UiStrings.battleRecordStatsTitle),
                  if (memory.isPreRecord)
                    // pre-record 降级：整块替换为「此役不详」
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        UiStrings.battleRecordPreRecord,
                        style: TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 13,
                          letterSpacing: 1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else ...[
                    // 完整态：渲染伤害/暴击/回合数字
                    if (memory.totalDamage != null)
                      _StatRow(
                        label: UiStrings.battleRecordDamage(
                          memory.totalDamage!,
                        ),
                      ),
                    if (memory.critCount != null)
                      _StatRow(
                        label: UiStrings.battleRecordCrits(memory.critCount!),
                      ),
                    if (memory.totalTicks != null)
                      _StatRow(
                        label: UiStrings.battleRecordTurns(memory.totalTicks!),
                      ),
                  ],
                  // 初胜日期（pre-record 有则显，无则略）
                  if (dateStr != null) ...[
                    const SizedBox(height: 4),
                    _StatRow(
                      label: UiStrings.battleRecordClearedAt(dateStr),
                      muted: true,
                    ),
                  ],
                  // 击败次数
                  const SizedBox(height: 4),
                  _StatRow(
                    label: UiStrings.battleRecordDefeatCount(
                      memory.defeatCount,
                    ),
                    muted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 此战之最区（topContributorName 有值才渲染）────────────────
            if (memory.topContributorName != null) ...[
              PaperPanel(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      UiStrings.battleRecordTopContributorTitle,
                    ),
                    Row(
                      children: [
                        Text(
                          memory.topContributorName!,
                          style: const TextStyle(
                            color: WuxiaUi.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        if (memory.topContributorDamage != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            UiStrings.battleRecordDamage(
                              memory.topContributorDamage!,
                            ),
                            style: const TextStyle(
                              color: WuxiaColors.bossFrame,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── 所获区（treasureName 有值才渲染）─────────────────────────
            if (memory.treasureName != null) ...[
              PaperPanel(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(UiStrings.battleRecordTreasureTitle),
                    Row(
                      children: [
                        Text(
                          memory.treasureName!,
                          style: const TextStyle(
                            color: WuxiaUi.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        if (memory.treasureTier != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            EnumL10n.equipmentTier(memory.treasureTier!),
                            style: const TextStyle(
                              color: WuxiaUi.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── 出战区（rosterNames 非空才渲染）──────────────────────────
            if (memory.rosterNames.isNotEmpty) ...[
              PaperPanel(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(UiStrings.battleRecordRosterTitle),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < memory.rosterNames.length; i++)
                          _RosterChip(
                            name: memory.rosterNames[i],
                            portraitPath: i < memory.rosterPortraits.length
                                ? memory.rosterPortraits[i]
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Boss 立绘英雄区 ──────────────────────────────────────────────────────────

class _BossPortraitHero extends StatelessWidget {
  const _BossPortraitHero({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePath != null
            ? WuxiaImage(
                imagePath!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.person_outline, color: Colors.white24, size: 56),
    );
  }
}

// ── 阵容头像小徽章 ───────────────────────────────────────────────────────────

class _RosterChip extends StatelessWidget {
  const _RosterChip({required this.name, required this.portraitPath});

  final String name;
  final String? portraitPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 小头像（缺图走纸调兜底）
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: portraitPath != null
              ? WuxiaImage(
                  portraitPath!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _miniPlaceholder(),
                )
              : _miniPlaceholder(),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(
            color: WuxiaColors.textSecondary,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.25)),
      ),
    );
  }
}

// ── 战绩统计行 ───────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? WuxiaColors.textMuted : WuxiaColors.textPrimary,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
