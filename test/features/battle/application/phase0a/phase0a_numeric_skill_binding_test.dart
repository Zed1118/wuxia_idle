import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

const testSkill = SkillDef(
  id: 'test_skill',
  name: 'test_skill',
  description: 'test_skill',
  type: SkillType.powerSkill,
  powerMultiplier: 1,
  qiDelta: -30,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
  targetType: TargetType.aoe,
);

Phase0aNumericSkillBinding binding(int hotkey) => Phase0aNumericSkillBinding(
  hotkey: hotkey,
  loadoutSlot: CombatantSkillLoadout.numericSlots[hotkey - 1],
  skill: testSkill,
  slotId: 'slot-$hotkey',
  attackRange: 10,
  halfArc: 20,
  effectRadius: 3,
  cooldownSeconds: 1,
);

void main() {
  test('validates binding and exposes skill-owned qiDelta/targetType', () {
    final b = binding(1);
    expect(b.hotkey, 1);
    expect(b.loadoutSlot, CombatantSkillSlot.main1);
    expect(b.qiDelta, -30);
    expect(b.targetType, TargetType.aoe);
  });

  test('rejects invalid hotkey, slot, text, and geometry values', () {
    expect(() => binding(0), throwsArgumentError);
    expect(() => binding(7), throwsArgumentError);
    expect(
      () => Phase0aNumericSkillBinding(
        hotkey: 1,
        loadoutSlot: CombatantSkillSlot.key,
        skill: testSkill,
        slotId: 'x',
        attackRange: 0,
        halfArc: 0,
        effectRadius: 0,
        cooldownSeconds: 0,
      ),
      throwsArgumentError,
    );
    const unsupported = SkillDef(
      id: 'unsupported',
      name: 'unsupported',
      description: 'unsupported',
      type: SkillType.powerSkill,
      powerMultiplier: 1,
      qiDelta: -30,
      cooldownTurns: 1,
      requiresManualTrigger: false,
      visualEffect: '',
      defenseBreakPct: 0.1,
    );
    expect(
      () => Phase0aNumericSkillBinding(
        hotkey: 1,
        loadoutSlot: CombatantSkillSlot.main1,
        skill: unsupported,
        slotId: 'x',
        attackRange: 0,
        halfArc: 0,
        effectRadius: 0,
        cooldownSeconds: 0,
      ),
      throwsStateError,
    );
    for (final value in [-1.0, double.infinity, double.nan]) {
      expect(
        () => Phase0aNumericSkillBinding(
          hotkey: 1,
          loadoutSlot: CombatantSkillSlot.main1,
          skill: testSkill,
          slotId: 'x',
          attackRange: value,
          halfArc: 0,
          effectRadius: 0,
          cooldownSeconds: 0,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => Phase0aNumericSkillBinding(
        hotkey: 1,
        loadoutSlot: CombatantSkillSlot.main1,
        skill: testSkill,
        slotId: '  ',
        attackRange: 0,
        halfArc: 0,
        effectRadius: 0,
        cooldownSeconds: 0,
      ),
      throwsArgumentError,
    );
  });

  test(
    'rejects legacy interrupt and qi-drain effects without typed consumers',
    () {
      const legacyInterrupt = SkillDef(
        id: 'legacy_interrupt',
        name: 'legacy_interrupt',
        description: 'legacy_interrupt',
        type: SkillType.powerSkill,
        powerMultiplier: 1,
        qiDelta: -30,
        cooldownTurns: 1,
        requiresManualTrigger: false,
        visualEffect: '',
        canInterrupt: true,
      );
      const legacyQiDrain = SkillDef(
        id: 'legacy_qi_drain',
        name: 'legacy_qi_drain',
        description: 'legacy_qi_drain',
        type: SkillType.powerSkill,
        powerMultiplier: 1,
        qiDelta: -30,
        cooldownTurns: 1,
        requiresManualTrigger: false,
        visualEffect: '',
        qiDrainPct: 0.1,
      );

      for (final skill in [legacyInterrupt, legacyQiDrain]) {
        expect(
          () => Phase0aNumericSkillBinding(
            hotkey: 1,
            loadoutSlot: CombatantSkillSlot.main1,
            skill: skill,
            slotId: 'x',
            attackRange: 0,
            halfArc: 0,
            effectRadius: 0,
            cooldownSeconds: 0,
          ),
          throwsStateError,
          reason: skill.id,
        );
      }
    },
  );

  test(
    'keeps stable hotkey order, empty slots, and an unmodifiable collection',
    () {
      const empty = Phase0aNumericSkillBindings.empty();
      expect(empty.equipped, isEmpty);
      final bindings = Phase0aNumericSkillBindings(
        one: binding(1),
        three: binding(3),
      );
      expect(bindings.bindingFor(1)?.slotId, 'slot-1');
      expect(bindings.bindingFor(2), isNull);
      expect(bindings.bindingFor(3)?.slotId, 'slot-3');
      expect(bindings.equipped.map((b) => b.hotkey), [1, 3]);
      expect(() => bindings.equipped.add(binding(4)), throwsUnsupportedError);
    },
  );
}
