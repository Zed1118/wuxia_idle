import '../../../../core/domain/enums.dart';
import '../../../../data/defs/phase0a_skill_behavior.dart';
import '../../../../data/defs/skill_def.dart';

enum Phase0aTacticalSkillKind { gather, clear }

/// Application-owned validation boundary between SkillDef behavior and the
/// reducer's currently supported Q/R intents.
final class Phase0aTacticalSkillBinding {
  Phase0aTacticalSkillBinding({
    required this.kind,
    required this.slot,
    required this.skill,
  }) {
    if (slot.trim().isEmpty) {
      throw ArgumentError.value(slot, 'slot', 'must not be empty');
    }
    final behavior = skill.phase0aBehavior;
    if (behavior == null) {
      throw StateError('${skill.id} has no Phase0a behavior');
    }
    if (skill.targetType != TargetType.aoe) {
      throw StateError('${skill.id} tactical behavior requires aoe targetType');
    }
    if (skill.source != SkillSource.special) {
      throw StateError('${skill.id} tactical behavior requires special source');
    }
    if (skill.qiDelta > 0 || skill.cooldownTurns < 0) {
      throw StateError('${skill.id} has unsupported tactical qi/cooldown');
    }
    final effectTypes = behavior.effects.map((effect) => effect.type).toSet();
    // 精确集匹配仍 fail-closed:Q 保持纯 pull;R 自 charge/破招批起接受
    // damage+stagger+break(break 经 reducer 破招状态迁移消费)。
    final expected = switch (kind) {
      Phase0aTacticalSkillKind.gather => {Phase0aSkillEffectType.pull},
      Phase0aTacticalSkillKind.clear => {
        Phase0aSkillEffectType.damage,
        Phase0aSkillEffectType.stagger,
        Phase0aSkillEffectType.breakPower,
      },
    };
    if (effectTypes.length != expected.length ||
        !effectTypes.containsAll(expected)) {
      throw StateError(
        '${skill.id} has unsupported ${kind.name} effects: '
        '${effectTypes.map((effect) => effect.name).toList()}',
      );
    }
  }

  final Phase0aTacticalSkillKind kind;
  final String slot;
  final SkillDef skill;

  Phase0aSkillBehavior get behavior => skill.phase0aBehavior!;
  double get effectRadius => behavior.geometry.radius;
  double? get destinationRadius =>
      behavior.effectOf(Phase0aSkillEffectType.pull)?.destinationRadius;
  int get qiCost => skill.qiCost;

  /// typed break 契约载荷(reducer 破招迁移唯一触发源);无 break 效果 = 0。
  int get breakPower =>
      behavior.effectOf(Phase0aSkillEffectType.breakPower)?.points ?? 0;

  /// Transitional tactical skills interpret legacy cooldown turns as seconds.
  /// Numeric and enemy bindings retain their existing conversion policies.
  double get cooldownSeconds => skill.cooldownTurns.toDouble();
}
