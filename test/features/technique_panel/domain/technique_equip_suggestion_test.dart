import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/technique_panel/domain/technique_equip_suggestion.dart';

void main() {
  Attributes attrs({int enlightenment = 5}) => Attributes()
    ..constitution = 5
    ..enlightenment = enlightenment
    ..agility = 5
    ..fortune = 5;

  Character character({
    required int id,
    required String name,
    RealmTier realmTier = RealmTier.xueTu,
    TechniqueSchool school = TechniqueSchool.gangMeng,
    int insightPoints = 10,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
    int enlightenment = 5,
  }) {
    return Character.create(
      name: name,
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: attrs(enlightenment: enlightenment),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 6, 28),
      school: school,
      insightPoints: insightPoints,
      mainTechniqueId: mainTechniqueId,
      assistTechniqueIds: assistTechniqueIds,
    )..id = id;
  }

  TechniqueDef techniqueDef({
    String id = 'tech_test',
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
  }) {
    return TechniqueDef(
      id: id,
      name: id,
      tier: tier,
      school: school,
      description: '',
      skillIds: const [],
      internalForceGrowthBonus: 1,
      speedBonus: 0,
      acquireSourceTags: const [],
    );
  }

  Technique learned({
    required int id,
    required String defId,
    required int ownerId,
    required TechniqueRole role,
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
  }) {
    return Technique.create(
      defId: defId,
      ownerCharacterId: ownerId,
      tier: tier,
      school: school,
      role: role,
      learnedAt: DateTime(2026, 6, 28),
    )..id = id;
  }

  const cost = LearningCostConfig(main: 3, assist: 2);
  TechniqueTier testCap(RealmTier tier) => TechniqueTier.values[tier.index];

  test('低境界面对高阶心法只显示境界不足,不作为可装配推荐', () {
    final low = character(id: 1, name: '低境界', realmTier: RealmTier.xueTu);
    final highTier = techniqueDef(tier: TechniqueTier.mingJiaGong);

    final suggestions = TechniqueEquipSuggestionService.buildSuggestions(
      technique: highTier,
      characters: [low],
      learnedTechniquesByCharacter: const {},
      learningCost: cost,
      techniqueTierCapOf: testCap,
    );

    expect(
      suggestions.single.status,
      TechniqueEquipSuggestionStatus.realmLocked,
    );
    expect(suggestions.single.isEquipable, isFalse);
    expect(suggestions.single.currentCap, TechniqueTier.ruMenGong);
  });

  test('同流派且有空主修槽的角色可修为主修', () {
    final candidate = character(
      id: 1,
      name: '可主修',
      realmTier: RealmTier.sanLiu,
      insightPoints: 3,
      enlightenment: 8,
    );
    final def = techniqueDef(tier: TechniqueTier.changLianGong);

    final suggestion = TechniqueEquipSuggestionService.buildSuggestions(
      technique: def,
      characters: [candidate],
      learnedTechniquesByCharacter: const {},
      learningCost: cost,
      techniqueTierCapOf: testCap,
    ).single;

    expect(suggestion.status, TechniqueEquipSuggestionStatus.readyForMain);
    expect(
      suggestion.reasons,
      contains(TechniqueEquipSuggestionReason.sameSchool),
    );
    expect(
      suggestion.reasons,
      contains(TechniqueEquipSuggestionReason.fillsMainSlot),
    );
  });

  test('已有主修且辅修槽满时显示槽位卡点', () {
    final full = character(
      id: 1,
      name: '槽满',
      realmTier: RealmTier.sanLiu,
      mainTechniqueId: 10,
      assistTechniqueIds: const [11, 12, 13],
    );

    final suggestion = TechniqueEquipSuggestionService.buildSuggestions(
      technique: techniqueDef(tier: TechniqueTier.changLianGong),
      characters: [full],
      learnedTechniquesByCharacter: const {},
      learningCost: cost,
      techniqueTierCapOf: testCap,
    ).single;

    expect(suggestion.status, TechniqueEquipSuggestionStatus.assistSlotsFull);
    expect(suggestion.isEquipable, isFalse);
  });

  test('已习得同一本心法的角色优先显示已装配状态', () {
    final owner = character(
      id: 1,
      name: '已学',
      realmTier: RealmTier.sanLiu,
      mainTechniqueId: 20,
    );
    final other = character(
      id: 2,
      name: '未学',
      realmTier: RealmTier.sanLiu,
      insightPoints: 0,
    );
    final def = techniqueDef(
      id: 'tech_same',
      tier: TechniqueTier.changLianGong,
    );

    final suggestions = TechniqueEquipSuggestionService.buildSuggestions(
      technique: def,
      characters: [other, owner],
      learnedTechniquesByCharacter: {
        1: [
          learned(
            id: 20,
            defId: 'tech_same',
            ownerId: 1,
            role: TechniqueRole.main,
            tier: TechniqueTier.changLianGong,
          ),
        ],
      },
      learningCost: cost,
      techniqueTierCapOf: testCap,
    );

    expect(suggestions.first.character.id, owner.id);
    expect(
      suggestions.first.status,
      TechniqueEquipSuggestionStatus.alreadyMain,
    );
    expect(suggestions.first.isEquipable, isTrue);
    expect(
      suggestions.last.status,
      TechniqueEquipSuggestionStatus.insufficientInsight,
    );
  });
}
