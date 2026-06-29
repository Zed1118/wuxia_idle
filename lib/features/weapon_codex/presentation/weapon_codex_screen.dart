import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/game_repository.dart';
import '../application/equipment_catalog_providers.dart';
import '../domain/equipment_catalog_entry.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/error_fallback.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import 'equipment_catalog_detail_screen.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 兵器谱收集图鉴主屏（Task 8）。
///
/// 全 80 件装备（[GameRepository.equipmentDefs]）按 tier 分组渲染。
/// [equipmentCatalogListProvider] 给出已建档（曾获得）的 defId 集合：
///   - 已获得 → [_AcquiredTile] 点亮卡（图标 + 名 + tier 色边），点击进详情。
///   - 未获得 → [_LockedTile] 水墨剪影占位（藏名「未得之器」），点击弹「尚未得手」。
///
/// 顶部 slot 筛选 chips（全部/兵器/护甲/饰品）+ 总进度。每档 PaperPanel
/// 自带该档进度小计。
class WeaponCodexScreen extends ConsumerStatefulWidget {
  const WeaponCodexScreen({super.key});

  @override
  ConsumerState<WeaponCodexScreen> createState() => _WeaponCodexScreenState();
}

class _WeaponCodexScreenState extends ConsumerState<WeaponCodexScreen> {
  /// 当前 slot 筛选；null = 全部。
  EquipmentSlot? _slot;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(equipmentCatalogListProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.weaponCodexTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => ErrorFallback(
            error: e,
            onRetry: () => ref.invalidate(equipmentCatalogListProvider),
          ),
          data: (entries) => _buildBody(context, entries),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<EquipmentCatalogEntry> entries,
  ) {
    if (!GameRepository.isLoaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            UiStrings.weaponCodexEmptyHint,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final acquired = {for (final e in entries) e.defId};
    final entryMap = {for (final e in entries) e.defId: e};
    final allDefs = GameRepository.instance.equipmentDefs.values;

    // slot 筛选
    final filtered = (_slot == null
            ? allDefs
            : allDefs.where((d) => d.slot == _slot))
        .toList(growable: false);

    // 按 tier 分组（照 baike byTier 体例，EquipmentTier.values 顺序，只显非空档）
    final byTier = <EquipmentTier, List<EquipmentDef>>{};
    for (final def in filtered) {
      byTier.putIfAbsent(def.tier, () => []).add(def);
    }
    final tiers = EquipmentTier.values
        .where((t) => byTier[t]?.isNotEmpty ?? false)
        .toList(growable: false);

    final totalGot = filtered.where((d) => acquired.contains(d.id)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── slot 筛选 chips ────────────────────────────────────────────
        _FilterRow(
          selected: _slot,
          onSelect: (s) => setState(() => _slot = s),
        ),
        const SizedBox(height: 8),
        // ── 总进度 ─────────────────────────────────────────────────────
        Text(
          UiStrings.weaponCodexProgress(totalGot, filtered.length),
          style: const TextStyle(
            color: WuxiaColors.resultHighlight,
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // ── 分档面板 ───────────────────────────────────────────────────
        for (final tier in tiers) ...[
          _TierPanel(
            tier: tier,
            defs: byTier[tier]!,
            acquired: acquired,
            entryMap: entryMap,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── slot 筛选行 ───────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});

  final EquipmentSlot? selected;
  final ValueChanged<EquipmentSlot?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: UiStrings.weaponCodexFilterAll,
          active: selected == null,
          onTap: () => onSelect(null),
        ),
        _FilterChip(
          label: UiStrings.weaponCodexFilterWeapon,
          active: selected == EquipmentSlot.weapon,
          onTap: () => onSelect(EquipmentSlot.weapon),
        ),
        _FilterChip(
          label: UiStrings.weaponCodexFilterArmor,
          active: selected == EquipmentSlot.armor,
          onTap: () => onSelect(EquipmentSlot.armor),
        ),
        _FilterChip(
          label: UiStrings.weaponCodexFilterAccessory,
          active: selected == EquipmentSlot.accessory,
          onTap: () => onSelect(EquipmentSlot.accessory),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? WuxiaColors.resultHighlight.withValues(alpha: 0.18)
              : WuxiaColors.panel,
          border: Border.all(
            color: active
                ? WuxiaColors.resultHighlight
                : WuxiaColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                active ? WuxiaColors.resultHighlight : WuxiaColors.textMuted,
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── 分档面板 ───────────────────────────────────────────────────────────────

class _TierPanel extends StatelessWidget {
  const _TierPanel({
    required this.tier,
    required this.defs,
    required this.acquired,
    required this.entryMap,
  });

  final EquipmentTier tier;
  final List<EquipmentDef> defs;
  final Set<String> acquired;
  final Map<String, EquipmentCatalogEntry> entryMap;

  @override
  Widget build(BuildContext context) {
    final got = defs.where((d) => acquired.contains(d.id)).length;

    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SectionHeader(EnumL10n.equipmentTier(tier))),
              Text(
                UiStrings.weaponCodexTierProgress(got, defs.length),
                style: TextStyle(
                  color: tierColorForEquipment(tier).withValues(alpha: 0.9),
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 网格：每件卡用 Wrap 平铺。
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final def in defs)
                acquired.contains(def.id)
                    ? _AcquiredTile(def: def, entry: entryMap[def.id]!)
                    : const _LockedTile(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 已获得卡（点亮，进详情）─────────────────────────────────────────────────

class _AcquiredTile extends StatelessWidget {
  const _AcquiredTile({required this.def, required this.entry});

  static const double _tileWidth = 86;

  final EquipmentDef def;
  final EquipmentCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = tierColorForEquipment(def.tier);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              EquipmentCatalogDetailScreen(def: def, entry: entry),
        ),
      ),
      child: SizedBox(
        width: _tileWidth,
        child: IntrinsicHeight(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: WuxiaColors.panel,
              border: Border.all(color: color.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: WuxiaImage(
                    def.iconPath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _iconPlaceholder(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  def.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.3)),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: Colors.white24,
        size: 28,
      ),
    );
  }
}

// ── 未获得卡（水墨剪影，藏名，弹提示）──────────────────────────────────────

class _LockedTile extends StatelessWidget {
  const _LockedTile();

  static const double _tileWidth = 86;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.weaponCodexNotObtained)),
      ),
      child: SizedBox(
        width: _tileWidth,
        child: IntrinsicHeight(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: WuxiaColors.avatarFill,
              border: Border.all(
                color: WuxiaColors.textMuted.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: WuxiaColors.textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white24,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  UiStrings.weaponCodexLockedItem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.5,
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
