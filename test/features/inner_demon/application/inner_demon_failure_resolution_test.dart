import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_resolution_service.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  Character makeCharacter() {
    final character = Character.create(
      name: '证红角色',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()..constitution = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 8, 23),
      internalForce: 1200,
      mainTechniqueId: 1,
    )..id = 1;
    return character;
  }

  Technique makeTechnique() {
    return Technique.create(
      defId: 'tech_test_inner_demon',
      ownerCharacterId: 1,
      tier: TechniqueTier.mingJiaGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 8, 23),
      cultivationLayer: CultivationLayer.daCheng,
      cultivationProgress: 200,
      cultivationProgressToNext: 500,
    )..id = 1;
  }

  CombatSettlementSnapshot defeatSnapshot() => CombatSettlementSnapshot(
    result: BattleResult.rightWin,
    totalTicks: 1,
    hadActions: false,
    playerCharacterId: 1,
    participants: const [
      CombatParticipantSnapshot(characterId: 1, currentHp: 0, maxHp: 1000),
    ],
    skillCasts: const [],
    totalDamage: 0,
    criticalCount: 0,
    damageByCharacterId: const {1: 0},
  );

  StageDef stage({required StageType type, required bool boss}) => StageDef(
    id: 'test_inner_demon_failure',
    name: '测试战败关',
    stageType: type,
    requiredRealm: RealmTier.erLiu,
    enemyTeam: const [],
    isBossStage: boss,
    baseExpReward: 0,
    difficultyMultiplier: 1,
  );

  test('心魔战败只施加 capped 内息紊乱并保留通用结算', () {
    final character = makeCharacter();
    final technique = makeTechnique();
    final equipment = Equipment.create(
      defId: 'weapon_test',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 8, 23),
      obtainedFrom: 'test',
      ownerCharacterId: character.id,
      enhanceLevel: 3,
      battleCount: 4,
    );
    final beforeForce = character.internalForce;
    final beforeRealmTier = character.realmTier;
    final beforeRealmLayer = character.realmLayer;
    final beforeLayer = technique.cultivationLayer;
    final beforeProgress = technique.cultivationProgress;

    final result = CombatResolutionService.resolveSnapshot(
      settlement: defeatSnapshot(),
      participatingCharacters: [character],
      equipmentsByCharacter: {
        character.id: [equipment],
      },
      techniquesByCharacter: {
        character.id: [technique],
      },
      rng: DefaultRng(seed: 17),
      progressToNextMap: const {},
      techniqueDefLookup: (_) => throw StateError('unused in this fixture'),
      dropService: DropService(
        equipmentDefLookup: (_) => throw StateError('unused'),
      ),
      stageDef: stage(type: StageType.innerDemon, boss: true),
      numbersConfig: GameRepository.instance.numbers,
      isHardFight: true,
    );

    expect(character.internalForce, beforeForce);
    expect(character.realmTier, beforeRealmTier);
    expect(character.realmLayer, beforeRealmLayer);
    expect(technique.cultivationLayer, beforeLayer);
    expect(technique.cultivationProgress, beforeProgress);
    final evidence = result.innerDemonPenaltyByCharacter[character.id]!;
    expect(evidence.progressBefore, beforeProgress);
    expect(evidence.progressAfter, beforeProgress);
    expect(equipment.defId, 'weapon_test');
    expect(equipment.ownerCharacterId, character.id);
    expect(equipment.enhanceLevel, 3);
    expect(equipment.battleCount, 5, reason: '装备仅保留通用战斗次数递增');
    expect(character.innerBreathDisorderHoursRemaining, greaterThan(0));
    expect(character.lightInjuryStacks, 0);
    expect(character.injuryHoursRemaining, 0);
  });

  test('普通 Boss 战败仍保留既有伤势行为', () {
    final character = makeCharacter();
    final technique = makeTechnique();

    CombatResolutionService.resolveSnapshot(
      settlement: defeatSnapshot(),
      participatingCharacters: [character],
      equipmentsByCharacter: const {},
      techniquesByCharacter: {
        character.id: [technique],
      },
      rng: DefaultRng(seed: 17),
      progressToNextMap: const {},
      techniqueDefLookup: (_) => throw StateError('unused in this fixture'),
      dropService: DropService(
        equipmentDefLookup: (_) => throw StateError('unused'),
      ),
      stageDef: stage(type: StageType.mainline, boss: true),
      numbersConfig: GameRepository.instance.numbers,
      isHardFight: true,
    );

    expect(character.lightInjuryStacks, 1);
    expect(character.injuryHoursRemaining, greaterThan(0));
  });
}
