import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import '../../support/test_data.dart';

/// 永久内力与开场真气的进场拆分契约。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  test('进场保留实际内力，真气按心法部分开场', () {
    final c = _mkChar(
      tier: RealmTier.xueTu,
      layer: RealmLayer.ruMen,
      internalForce: 100, // 远低于 internalForceMax(默认 500)→ 进场应被拉满
      school: TechniqueSchool.gangMeng,
    );
    final tech = _mkTech(
      defId: 'tech_gangmeng_jichu',
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
    );

    final bc = BattleCharacter.fromCharacter(
      character: c,
      equipped: const [],
      mainTechnique: tech,
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );

    expect(bc.internalForce, c.internalForce);
    expect(bc.maxQi, 100);
    expect(bc.currentQi, 55);
  });
}

Character _mkChar({
  required RealmTier tier,
  required RealmLayer layer,
  required int internalForce,
  int constitution = 5,
  int enlightenment = 5,
  int agility = 5,
  int fortune = 5,
  TechniqueSchool? school,
  String name = '测试',
}) {
  final attrs = Attributes()
    ..constitution = constitution
    ..enlightenment = enlightenment
    ..agility = agility
    ..fortune = fortune;
  return Character.create(
    name: name,
    realmTier: tier,
    realmLayer: layer,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: internalForce,
    school: school,
  );
}

Technique _mkTech({
  required String defId,
  required TechniqueTier tier,
  required TechniqueSchool school,
  CultivationLayer layer = CultivationLayer.chuKui,
  TechniqueRole role = TechniqueRole.main,
}) {
  return Technique.create(
    defId: defId,
    ownerCharacterId: 1,
    tier: tier,
    school: school,
    role: role,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: layer,
  );
}
