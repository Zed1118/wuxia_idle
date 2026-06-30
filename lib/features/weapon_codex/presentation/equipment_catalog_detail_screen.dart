import 'package:flutter/material.dart';

import '../../../data/defs/equipment_def.dart';
import '../domain/equipment_catalog_entry.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';

/// 兵器谱详情屏（Task 9）。
///
/// 展示单件装备的静态档案（[EquipmentDef]）+ 玩家个人获得历程
/// （[EquipmentCatalogEntry]）。
///
/// 回填档降级：[EquipmentCatalogEntry.isPreRecord] == true 或
/// [EquipmentCatalogEntry.firstObtainedAt] == null 时，个人历程区把首得来源/
/// 日期整块替换为「来历已不可考」，不渲染任何 null。
///
/// 纯只读展示，不读 provider / 不写库。
class EquipmentCatalogDetailScreen extends StatelessWidget {
  const EquipmentCatalogDetailScreen({
    super.key,
    required this.def,
    required this.entry,
  });

  final EquipmentDef def;
  final EquipmentCatalogEntry entry;

  /// 日期格式化（同 boss_memory_detail_screen：year.month.day）。
  static String _fmtDate(DateTime d) => '${d.year}.${d.month}.${d.day}';

  @override
  Widget build(BuildContext context) {
    final imagePath = def.detailPath ?? def.iconPath;
    final unknownHistory = entry.isPreRecord || entry.firstObtainedAt == null;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: def.name,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                PaperPanel(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _ArchivePanelContent(def: def, imagePath: imagePath),
                ),
                const SizedBox(height: 12),
                PaperPanel(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        UiStrings.weaponCodexDetailHistoryTitle,
                      ),
                      if (unknownHistory)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            UiStrings.weaponCodexHistoryUnknown,
                            style: TextStyle(
                              color: WuxiaUi.muted,
                              fontSize: 13,
                              letterSpacing: 1,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else ...[
                        _HistoryRow(
                          label: UiStrings.weaponCodexFirstObtainedFrom(
                            entry.firstObtainedFrom,
                          ),
                        ),
                        _HistoryRow(
                          label: UiStrings.weaponCodexFirstObtainedAt(
                            _fmtDate(entry.firstObtainedAt!),
                          ),
                          muted: true,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _HistoryRow(
                        label: UiStrings.weaponCodexObtainedCount(
                          entry.obtainedCount,
                        ),
                        muted: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchivePanelContent extends StatelessWidget {
  const _ArchivePanelContent({required this.def, required this.imagePath});

  final EquipmentDef def;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ArchiveRow(
          label: UiStrings.labelEquipmentTier,
          value: EnumL10n.equipmentTier(def.tier),
        ),
        _ArchiveRow(
          label: UiStrings.weaponCodexDetailSlot,
          value: EnumL10n.equipmentSlot(def.slot),
        ),
        _ArchiveRow(
          label: UiStrings.weaponCodexDetailAttackRange,
          value: UiStrings.weaponCodexDetailRange(
            def.baseAttackMin,
            def.baseAttackMax,
          ),
        ),
        _ArchiveRow(
          label: UiStrings.weaponCodexDetailHealthRange,
          value: UiStrings.weaponCodexDetailRange(
            def.baseHealthMin,
            def.baseHealthMax,
          ),
        ),
        _ArchiveRow(
          label: UiStrings.weaponCodexDetailSpeedRange,
          value: UiStrings.weaponCodexDetailRange(
            def.baseSpeedMin,
            def.baseSpeedMax,
          ),
        ),
        if (def.schoolBias != null)
          _ArchiveRow(
            label: UiStrings.labelSchool,
            value: EnumL10n.school(def.schoolBias!),
          ),
        if (def.specialSkillCandidates.isNotEmpty)
          _ArchiveRow(
            label: UiStrings.weaponCodexDetailSpecialSkills,
            value: '${def.specialSkillCandidates.length}',
          ),
        if (def.isLineageHeritage) ...[
          const SizedBox(height: 4),
          const Text(
            UiStrings.weaponCodexDetailLineage,
            style: TextStyle(
              color: WuxiaColors.bossFrame,
              fontSize: 12,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(UiStrings.weaponCodexDetailArchiveTitle),
            const SizedBox(height: 6),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailHero(imagePath: imagePath),
                  const SizedBox(width: 18),
                  Expanded(child: rows),
                ],
              )
            else ...[
              _DetailHero(imagePath: imagePath),
              const SizedBox(height: 12),
              rows,
            ],
          ],
        );
      },
    );
  }
}

// ── 器物大图英雄区 ───────────────────────────────────────────────────────────

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WuxiaImage(
          imagePath,
          width: 132,
          height: 132,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.shield_outlined, color: Colors.white24, size: 56),
    );
  }
}

// ── 静态档案行（label : value）───────────────────────────────────────────────

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: WuxiaUi.muted,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
                letterSpacing: 0.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 个人历程行 ───────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? WuxiaUi.muted : WuxiaUi.ink,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
