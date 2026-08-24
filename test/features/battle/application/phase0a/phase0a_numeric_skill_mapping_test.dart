import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

CombatantSnapshot player(NumbersConfig numbers) => testCombatantSnapshot(
  characterId: 1,
  name: 'mapping player',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  internalForce: 600,
  maxQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: 130,
  mainCultivationLayer: CultivationLayer.chuKui,
);

void main() {
  late GameRepository repo;

  setUpAll(() async => repo = await loadTestGameRepository());

  test('maps real Ch1 skills without compressing empty numeric slots', () {
    final numbers = repo.numbers;
    final skills = repo.skillDefs;
    final snapshot = player(numbers).copyWith(
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
    final bindings = mapping.playerAdapter.numericSkillBindings;

    expect(
      mapping.moveBindings[Phase0aDamageKind.basic]?.id,
      'skill_gangmeng_jichu_basic',
    );
    expect(bindings.one?.skill.id, 'skill_gangmeng_jichu_skill');
    expect(bindings.three?.skill.id, 'skill_gangmeng_jichu_skill');
    expect(bindings.five?.skill.id, 'skill_gangmeng_jichu_ult');
    expect(bindings.two, isNull);
    expect(bindings.four, isNull);
    expect(bindings.six, isNull);
    expect(bindings.equipped.map((b) => b.hotkey), [1, 3, 5]);
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
      final skill = bindings.bindingFor(hotkey)!.skill;
      expect(intent.skillId, skill.id);
      expect(intent.kind, phase0aDamageKindForSkillHotkey(hotkey));
      expect(intent.slot, 'phase0a_skill_$hotkey');
      expect(intent.qiDelta, skill.qiDelta);
      expect(intent.targetType, skill.targetType);
      expect(intent.cooldownSeconds, skill.cooldownSeconds);
    }
  });

  test(
    'normalAttack stays on mouse basic and is excluded from numeric slots',
    () {
      final numbers = repo.numbers;
      final basic = repo.getSkill('skill_gangmeng_jichu_basic');
      final snapshot = player(numbers).copyWith(
        skillLoadout: CombatantSkillLoadout(basicAttack: basic, main1: basic),
      );
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: snapshot,
        numbers: numbers,
      );

      expect(mapping.moveBindings[Phase0aDamageKind.basic], same(basic));
      expect(mapping.playerAdapter.numericSkillBindings.equipped, isEmpty);
      expect(
        mapping.playerAdapter.intentsFor(
          state: mapping.initialState,
          command: const Phase0aPlayerCommand(skillHotkey: 1),
        ),
        isEmpty,
      );
    },
  );

  test('full legacy mapping reuses the player-only assembly fields', () {
    final numbers = repo.numbers;
    final skills = repo.skillDefs;
    final snapshot = player(numbers).copyWith(
      skillLoadout: CombatantSkillLoadout(
        basicAttack: skills['skill_gangmeng_jichu_basic'],
        main1: skills['skill_gangmeng_jichu_skill'],
      ),
    );
    final playerOnly = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_01',
      playerSnapshot: snapshot,
      numbers: numbers,
    );
    final full = Phase0aStageContentMapper.map(
      stage: repo.getStage('stage_01_01'),
      playerSnapshot: snapshot,
      numbers: numbers,
    );

    expect(full.initialState.player.id, playerOnly.initialPlayer.id);
    expect(
      full.initialState.player.position.x,
      playerOnly.initialPlayer.position.x,
    );
    expect(
      full.initialState.player.position.y,
      playerOnly.initialPlayer.position.y,
    );
    expect(
      full.initialState.skillSlots.map((slot) => slot.slot),
      playerOnly.skillSlots.map((slot) => slot.slot),
    );
    expect(full.moveBindings.keys, playerOnly.moveBindings.keys);
    for (final kind in playerOnly.moveBindings.keys) {
      expect(full.moveBindings[kind], same(playerOnly.moveBindings[kind]));
    }
    expect(full.playerAdapter.playerId, playerOnly.playerAdapter.playerId);
    expect(
      full.playerAdapter.numericSkillBindings.equipped.map(
        (binding) => binding.skill.id,
      ),
      playerOnly.playerAdapter.numericSkillBindings.equipped.map(
        (binding) => binding.skill.id,
      ),
    );
  });
}
