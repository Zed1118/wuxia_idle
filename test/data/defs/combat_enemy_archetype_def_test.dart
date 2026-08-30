// Contract tests for P2-G2-S01 CombatEnemyArchetypeDef.

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';

CombatArchetypeVariant variant({
  String roleId = 'melee_brute',
  String displayName = '近战力士',
  CombatAttackTokenKind attackTokenKind = CombatAttackTokenKind.melee,
  double hpMultiplier = 1.0,
  double attackMultiplier = 1.0,
  double defenseMultiplier = 0.5,
  double speedMultiplier = 1.0,
  String attackSetId = 'attack_set_default',
  List<String> attackTagIds = const ['attack_tag_default'],
  String postureProfileId = 'posture_default',
  String dropGroupId = 'drop_default',
  String sfxGroupId = 'sfx_default',
  List<String> visualVariantIds = const ['visual_default'],
}) => CombatArchetypeVariant(
  roleId: roleId,
  displayName: displayName,
  attackTokenKind: attackTokenKind,
  hpMultiplier: hpMultiplier,
  attackMultiplier: attackMultiplier,
  defenseMultiplier: defenseMultiplier,
  speedMultiplier: speedMultiplier,
  attackSetId: attackSetId,
  attackTagIds: attackTagIds,
  postureProfileId: postureProfileId,
  dropGroupId: dropGroupId,
  sfxGroupId: sfxGroupId,
  visualVariantIds: visualVariantIds,
);

CombatEnemyArchetypeDef archetype({
  String id = 'bandit_swordsman',
  List<CombatArchetypeVariant> variants = const [],
}) => CombatEnemyArchetypeDef(id: id, variants: variants);

void main() {
  group('CombatArchetypeVariant', () {
    test('constructs with explicit caller values and exposes them', () {
      final v = variant(
        roleId: 'ranged_archer',
        attackTokenKind: CombatAttackTokenKind.ranged,
        hpMultiplier: 0.8,
        attackMultiplier: 1.4,
        defenseMultiplier: 0.3,
        speedMultiplier: 1.1,
      );
      expect(v.roleId, 'ranged_archer');
      expect(v.displayName, '近战力士');
      expect(v.attackTokenKind, CombatAttackTokenKind.ranged);
      expect(v.hpMultiplier, 0.8);
      expect(v.attackMultiplier, 1.4);
      expect(v.defenseMultiplier, 0.3);
      expect(v.speedMultiplier, 1.1);
    });

    test('blank roleId fails closed', () {
      expect(() => variant(roleId: '  '), throwsArgumentError);
      expect(() => variant(roleId: ''), throwsArgumentError);
    });

    test('roleId containing whitespace fails closed', () {
      expect(() => variant(roleId: 'melee brute'), throwsArgumentError);
    });

    test('blank or padded displayName fails closed', () {
      expect(() => variant(displayName: ''), throwsArgumentError);
      expect(() => variant(displayName: '  '), throwsArgumentError);
      expect(() => variant(displayName: ' 外门弟子'), throwsArgumentError);
      expect(() => variant(displayName: '外门弟子 '), throwsArgumentError);
    });

    test('non-finite multipliers fail closed', () {
      expect(() => variant(hpMultiplier: double.nan), throwsArgumentError);
      expect(() => variant(hpMultiplier: double.infinity), throwsArgumentError);
      expect(() => variant(attackMultiplier: double.nan), throwsArgumentError);
      expect(
        () => variant(defenseMultiplier: double.negativeInfinity),
        throwsArgumentError,
      );
      expect(
        () => variant(speedMultiplier: double.infinity),
        throwsArgumentError,
      );
    });

    test('negative multipliers fail closed', () {
      expect(() => variant(hpMultiplier: -1), throwsArgumentError);
      expect(() => variant(attackMultiplier: -0.1), throwsArgumentError);
      expect(() => variant(defenseMultiplier: -1), throwsArgumentError);
      expect(() => variant(speedMultiplier: -1), throwsArgumentError);
    });

    test('zero hp multiplier fails closed', () {
      expect(() => variant(hpMultiplier: 0), throwsArgumentError);
    });

    test('zero attack/defense/speed multipliers are allowed', () {
      final v = variant(
        attackMultiplier: 0,
        defenseMultiplier: 0,
        speedMultiplier: 0,
      );
      expect(v.attackMultiplier, 0);
      expect(v.defenseMultiplier, 0);
      expect(v.speedMultiplier, 0);
    });
  });

  group('CombatEnemyArchetypeDef', () {
    test('constructs with variants and resolves roles', () {
      final def = archetype(
        id: 'bandit_swordsman',
        variants: [
          variant(roleId: 'melee_brute'),
          variant(
            roleId: 'ranged_archer',
            attackTokenKind: CombatAttackTokenKind.ranged,
          ),
        ],
      );
      expect(def.id, 'bandit_swordsman');
      expect(def.variants, hasLength(2));
      expect(
        def.variantByRole('melee_brute')!.attackTokenKind,
        CombatAttackTokenKind.melee,
      );
      expect(
        def.variantByRole('ranged_archer')!.attackTokenKind,
        CombatAttackTokenKind.ranged,
      );
      expect(def.variantByRole('unknown_role'), isNull);
    });

    test('blank or whitespace id fails closed', () {
      expect(() => archetype(id: ''), throwsArgumentError);
      expect(() => archetype(id: '  '), throwsArgumentError);
      expect(() => archetype(id: 'bandit swordsman'), throwsArgumentError);
    });

    test('empty variants fail closed', () {
      expect(() => archetype(variants: []), throwsArgumentError);
    });

    test('duplicate roleIds fail closed', () {
      expect(
        () => archetype(
          variants: [
            variant(roleId: 'melee_brute'),
            variant(roleId: 'melee_brute'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('mutating the caller input list after construction is a no-op', () {
      final input = [
        variant(roleId: 'melee_brute'),
        variant(roleId: 'ranged_archer'),
      ];
      final def = CombatEnemyArchetypeDef(id: 'bandit', variants: input);
      input.clear();
      input.add(variant(roleId: 'support_shaman'));
      expect(def.variants, hasLength(2));
      expect(def.variantByRole('melee_brute'), isNotNull);
      expect(def.variantByRole('support_shaman'), isNull);
    });

    test('exposed variants list is unmodifiable', () {
      final def = archetype(variants: [variant()]);
      expect(
        () => def.variants.add(variant(roleId: 'other')),
        throwsUnsupportedError,
      );
      expect(() => def.variants.clear(), throwsUnsupportedError);
    });
  });
}
