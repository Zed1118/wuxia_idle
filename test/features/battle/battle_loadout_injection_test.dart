import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// P1b 藏经阁 · Task4:BattleCharacter.fromCharacter 的 availableSkills
/// 改读 6 装配槽(主修×2 / 辅修 / 共鸣 / 大招 / 奇遇)非空技能。
///
/// 覆盖:
/// 1. 显式设部分装配槽 → availableSkills == {已设槽技能 + 破势(玩家方广发)},
///    不含主修心法其他未装招、不走 fallback(槽非全空)。
/// 2. 空槽(mainSkillId2=null 等)silent skip,不报错不注入。
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

  test('装配槽非全空 → availableSkills 只含已设槽技能 + 破势(不走 fallback)', () {
    final c = _mkChar()
      // 主修槽 1 + 大招槽 + 奇遇槽,其余(mainSkillId2/assist/resonance)留 null。
      ..mainSkillId1 = 'skill_gangmeng_jichu_basic'
      ..ultimateSkillId = 'skill_gangmeng_jichu_ult'
      ..equippedEncounterSkillId = 'skill_encounter_ting_yu_jian';
    // 主修心法仍是 tech_gangmeng_jichu(skillIds 含 basic/skill/ult 三招),
    // 但因装配槽非全空,fromCharacter 不走 fallback「主修全招」。
    final tech = _mkTech();

    final bc = BattleCharacter.fromCharacter(
      character: c,
      equipped: const [],
      mainTechnique: tech,
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );

    final ids = bc.availableSkills.map((s) => s.id).toSet();
    // 期望:basic(主修槽1) + ult(大招槽) + 奇遇 + 破势。
    expect(ids, {
      'skill_gangmeng_jichu_basic',
      'skill_gangmeng_jichu_ult',
      'skill_encounter_ting_yu_jian',
      'skill_po_shi',
    });
    // 未装的主修招(_skill 槽)不应进战斗池 → 证明没走 fallback。
    expect(ids.contains('skill_gangmeng_jichu_skill'), isFalse,
        reason: '装配槽非全空时不应注入未装的主修招');
    // mainSkillId2=null 等空槽 silent skip:不报错、不引入额外技能。
    expect(bc.availableSkills.length, 4);
  });

  test('mainSkillId2=null 空槽不注入也不抛错', () {
    final c = _mkChar()
      ..mainSkillId1 = 'skill_gangmeng_jichu_basic';
    // 仅设 1 槽,其余全 null。
    final tech = _mkTech();

    final bc = BattleCharacter.fromCharacter(
      character: c,
      equipped: const [],
      mainTechnique: tech,
      numbers: GameRepository.instance.numbers,
      teamSide: 0,
      slotIndex: 0,
    );

    final ids = bc.availableSkills.map((s) => s.id).toSet();
    expect(ids, {'skill_gangmeng_jichu_basic', 'skill_po_shi'});
  });
}

Character _mkChar() {
  final attrs = Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;
  return Character.create(
    name: '测试',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.ruMen,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 100,
    school: TechniqueSchool.gangMeng,
  );
}

Technique _mkTech() {
  return Technique.create(
    defId: 'tech_gangmeng_jichu',
    ownerCharacterId: 1,
    tier: TechniqueTier.ruMenGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.chuKui,
  );
}
