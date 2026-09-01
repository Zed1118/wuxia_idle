import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/weapon_attack_profile_loader.dart';

import '../../support/test_data.dart';

void main() {
  tearDown(GameRepository.resetForTest);

  test(
    'production manifest resolves five exact single-stage profiles',
    () async {
      final repository = await loadTestGameRepository();
      final catalog = repository.weaponAttackProfiles;

      expect(catalog, isNotNull);
      expect(
        catalog!.profiles.map((profile) => profile.archetype).toSet(),
        WeaponArchetype.values.toSet(),
      );
      expect(
        catalog.profiles.every((profile) => profile.maxTargets == 1),
        isTrue,
      );
      expect(
        catalog.profiles.every((profile) => profile.attackDisplacement == 0),
        isTrue,
      );
      expect(
        catalog.profiles
            .map(
              (profile) => (
                profile.rangeFactor,
                profile.halfArcFactor,
                profile.cooldownFactor,
                profile.postureDamageFactor,
              ),
            )
            .toSet(),
        hasLength(WeaponArchetype.values.length),
      );
    },
  );

  test('missing archetype fails closed', () {
    expect(
      () => loadWeaponAttackProfileCatalog(
        sourceName: 'fixture.yaml',
        yaml: _validYaml.replaceFirst(
          RegExp(r'  - archetype: hidden[\s\S]*$'),
          '',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('multi-target and attack displacement fail closed independently', () {
    expect(
      () => loadWeaponAttackProfileCatalog(
        sourceName: 'fixture.yaml',
        yaml: _validYaml.replaceFirst('max_targets: 1', 'max_targets: 2'),
      ),
      throwsArgumentError,
    );
    expect(
      () => loadWeaponAttackProfileCatalog(
        sourceName: 'fixture.yaml',
        yaml: _validYaml.replaceFirst(
          'attack_displacement: 0.0',
          'attack_displacement: 1.0',
        ),
      ),
      throwsArgumentError,
    );
  });
}

const _validYaml = '''
player_attack_profiles:
  - archetype: sword
    range_factor: 1.0
    half_arc_factor: 1.0
    cooldown_factor: 1.0
    posture_damage_factor: 1.0
    max_targets: 1
    attack_displacement: 0.0
  - archetype: heavy
    range_factor: 0.9
    half_arc_factor: 1.1
    cooldown_factor: 1.2
    posture_damage_factor: 1.3
    max_targets: 1
    attack_displacement: 0.0
  - archetype: flexible
    range_factor: 1.1
    half_arc_factor: 1.2
    cooldown_factor: 1.1
    posture_damage_factor: 1.1
    max_targets: 1
    attack_displacement: 0.0
  - archetype: dual
    range_factor: 0.8
    half_arc_factor: 0.9
    cooldown_factor: 0.8
    posture_damage_factor: 0.8
    max_targets: 1
    attack_displacement: 0.0
  - archetype: hidden
    range_factor: 1.2
    half_arc_factor: 0.8
    cooldown_factor: 0.9
    posture_damage_factor: 0.9
    max_targets: 1
    attack_displacement: 0.0
''';
