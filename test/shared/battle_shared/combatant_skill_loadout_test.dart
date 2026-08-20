import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

SkillDef skill(String id) => SkillDef(
  id: id,
  name: id,
  description: id,
  type: SkillType.powerSkill,
  powerMultiplier: 1,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

void main() {
  test('reads all seven slots and keeps stable equipped order', () {
    final loadout = CombatantSkillLoadout(
      main1: skill('main1'),
      main2: skill('main2'),
      assist: skill('assist'),
      resonance: skill('resonance'),
      ultimate: skill('ultimate'),
      encounter: skill('encounter'),
      key: skill('key'),
    );

    expect(loadout.skillFor(CombatantSkillSlot.key)?.id, 'key');
    expect(loadout.equippedSkills.map((s) => s.id), [
      'main1',
      'main2',
      'assist',
      'resonance',
      'ultimate',
      'encounter',
      'key',
    ]);
    expect(loadout.ids, [
      'main1',
      'main2',
      'assist',
      'resonance',
      'ultimate',
      'encounter',
      'key',
    ]);
  });

  test(
    'numeric slots are fixed, preserve empty positions, and exclude key',
    () {
      expect(CombatantSkillLoadout.numericSlots, [
        CombatantSkillSlot.main1,
        CombatantSkillSlot.main2,
        CombatantSkillSlot.assist,
        CombatantSkillSlot.resonance,
        CombatantSkillSlot.ultimate,
        CombatantSkillSlot.encounter,
      ]);
      final loadout = CombatantSkillLoadout(
        main1: skill('one'),
        ultimate: skill('five'),
      );
      expect(
        CombatantSkillLoadout.numericSlots
            .map(loadout.skillFor)
            .map((s) => s?.id),
        ['one', null, null, null, 'five', null],
      );
      expect(
        CombatantSkillLoadout.numericSlots,
        isNot(contains(CombatantSkillSlot.key)),
      );
    },
  );

  test('empty is const-compatible and collections are not writable', () {
    const loadout = CombatantSkillLoadout.empty();
    expect(loadout.equippedSkills, isEmpty);
    expect(loadout.ids, isEmpty);
    expect(
      () => loadout.equippedSkills.add(skill('x')),
      throwsUnsupportedError,
    );
    expect(() => loadout.ids.add('x'), throwsUnsupportedError);
  });
}
