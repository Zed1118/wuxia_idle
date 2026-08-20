import '../../data/defs/skill_def.dart';

/// Logical combat slots exposed by a combatant's loadout.
enum CombatantSkillSlot {
  main1,
  main2,
  assist,
  resonance,
  ultimate,
  encounter,
  key,
}

/// Immutable combat-facing view of the seven persisted skill slots.
class CombatantSkillLoadout {
  const CombatantSkillLoadout({
    this.basicAttack,
    this.main1,
    this.main2,
    this.assist,
    this.resonance,
    this.ultimate,
    this.encounter,
    this.key,
  });

  const CombatantSkillLoadout.empty()
    : basicAttack = null,
      main1 = null,
      main2 = null,
      assist = null,
      resonance = null,
      ultimate = null,
      encounter = null,
      key = null;

  static const List<CombatantSkillSlot> numericSlots = [
    CombatantSkillSlot.main1,
    CombatantSkillSlot.main2,
    CombatantSkillSlot.assist,
    CombatantSkillSlot.resonance,
    CombatantSkillSlot.ultimate,
    CombatantSkillSlot.encounter,
  ];

  /// 主修心法的真实普通攻击，不占数字 1–6 装配槽。
  final SkillDef? basicAttack;

  final SkillDef? main1;
  final SkillDef? main2;
  final SkillDef? assist;
  final SkillDef? resonance;
  final SkillDef? ultimate;
  final SkillDef? encounter;
  final SkillDef? key;

  SkillDef? skillFor(CombatantSkillSlot slot) => switch (slot) {
    CombatantSkillSlot.main1 => main1,
    CombatantSkillSlot.main2 => main2,
    CombatantSkillSlot.assist => assist,
    CombatantSkillSlot.resonance => resonance,
    CombatantSkillSlot.ultimate => ultimate,
    CombatantSkillSlot.encounter => encounter,
    CombatantSkillSlot.key => key,
  };

  /// All equipped skills, preserving the seven-slot order and omitting nulls.
  List<SkillDef> get equippedSkills => List.unmodifiable(
    [
      main1,
      main2,
      assist,
      resonance,
      ultimate,
      encounter,
      key,
    ].whereType<SkillDef>(),
  );

  /// All equipped skill ids, preserving the seven-slot order and omitting nulls.
  List<String> get ids =>
      List.unmodifiable(equippedSkills.map((skill) => skill.id));
}
