import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

void main() {
  late GameRepository repo;
  late Map<String, dynamic> numbersYaml;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    numbersYaml = parseYamlMap(await loadTestAsset('data/numbers.yaml'));
  });

  Map<String, dynamic> copyNumbers() =>
      (jsonDecode(jsonEncode(numbersYaml)) as Map).cast<String, dynamic>();

  Map<String, dynamic> copyMapping() =>
      ((copyNumbers()['phase0a_arena'] as Map)['weapon_mapping'] as Map)
          .cast<String, dynamic>();

  CombatantSnapshot player({
    WeaponArchetype? weapon = WeaponArchetype.sword,
    double gain = 1,
    double reduction = 0,
    CombatantSkillLoadout? loadout,
  }) => testCombatantSnapshot(
    weaponArchetype: weapon,
    maxQi: 130,
    currentQi: 23,
    qiGainMultiplier: gain,
    qiCostReductionPct: reduction,
    skillLoadout:
        loadout ??
        CombatantSkillLoadout(
          basicAttack: repo.getSkill('skill_gangmeng_jichu_basic'),
          main1: repo.getSkill('skill_gangmeng_jichu_skill'),
          main2: repo.getSkill('skill_hui_xiu_hui_feng'),
          assist: repo.getSkill('skill_chen_sha_yi_jue'),
          resonance: repo.getSkill('skill_zhi_shui_jue'),
          ultimate: repo.getSkill('skill_gangmeng_jichu_ult'),
        ),
  );

  Phase0aPlayerRuntimeMapping mapPlayer(
    CombatantSnapshot snapshot, {
    NumbersConfig? numbers,
  }) => Phase0aStageContentMapper.mapPlayerOnly(
    contentId: 'm0_mapping_probe',
    playerSnapshot: snapshot,
    numbers: numbers ?? repo.numbers,
  );

  Phase0aArenaState stateOf(Phase0aPlayerRuntimeMapping mapping) =>
      Phase0aArenaState(
        tick: 0,
        nextSeq: 0,
        player: mapping.initialPlayer,
        enemies: const [],
        skillSlots: mapping.skillSlots,
      );

  // Approved B's full nine-value vectors and C's resource amounts, independent
  // of the loader's representation and the mapper's arithmetic.
  const expected = {
    WeaponArchetype.sword: ([1, 2, 3, 1, 1, 4, 3, 2, 4], [20, 28, 52]),
    WeaponArchetype.heavy: ([2, 3, 3, 2, 2, 5, 4, 3, 5], [24, 34, 60]),
    WeaponArchetype.flexible: ([1, 4, 2, 1, 1, 4, 3, 2, 4], [22, 30, 54]),
    WeaponArchetype.dual: ([0, 4, 2, 0, 0, 4, 2, 1, 3], [18, 24, 46]),
    WeaponArchetype.hidden: ([0, 2, 3, 0, 0, 3, 2, 1, 3], [18, 26, 48]),
  };

  test('production YAML contains complete approved B/C and cost anchors', () {
    final config = repo.numbers.phase0aArena.weaponMapping!;
    expect(
      [
        config.powerCostAnchor,
        config.ultimateCostAnchor,
        config.killQiGain,
        config.killQiWindowCap,
      ],
      [30, 60, 5, 15],
    );
    for (final entry in expected.entries) {
      final profile = config.profileFor(entry.key);
      final timeline = profile.timeline;
      expect([
        timeline.windupTicks,
        timeline.activeTicks,
        timeline.recoveryTicks,
        timeline.firstEffectTick,
        timeline.cancelWindowStartTick,
        timeline.cancelWindowEndTick,
        timeline.interruptedCooldownTicks,
        timeline.cancelledCooldownTicks,
        timeline.failedCooldownTicks,
      ], entry.value.$1);
      expect([
        profile.basicGain,
        profile.powerCost,
        profile.ultimateCost,
      ], entry.value.$2);
      expect([profile.capacity, profile.opening], [100, 40]);
    }
  });

  test(
    'present mapping rejects missing, unknown, fractional and invalid values',
    () {
      final mutations = <void Function(Map<String, dynamic>)>[
        (value) => value.remove('power_cost_anchor'),
        (value) => value['power_cost_anchor'] = 0,
        (value) => value['kill_gain'] = -1,
        (value) => value['kill_gain'] = 5.5,
        (value) => value['kill_gain'] = '5',
        (value) => value['unknown'] = 1,
        (value) => (value['weapons'] as Map).remove('heavy'),
        (value) => (value['weapons'] as Map)['axe'] = <String, dynamic>{},
        (value) => ((value['weapons'] as Map)['sword'] as Map)['opening'] = 101,
        (value) =>
            (((value['weapons'] as Map)['sword'] as Map)['timeline']
                    as Map)['first_effect_tick'] =
                3,
        (value) =>
            (((value['weapons'] as Map)['sword'] as Map)['timeline']
                    as Map)['active_ticks'] =
                0,
        (value) =>
            (((value['weapons'] as Map)['sword'] as Map)['timeline'] as Map)
                .remove('failed_cooldown_ticks'),
      ];
      for (var index = 0; index < mutations.length; index++) {
        final raw = copyMapping();
        mutations[index](raw);
        expect(
          () => Phase0aWeaponMappingConfig.fromYaml(raw),
          throwsArgumentError,
          reason: 'mutation $index',
        );
      }
      expect(
        () => Phase0aWeaponMappingConfig.fromYaml(null),
        throwsArgumentError,
      );
    },
  );

  test(
    'equipped production player fails closed without mapping; unarmed fixture stays legacy',
    () {
      final raw = copyNumbers();
      (raw['phase0a_arena'] as Map).remove('weapon_mapping');
      final numbers = NumbersConfig.fromYaml(raw);
      expect(() => mapPlayer(player(), numbers: numbers), throwsStateError);
      final fixture = mapPlayer(
        player(weapon: null, gain: 1.5, reduction: 0.2),
        numbers: numbers,
      );
      expect(fixture.playerAdapter.attackTimelineConfig, isNull);
      expect(fixture.playerAdapter.attackQiDelta, 20);
      expect(fixture.initialPlayer.qiLedger, isNull);
      expect(fixture.playerAdapter.numericSkillBindings.one!.qiCost, 30);
    },
  );

  test(
    'five real weapon mappings preserve skill identities and share effective amounts',
    () {
      for (final entry in expected.entries) {
        final snapshot = player(weapon: entry.key);
        final mapping = mapPlayer(snapshot);
        final adapter = mapping.playerAdapter;
        final state = stateOf(mapping);
        final attack =
            adapter
                    .intentsFor(
                      state: state,
                      command: const Phase0aPlayerCommand(attack: true),
                    )
                    .single
                as Phase0aAttackIntent;
        expect(attack.timelineConfig, same(adapter.attackTimelineConfig));
        expect(attack.timelineConfig!.firstEffectTick, entry.value.$1[3]);
        expect(attack.qiDelta, entry.value.$2[0]);
        final profile = repo.weaponAttackProfiles!.profileFor(entry.key);
        expect(
          attack.cooldownSeconds,
          repo.numbers.phase0aArena.playerAttackCooldownSeconds *
              profile.cooldownFactor,
        );
        expect(adapter.basicAttackChain, isNull);
        expect(mapping.initialPlayer.qiMax, 130);
        expect(mapping.initialPlayer.qiCurrent, 23);
        expect(mapping.initialPlayer.qiLedger, isNotNull);
        expect(
          [
            mapping.initialPlayer.killQiGain,
            mapping.initialPlayer.killQiWindowCap,
          ],
          [5, 15],
        );
        final costs = [
          entry.value.$2[1],
          for (var index = 0; index < 3; index++) entry.value.$2[1] + 5,
          entry.value.$2[2],
        ];
        for (var hotkey = 1; hotkey <= costs.length; hotkey++) {
          final binding = adapter.numericSkillBindings.bindingFor(hotkey)!;
          final intent =
              adapter
                      .intentsFor(
                        state: state,
                        command: Phase0aPlayerCommand(skillHotkey: hotkey),
                      )
                      .single
                  as Phase0aSkillIntent;
          final slot = mapping.skillSlots.singleWhere(
            (slot) => slot.slot == binding.slotId,
          );
          expect(
            binding.skill,
            same(snapshot.skillLoadout.skillFor(binding.loadoutSlot)),
          );
          expect(mapping.moveBindings[intent.kind], same(binding.skill));
          expect(binding.qiDelta, -costs[hotkey - 1]);
          expect(intent.qiDelta, binding.qiDelta);
          expect(slot.qiCost, binding.qiCost);
          expect(intent.cooldownSeconds, binding.skill.cooldownSeconds);
        }
        expect(
          adapter.gatherSkillBinding!.skill,
          same(repo.getSkill(repo.numbers.phase0aArena.gatherSkillId)),
        );
        expect(
          adapter.clearSkillBinding!.skill,
          same(repo.getSkill(repo.numbers.phase0aArena.clearSkillId)),
        );
        expect([adapter.gatherQiCost, adapter.clearQiCost], [25, 50]);
      }
    },
  );

  test(
    'mind modifiers are clamped and Q/R retain raw bases before reduction',
    () {
      final mapping = mapPlayer(
        player(weapon: WeaponArchetype.heavy, gain: 99, reduction: 99),
      );
      final adapter = mapping.playerAdapter;
      final state = stateOf(mapping);
      expect(adapter.attackQiDelta, 36);
      expect(
        adapter.numericSkillBindings.equipped.map((binding) => binding.qiCost),
        [27, 31, 31, 31, 48],
      );
      expect(adapter.numericSkillBindings.one!.skill.qiDelta, -30);
      final gather =
          adapter
                  .intentsFor(
                    state: state,
                    command: const Phase0aPlayerCommand(gather: true),
                  )
                  .single
              as Phase0aGatherIntent;
      final clear =
          adapter
                  .intentsFor(
                    state: state,
                    command: const Phase0aPlayerCommand(clear: true),
                  )
                  .single
              as Phase0aClearIntent;
      expect([gather.qiCost, clear.qiCost], [20, 40]);
      expect(
        mapping.skillSlots
            .singleWhere((slot) => slot.slot == gather.slot)
            .qiCost,
        gather.qiCost,
      );
      expect(
        mapping.skillSlots
            .singleWhere((slot) => slot.slot == gather.slot)
            .availability,
        Phase0aSkillAvailability.ready,
      );
      expect(
        mapping.skillSlots
            .singleWhere((slot) => slot.slot == clear.slot)
            .qiCost,
        clear.qiCost,
      );
      expect([gather.cooldownSeconds, clear.cooldownSeconds], [5, 8]);
      expect(
        [
          adapter.gatherSkillBinding!.skill.qiCost,
          adapter.clearSkillBinding!.skill.qiCost,
        ],
        [25, 50],
      );
    },
  );

  test('tactical exemption follows real skill ID even in numeric slots', () {
    final arena = repo.numbers.phase0aArena;
    final snapshot = player(
      weapon: WeaponArchetype.heavy,
      reduction: 0.2,
      loadout: CombatantSkillLoadout(
        basicAttack: repo.getSkill('skill_gangmeng_jichu_basic'),
        main1: repo.getSkill(arena.gatherSkillId),
        main2: repo.getSkill(arena.clearSkillId),
      ),
    );
    final mapping = mapPlayer(snapshot);
    expect(mapping.playerAdapter.numericSkillBindings.one!.qiCost, 20);
    expect(mapping.playerAdapter.numericSkillBindings.two!.qiCost, 40);
    expect(
      mapping.playerAdapter.numericSkillBindings.two!.skill.type,
      SkillType.powerSkill,
    );
  });
}
