import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../equipment/application/equipment_service.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../inventory/presentation/equipment_detail_screen.dart';
import '../domain/equipment_stat_diff.dart';

/// 装备槽统一对话框（2026-06-26 · 一步到位 + 全量对比）。
///
/// 点角色面板装备槽 → 居中两栏：左栏候选(带 effective 攻/血/速 mini-diff)，
/// 右栏「当前 ▸ 候选」全量对比 + 确认更换。替代旧 `_EquipQuickActionSheet` +
/// `_EquipPickerSheet`（贴底两步）。纯表现层，换装恒走 [EquipmentService.equip]
/// 不绕 §5.3 校验。
class EquipSlotDialog extends ConsumerStatefulWidget {
  const EquipSlotDialog({
    super.key,
    required this.character,
    required this.slot,
    required this.currentId,
  });

  final Character character;
  final EquipmentSlot slot;
  final int? currentId;

  @override
  ConsumerState<EquipSlotDialog> createState() => _EquipSlotDialogState();
}

class _EquipSlotDialogState extends ConsumerState<EquipSlotDialog> {
  int? _selectedId; // 右栏选中的候选 equipment id

  void _invalidate({int? touched}) {
    ref.invalidate(characterByIdProvider(widget.character.id));
    ref.invalidate(allEquipmentsProvider);
    if (touched != null) ref.invalidate(equipmentByIdProvider(touched));
    if (widget.currentId != null) {
      ref.invalidate(equipmentByIdProvider(widget.currentId!));
    }
  }

  Future<void> _equip(Equipment eq) async {
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    final outcome = await EquipmentService(
      isar: isar,
    ).equip(characterId: widget.character.id, equipmentId: eq.id);
    if (!mounted) return;
    if (outcome == EquipOutcome.lockedByRealm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.equipLockedByRealm)),
      );
      return;
    }
    if (outcome == EquipOutcome.protectedCurrentEquipment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.equipProtectedCurrent)),
      );
      return;
    }
    if (outcome != EquipOutcome.success) return;
    _invalidate(touched: eq.id);
    Navigator.pop(context);
  }

  Future<void> _unequip() async {
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    await EquipmentService(
      isar: isar,
    ).unequip(characterId: widget.character.id, slot: widget.slot);
    if (!mounted) return;
    _invalidate();
    Navigator.pop(context);
  }

  Future<void> _openEnhance(Equipment eq, int tab) async {
    final def = GameRepository.instance.equipmentDefs[eq.defId];
    if (def == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => EnhanceDialog(equipment: eq, def: def, initialTab: tab),
    );
    _invalidate(touched: eq.id);
  }

  void _openLore(Equipment eq) {
    final def = GameRepository.instance.equipmentDefs[eq.defId];
    if (def == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EquipmentDetailScreen(equipment: eq, def: def),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final async = ref.watch(allEquipmentsProvider);
    // 干净冷色深底面板(对齐 EnhanceDialog/App 主题)。原 WuxiaPaperPanel 暖宣纸
    // 纹理与冷色 UI 不协调、文字压纹理显模糊(用户实玩反馈),宣纸留给典故/卷轴阅读屏。
    return Dialog(
      backgroundColor: WuxiaColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: WuxiaColors.border),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: async.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$e',
                style: const TextStyle(color: WuxiaColors.hpLow),
              ),
            ),
            data: _content,
          ),
        ),
      ),
    );
  }

  Widget _content(List<Equipment> all) {
    final items = all.where((e) => e.slot == widget.slot).toList();
    Equipment? current;
    if (widget.currentId != null) {
      for (final e in all) {
        if (e.id == widget.currentId) {
          current = e;
          break;
        }
      }
    }
    Equipment? selected;
    if (_selectedId != null) {
      for (final e in items) {
        if (e.id == _selectedId) {
          selected = e;
          break;
        }
      }
    }
    final cur = current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          slot: widget.slot,
          current: cur,
          onEnhance: cur == null ? null : () => _openEnhance(cur, 0),
          onForge: cur == null ? null : () => _openEnhance(cur, 1),
          onLore: cur == null ? null : () => _openLore(cur),
          onUnequip: cur == null ? null : _unequip,
          onClose: () => Navigator.pop(context),
        ),
        const Divider(height: 12, color: WuxiaColors.border),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 44,
                child: _CandidateList(
                  items: items,
                  current: cur,
                  realmTier: widget.character.realmTier,
                  characterId: widget.character.id,
                  selectedId: _selectedId,
                  onSelect: (id) => setState(() => _selectedId = id),
                ),
              ),
              const VerticalDivider(width: 12, color: WuxiaColors.border),
              Expanded(
                flex: 56,
                child: selected == null
                    ? const _ComparePlaceholder()
                    : _ComparePane(
                        current: cur,
                        candidate: selected,
                        onConfirm: () => _equip(selected!),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.slot,
    required this.current,
    required this.onEnhance,
    required this.onForge,
    required this.onLore,
    required this.onUnequip,
    required this.onClose,
  });

  final EquipmentSlot slot;
  final Equipment? current;
  final VoidCallback? onEnhance;
  final VoidCallback? onForge;
  final VoidCallback? onLore;
  final VoidCallback? onUnequip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cur = current;
    final name = cur == null
        ? null
        : GameRepository.instance.getEquipment(cur.defId).name;
    return Row(
      children: [
        Expanded(
          child: Text(
            cur == null
                ? '${UiStrings.equipPickerTitle} · ${EnumL10n.equipmentSlot(slot)}'
                : '${EnumL10n.equipmentSlot(slot)} · $name',
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (cur != null) ...[
          _iconBtn(Icons.arrow_upward, UiStrings.tabEnhance, onEnhance),
          _iconBtn(Icons.auto_fix_high, UiStrings.tabForging, onForge),
          _iconBtn(Icons.menu_book, UiStrings.equipQuickViewLore, onLore),
          _iconBtn(
            Icons.remove_circle_outline,
            UiStrings.equipUnequip,
            onUnequip,
          ),
        ],
        _iconBtn(Icons.close, UiStrings.equipPickerClose, onClose),
      ],
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
    icon: Icon(
      icon,
      size: 20,
      color: onTap == null ? WuxiaColors.textMuted : WuxiaColors.textSecondary,
    ),
    tooltip: tip,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
  );
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.items,
    required this.current,
    required this.realmTier,
    required this.characterId,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Equipment> items;
  final Equipment? current;
  final RealmTier realmTier;
  final int characterId;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          UiStrings.equipPickerEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(color: WuxiaColors.textMuted),
        ),
      );
    }
    final n = GameRepository.instance.numbers;
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: WuxiaColors.border),
      itemBuilder: (ctx, i) {
        final eq = items[i];
        final canEquip = eq.isEquippableAtRealm(realmTier);
        final isCurrent = eq.id == current?.id;
        final isSelected = eq.id == selectedId;
        final name = GameRepository.instance.getEquipment(eq.defId).name;
        // 该件正被队内其他角色穿戴 → 标注(选它会移装,原角色卸下)。不禁用。
        final ownerId = eq.ownerCharacterId;
        final wornByOther =
            ownerId != null && ownerId != characterId && !isCurrent;
        final cmp = equipmentFullDiff(
          current: current,
          candidate: eq,
          numbers: n,
        );
        return Material(
          // 选中高亮用更亮的 inkPanelTop(对话框底已是 panel,同色会看不见)。
          color: isSelected ? WuxiaColors.inkPanelTop : Colors.transparent,
          child: ListTile(
            dense: true,
            enabled: canEquip,
            selected: isSelected,
            title: Text(
              name,
              style: TextStyle(
                color: canEquip
                    ? WuxiaColors.textPrimary
                    : WuxiaColors.textMuted,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${EnumL10n.equipmentTier(eq.tier)} · '
                            '${UiStrings.enhanceLevel(eq.enhanceLevel)}'
                            '${isCurrent ? "  ${UiStrings.currentEquippedBadge}" : ""}',
                      ),
                      if (wornByOther)
                        const TextSpan(
                          text: '  · ${UiStrings.equipWornByOther}',
                          style: TextStyle(color: WuxiaColors.gangMeng),
                        ),
                    ],
                  ),
                ),
                if (!cmp.isBaseline) _MiniDiff(cmp: cmp),
              ],
            ),
            trailing: canEquip
                ? Icon(
                    isCurrent ? Icons.check : Icons.chevron_right,
                    color: WuxiaColors.textSecondary,
                    size: 18,
                  )
                : const Icon(
                    Icons.lock_outline,
                    color: WuxiaColors.textMuted,
                    size: 16,
                  ),
            onTap: canEquip ? () => onSelect(eq.id) : null,
          ),
        );
      },
    );
  }
}

/// 候选行内联 effective 攻/血/速 mini-diff（升绿/降红/平灰）。
class _MiniDiff extends StatelessWidget {
  const _MiniDiff({required this.cmp});
  final EquipmentComparison cmp;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final r in cmp.numericRows.where((r) => r.label.startsWith('实战'))) {
      final delta = r.candidateValue - (r.currentValue ?? r.candidateValue);
      final c = r.direction == StatDirection.up
          ? WuxiaColors.hpHigh
          : r.direction == StatDirection.down
          ? WuxiaColors.hpLow
          : WuxiaColors.textMuted;
      final arrow = r.direction == StatDirection.up
          ? '↑'
          : r.direction == StatDirection.down
          ? '↓'
          : '·';
      final tag = r.label.substring(2, 3); // 攻/血/速
      spans.add(
        TextSpan(
          text: '$tag$arrow${delta.abs()}  ',
          style: TextStyle(color: c, fontSize: 11),
        ),
      );
    }
    return Text.rich(TextSpan(children: spans));
  }
}

class _ComparePlaceholder extends StatelessWidget {
  const _ComparePlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        UiStrings.equipSlotDialogPickHint,
        style: TextStyle(color: WuxiaColors.textMuted),
      ),
    ),
  );
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({
    required this.current,
    required this.candidate,
    required this.onConfirm,
  });

  final Equipment? current;
  final Equipment candidate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final n = GameRepository.instance.numbers;
    final cmp = equipmentFullDiff(
      current: current,
      candidate: candidate,
      numbers: n,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            UiStrings.equipSlotDialogCompareTitle,
            style: TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in cmp.numericRows) _numericRow(r, cmp.isBaseline),
                for (final r in cmp.categoryRows)
                  _categoryRow(r, cmp.isBaseline),
                _forgingRows(cmp),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onConfirm,
            child: Text(
              cmp.isBaseline
                  ? UiStrings.equipSlotDialogEquip
                  : UiStrings.equipSlotDialogConfirm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numericRow(StatDiffRow r, bool baseline) {
    final c = r.direction == StatDirection.up
        ? WuxiaColors.hpHigh
        : r.direction == StatDirection.down
        ? WuxiaColors.hpLow
        : WuxiaColors.textPrimary;
    final right = baseline || r.currentValue == null
        ? '${r.candidateValue}'
        : '${r.currentValue} ▸ ${r.candidateValue}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              r.label,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            right,
            style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(CategoryRow r, bool baseline) {
    final right = baseline || r.currentText == null
        ? r.candidateText
        : '${r.currentText} ▸ ${r.candidateText}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              r.label,
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            right,
            style: TextStyle(
              color: r.highlightUp
                  ? WuxiaColors.hpHigh
                  : WuxiaColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _forgingRows(EquipmentComparison cmp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            UiStrings.equipSlotDialogForgingLabel,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
          ),
          for (var i = 0; i < 3; i++)
            Text(
              cmp.isBaseline
                  ? cmp.forgingCandidate[i]
                  : '${cmp.forgingCurrent[i]} ▸ ${cmp.forgingCandidate[i]}',
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
