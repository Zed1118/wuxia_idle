import 'package:flutter_test/flutter_test.dart';
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

    expect(base.attributes.total, 20);
    for (final raisedAttribute in AttributeKey.values) {
      final variant = fixture.createCharacter(
        GrowthStage.middle,
        id: 202 + raisedAttribute.index,
        raisedAttribute: raisedAttribute,
      );
      final values = {
        AttributeKey.constitution: variant.attributes.constitution,
        AttributeKey.enlightenment: variant.attributes.enlightenment,
        AttributeKey.agility: variant.attributes.agility,
        AttributeKey.fortune: variant.attributes.fortune,
      };

      expect(variant.attributes.total, 23);
      for (final attribute in AttributeKey.values) {
        expect(
          values[attribute],
          attribute == raisedAttribute ? 8 : 5,
          reason: '$raisedAttribute should only raise its own field',
        );
      }
    }
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
      expect(character.internalForce, realm.internalForceMax);
      expect(character.internalForceMax, realm.internalForceMax);
    },
  );

  test('validation rejects RealmDef resource mismatches', () {
    final fixture = ProgressionPlaytestFixture(repository);
    final character = fixture.createCharacter(GrowthStage.middle, id: 401);
    final realm = repository.getRealm(
      character.realmTier,
      character.realmLayer,
    );

    character.internalForce = realm.internalForceMax - 1;
    expect(() => fixture.validateCharacter(character), throwsStateError);

    character.internalForce = realm.internalForceMax;
    character.experienceToNextLayer = realm.experienceToNext + 1;
    expect(() => fixture.validateCharacter(character), throwsStateError);
  });
}
