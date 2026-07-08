import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_readiness.dart';

void main() {
  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );

  test('旧档未初始化时按满战备处理', () {
    final now = DateTime(2026, 7, 8, 12);
    final state = SweepReadinessState.normalize(
      points: null,
      lastRecoveredAt: null,
      now: now,
      config: config,
    );

    expect(state.points, 60);
    expect(state.lastRecoveredAt, now);
  });

  test('按真实时间恢复并保留不足一格的剩余时间', () {
    final state = SweepReadinessState.normalize(
      points: 10,
      lastRecoveredAt: DateTime(2026, 7, 8, 10, 15),
      now: DateTime(2026, 7, 8, 12, 45),
      config: config,
    );

    expect(state.points, 12);
    expect(state.lastRecoveredAt, DateTime(2026, 7, 8, 12, 15));
  });

  test('整章扫荡费用 = 关数 * mainlineStageCost', () {
    expect(config.mainlineSweepCostFor(5), 5);
  });

  test('扣除主线扫荡战备不为负', () {
    final state = SweepReadinessState(
      points: 3,
      lastRecoveredAt: DateTime(2026, 7, 8, 12),
      config: config,
    );

    expect(state.canSweepMainlineStages(4), isFalse);
    expect(state.spendMainlineStages(4).points, 3);
    expect(state.spendMainlineStages(3).points, 0);
  });
}
