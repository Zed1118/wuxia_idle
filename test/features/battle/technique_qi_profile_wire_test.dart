import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

void main() {
  tearDown(GameRepository.resetForTest);

  test('三流派代表心法提供有界真气差异', () async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );

    final gangMeng = snapshot(
      defId: 'tech_gangmeng_jichu',
      school: TechniqueSchool.gangMeng,
      numbers: repo.numbers,
    );
    final lingQiao = snapshot(
      defId: 'tech_lingqiao_jichu',
      school: TechniqueSchool.lingQiao,
      numbers: repo.numbers,
    );
    final yinRou = snapshot(
      defId: 'tech_yinrou_jichu',
      school: TechniqueSchool.yinRou,
      numbers: repo.numbers,
    );

    expect(gangMeng.currentQi, 55);
    expect(gangMeng.maxQi, 100);
    expect(lingQiao.maxQi, 120);
    expect(lingQiao.currentQi, 40);
    expect(yinRou.qiGainMultiplier, 1.20);
    expect(yinRou.maxQi, 100);
  });

  test('内息紊乱只压低战斗有效内力和开场真气', () async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    final affected = snapshot(
      defId: 'tech_gangmeng_jichu',
      school: TechniqueSchool.gangMeng,
      numbers: repo.numbers,
      disorderHours: repo.numbers.innerBreathDisorder.maxHours,
    );

    expect(affected.internalForce, 400);
    expect(affected.currentQi, 35);
    expect(affected.maxQi, 100);
  });
}

BattleCharacter snapshot({
  required String defId,
  required TechniqueSchool school,
  required NumbersConfig numbers,
  double disorderHours = 0,
}) {
  final character = Character.create(
    name: '测试角色',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026),
    internalForce: 500,
    internalForceMax: 500,
    innerBreathDisorderHoursRemaining: disorderHours,
    school: school,
  );
  final technique = Technique.create(
    defId: defId,
    ownerCharacterId: character.id,
    tier: TechniqueTier.ruMenGong,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026),
  );
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: const [],
    mainTechnique: technique,
    numbers: numbers,
    teamSide: 0,
    slotIndex: 0,
  );
}
