import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../support/test_data.dart';

void main() {
  test('流派百科逐向匹配生产 SchoolCounterMatrix', () async {
    final repo = await loadTestGameRepository();
    final matrix = repo.numbers.schoolCounter;
    const labels = <TechniqueSchool, String>{
      TechniqueSchool.gangMeng: '刚猛',
      TechniqueSchool.lingQiao: '灵巧',
      TechniqueSchool.yinRou: '阴柔',
    };

    for (final attacker in TechniqueSchool.values) {
      final target = TechniqueSchool.values.singleWhere(
        (candidate) =>
            matrix.multiplierFor(attacker, candidate) == matrix.counter,
      );
      expect(
        UiStrings.glossarySchool,
        contains('${labels[attacker]}克${labels[target]}'),
        reason: '${attacker.name} 的百科克制方向必须由生产矩阵决定',
      );
    }
  });

  test('散功提示逐项匹配生产 DispelService 结算', () async {
    final repo = await loadTestGameRepository();
    final character =
        Character.create(
            name: '测试者',
            realmTier: RealmTier.erLiu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes()
              ..constitution = 5
              ..enlightenment = 5
              ..agility = 5
              ..fortune = 5,
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.disciple,
            createdAt: DateTime(2026, 7, 19),
            internalForce: 5000,
            internalForceMax: 10000,
            mainTechniqueId: 10,
            assistTechniqueIds: [11],
          )
          ..id = 1
          ..innerBreathDisorderHoursRemaining = 9;
    final oldMain = Technique.create(
      defId: 'tech_old_main',
      ownerCharacterId: 1,
      tier: TechniqueTier.mingJiaGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 19),
      cultivationLayer: CultivationLayer.daCheng,
      cultivationProgress: 800,
      cultivationProgressToNext: 900,
    )..id = 10;
    final incomingMain = Technique.create(
      defId: 'tech_incoming_main',
      ownerCharacterId: 1,
      tier: TechniqueTier.mingJiaGong,
      school: TechniqueSchool.yinRou,
      role: TechniqueRole.assist,
      learnedAt: DateTime(2026, 7, 19),
      cultivationLayer: CultivationLayer.xiaoCheng,
      cultivationProgress: 275,
      cultivationProgressToNext: 250,
    )..id = 11;

    final result = DispelService.dispel(
      ch: character,
      mainTech: oldMain,
      newMainTech: incomingMain,
      n: repo.numbers,
    );

    expect(result.success, isTrue);
    expect(result.internalForceBefore, 5000);
    expect(result.internalForceAfter, 5000);
    expect(character.innerBreathDisorderHoursRemaining, 12);
    expect(result.progressAfter, 400);
    expect(incomingMain.cultivationProgress, 275, reason: '换入主修原为辅修，修炼度不动');
    expect(
      UiStrings.dispelCostInternalForce(
        result.internalForceBefore,
        result.internalForceAfter,
      ),
      '永久内力 5000（不变）',
    );
    expect(
      UiStrings.dispelCostCultivation(800, result.progressAfter),
      '原主修修炼度 800 → 400',
    );
    expect(
      UiStrings.dispelCostInnerBreathDisorder(9, 12, 12),
      '内息紊乱 9.0 → 12.0 小时（累计上限 12.0 小时）',
    );
  });
}
