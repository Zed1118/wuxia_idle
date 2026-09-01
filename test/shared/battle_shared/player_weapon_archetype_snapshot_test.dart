import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_builder.dart';

import '../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late Character character;
  late Technique technique;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    character = Character.create(
      name: '武器身份测试角色',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 9, 1),
      internalForce: 500,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
      isFounder: true,
      isActive: true,
    )..id = 1;
    technique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: 1,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.utc(2026, 9, 1),
    );
  });

  Equipment weapon(String defId) => Equipment.create(
    defId: defId,
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime.utc(2026, 9, 1),
    obtainedFrom: 'test',
  );

  test('真实装备 def 的显式类别进入玩家战斗快照', () {
    final snapshot = PlayerCombatantSnapshotBuilder.build(
      character: character,
      equipped: [weapon('weapon_xunchang_chai_dao')],
      mainTechnique: technique,
      numbers: repository.numbers,
    );

    expect(snapshot.weaponArchetype, WeaponArchetype.dual);
  });

  test('未装备武器保持现有无武器掌风基线', () {
    final snapshot = PlayerCombatantSnapshotBuilder.build(
      character: character,
      equipped: const [],
      mainTechnique: technique,
      numbers: repository.numbers,
    );

    expect(snapshot.weaponArchetype, isNull);
  });

  test('同一快照出现两件武器时 fail closed', () {
    expect(
      () => PlayerCombatantSnapshotBuilder.build(
        character: character,
        equipped: [
          weapon('weapon_xunchang_tie_jian'),
          weapon('weapon_xunchang_chai_dao'),
        ],
        mainTechnique: technique,
        numbers: repository.numbers,
      ),
      throwsStateError,
    );
  });
}
