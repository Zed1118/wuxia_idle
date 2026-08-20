import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../../../../support/test_data.dart';

BattleCharacter player(NumbersConfig numbers) => BattleCharacter(
  characterId: 1,
  name: 'mapping player',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  currentHp: 15000,
  internalForce: 600,
  maxQi: 100,
  currentQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: 130,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: 0,
  slotIndex: 0,
);

void main() {
  late GameRepository repo;

  setUpAll(() async => repo = await loadTestGameRepository());

  test('maps real Ch1 skills without compressing empty numeric slots', () {
    final numbers = repo.numbers;
    final skills = repo.skillDefs;
    final snapshot = Legacy3v3CombatantAdapter.toSnapshot(player(numbers))
        .copyWith(
          skillLoadout: CombatantSkillLoadout(
            basicAttack: skills['skill_gangmeng_jichu_basic'],
            main1: skills['skill_gangmeng_jichu_skill'],
            assist: skills['skill_gangmeng_jichu_skill'],
            ultimate: skills['skill_gangmeng_jichu_ult'],
          ),
        );
    final mapping = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_01'),
      playerSnapshot: snapshot,
      numbers: numbers,
    );
    final arena = numbers.phase0aArena;

    expect(
      mapping.moveBindings[Phase0aDamageKind.basic]?.id,
      'skill_gangmeng_jichu_basic',
    );
    expect(
      mapping.numericSkillBindings.one?.skill.id,
      'skill_gangmeng_jichu_skill',
    );
    expect(
      mapping.numericSkillBindings.three?.skill.id,
      'skill_gangmeng_jichu_skill',
    );
    expect(
      mapping.numericSkillBindings.five?.skill.id,
      'skill_gangmeng_jichu_ult',
    );
    expect(mapping.numericSkillBindings.two, isNull);
    expect(mapping.numericSkillBindings.four, isNull);
    expect(mapping.numericSkillBindings.six, isNull);
    expect(mapping.numericSkillBindings.equipped.map((b) => b.hotkey), [
      1,
      3,
      5,
    ]);
    expect(
      mapping.playerAdapter.numericSkillBindings,
      same(mapping.numericSkillBindings),
    );

    final slots = mapping.initialState.skillSlots;
    expect(slots.map((s) => s.slot), [
      arena.gatherSlot,
      arena.clearSlot,
      'phase0a_skill_1',
      'phase0a_skill_3',
      'phase0a_skill_5',
    ]);
    expect(slots[2].qiCost, skills['skill_gangmeng_jichu_skill']!.qiCost);
    expect(slots[3].qiCost, skills['skill_gangmeng_jichu_skill']!.qiCost);
    expect(slots[4].qiCost, skills['skill_gangmeng_jichu_ult']!.qiCost);
    expect(slots[2].availability, Phase0aSkillAvailability.ready);
    expect(slots[4].availability, Phase0aSkillAvailability.ready);

    for (final hotkey in [2, 4, 6]) {
      expect(
        mapping.playerAdapter.intentsFor(
          state: mapping.initialState,
          command: Phase0aPlayerCommand(skillHotkey: hotkey),
        ),
        isEmpty,
      );
    }
    for (final hotkey in [1, 3, 5]) {
      final intents = mapping.playerAdapter.intentsFor(
        state: mapping.initialState,
        command: Phase0aPlayerCommand(skillHotkey: hotkey),
      );
      final intent = intents.single as Phase0aSkillIntent;
      final skill = mapping.numericSkillBindings.bindingFor(hotkey)!.skill;
      expect(intent.skillId, skill.id);
      expect(intent.kind, Phase0aDamageKindX.forSkillHotkey(hotkey));
      expect(intent.slot, 'phase0a_skill_$hotkey');
      expect(intent.qiDelta, skill.qiDelta);
      expect(intent.targetType, skill.targetType);
      expect(
        intent.cooldownSeconds,
        skill.cooldownTurns * arena.playerAttackCooldownSeconds,
      );
    }
  });
}
