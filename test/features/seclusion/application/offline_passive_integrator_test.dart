import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/application/passive_idle_integrator.dart';

import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());

  Character fixture() => Character.create(
    name: 'tier boundary',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.dengFeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    experience:
        repository
            .getRealm(RealmTier.xueTu, RealmLayer.dengFeng)
            .experienceToNext -
        1,
  );

  test(
    'tier rate changes at the actual experience event within a long window',
    () {
      final character = fixture();
      final result = PassiveIdleIntegrator.accrue(
        character: character,
        elapsedMicroseconds: const Duration(hours: 8).inMicroseconds,
        config: repository.numbers.passiveIdle,
        experienceRemainder: 0,
        mojianshiRemainder: 0,
        realmLookup: repository.getRealm,
        isLayerLocked: (_, _) => false,
      );

      expect(character.realmTier, RealmTier.sanLiu);
      expect(result.experience, 37);
      expect(result.mojianshi, 3);
      expect(result.experienceRemainder, closeTo(0.8, 1e-9));
      expect(result.mojianshiRemainder, closeTo(0.15, 1e-9));
      expect(result.realmTierChanges, [
        (
          elapsedMicroseconds: const Duration(minutes: 20).inMicroseconds,
          previousTier: RealmTier.xueTu,
        ),
      ]);
    },
  );

  test(
    'irregular subsecond partitions equal one window across a tier change',
    () {
      final wholeCharacter = fixture();
      final whole = PassiveIdleIntegrator.accrue(
        character: wholeCharacter,
        elapsedMicroseconds: const Duration(hours: 8).inMicroseconds,
        config: repository.numbers.passiveIdle,
        experienceRemainder: 0,
        mojianshiRemainder: 0,
        realmLookup: repository.getRealm,
        isLayerLocked: (_, _) => false,
      );

      final splitCharacter = fixture();
      var remaining = const Duration(hours: 8).inMicroseconds;
      var expFraction = 0.0;
      var materialFraction = 0.0;
      var experience = 0;
      var material = 0;
      var elapsedTotal = 0;
      final changes = <PassiveRealmTierChange>[];
      const step = Duration(seconds: 59, microseconds: 731);
      while (remaining > 0) {
        final elapsed = remaining < step.inMicroseconds
            ? remaining
            : step.inMicroseconds;
        final part = PassiveIdleIntegrator.accrue(
          character: splitCharacter,
          elapsedMicroseconds: elapsed,
          config: repository.numbers.passiveIdle,
          experienceRemainder: expFraction,
          mojianshiRemainder: materialFraction,
          realmLookup: repository.getRealm,
          isLayerLocked: (_, _) => false,
        );
        expFraction = part.experienceRemainder;
        materialFraction = part.mojianshiRemainder;
        experience += part.experience;
        material += part.mojianshi;
        changes.addAll(
          part.realmTierChanges.map(
            (change) => (
              elapsedMicroseconds: elapsedTotal + change.elapsedMicroseconds,
              previousTier: change.previousTier,
            ),
          ),
        );
        elapsedTotal += elapsed;
        remaining -= elapsed;
      }

      expect(experience, whole.experience);
      expect(material, whole.mojianshi);
      expect(splitCharacter.realmTier, wholeCharacter.realmTier);
      expect(splitCharacter.realmLayer, wholeCharacter.realmLayer);
      expect(splitCharacter.experience, wholeCharacter.experience);
      expect(expFraction, closeTo(whole.experienceRemainder, 1e-7));
      expect(materialFraction, closeTo(whole.mojianshiRemainder, 1e-7));
      expect(changes.length, whole.realmTierChanges.length);
      for (var i = 0; i < changes.length; i++) {
        expect(changes[i].previousTier, whole.realmTierChanges[i].previousTier);
        expect(
          changes[i].elapsedMicroseconds,
          closeTo(whole.realmTierChanges[i].elapsedMicroseconds, 1),
        );
      }
    },
  );

  test(
    'a locked advancement preserves the old rate and accumulated experience',
    () {
      final character = fixture();
      final before = character.experience;
      final result = PassiveIdleIntegrator.accrue(
        character: character,
        elapsedMicroseconds: const Duration(hours: 8).inMicroseconds,
        config: repository.numbers.passiveIdle,
        experienceRemainder: 0,
        mojianshiRemainder: 0,
        realmLookup: repository.getRealm,
        isLayerLocked: (_, _) => true,
      );
      expect(result.experience, 24);
      expect(result.mojianshi, 2);
      expect(character.realmTier, RealmTier.xueTu);
      expect(character.experience, before + 24);
      expect(result.realmTierChanges, isEmpty);
    },
  );

  test('same-tier layer advancement does not create an island boundary', () {
    final character = fixture()
      ..realmLayer = RealmLayer.qiMeng
      ..experience =
          repository
              .getRealm(RealmTier.xueTu, RealmLayer.qiMeng)
              .experienceToNext -
          1;
    final result = PassiveIdleIntegrator.accrue(
      character: character,
      elapsedMicroseconds: const Duration(minutes: 20).inMicroseconds,
      config: repository.numbers.passiveIdle,
      experienceRemainder: 0,
      mojianshiRemainder: 0,
      realmLookup: repository.getRealm,
      isLayerLocked: (_, _) => false,
    );
    expect(character.realmLayer, RealmLayer.ruMen);
    expect(result.realmTierChanges, isEmpty);
  });
}
