import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart';

import '../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  Character character(int legacyLevel) => Character.create(
    name: '测试',
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.xunChang,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 7, 13),
    internalForce: 1000,
    internalForceMax: 3000,
    level: legacyLevel,
  );

  test('legacy level values do not affect combat stats', () {
    final low = character(1);
    final corrupt = character(1000000);
    final numbers = repository.numbers;
    final technique = Technique.create(
      defId: 'test_technique',
      ownerCharacterId: 1,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 13),
    );

    expect(
      CharacterDerivedStats.maxHp(low, [], numbers),
      CharacterDerivedStats.maxHp(corrupt, [], numbers),
    );
    expect(
      CharacterDerivedStats.internalForceMaxWithLineage(low, [], numbers),
      CharacterDerivedStats.internalForceMaxWithLineage(corrupt, [], numbers),
    );
    expect(
      CharacterDerivedStats.speed(low, [], technique, numbers),
      CharacterDerivedStats.speed(corrupt, [], technique, numbers),
    );
  });

  test('numbers yaml has no independent level system', () async {
    final yaml = await File('data/numbers.yaml').readAsString();
    expect(yaml, isNot(contains('\nlevel:\n')));
    expect(yaml, isNot(contains('bonus_max_hp_per_level')));
  });
}
