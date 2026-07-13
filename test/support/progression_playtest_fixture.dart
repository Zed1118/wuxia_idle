import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

enum GrowthStage { early, middle, late }

final class ProgressionPlaytestFixture {
  const ProgressionPlaytestFixture(this.repository);

  final GameRepository repository;

  Character createCharacter(
    GrowthStage stage, {
    required int id,
    AttributeKey? raisedAttribute,
  }) {
    final (tier, layer) = switch (stage) {
      GrowthStage.early => (RealmTier.xueTu, RealmLayer.jingTong),
      GrowthStage.middle => (RealmTier.yiLiu, RealmLayer.jingTong),
      GrowthStage.late => (RealmTier.wuSheng, RealmLayer.jingTong),
    };
    final realm = repository.getRealm(tier, layer);
    final attributes = Attributes()
      ..constitution = raisedAttribute == AttributeKey.constitution ? 8 : 5
      ..enlightenment = raisedAttribute == AttributeKey.enlightenment ? 8 : 5
      ..agility = raisedAttribute == AttributeKey.agility ? 8 : 5
      ..fortune = raisedAttribute == AttributeKey.fortune ? 8 : 5;
    final character = Character.create(
      name: '体检角色-${stage.name}-$id',
      realmTier: tier,
      realmLayer: layer,
      attributes: attributes,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 7, 13),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: true,
      isActive: true,
      school: TechniqueSchool.gangMeng,
    )..id = id;
    validateCharacter(character);
    return character;
  }

  void validateCharacter(Character character) {
    final realm = repository.getRealm(
      character.realmTier,
      character.realmLayer,
    );
    if (character.attributes.total < 16 || character.attributes.total > 24) {
      throw StateError('属性总和 ${character.attributes.total} 不在 [16, 24]');
    }
    if (character.internalForceMax != realm.internalForceMax) {
      throw StateError('角色内力上限未使用真实 RealmDef');
    }
  }
}
