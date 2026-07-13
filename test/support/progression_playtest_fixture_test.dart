import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import 'progression_playtest_fixture.dart';
import 'test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  test('early middle late profiles use real realm definitions', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final early = fixture.createCharacter(GrowthStage.early, id: 101);
    final middle = fixture.createCharacter(GrowthStage.middle, id: 102);
    final late = fixture.createCharacter(GrowthStage.late, id: 103);

    expect(
      repository.getRealm(early.realmTier, early.realmLayer).absoluteLevel,
      4,
    );
    expect(
      repository.getRealm(middle.realmTier, middle.realmLayer).absoluteLevel,
      25,
    );
    expect(
      repository.getRealm(late.realmTier, late.realmLayer).absoluteLevel,
      46,
    );
    expect([early.id, middle.id, late.id], [101, 102, 103]);
  });

  test('attribute variant changes exactly one field and stays legal', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final base = fixture.createCharacter(GrowthStage.middle, id: 201);
    final agile = fixture.createCharacter(
      GrowthStage.middle,
      id: 202,
      raisedAttribute: AttributeKey.agility,
    );

    expect(base.attributes.total, 20);
    expect(agile.attributes.total, 23);
    expect(agile.attributes.constitution, base.attributes.constitution);
    expect(agile.attributes.enlightenment, base.attributes.enlightenment);
    expect(agile.attributes.agility, 8);
    expect(agile.attributes.fortune, base.attributes.fortune);
  });

  test(
    'fixture mirrors the current RealmDef threshold only for compatibility',
    () {
      final fixture = ProgressionPlaytestFixture(repository);
      final character = fixture.createCharacter(GrowthStage.late, id: 301);
      final realm = repository.getRealm(
        character.realmTier,
        character.realmLayer,
      );

      expect(character.experienceToNextLayer, realm.experienceToNext);
      expect(character.internalForceMax, realm.internalForceMax);
    },
  );
}
