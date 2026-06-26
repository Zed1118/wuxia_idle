# 装备槽对话框重做 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 点角色面板装备槽一步到位进居中两栏对话框：左栏候选列表(带 effective 攻/血/速 mini-diff)，右栏「当前 ▸ 候选」全量对比 + 确认更换。

**Architecture:** 纯表现层。新增纯函数 `equipmentFullDiff`（锁对比口径，TDD）+ 新 widget `EquipSlotDialog`（ConsumerStatefulWidget，两栏）。`character_panel_screen._tappableSlot` 改 `showDialog` 调它，删旧 `_EquipQuickActionSheet` + `_EquipPickerSheet`。0 改 saveVer / 战斗数值 / `equip` 校验。

**Tech Stack:** Flutter + Riverpod 3.x + Isar。复用 `CharacterDerivedStats.effectiveEquipment*`(int)、`EquipmentService.equip/unequip`、`EnumL10n`、`UiStrings`、`WuxiaPaperPanel`、`WuxiaColors`。

---

## File Structure

- **Create** `lib/features/character_panel/domain/equipment_stat_diff.dart` — 纯函数 + `EquipmentComparison`/`StatDiffRow`/`CategoryRow` 数据类。
- **Create** `lib/features/character_panel/presentation/equip_slot_dialog.dart` — 两栏对话框 widget。
- **Modify** `lib/features/character_panel/presentation/character_panel_screen.dart:955` — `_tappableSlot` 改 `showDialog(EquipSlotDialog)`；删 `_EquipQuickActionSheet`(981-1086) + `_EquipPickerSheet`(1090-1294)。
- **Modify** `lib/shared/strings.dart` — 新增 UiStrings 标签。
- **Test** `test/features/character_panel/equipment_stat_diff_test.dart`
- **Test** `test/features/character_panel/equip_slot_dialog_test.dart`

---

## Task 1: 纯函数 equipmentFullDiff + 数据类

**Files:**
- Create: `lib/features/character_panel/domain/equipment_stat_diff.dart`
- Test: `test/features/character_panel/equipment_stat_diff_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/character_panel/equipment_stat_diff_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/features/character_panel/domain/equipment_stat_diff.dart';
import 'package:wuxia_idle/data/game_repository.dart';

Equipment _eq({
  int atk = 100, int hp = 100, int spd = 10, int enhance = 0,
  EquipmentTier tier = EquipmentTier.xunChangHuo,
  int battleCount = 0, bool heritage = false,
  TechniqueSchool? school, List<ForgingSlot>? forging,
}) => Equipment.create(
      defId: 'sword_xunchang_tie_jian', tier: tier, slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026), obtainedFrom: 'test',
      baseAttack: atk, baseHealth: hp, baseSpeed: spd, enhanceLevel: enhance,
      battleCount: battleCount, isLineageHeritage: heritage, school: school,
      forgingSlots: forging,
    );

void main() {
  setUpAll(() async {
    await GameRepository.instance.load();
  });
  final n = GameRepository.instance.numbers;

  test('候选攻高血低 → direction up/down/flat 正确', () {
    final cmp = equipmentFullDiff(
      current: _eq(atk: 100, hp: 200, spd: 10),
      candidate: _eq(atk: 150, hp: 100, spd: 10),
      numbers: n,
    );
    expect(cmp.isBaseline, isFalse);
    final atkRow = cmp.numericRows.firstWhere((r) => r.label.contains('攻'));
    final hpRow = cmp.numericRows.firstWhere((r) => r.label.contains('血'));
    final spdRow = cmp.numericRows.firstWhere((r) => r.label.contains('速'));
    expect(atkRow.direction, StatDirection.up);
    expect(hpRow.direction, StatDirection.down);
    expect(spdRow.direction, StatDirection.flat);
    expect(atkRow.candidateValue, greaterThan(atkRow.currentValue!));
  });

  test('空槽 current==null → isBaseline + currentValue null + 全 flat', () {
    final cmp = equipmentFullDiff(current: null, candidate: _eq(), numbers: n);
    expect(cmp.isBaseline, isTrue);
    expect(cmp.numericRows.every((r) => r.currentValue == null), isTrue);
    expect(cmp.numericRows.every((r) => r.direction == StatDirection.flat), isTrue);
    expect(cmp.numericRows.firstWhere((r) => r.label.contains('攻')).candidateValue,
        greaterThan(0));
  });

  test('品阶升 → categoryRow.highlightUp', () {
    final cmp = equipmentFullDiff(
      current: _eq(tier: EquipmentTier.xunChangHuo),
      candidate: _eq(tier: EquipmentTier.xiangYangHuo),
      numbers: n,
    );
    final tierRow = cmp.categoryRows.firstWhere((r) => r.label.contains('品阶'));
    expect(tierRow.highlightUp, isTrue);
  });

  test('开锋槽两侧长 3、空槽显占位', () {
    final cmp = equipmentFullDiff(current: _eq(), candidate: _eq(), numbers: n);
    expect(cmp.forgingCurrent.length, 3);
    expect(cmp.forgingCandidate.length, 3);
    expect(cmp.forgingCandidate.every((s) => s == EquipmentStatDiffText.emptyForging),
        isTrue);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/character_panel/equipment_stat_diff_test.dart`
Expected: FAIL — `equipment_stat_diff.dart` 不存在 / `equipmentFullDiff` undefined。

- [ ] **Step 3: 写实现**

```dart
// lib/features/character_panel/domain/equipment_stat_diff.dart
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../data/numbers_config.dart';
import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';

enum StatDirection { up, down, flat }

class StatDiffRow {
  const StatDiffRow({
    required this.label,
    required this.currentValue, // null = 空槽无基线
    required this.candidateValue,
    required this.direction,
  });
  final String label;
  final int? currentValue;
  final int candidateValue;
  final StatDirection direction;
}

class CategoryRow {
  const CategoryRow({
    required this.label,
    required this.currentText, // null = 空槽
    required this.candidateText,
    required this.highlightUp,
  });
  final String label;
  final String? currentText;
  final String candidateText;
  final bool highlightUp;
}

class EquipmentComparison {
  const EquipmentComparison({
    required this.isBaseline,
    required this.numericRows,
    required this.categoryRows,
    required this.forgingCurrent,
    required this.forgingCandidate,
  });
  final bool isBaseline;
  final List<StatDiffRow> numericRows;
  final List<CategoryRow> categoryRows;
  final List<String> forgingCurrent;  // 长 3
  final List<String> forgingCandidate; // 长 3
}

class EquipmentStatDiffText {
  static const labelAttack = '实战攻击';
  static const labelHealth = '实战血量';
  static const labelSpeed = '实战速度';
  static const labelEnhance = '强化等级';
  static const labelTier = '品阶';
  static const labelResonance = '共鸣';
  static const labelSchool = '流派';
  static const labelHeritage = '师承遗物';
  static const emptyForging = '—';
  static const schoolNone = '无';
  static const heritageYes = '遗物';
  static const heritageNo = '—';
}

StatDirection _dir(int? cur, int cand) {
  if (cur == null) return StatDirection.flat;
  if (cand > cur) return StatDirection.up;
  if (cand < cur) return StatDirection.down;
  return StatDirection.flat;
}

List<String> _forgingTexts(Equipment eq) {
  final out = <String>[];
  for (var i = 0; i < 3; i++) {
    final slot = i < eq.forgingSlots.length ? eq.forgingSlots[i] : null;
    if (slot == null || !slot.unlocked || slot.type == null) {
      out.add(EquipmentStatDiffText.emptyForging);
    } else if (slot.type == ForgingSlotType.specialSkill) {
      out.add(EnumL10n.forgingSlotType(slot.type!));
    } else {
      out.add('${EnumL10n.forgingSlotType(slot.type!)}+${slot.bonusValue}');
    }
  }
  return out;
}

/// 两件装备全量对比（纯函数，widget 只渲染不算）。current==null = 空槽基线态。
EquipmentComparison equipmentFullDiff({
  required Equipment? current,
  required Equipment candidate,
  required NumbersConfig numbers,
}) {
  int? cAtk, cHp, cSpd, cEnh;
  if (current != null) {
    cAtk = CharacterDerivedStats.effectiveEquipmentAttack(current, numbers);
    cHp = CharacterDerivedStats.effectiveEquipmentHp(current, numbers);
    cSpd = CharacterDerivedStats.effectiveEquipmentSpeed(current, numbers);
    cEnh = current.enhanceLevel;
  }
  final candAtk = CharacterDerivedStats.effectiveEquipmentAttack(candidate, numbers);
  final candHp = CharacterDerivedStats.effectiveEquipmentHp(candidate, numbers);
  final candSpd = CharacterDerivedStats.effectiveEquipmentSpeed(candidate, numbers);

  final numericRows = [
    StatDiffRow(label: EquipmentStatDiffText.labelAttack, currentValue: cAtk,
        candidateValue: candAtk, direction: _dir(cAtk, candAtk)),
    StatDiffRow(label: EquipmentStatDiffText.labelHealth, currentValue: cHp,
        candidateValue: candHp, direction: _dir(cHp, candHp)),
    StatDiffRow(label: EquipmentStatDiffText.labelSpeed, currentValue: cSpd,
        candidateValue: candSpd, direction: _dir(cSpd, candSpd)),
    StatDiffRow(label: EquipmentStatDiffText.labelEnhance, currentValue: cEnh,
        candidateValue: candidate.enhanceLevel,
        direction: _dir(cEnh, candidate.enhanceLevel)),
  ];

  final categoryRows = [
    CategoryRow(label: EquipmentStatDiffText.labelTier,
        currentText: current == null ? null : EnumL10n.equipmentTier(current.tier),
        candidateText: EnumL10n.equipmentTier(candidate.tier),
        highlightUp: current != null && candidate.tier.index > current.tier.index),
    CategoryRow(label: EquipmentStatDiffText.labelResonance,
        currentText: current == null
            ? null : EnumL10n.resonanceStage(current.resonanceStage(numbers)),
        candidateText: EnumL10n.resonanceStage(candidate.resonanceStage(numbers)),
        highlightUp: current != null &&
            candidate.resonanceStage(numbers).index > current.resonanceStage(numbers).index),
    CategoryRow(label: EquipmentStatDiffText.labelSchool,
        currentText: current == null
            ? null
            : (current.school == null
                ? EquipmentStatDiffText.schoolNone
                : EnumL10n.techniqueSchool(current.school!)),
        candidateText: candidate.school == null
            ? EquipmentStatDiffText.schoolNone
            : EnumL10n.techniqueSchool(candidate.school!),
        highlightUp: false),
    CategoryRow(label: EquipmentStatDiffText.labelHeritage,
        currentText: current == null
            ? null
            : (current.isLineageHeritage
                ? EquipmentStatDiffText.heritageYes
                : EquipmentStatDiffText.heritageNo),
        candidateText: candidate.isLineageHeritage
            ? EquipmentStatDiffText.heritageYes
            : EquipmentStatDiffText.heritageNo,
        highlightUp: candidate.isLineageHeritage &&
            (current == null || !current.isLineageHeritage)),
  ];

  return EquipmentComparison(
    isBaseline: current == null,
    numericRows: numericRows,
    categoryRows: categoryRows,
    forgingCurrent: current == null
        ? List.filled(3, EquipmentStatDiffText.emptyForging)
        : _forgingTexts(current),
    forgingCandidate: _forgingTexts(candidate),
  );
}
```

> **实现前核对**（subagent 开工首步 grep，防签名 drift）：
> - `EnumL10n.resonanceStage` / `EnumL10n.techniqueSchool` / `EnumL10n.equipmentTier` / `EnumL10n.forgingSlotType` 真实存在且签名匹配 —— `grep -nE 'static String (resonanceStage|techniqueSchool|equipmentTier|forgingSlotType)' lib/features/battle/domain/enum_localizations.dart`。若 `resonanceStage` 名不同(如 `resonance`)按实际改。
> - `Equipment.resonanceStage(n)` extension 在 `equipment.dart`（已确认 line 117）。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/character_panel/equipment_stat_diff_test.dart`
Expected: PASS（4 测）。若 EnumL10n 方法名不符，按 grep 结果修实现再跑。

- [ ] **Step 5: 提交**

```bash
git add lib/features/character_panel/domain/equipment_stat_diff.dart test/features/character_panel/equipment_stat_diff_test.dart
git commit -m "feat: 装备全量对比纯函数 equipmentFullDiff + 数据类(TDD)"
```

---

## Task 2: UiStrings 标签

**Files:**
- Modify: `lib/shared/strings.dart`

- [ ] **Step 1: 加标签**（沿 UiStrings 既有体例，找 equip 相关串聚集处插入）

```dart
// lib/shared/strings.dart — 装备槽对话框(2026-06-26)
static const equipSlotDialogConfirm = '确认更换';
static const equipSlotDialogEquip = '装备';
static const equipSlotDialogPickHint = '选一件查看属性';
static const equipSlotDialogCompareTitle = '属性对比';
static const equipSlotDialogForgingLabel = '开锋';
// 复用现有：equipQuickReplace/tabEnhance/tabForging/equipQuickViewLore/
// equipUnequip/equipPickerEmpty/equipPickerClose/currentEquippedBadge/
// equipWornByOther/equipLockedByRealm —— 不重复新增。
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues（新 static const 无语法错）。

- [ ] **Step 3: 提交**

```bash
git add lib/shared/strings.dart
git commit -m "feat: 装备槽对话框 UiStrings 标签"
```

---

## Task 3: EquipSlotDialog widget（两栏）

**Files:**
- Create: `lib/features/character_panel/presentation/equip_slot_dialog.dart`

- [ ] **Step 1: 写 widget**（ConsumerStatefulWidget，左候选 + 右对比；操作图标行）

```dart
// lib/features/character_panel/presentation/equip_slot_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_paper_panel.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../equipment/application/equipment_service.dart';
import '../../equipment/presentation/enhance_dialog.dart';
import '../../inventory/presentation/equipment_detail_screen.dart';
import '../domain/equipment_stat_diff.dart';

/// 装备槽统一对话框：点槽一步到位。左栏候选(带 mini-diff)，右栏全量对比。
/// 替代旧 `_EquipQuickActionSheet` + `_EquipPickerSheet`（贴底两步）。
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
    final outcome = await EquipmentService(isar: isar)
        .equip(characterId: widget.character.id, equipmentId: eq.id);
    if (!mounted) return;
    if (outcome == EquipOutcome.lockedByRealm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UiStrings.equipLockedByRealm)),
      );
      return;
    }
    _invalidate(touched: eq.id);
    Navigator.pop(context);
  }

  Future<void> _unequip() async {
    final isar = ref.read(isarProvider);
    if (isar == null) return;
    await EquipmentService(isar: isar)
        .unequip(characterId: widget.character.id, slot: widget.slot);
    if (!mounted) return;
    _invalidate();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final async = ref.watch(allEquipmentsProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.75,
        ),
        child: WuxiaPaperPanel(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$e', style: const TextStyle(color: WuxiaColors.hpLow)),
            ),
            data: (list) => _content(list),
          ),
        ),
      ),
    );
  }

  Widget _content(List<Equipment> all) {
    final items = all.where((e) => e.slot == widget.slot).toList();
    final current = widget.currentId == null
        ? null
        : all.where((e) => e.id == widget.currentId).cast<Equipment?>().firstWhere(
              (e) => e != null,
              orElse: () => null,
            );
    final selected = _selectedId == null
        ? null
        : items.cast<Equipment?>().firstWhere((e) => e?.id == _selectedId,
            orElse: () => null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          slot: widget.slot,
          current: current,
          onEnhance: current == null ? null : () => _openEnhance(current, 0),
          onForge: current == null ? null : () => _openEnhance(current, 1),
          onLore: current == null ? null : () => _openLore(current),
          onUnequip: current == null ? null : _unequip,
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
                  current: current,
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
                        current: current,
                        candidate: selected,
                        onConfirm: () => _equip(selected),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
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
}
```

> 注：`_Header` / `_CandidateList` / `_ComparePane` / `_ComparePlaceholder` 子 widget 在 Task 4 补。
> **核对**（开工 grep）：`isarProvider` 在 `isar_providers.dart`、`characterByIdProvider`/`equipmentByIdProvider`/`allEquipmentsProvider` 来源（character_panel_screen 现 import 处照抄），`EnhanceDialog`/`EquipmentDetailScreen`/`EquipmentService`/`EquipOutcome` import 路径以 character_panel_screen.dart 顶部为准。`Character.realmTier` getter 存在（picker 现用 `character.realmTier`）。

- [ ] **Step 2: 编译检查（占位子 widget 暂留编译错，Task 4 补全后再过）**

Run: `flutter analyze lib/features/character_panel/presentation/equip_slot_dialog.dart`
Expected: 报 `_Header`/`_CandidateList`/`_ComparePane`/`_ComparePlaceholder` undefined —— 预期，Task 4 补。

- [ ] **Step 3: 不单独提交**（与 Task 4 一起，避免中间不可编译态入库）。

---

## Task 4: 子 widget（Header / 候选行 / 对比面板）

**Files:**
- Modify: `lib/features/character_panel/presentation/equip_slot_dialog.dart`（追加子 widget）

- [ ] **Step 1: 追加子 widget**

```dart
// 追加到 equip_slot_dialog.dart 末尾

class _Header extends StatelessWidget {
  const _Header({
    required this.slot, required this.current,
    required this.onEnhance, required this.onForge, required this.onLore,
    required this.onUnequip, required this.onClose,
  });
  final EquipmentSlot slot;
  final Equipment? current;
  final VoidCallback? onEnhance, onForge, onLore, onUnequip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final name = current == null
        ? null
        : GameRepository.instance.getEquipment(current!.defId).name;
    return Row(
      children: [
        Expanded(
          child: Text(
            current == null
                ? '${UiStrings.equipPickerTitle} · ${EnumL10n.equipmentSlot(slot)}'
                : '${EnumL10n.equipmentSlot(slot)} · $name',
            style: const TextStyle(
                color: WuxiaColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        if (current != null) ...[
          _iconBtn(Icons.arrow_upward, UiStrings.tabEnhance, onEnhance),
          _iconBtn(Icons.auto_fix_high, UiStrings.tabForging, onForge),
          _iconBtn(Icons.menu_book, UiStrings.equipQuickViewLore, onLore),
          _iconBtn(Icons.remove_circle_outline, UiStrings.equipUnequip, onUnequip),
        ],
        _iconBtn(Icons.close, UiStrings.equipPickerClose, onClose),
      ],
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
        icon: Icon(icon, size: 20,
            color: onTap == null ? WuxiaColors.textMuted : WuxiaColors.textSecondary),
        tooltip: tip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      );
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.items, required this.current, required this.realmTier,
    required this.characterId, required this.selectedId, required this.onSelect,
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
        child: Text(UiStrings.equipPickerEmpty, textAlign: TextAlign.center,
            style: TextStyle(color: WuxiaColors.textMuted)),
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
        final cmp = equipmentFullDiff(current: current, candidate: eq, numbers: n);
        return Material(
          color: isSelected ? WuxiaColors.panel : Colors.transparent,
          child: ListTile(
            dense: true,
            enabled: canEquip,
            selected: isSelected,
            title: Text(name,
                style: TextStyle(
                  color: canEquip ? WuxiaColors.textPrimary : WuxiaColors.textMuted,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${EnumL10n.equipmentTier(eq.tier)} · '
                  '${UiStrings.enhanceLevel(eq.enhanceLevel)}'
                  '${isCurrent ? "  ${UiStrings.currentEquippedBadge}" : ""}',
                  style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12),
                ),
                if (!cmp.isBaseline) _MiniDiff(cmp: cmp),
              ],
            ),
            trailing: canEquip
                ? Icon(isCurrent ? Icons.check : Icons.chevron_right,
                    color: WuxiaColors.textSecondary, size: 18)
                : const Icon(Icons.lock_outline, color: WuxiaColors.textMuted, size: 16),
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
          ? '↑' : r.direction == StatDirection.down ? '↓' : '·';
      final tag = r.label.substring(2, 3); // 攻/血/速
      spans.add(TextSpan(
        text: '$tag$arrow${delta.abs()}  ',
        style: TextStyle(color: c, fontSize: 11),
      ));
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
          child: Text(UiStrings.equipSlotDialogPickHint,
              style: TextStyle(color: WuxiaColors.textMuted)),
        ),
      );
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({
    required this.current, required this.candidate, required this.onConfirm,
  });
  final Equipment? current;
  final Equipment candidate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final n = GameRepository.instance.numbers;
    final cmp = equipmentFullDiff(current: current, candidate: candidate, numbers: n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(UiStrings.equipSlotDialogCompareTitle,
              style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in cmp.numericRows) _numericRow(r, cmp.isBaseline),
                for (final r in cmp.categoryRows) _categoryRow(r, cmp.isBaseline),
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
            child: Text(cmp.isBaseline
                ? UiStrings.equipSlotDialogEquip
                : UiStrings.equipSlotDialogConfirm),
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
          Expanded(child: Text(r.label,
              style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12))),
          Text(right, style: TextStyle(color: c, fontSize: 13,
              fontWeight: FontWeight.w600)),
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
          Expanded(child: Text(r.label,
              style: const TextStyle(color: WuxiaColors.textMuted, fontSize: 12))),
          Text(right, style: TextStyle(
              color: r.highlightUp ? WuxiaColors.hpHigh : WuxiaColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600)),
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
          const Text(UiStrings.equipSlotDialogForgingLabel,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 12)),
          for (var i = 0; i < 3; i++)
            Text(
              cmp.isBaseline
                  ? cmp.forgingCandidate[i]
                  : '${cmp.forgingCurrent[i]} ▸ ${cmp.forgingCandidate[i]}',
              style: const TextStyle(color: WuxiaColors.textPrimary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 编译检查**

Run: `flutter analyze lib/features/character_panel/presentation/equip_slot_dialog.dart`
Expected: No issues。若报 `EnumL10n.equipmentSlot` 等签名不符，按实际 grep 修。

- [ ] **Step 3: 提交（Task 3+4 一起）**

```bash
git add lib/features/character_panel/presentation/equip_slot_dialog.dart
git commit -m "feat: EquipSlotDialog 两栏装备槽对话框(候选mini-diff+全量对比)"
```

---

## Task 5: 接入 character_panel_screen + 删旧 sheet

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`

- [ ] **Step 1: 改 `_tappableSlot`（955）为 showDialog**

```dart
// 替换 onTap 整块
onTap: () => showDialog<void>(
  context: context,
  builder: (_) => EquipSlotDialog(
    character: character,
    slot: slot,
    currentId: equipmentId,
  ),
),
```

- [ ] **Step 2: 删旧 `_EquipQuickActionSheet`(class 981-1086) 与 `_EquipPickerSheet`(class 1090-1294)**

整两个 class 删除。加 import：
```dart
import 'equip_slot_dialog.dart';
```

- [ ] **Step 3: grep 确认无残留引用**

Run: `grep -nE '_EquipQuickActionSheet|_EquipPickerSheet' lib/features/character_panel/presentation/character_panel_screen.dart`
Expected: 空（无输出）。若有残留，删除/改引用。

- [ ] **Step 4: 全项目 analyze**

Run: `flutter analyze`
Expected: No issues found（0）。可能暴露 `_tile`/未用 import 残留 → 清掉。

- [ ] **Step 5: 提交**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart
git commit -m "refactor: 装备槽改 EquipSlotDialog 一步到位,删旧贴底两 sheet"
```

---

## Task 6: widget 测试

**Files:**
- Test: `test/features/character_panel/equip_slot_dialog_test.dart`

- [ ] **Step 1: 写测试**（ListView 扩 viewport · memory `feedback_listview_widget_test_viewport`）

```dart
// test/features/character_panel/equip_slot_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_providers.dart';
import 'package:wuxia_idle/features/character_panel/presentation/equip_slot_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';
// + Isar 测试夹具 helper（沿用项目现有 test util 开内存 isar；
//   参考既有 character_panel / equipment 测的 setUp 体例）。

void main() {
  // setUp: GameRepository.instance.load() + 内存 Isar + 注入 1 角色 + 2 件 weapon。
  // 体例照抄已有 equipment 相关 widget 测（含 cp libisar.dylib 前置）。

  testWidgets('已装备态：渲染操作图标 + 选候选出确认更换', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // pump EquipSlotDialog(currentId: 已装备件id) 包 ProviderScope(isar override)
    // 1. 期望见 enhance/forge/lore/unequip 图标(by tooltip)
    // 2. 期望见候选列表 ≥1 行
    // 3. tap 一个候选 → 期望见 UiStrings.equipSlotDialogConfirm
  });

  testWidgets('空槽态：无卸下图标 + 初始占位 + 选后显装备', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // pump EquipSlotDialog(currentId: null)
    // 1. 期望初始见 UiStrings.equipSlotDialogPickHint
    // 2. tap 候选 → 期望见 UiStrings.equipSlotDialogEquip（非"确认更换"）
  });

  testWidgets('§5.3 灰显候选不可选', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // 注入一件 tier 高于角色境界的 weapon → 期望 lock 图标 + tap 不刷新右栏
  });
}
```

> **测试夹具核对**（开工首步）：找 1 个已有 equipment/character widget 测（如 `grep -rl "EquipmentService\|allEquipmentsProvider" test/`）抄其内存 Isar setUp + ProviderScope override 体例，避免重造。轻量测撞 GameRepository config 读 → 已在 dialog 用 `GameRepository.instance`，setUp 必 `load()`（memory `feedback_battle_result_path_config_read_crashes_light_test`）。fresh worktree 必先 cp libisar.dylib（memory `feedback_fresh_worktree_libisar_dylib`）。

- [ ] **Step 2: 跑测试**

Run: `flutter test test/features/character_panel/equip_slot_dialog_test.dart`
Expected: 先按真实夹具补全 setUp 后 PASS（3 测）。若 Isar dlopen 失败 → cp 主仓 libisar.dylib。

- [ ] **Step 3: 提交**

```bash
git add test/features/character_panel/equip_slot_dialog_test.dart
git commit -m "test: EquipSlotDialog widget 测(已装备/空槽/境界锁三态)"
```

---

## Task 7: 全量回归 + 收尾

- [ ] **Step 1: 全项目 analyze + 全量 test**

Run: `flutter analyze && flutter test`
Expected: analyze 0；test 全绿（基线 3130+1skip + 本批 ~7 新测，0 回归）。记录实测数字（防幻觉，禁转抄）。

- [ ] **Step 2: 真机目检（用户侧）**

`flutter run -d macos` → 角色屏点装备槽 → 验：居中两栏 / 操作图标 / 候选 mini-diff / 选候选右栏全量对比 / 确认更换生效 / 空槽态 / 境界锁灰显。手感问题反馈调。

- [ ] **Step 3: PROGRESS.md 顶段追加条目 + 提交**

```bash
git add PROGRESS.md
git commit -m "docs: PROGRESS - 装备槽对话框重做(一步到位+全量对比)"
```

---

## Self-Review 结论（写计划后自查）

- **Spec 覆盖**：#3 居中(Task 3 Dialog) ✅ / #3 一步到位操作收图标(Task 4 _Header) ✅ / #4 候选 mini-diff(Task 4 _MiniDiff) ✅ / #4 全量对比 7 维(Task 1 纯函数 + Task 4 _ComparePane) ✅ / 空槽 isBaseline(Task 1 + 渲染) ✅ / 删旧 sheet(Task 5) ✅ / 测试(Task 1/6) ✅。
- **类型一致**：`EquipmentComparison`/`StatDiffRow`/`CategoryRow`/`StatDirection`/`EquipmentStatDiffText` 跨 Task 1→4→6 命名一致；`equipmentFullDiff(current:, candidate:, numbers:)` 签名贯穿。
- **占位**：无 TBD；widget 测 setUp 标「照抄现有夹具」是有意（避免凭空造内存 Isar 体例致 drift），开工 grep 锚真实 util。
- **风险**：EnumL10n 方法名(`resonanceStage`/`techniqueSchool`)需开工 grep 验真名 —— 已在 Task 1/3/4 注「核对」步骤。
