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
    if (skill.canInterrupt ||
        skill.defenseBreakPct != 0 ||
        skill.qiDrainPct != 0) {
      throw StateError(
        'Phase0a numeric skill ${skill.id}: interrupt/defenseBreak/qiDrain '
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
