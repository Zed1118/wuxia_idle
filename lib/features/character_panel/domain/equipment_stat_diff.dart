import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/forging_slot.dart';
import '../../../data/numbers_config.dart';
import '../../battle/domain/derived_stats.dart';
import '../../battle/domain/enum_localizations.dart';

/// 装备槽对话框「全量对比」的纯数据层（2026-06-26 · 一步到位 + 全量对比）。
///
/// [equipmentFullDiff] 把「当前装备 vs 候选装备」算成结构化对比结果，widget
/// 只渲染不算（口径锁在这里，可 TDD）。`current==null` = 空槽基线态。
enum StatDirection { up, down, flat }

/// 数值维一行（实战攻/血/速、强化等级）。`currentValue==null` = 空槽无基线。
class StatDiffRow {
  const StatDiffRow({
    required this.label,
    required this.currentValue,
    required this.candidateValue,
    required this.direction,
  });
  final String label;
  final int? currentValue;
  final int candidateValue;
  final StatDirection direction;
}

/// 类别维一行（品阶/共鸣/流派/师承）。`currentText==null` = 空槽。
class CategoryRow {
  const CategoryRow({
    required this.label,
    required this.currentText,
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
  final List<String> forgingCurrent; // 长 3
  final List<String> forgingCandidate; // 长 3
}

/// 集中文案（中文不散写，与 UiStrings/EnumL10n 同类合法 sink）。
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

/// 两件装备全量对比。`current==null` = 空槽基线态（渲染层据 [EquipmentComparison.isBaseline]
/// 只显候选绝对值、不画箭头）。effective* 走派生乘法链（强化×共鸣×开锋），非裸 base。
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
  final candAtk =
      CharacterDerivedStats.effectiveEquipmentAttack(candidate, numbers);
  final candHp = CharacterDerivedStats.effectiveEquipmentHp(candidate, numbers);
  final candSpd =
      CharacterDerivedStats.effectiveEquipmentSpeed(candidate, numbers);

  final numericRows = [
    StatDiffRow(
      label: EquipmentStatDiffText.labelAttack,
      currentValue: cAtk,
      candidateValue: candAtk,
      direction: _dir(cAtk, candAtk),
    ),
    StatDiffRow(
      label: EquipmentStatDiffText.labelHealth,
      currentValue: cHp,
      candidateValue: candHp,
      direction: _dir(cHp, candHp),
    ),
    StatDiffRow(
      label: EquipmentStatDiffText.labelSpeed,
      currentValue: cSpd,
      candidateValue: candSpd,
      direction: _dir(cSpd, candSpd),
    ),
    StatDiffRow(
      label: EquipmentStatDiffText.labelEnhance,
      currentValue: cEnh,
      candidateValue: candidate.enhanceLevel,
      direction: _dir(cEnh, candidate.enhanceLevel),
    ),
  ];

  final categoryRows = [
    CategoryRow(
      label: EquipmentStatDiffText.labelTier,
      currentText:
          current == null ? null : EnumL10n.equipmentTier(current.tier),
      candidateText: EnumL10n.equipmentTier(candidate.tier),
      highlightUp:
          current != null && candidate.tier.index > current.tier.index,
    ),
    CategoryRow(
      label: EquipmentStatDiffText.labelResonance,
      currentText: current == null
          ? null
          : EnumL10n.resonanceStage(current.resonanceStage(numbers)),
      candidateText:
          EnumL10n.resonanceStage(candidate.resonanceStage(numbers)),
      highlightUp: current != null &&
          candidate.resonanceStage(numbers).index >
              current.resonanceStage(numbers).index,
    ),
    CategoryRow(
      label: EquipmentStatDiffText.labelSchool,
      currentText: current == null
          ? null
          : (current.school == null
              ? EquipmentStatDiffText.schoolNone
              : EnumL10n.school(current.school!)),
      candidateText: candidate.school == null
          ? EquipmentStatDiffText.schoolNone
          : EnumL10n.school(candidate.school!),
      highlightUp: false,
    ),
    CategoryRow(
      label: EquipmentStatDiffText.labelHeritage,
      currentText: current == null
          ? null
          : (current.isLineageHeritage
              ? EquipmentStatDiffText.heritageYes
              : EquipmentStatDiffText.heritageNo),
      candidateText: candidate.isLineageHeritage
          ? EquipmentStatDiffText.heritageYes
          : EquipmentStatDiffText.heritageNo,
      highlightUp: candidate.isLineageHeritage &&
          (current == null || !current.isLineageHeritage),
    ),
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
