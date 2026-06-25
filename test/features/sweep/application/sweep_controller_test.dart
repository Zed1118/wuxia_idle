import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_controller.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';

/// T6 扫荡驱动状态机测。SweepScreen 把每场真战斗胜负喂给它，它决定
/// 前进 / 收工 / 停 / 战败 halt，并累加 recap。确定性、无 widget 依赖。
void main() {
  const win = SweepBattleOutcome(
    equipmentDrops: 1,
    itemsByDefId: {'item_silver': 100},
    expGained: 20,
  );

  test('初态：running / index 0 / 空账', () {
    final c = SweepController(totalUnits: 3);
    expect(c.status, SweepStatus.running);
    expect(c.currentIndex, 0);
    expect(c.recap.stagesCleared, 0);
    expect(c.isRunning, isTrue);
  });

  test('连胜全部关 → completed，recap 计满，index 到尾', () {
    final c = SweepController(totalUnits: 3);
    c.recordVictory(win);
    expect(c.status, SweepStatus.running); // 还有关
    expect(c.currentIndex, 1);
    c.recordVictory(win);
    c.recordVictory(win);
    expect(c.status, SweepStatus.completed);
    expect(c.currentIndex, 3);
    expect(c.recap.stagesCleared, 3);
    expect(c.recap.expGained, 60);
  });

  test('中途请求停止 → 当前关打完即 stoppedByUser，不再前进', () {
    final c = SweepController(totalUnits: 5);
    c.recordVictory(win); // index 1
    c.requestStop();
    c.recordVictory(win); // 当前关打完
    expect(c.status, SweepStatus.stoppedByUser);
    expect(c.currentIndex, 2);
    expect(c.recap.stagesCleared, 2);
    expect(c.isRunning, isFalse);
  });

  test('某关战败 → stoppedByDefeat，index 停在该关', () {
    final c = SweepController(totalUnits: 5);
    c.recordVictory(win); // index 1
    c.recordVictory(win); // index 2
    c.recordDefeat();
    expect(c.status, SweepStatus.stoppedByDefeat);
    expect(c.currentIndex, 2); // 第 3 关(index 2)战败
    expect(c.recap.stagesCleared, 2);
  });

  test('终态后再喂胜负 → no-op(不污染账)', () {
    final c = SweepController(totalUnits: 2);
    c.recordVictory(win);
    c.recordVictory(win); // completed
    c.recordVictory(win); // 应被忽略
    c.recordDefeat(); // 应被忽略
    expect(c.status, SweepStatus.completed);
    expect(c.recap.stagesCleared, 2);
    expect(c.currentIndex, 2);
  });
}
