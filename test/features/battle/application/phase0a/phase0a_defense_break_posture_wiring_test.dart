import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';

import '../../../../support/isar_test_support.dart';
import '../../../../support/test_data.dart';

final class _HitResolver implements Phase0aDamageResolver {
  const _HitResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 0);
}

void main() {
  late Directory tempDir;
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'phase0a_defense_break_posture_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<CombatantSnapshot> assembleSenior() async {
    final isar = IsarSetup.instance;
    late int seniorId;
    await isar.writeTxn(() async {
      final senior = Character.create(
        name: 'senior posture fixture',
        realmTier: RealmTier.sanLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.senior,
        createdAt: DateTime(2026, 8, 26),
        school: TechniqueSchool.gangMeng,
        internalForce: 500,
        internalForceMax: 500,
      );
      seniorId = await isar.characters.put(senior);
      final technique = Technique.create(
        defId: 'tech_gangmeng_changlian',
        ownerCharacterId: seniorId,
        tier: TechniqueTier.changLianGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 8, 26),
        cultivationLayer: CultivationLayer.xiaoCheng,
      );
      senior.mainTechniqueId = await isar.techniques.put(technique);
      await isar.characters.put(senior);
    });
    return (await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadExactRoster([seniorId])).single;
  }

  test(
    'real defense-break autoFill maps into the Phase 0A numeric path',
    () async {
      final player = await assembleSenior();
      final defenseBreakSlots = CombatantSkillLoadout.numericSlots.where((
        slot,
      ) {
        final skill = player.skillLoadout.skillFor(slot);
        return skill != null && skill.defenseBreakPct != 0;
      });
      expect(defenseBreakSlots, hasLength(1));

      expect(
        () => Phase0aStageContentMapper.map(
          stage: repository.getStage('stage_01_01'),
          playerSnapshot: player,
          numbers: repository.numbers,
        ),
        returnsNormally,
      );
    },
  );

  test(
    'defenseBreakPct adds posture damage to the authoritative state',
    () async {
      final player = await assembleSenior();
      final mapping = Phase0aStageContentMapper.map(
        stage: repository.getStage('stage_01_01'),
        playerSnapshot: player,
        numbers: repository.numbers,
      );
      final binding = mapping.playerAdapter.numericSkillBindings.equipped
          .singleWhere((candidate) => candidate.skill.defenseBreakPct != 0);
      final target = mapping.initialState.enemies.first;
      final state = Phase0aArenaState(
        tick: mapping.initialState.tick,
        nextSeq: mapping.initialState.nextSeq,
        player: mapping.initialState.player.copyWith(position: target.position),
        enemies: mapping.initialState.enemies,
        skillSlots: mapping.initialState.skillSlots,
        winCondition: mapping.initialState.winCondition,
      );
      final intent = mapping.playerAdapter
          .intentsFor(
            state: state,
            command: Phase0aPlayerCommand(skillHotkey: binding.hotkey),
          )
          .whereType<Phase0aSkillIntent>()
          .single;
      final basePostureDamage = powerMultiplierToPostureDamage(
        binding.skill.powerMultiplier,
        basicPowerMultiplier:
            repository.numbers.phase0aArena.basicPowerMultiplier,
      );
      final expectedExtra = basePostureDamage * binding.skill.defenseBreakPct;

      expect(
        intent.postureDamage - basePostureDamage,
        closeTo(expectedExtra, 0.000000000001),
      );

      final result = reducePhase0aTick(
        state: state,
        intents: [intent],
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        damageResolver: const _HitResolver(),
      );
      final settledTarget = result.state.enemies.singleWhere(
        (enemy) => enemy.id == target.id,
      );
      expect(
        settledTarget.posture!.accumulated,
        closeTo(basePostureDamage + expectedExtra, 0.000000000001),
      );
    },
  );

  test('defense-break posture bonus can complete a charge interrupt', () async {
    final player = await assembleSenior();
    final mapping = Phase0aStageContentMapper.map(
      stage: repository.getStage('stage_01_05'),
      playerSnapshot: player,
      numbers: repository.numbers,
    );
    final binding = mapping.playerAdapter.numericSkillBindings.equipped
        .singleWhere((candidate) => candidate.skill.defenseBreakPct != 0);
    final boss = mapping.waves.last.enemies.single;
    final basePostureDamage = powerMultiplierToPostureDamage(
      binding.skill.powerMultiplier,
      basicPowerMultiplier:
          repository.numbers.phase0aArena.basicPowerMultiplier,
    );
    final expectedTotal =
        basePostureDamage + basePostureDamage * binding.skill.defenseBreakPct;
    final primedPosture = PostureState.initial(
      boss.posture!.config,
    ).apply(boss.posture!.config.capacity - expectedTotal).state;
    final state = Phase0aArenaState(
      tick: mapping.initialState.tick,
      nextSeq: mapping.initialState.nextSeq,
      player: mapping.initialState.player.copyWith(position: boss.position),
      enemies: [
        boss.copyWith(
          posture: primedPosture,
          chargingCast: boss.chargeCast,
          chargeTicksRemaining: boss.chargeCast!.chargeTicks,
        ),
      ],
      skillSlots: mapping.initialState.skillSlots,
      winCondition: mapping.initialState.winCondition,
    );
    final intent = mapping.playerAdapter
        .intentsFor(
          state: state,
          command: Phase0aPlayerCommand(skillHotkey: binding.hotkey),
        )
        .whereType<Phase0aSkillIntent>()
        .single;

    final result = reducePhase0aTick(
      state: state,
      intents: [intent],
      deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
      damageResolver: const _HitResolver(),
    );
    final settledBoss = result.state.enemies.single;
    expect(intent.breakPower, 0);
    expect(settledBoss.chargingCast, isNull);
    expect(settledBoss.posture!.isVulnerable, isTrue);
  });
}
