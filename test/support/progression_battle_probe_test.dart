import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

import 'progression_battle_probe.dart';
import 'test_data.dart';

void main() {
  late GameRepository repository;
  late StageDef stage;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    stage = repository.stageDefs['stage_01_05']!;
  });

  test('all profiles tiers and team slots create legal domain objects', () {
    for (final profile in ProgressionBuildProfile.values) {
      for (final tier in RealmTier.values) {
        final builds = [
          for (var slot = 0; slot < 3; slot++)
            buildProgressionPlayerBuild(
              repository: repository,
              tier: tier,
              slot: slot,
              isFounder: slot == 0,
              profile: profile,
            ),
        ];
        expect(
          builds.map((build) => build.character.id).toSet(),
          hasLength(3),
          reason: '${tier.name}/${profile.name} 的 3 人角色 id 必须唯一',
        );

        for (var slot = 0; slot < builds.length; slot++) {
          final build = builds[slot];
          final character = build.character;
          final realm = repository.getRealm(tier, RealmLayer.huaJing);
          final equipmentTier = RealmUtils.equipmentTierCapOf(tier);
          final techniqueTier = RealmUtils.techniqueTierCapOf(tier);
          final expectedTotal = profile == ProgressionBuildProfile.nearMax
              ? 22
              : 20;
          final expectedAttribute = profile == ProgressionBuildProfile.nearMax
              ? 6
              : 5;
          final expectedRarity = profile == ProgressionBuildProfile.nearMax
              ? RarityTier.ziYou
              : RarityTier.biaoZhun;

          expect(character.id, 7000 + slot);
          expect(character.realmTier, tier);
          expect(character.realmLayer, RealmLayer.huaJing);
          expect(character.attributes.total, expectedTotal);
          expect(character.attributes.constitution, expectedAttribute);
          expect(character.attributes.agility, expectedAttribute);
          expect(character.attributes.enlightenment, 5);
          expect(character.attributes.fortune, 5);
          expect(character.rarity, expectedRarity);
          expect(character.internalForce, realm.internalForceMax);
          expect(character.internalForceMax, realm.internalForceMax);
          expect(character.experienceToNextLayer, realm.experienceToNext);
          expect(character.school, TechniqueSchool.gangMeng);
          expect(character.isFounder, slot == 0);
          expect(
            character.lineageRole,
            slot == 0 ? LineageRole.founder : LineageRole.disciple,
          );
          expect(character.isActive, isTrue);

          expect(build.equipped, hasLength(3));
          expect(
            build.equipped.map((equipment) => equipment.slot).toSet(),
            EquipmentSlot.values.toSet(),
          );
          for (final equipment in build.equipped) {
            final def = repository.getEquipment(equipment.defId);
            expect(equipment.tier, equipmentTier);
            expect(equipment.tier, def.tier);
            expect(equipment.slot, def.slot);
            expect(equipment.ownerCharacterId, character.id);
            expect(equipment.school, TechniqueSchool.gangMeng);
            expect(
              equipment.baseAttack,
              (def.baseAttackMin + def.baseAttackMax) ~/ 2,
            );
            expect(
              equipment.baseHealth,
              (def.baseHealthMin + def.baseHealthMax) ~/ 2,
            );
            expect(
              equipment.baseSpeed,
              (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
            );
            expect(equipment.forgingSlots, hasLength(3));
            expect(
              equipment.forgingSlots.map(
                (forgingSlot) => forgingSlot.slotIndex,
              ),
              [1, 2, 3],
            );
            for (final forgingSlot in equipment.forgingSlots) {
              expect(forgingSlot.type, isNull);
              expect(forgingSlot.unlocked, isFalse);
              expect(forgingSlot.bonusValue, 0);
              expect(forgingSlot.specialSkillId, isNull);
            }
          }

          final techniqueDef = repository.getTechnique(
            build.mainTechnique.defId,
          );
          expect(build.mainTechnique.ownerCharacterId, character.id);
          expect(build.mainTechnique.tier, techniqueTier);
          expect(build.mainTechnique.tier, techniqueDef.tier);
          expect(build.mainTechnique.school, TechniqueSchool.gangMeng);
          expect(build.mainTechnique.school, techniqueDef.school);
          expect(build.mainTechnique.role, TechniqueRole.main);
          expect(build.battleCharacter.characterId, character.id);
          expect(build.battleCharacter.realmTier, character.realmTier);
          expect(build.battleCharacter.realmLayer, character.realmLayer);
          expect(build.battleCharacter.slotIndex, slot);
        }
      }
    }
  });

  test('profile investment fields are monotonic without fixing outcomes', () {
    for (final tier in RealmTier.values) {
      final builds = [
        for (final profile in ProgressionBuildProfile.values)
          buildProgressionPlayerBuild(
            repository: repository,
            tier: tier,
            slot: 0,
            isFounder: true,
            profile: profile,
          ),
      ];
      final enhanceLevels = [
        for (final build in builds) build.equipped.first.enhanceLevel,
      ];
      final battleCounts = [
        for (final build in builds) build.equipped.first.battleCount,
      ];

      expect(enhanceLevels[0], lessThan(enhanceLevels[1]));
      expect(enhanceLevels[1], lessThan(enhanceLevels[2]));
      expect(battleCounts[0], lessThan(battleCounts[1]));
      expect(battleCounts[1], lessThan(battleCounts[2]));
      expect(
        builds.map((build) => build.mainTechnique.cultivationLayer.index),
        orderedEquals([
          CultivationLayer.zhongCheng.index,
          CultivationLayer.zhongCheng.index,
          CultivationLayer.daCheng.index,
        ]),
      );
      expect(
        builds[0].battleCharacter.totalEquipmentAttack,
        lessThan(builds[1].battleCharacter.totalEquipmentAttack),
      );
      expect(
        builds[1].battleCharacter.totalEquipmentAttack,
        lessThan(builds[2].battleCharacter.totalEquipmentAttack),
      );
      expect(
        builds[0].battleCharacter.criticalRate,
        builds[1].battleCharacter.criticalRate,
      );
      expect(
        builds[1].battleCharacter.criticalRate,
        lessThan(builds[2].battleCharacter.criticalRate),
      );
    }
  });

  test('runner rejects a draw caused by reaching maxTicks', () {
    const profile = ProgressionBuildProfile.undergeared;
    const seed = 23;
    final longStage = repository.stageDefs['stage_06_05']!;

    expect(
      () => runProgressionMainlineStage(
        repository: repository,
        stage: longStage,
        profile: profile,
        seed: seed,
        maxTicks: 1,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains(longStage.id),
            contains(profile.name),
            contains('seed=$seed'),
            contains('maxTicks=1'),
          ),
        ),
      ),
    );
  });

  test('tick-cap classification accepts a mutual-annihilation draw', () {
    const maxTicks = 1;
    final left = buildProgressionPlayer(
      repository: repository,
      tier: stage.requiredRealm,
      slot: 0,
      isFounder: true,
      profile: ProgressionBuildProfile.standard,
    );
    final right = left.copyWith(
      characterId: left.characterId + 1,
      name: '成长体检对手',
      teamSide: 1,
    );
    final terminal = BattleState.initial(leftTeam: [left], rightTeam: [right])
        .copyWith(
          leftTeam: [left.copyWith(currentHp: 0, isAlive: false)],
          rightTeam: [right.copyWith(currentHp: 0, isAlive: false)],
          tick: maxTicks,
          result: BattleResult.draw,
        );

    expect(terminal.tick, maxTicks);
    expect(terminal.result, BattleResult.draw);
    expect(isUnfinishedAtTickCap(terminal, maxTicks: maxTicks), isFalse);
  });

  test('probe is deterministic for the same stage profile and seed', () {
    final first = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: ProgressionBuildProfile.standard,
      seed: 17,
    );
    final second = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: ProgressionBuildProfile.standard,
      seed: 17,
    );

    expect(_snapshot(first), _snapshot(second));
  });

  test('probe projects every observation field from the shared run', () {
    const profile = ProgressionBuildProfile.undergeared;
    const seed = 23;
    final run = runProgressionMainlineStage(
      repository: repository,
      stage: stage,
      profile: profile,
      seed: seed,
    );
    final observation = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: profile,
      seed: seed,
    );

    expect(observation.stageId, stage.id);
    expect(observation.profile, profile);
    expect(observation.seed, seed);
    expect(observation.result, run.terminal.result);
    expect(observation.ticks, run.terminal.tick);
    expect(observation.playerHpStart, _sumHp(run.initial.leftTeam));
    expect(observation.playerHpEnd, _sumHp(run.terminal.leftTeam));
    expect(observation.playerQiStart, _sumQi(run.initial.leftTeam));
    expect(observation.playerQiEnd, _sumQi(run.terminal.leftTeam));
    expect(observation.actionRows, run.terminal.actionLog.length);
  });
}

(
  String,
  ProgressionBuildProfile,
  int,
  BattleResult,
  int,
  int,
  int,
  int,
  int,
  int,
)
_snapshot(ProgressionBattleObservation observation) => (
  observation.stageId,
  observation.profile,
  observation.seed,
  observation.result,
  observation.ticks,
  observation.playerHpStart,
  observation.playerHpEnd,
  observation.playerQiStart,
  observation.playerQiEnd,
  observation.actionRows,
);

int _sumHp(List<BattleCharacter> team) =>
    team.fold(0, (sum, character) => sum + character.currentHp);

int _sumQi(List<BattleCharacter> team) =>
    team.fold(0, (sum, character) => sum + character.currentQi);
