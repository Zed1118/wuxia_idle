import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_skill_seals.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/strings.dart';

SkillDef _skill(String id, String name, int qiDelta) => SkillDef(
  id: id,
  name: name,
  description: name,
  type: SkillType.powerSkill,
  powerMultiplier: 100,
  qiDelta: qiDelta,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);

Phase0aNumericSkillBinding _binding(int hotkey, SkillDef skill) =>
    Phase0aNumericSkillBinding(
      hotkey: hotkey,
      loadoutSlot: CombatantSkillLoadout.numericSlots[hotkey - 1],
      skill: skill,
      visualSchool: TechniqueSchool.gangMeng,
      slotId: 'skill_$hotkey',
      attackRange: 100,
      halfArc: 1,
      effectRadius: 200,
      cooldownSeconds: 2,
    );

void main() {
  for (final hasRuntime in [false, true]) {
    testWidgets('bound down or missing runtime stays disabled ($hasRuntime)', (
      tester,
    ) async {
      final binding = _binding(1, _skill('one', 'One', -20));
      final pressed = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Phase0aNumericSkillSeals(
              bindings: Phase0aNumericSkillBindings(one: binding),
              slots: {
                if (hasRuntime)
                  'skill_1': const Phase0aSkillSlot(
                    slot: 'skill_1',
                    cooldownRemaining: 0,
                    qiCost: 20,
                    availability: Phase0aSkillAvailability.down,
                  ),
              },
              qiCurrent: 40,
              onPressed: pressed.add,
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.phase0aSealDown), findsOneWidget);
      await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(1)));
      expect(pressed, isEmpty);
      expect(
        tester
            .getSemantics(find.byKey(Phase0aNumericSkillSeals.keyFor(1)))
            .label,
        'One 1 ${UiStrings.phase0aSealDown}',
      );
    });
  }

  testWidgets('六槽位置稳定、真实技能名与键位可见，空槽不压缩', (tester) async {
    final one = _binding(1, _skill('one', '一苇渡江', -20));
    final three = _binding(3, _skill('three', '三叠浪', -30));
    final five = _binding(5, _skill('five', '五岳归一', -60));
    final pressed = <int>[];

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Phase0aNumericSkillSeals(
              bindings: Phase0aNumericSkillBindings(
                one: one,
                three: three,
                five: five,
              ),
              slots: const {
                'skill_1': Phase0aSkillSlot(
                  slot: 'skill_1',
                  cooldownRemaining: 0,
                  qiCost: 20,
                  availability: Phase0aSkillAvailability.ready,
                ),
                'skill_3': Phase0aSkillSlot(
                  slot: 'skill_3',
                  cooldownRemaining: 1.5,
                  qiCost: 30,
                  availability: Phase0aSkillAvailability.cooldown,
                ),
                'skill_5': Phase0aSkillSlot(
                  slot: 'skill_5',
                  cooldownRemaining: 0,
                  qiCost: 60,
                  availability: Phase0aSkillAvailability.qi,
                ),
              },
              qiCurrent: 40,
              onPressed: pressed.add,
            ),
          ),
        ),
      ),
    );

    for (var hotkey = 1; hotkey <= 6; hotkey++) {
      expect(
        find.byKey(Phase0aNumericSkillSeals.keyFor(hotkey)),
        findsOneWidget,
      );
      expect(find.text('$hotkey'), findsOneWidget);
    }
    expect(find.text('一苇渡江'), findsOneWidget);
    expect(find.text('三叠浪'), findsOneWidget);
    expect(find.text('五岳归一'), findsOneWidget);
    expect(find.text('未装备'), findsNWidgets(3));
    expect(find.text(UiStrings.phase0aSealDown), findsNothing);
    for (final emptyHotkey in [2, 4, 6]) {
      final empty = tester.getSemantics(
        find.byKey(Phase0aNumericSkillSeals.keyFor(emptyHotkey)),
      );
      expect(empty.label, '${UiStrings.slotEmpty} $emptyHotkey');
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(1)));
    await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(2)));
    await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(3)));
    await tester.tap(find.byKey(Phase0aNumericSkillSeals.keyFor(5)));
    expect(pressed, [1]);

    final semantics = tester.getSemantics(
      find.byKey(Phase0aNumericSkillSeals.keyFor(1)),
    );
    expect(semantics.label, contains('一苇渡江'));
    expect(semantics.label, contains('1'));
  });
}
