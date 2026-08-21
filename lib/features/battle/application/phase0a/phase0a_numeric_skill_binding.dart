import '../../../../data/defs/phase0a_skill_behavior.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../core/domain/enums.dart';
import '../../../../shared/battle_shared/combatant_skill_loadout.dart';

class Phase0aNumericSkillBinding {
  Phase0aNumericSkillBinding({
    required this.hotkey,
    required this.loadoutSlot,
    required this.skill,
    required this.slotId,
    required this.attackRange,
    required this.halfArc,
    required this.effectRadius,
    required this.cooldownSeconds,
  }) {
    if (hotkey < 1 || hotkey > 6) {
      throw ArgumentError.value(hotkey, 'hotkey', 'must be in 1..6');
    }
    if (loadoutSlot != CombatantSkillLoadout.numericSlots[hotkey - 1]) {
      throw ArgumentError('loadoutSlot must match hotkey numeric slot');
    }
    if (slotId.trim().isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'must not be empty');
    }
    // canInterrupt 自 charge/破招批起只认 typed 契约:带 phase0aBehavior
    // break 效果者放行(经 Phase0aSkillIntent.breakPower 进 reducer 破招
    // 迁移),无 typed behavior 者仍大声拒绝(fail-closed,不猜名称/标志)。
    if (skill.canInterrupt &&
        !(skill.phase0aBehavior?.hasEffect(Phase0aSkillEffectType.breakPower) ??
            false)) {
      throw StateError(
        'Phase0a numeric skill ${skill.id}: canInterrupt 技能缺 '
        'phase0aBehavior.break typed 契约，禁止静默丢失',
      );
    }
    if (skill.defenseBreakPct != 0 || skill.qiDrainPct != 0) {
      throw StateError(
        'Phase0a numeric skill ${skill.id}: defenseBreak/qiDrain '
        '尚无 reducer 状态消费方，禁止静默丢失',
      );
    }
    for (final entry in {
      'attackRange': attackRange,
      'halfArc': halfArc,
      'effectRadius': effectRadius,
      'cooldownSeconds': cooldownSeconds,
    }.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must be finite and nonnegative',
        );
      }
    }
  }

  final int hotkey;
  final CombatantSkillSlot loadoutSlot;
  final SkillDef skill;
  final String slotId;
  final double attackRange;
  final double halfArc;
  final double effectRadius;
  final double cooldownSeconds;

  int get qiDelta => skill.qiDelta;
  TargetType get targetType => skill.targetType;

  /// typed break 契约载荷(reducer 破招迁移唯一触发源);无 break 效果 = 0。
  int get breakPower =>
      skill.phase0aBehavior
          ?.effectOf(Phase0aSkillEffectType.breakPower)
          ?.points ??
      0;
}

class Phase0aNumericSkillBindings {
  const Phase0aNumericSkillBindings({
    this.one,
    this.two,
    this.three,
    this.four,
    this.five,
    this.six,
  });

  const Phase0aNumericSkillBindings.empty()
    : one = null,
      two = null,
      three = null,
      four = null,
      five = null,
      six = null;

  final Phase0aNumericSkillBinding? one;
  final Phase0aNumericSkillBinding? two;
  final Phase0aNumericSkillBinding? three;
  final Phase0aNumericSkillBinding? four;
  final Phase0aNumericSkillBinding? five;
  final Phase0aNumericSkillBinding? six;

  Phase0aNumericSkillBinding? bindingFor(int hotkey) => switch (hotkey) {
    1 => one,
    2 => two,
    3 => three,
    4 => four,
    5 => five,
    6 => six,
    _ => null,
  };

  List<Phase0aNumericSkillBinding> get equipped => List.unmodifiable(
    [one, two, three, four, five, six].whereType<Phase0aNumericSkillBinding>(),
  );
}
