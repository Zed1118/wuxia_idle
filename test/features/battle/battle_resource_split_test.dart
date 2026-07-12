import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

BattleCharacter battleCharacter({
  required int internalForce,
  required int currentQi,
}) => BattleCharacter(
  characterId: 1,
  name: '测试角色',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 1000,
  currentHp: 1000,
  internalForce: internalForce,
  maxQi: 100,
  currentQi: currentQi,
  speed: 100,
  criticalRate: 0.05,
  evasionRate: 0.05,
  defenseRate: 0.05,
  totalEquipmentAttack: 0,
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
  tearDown(GameRepository.resetForTest);

  test('battle snapshot keeps permanent inner force separate from qi', () {
    final full = battleCharacter(internalForce: 5000, currentQi: 100);
    final spent = full.copyWith(currentQi: 10);

    expect(spent.internalForce, 5000);
    expect(spent.maxQi, 100);
    expect(spent.currentQi, 10);
  });

  test(
    'max hp no longer changes when only actual inner force changes',
    () async {
      final repo = await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
      Character character(int innerForce) => Character.create(
        name: '测试角色',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.yuanShu,
        attributes: Attributes()..constitution = 7,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026),
        internalForce: innerForce,
        internalForceMax: 3500,
      );

      final low = CharacterDerivedStats.maxHp(
        character(500),
        const [],
        repo.numbers,
      );
      final high = CharacterDerivedStats.maxHp(
        character(3500),
        const [],
        repo.numbers,
      );

      expect(high, low);
    },
  );
}
