import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';

/// Pre-resolved enemy skill behavior for the Phase 0A arena.
///
/// Spatial values come from `numbers.phase0a_arena`; skill qi/cooldown/damage
/// values remain the production [SkillDef] values. Dynamic mechanics that the
/// reducer cannot consume yet fail fast here instead of being dropped.
final class Phase0aEnemySkillBinding {
  Phase0aEnemySkillBinding({
    required this.skill,
    required this.attackRange,
    required this.halfArcRadians,
    required this.effectRadius,
    required this.cooldownSeconds,
  }) {
    if (skill.canInterrupt ||
        skill.defenseBreakPct != 0 ||
        skill.qiDrainPct != 0) {
      throw StateError(
        'Phase0a enemy skill ${skill.id}: '
        'interrupt/defenseBreak/qiDrain is unsupported',
      );
    }
    for (final entry in {
      'attackRange': attackRange,
      'halfArcRadians': halfArcRadians,
      'effectRadius': effectRadius,
      'cooldownSeconds': cooldownSeconds,
    }.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must be finite and non-negative',
        );
      }
    }
  }

  final SkillDef skill;
  final double attackRange;
  final double halfArcRadians;
  final double effectRadius;
  final double cooldownSeconds;

  bool get isAutoSkill =>
      skill.type == SkillType.powerSkill || skill.type == SkillType.ultimate;
}
