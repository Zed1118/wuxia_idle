import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/seclusion/application/retreat_settlement_calculator.dart';

void main() {
  group('RetreatSettlementCalculator.splitHours', () {
    test('72h01m 分为 72h 闭关 + 1min 普通挂机', () {
      final split = RetreatSettlementCalculator.splitHours(
        elapsedHours: 72 + 1 / 60,
        fullRateHours: 72,
      );

      expect(split.retreatHours, 72);
      expect(split.passiveHours, closeTo(1 / 60, 1e-9));
    });

    test('时钟回拨时两段时长均为 0', () {
      final split = RetreatSettlementCalculator.splitHours(
        elapsedHours: -3,
        fullRateHours: 72,
      );

      expect(split.retreatHours, 0);
      expect(split.passiveHours, 0);
    });
  });

  group('RetreatSettlementCalculator equipment nodes', () {
    test('12 小时一次，72 小时后最多六次', () {
      expect(
        RetreatSettlementCalculator.equipmentRollCount(
          retreatHours: 11 + 59 / 60,
          intervalHours: 12,
          maxCount: 6,
        ),
        0,
      );
      expect(
        RetreatSettlementCalculator.equipmentRollCount(
          retreatHours: 12,
          intervalHours: 12,
          maxCount: 6,
        ),
        1,
      );
      expect(
        RetreatSettlementCalculator.equipmentRollCount(
          retreatHours: 71 + 59 / 60,
          intervalHours: 12,
          maxCount: 6,
        ),
        5,
      );
      expect(
        RetreatSettlementCalculator.equipmentRollCount(
          retreatHours: 72,
          intervalHours: 12,
          maxCount: 6,
        ),
        6,
      );
      expect(
        RetreatSettlementCalculator.equipmentRollCount(
          retreatHours: 240,
          intervalHours: 12,
          maxCount: 6,
        ),
        6,
      );
    });

    test('同一组存档材料的稳定种子始终相同', () {
      const values = [1, 77, 1783824000000000, 6];
      final first = RetreatSettlementCalculator.stableRetreatSeed(values);
      final second = RetreatSettlementCalculator.stableRetreatSeed(values);

      expect(second, first);
      expect(
        RetreatSettlementCalculator.stableRetreatSeed([...values.take(3), 5]),
        isNot(first),
      );
    });

    test('高阶权重溢出时全部并入神物', () {
      const row = RetreatEquipmentTierWeights(
        hour: 72,
        base: 0.30,
        current: 0.40,
        above1: 0.20,
        above2: 0.10,
      );

      expect(
        RetreatSettlementCalculator.selectEquipmentTier(
          anchorTier: EquipmentTier.baoWu,
          weights: row,
          roll: 0.31,
        ),
        EquipmentTier.shenWu,
      );
      expect(
        RetreatSettlementCalculator.selectEquipmentTier(
          anchorTier: EquipmentTier.baoWu,
          weights: row,
          roll: 0.99,
        ),
        EquipmentTier.shenWu,
      );
    });
  });
}
