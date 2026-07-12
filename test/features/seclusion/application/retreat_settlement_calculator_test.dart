import 'package:flutter_test/flutter_test.dart';
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
}
