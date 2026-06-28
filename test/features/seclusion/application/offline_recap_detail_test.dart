import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_recap_detail.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_recap_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  group('OfflineRecapDetailFormatter', () {
    test('active recap 明细总量只来自 recap 现有字段', () {
      const recap = (
        awayHours: 5.0,
        mapName: '山林',
        isComplete: true,
        progressPct: 1.0,
        estimatedMojianshi: 120,
        estimatedExperience: 300,
        estimatedItemRewards: {'item_yaocao': 4, 'item_silver_leaf': 2},
        estimatedTechniqueLearnPoints: 3,
        estimatedSilver: 45,
        settledHours: 4.0,
        limitReason: OfflineRecapLimitReason.plannedDuration,
      );

      final detail = OfflineRecapDetailFormatter.forRetreat(
        recap,
        itemNameOf: (id) => switch (id) {
          'item_yaocao' => '药草',
          'item_silver_leaf' => '银叶',
          _ => id,
        },
      );

      expect(detail.experience, recap.estimatedExperience);
      expect(detail.silver, recap.estimatedSilver);
      expect(
        detail.materialQuantity,
        recap.estimatedMojianshi +
            recap.estimatedItemRewards.values.fold<int>(0, (a, b) => a + b),
      );
      expect(detail.techniqueLearnPoints, recap.estimatedTechniqueLearnPoints);
      expect(detail.skillProficiencyPoints, 0);
      expect(detail.equipmentDropCount, 0);
      expect(detail.equipmentDropPending, isTrue);
      expect(
        detail.rows,
        contains(UiStrings.offlineRecapMaterialDetail('磨剑石 120 · 药草 4 · 银叶 2')),
      );
      expect(
        detail.rows,
        contains(UiStrings.offlineRecapTechniqueLearnDetail(3)),
      );
      expect(
        detail.groups.map((g) => g.title),
        containsAll([
          UiStrings.offlineRecapSettlementGroupTitle,
          UiStrings.offlineRecapRetreatGainGroupTitle,
          UiStrings.offlineRecapCollectGroupTitle,
        ]),
      );
      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapSkillProficiencyDetail(0))),
      );
    });

    test('active recap 隐藏 0 值收益项但保留收功揭晓说明', () {
      const recap = (
        awayHours: 2.0,
        mapName: '山林',
        isComplete: false,
        progressPct: 0.5,
        estimatedMojianshi: 0,
        estimatedExperience: 0,
        estimatedItemRewards: {'item_yaocao': 0},
        estimatedTechniqueLearnPoints: 0,
        estimatedSilver: 0,
        settledHours: 2.0,
        limitReason: OfflineRecapLimitReason.inProgress,
      );

      final detail = OfflineRecapDetailFormatter.forRetreat(
        recap,
        itemNameOf: (_) => '药草',
      );

      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapExperienceDetail(0))),
      );
      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapSilverDetail(0))),
      );
      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapMaterialDetail('无'))),
      );
      expect(detail.rows, contains(UiStrings.offlineRecapNoGainsDetail));
      expect(
        detail.rows,
        contains(
          UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapDropPending),
        ),
      );
    });

    test('passive recap 明细不引入银两、熟练度或装备掉落', () {
      const yield_ = (
        mojianshi: 2,
        experience: 250,
        awayHours: 10.0,
        settledHours: 10.0,
        isCapped: false,
      );

      final detail = OfflineRecapDetailFormatter.forPassive(yield_);

      expect(detail.experience, yield_.experience);
      expect(detail.silver, 0);
      expect(detail.materialQuantity, yield_.mojianshi);
      expect(detail.techniqueLearnPoints, 0);
      expect(detail.skillProficiencyPoints, 0);
      expect(detail.equipmentDropCount, 0);
      expect(detail.equipmentDropPending, isFalse);
      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapSilverDetail(0))),
      );
      expect(
        detail.rows,
        isNot(contains(UiStrings.offlineRecapSkillProficiencyDetail(0))),
      );
      expect(
        detail.rows,
        isNot(
          contains(
            UiStrings.offlineRecapDropDetail(UiStrings.offlineRecapNoDrop),
          ),
        ),
      );
      expect(
        detail.groups.map((g) => g.title),
        containsAll([
          UiStrings.offlineRecapSettlementGroupTitle,
          UiStrings.offlineRecapPassiveGainGroupTitle,
        ]),
      );
    });
  });
}
