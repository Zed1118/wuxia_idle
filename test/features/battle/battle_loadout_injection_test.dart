import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// P1b 藏经阁 · Task4:BattleCharacter.fromCharacter 的 availableSkills
/// 改读 7 装配槽(主修×2 / 辅修 / 共鸣 / 大招 / 奇遇 / 破招)非空技能。
///
/// 覆盖(波A build gate 后契约):
/// 1. 显式设部分装配槽 → availableSkills == 已设槽技能,**不再广发破势**
///    (破招技走 keySkillId 槽),不含未装主修招、不走 fallback(槽非全空)。
/// 2. 空槽(mainSkillId2=null 等)silent skip,不报错不注入。
/// 3. keySkillId 槽显式装破招技 → 注入。
/// 4. 5 槽全空 fallback → 主修全招 + 本流派破招技(旧档行为等价)。
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
    // 波A:期望 = basic(主修槽1) + ult(大招槽) + 奇遇,**无破势**(keySkillId 空)。
    expect(ids, {
      'skill_gangmeng_jichu_basic',
      'skill_gangmeng_jichu_ult',
      'skill_encounter_ting_yu_jian',
    });
    // 未装的主修招(_skill 槽)不应进战斗池 → 证明没走 fallback。
    expect(ids.contains('skill_gangmeng_jichu_skill'), isFalse,
        reason: '装配槽非全空时不应注入未装的主修招');
    // mainSkillId2=null 等空槽 silent skip:不报错、不引入额外技能。
    expect(bc.availableSkills.length, 3);
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
    expect(ids, {'skill_gangmeng_jichu_basic'});
  });

  test('keySkillId 槽显式装破招技 → 注入(波A 第 7 槽)', () {
    final c = _mkChar()
      ..mainSkillId1 = 'skill_gangmeng_jichu_basic'
      ..keySkillId = 'skill_po_shi';
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

  test('5 槽全空 fallback → 主修全招 + 本流派破招技(旧档行为等价)', () {
    final c = _mkChar(); // 全槽 null,school=gangMeng
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
    // 主修三招 + 刚猛破招技破势(style 匹配 school)。
    expect(ids.contains('skill_po_shi'), isTrue,
        reason: '旧档 fallback 自动带本流派破招技,P0 手感不倒退');
    expect(ids.contains('skill_jie_ying'), isFalse,
        reason: '灵巧破招技不应发给刚猛角色(build gate)');
  });

  test('fallback 流派匹配:lingQiao 角色得截影非破势', () {
    final c = _mkChar(school: TechniqueSchool.lingQiao);
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
    expect(ids.contains('skill_jie_ying'), isTrue);
    expect(ids.contains('skill_po_shi'), isFalse);
  });
}

Character _mkChar({TechniqueSchool school = TechniqueSchool.gangMeng}) {
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
    school: school,
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
