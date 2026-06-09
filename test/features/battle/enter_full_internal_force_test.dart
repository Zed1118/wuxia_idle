import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// P0 破招 Task 4:战斗内力进场满(maxIf · 每场预算模型 · 与敌方对称)。
///
/// 现状 `BattleCharacter.fromCharacter` 玩家进场 currentInternalForce =
/// character.internalForce(角色当前持有内力),不等于 maxInternalForce。
/// 敌方进场是 current=max(满)。本测断言玩家进场也满,使「每场内力预算」
/// 模型干净 + 与敌方对称。
///
/// fixture 沿 test/combat/battle_state_test.dart 的 _mkChar/_mkTech 体例。
/// 关键:character.internalForce(100)< internalForceMax(默认 500)→ maxIf=500,
/// 进场后 current 应被拉满到 500,使断言在「自然方向」上有意义。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  test('进场内力满:currentInternalForce == maxInternalForce（与敌方对称）', () {
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

    // 前提:fixture 的 character.internalForce 确实 < maxIf,断言才有意义。
    expect(c.internalForce, lessThan(bc.maxInternalForce));
    // 核心断言:进场满。
    expect(bc.currentInternalForce, bc.maxInternalForce);
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
