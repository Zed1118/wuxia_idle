import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';

import '../../../support/progression_playtest_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
  });

  test('49 real layers expose exactly Lv1 through Lv490', () {
    final realms = [...repository.realms]
      ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
    expect(realms.length, 49);

    final levels = <int>[];
    for (final realm in realms) {
      for (var segment = 0; segment < 10; segment++) {
        final experience = segment == 9
            ? realm.experienceToNext - 1
            : (realm.experienceToNext * segment + 9) ~/ 10;
        levels.add(
          RealmProgressDisplay.fromSnapshot(
            absoluteRealmLevel: realm.absoluteLevel,
            experience: experience,
            experienceToNext: realm.experienceToNext,
            hasNextRealmLayer: realm.absoluteLevel < 49,
          ).level,
        );
      }
    }

    expect(levels, List<int>.generate(490, (index) => index + 1));
  });

  test(
    'every real layer advances to the next RealmDef and refreshes its mirror',
    () {
      final realms = [...repository.realms]
        ..sort((a, b) => a.absoluteLevel.compareTo(b.absoluteLevel));
      for (var index = 0; index < realms.length - 1; index++) {
        final current = realms[index];
        final next = realms[index + 1];
        final reason = 'absolute=${current.absoluteLevel}';
        final character =
            fixture.createCharacter(GrowthStage.early, id: 1000 + index)
              ..realmTier = current.tier
              ..realmLayer = current.layer
              ..internalForceMax = current.internalForceMax
              ..experienceToNextLayer = 999999;

        final result = CharacterAdvancementService.applyExperience(
          character,
          current.experienceToNext,
          realmLookup: repository.getRealm,
        );

        expect(result.layersGained, 1, reason: reason);
        expect(character.realmTier, next.tier, reason: reason);
        expect(character.realmLayer, next.layer, reason: reason);
        expect(
          character.experienceToNextLayer,
          next.experienceToNext,
          reason: reason,
        );
      }
    },
  );

  test('locked overflow remains at level ten then advances after unlock', () {
    final character = fixture.createCharacter(GrowthStage.early, id: 2001);
    final current = repository.getRealm(
      character.realmTier,
      character.realmLayer,
    );
    final nextLayer = CharacterAdvancementService.nextLayer(
      current.tier,
      current.layer,
    )!;
    final next = repository.getRealm(nextLayer.tier, nextLayer.layer);
    final lockedExperience = current.experienceToNext * 2;

    final locked = CharacterAdvancementService.applyExperience(
      character,
      lockedExperience,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => true,
    );
    expect(locked.layersGained, 0);
    expect(character.realmTier, current.tier);
    expect(character.realmLayer, current.layer);
    expect(character.experience, lockedExperience);
    expect(character.experienceToNextLayer, current.experienceToNext);
    expect(locked.progressChange.after.level, current.absoluteLevel * 10);
    expect(locked.progressChange.after.isWaitingForBreakthrough, isTrue);

    final unlocked = CharacterAdvancementService.applyExperience(
      character,
      1,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => false,
    );
    final remainingExperience = lockedExperience + 1 - current.experienceToNext;
    expect(
      remainingExperience,
      lessThan(next.experienceToNext),
      reason: 'real RealmDef curve must stop after the immediate next layer',
    );
    expect(unlocked.layersGained, 1);
    expect(character.realmTier, next.tier);
    expect(character.realmLayer, next.layer);
    expect(character.experience, remainingExperience);
    expect(character.experienceToNextLayer, next.experienceToNext);
  });

  test('terminal realm reaches Lv490 and never creates layer 50', () {
    final terminal = repository.getRealm(
      RealmTier.wuSheng,
      RealmLayer.dengFeng,
    );
    final character = fixture.createCharacter(GrowthStage.late, id: 3001)
      ..realmTier = terminal.tier
      ..realmLayer = terminal.layer
      ..experience = 0
      ..experienceToNextLayer = 0
      ..internalForceMax = terminal.internalForceMax;
    final awardedExperience = terminal.experienceToNext * 2;

    final result = CharacterAdvancementService.applyExperience(
      character,
      awardedExperience,
      realmLookup: repository.getRealm,
    );

    expect(result.layersGained, 0);
    expect(result.experienceGained, awardedExperience);
    expect(character.realmTier, RealmTier.wuSheng);
    expect(character.realmLayer, RealmLayer.dengFeng);
    expect(character.experience, awardedExperience);
    expect(character.experienceToNextLayer, terminal.experienceToNext);
    expect(result.progressChange.after.level, 490);
    expect(result.progressChange.after.didReachPeak, isTrue);
    expect(
      CharacterAdvancementService.nextLayer(
        character.realmTier,
        character.realmLayer,
      ),
      isNull,
    );
  });
}
