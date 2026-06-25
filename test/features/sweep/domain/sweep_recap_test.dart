import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_recap.dart';

/// T3 扫荡战果汇总累加模型测。
/// 扫荡逐关 settle 后把每关 [SweepBattleOutcome] 折进 [SweepRecap]，
/// 收尾一张总账（总掉落/银两/经验/升层）。
void main() {
  group('SweepRecap', () {
    test('空账全零', () {
      const r = SweepRecap.empty();
      expect(r.stagesCleared, 0);
      expect(r.equipmentDrops, 0);
      expect(r.expGained, 0);
      expect(r.realmAdvances, 0);
      expect(r.skillFragments, 0);
      expect(r.itemsByDefId, isEmpty);
    });

    test('折入一关战果', () {
      const r = SweepRecap.empty();
      final next = r.accumulate(const SweepBattleOutcome(
        equipmentDrops: 2,
        itemsByDefId: {'item_silver': 120, 'mojianshi': 3},
        expGained: 50,
        realmAdvances: 1,
        skillFragments: 1,
      ));
      expect(next.stagesCleared, 1);
      expect(next.equipmentDrops, 2);
      expect(next.itemsByDefId['item_silver'], 120);
      expect(next.itemsByDefId['mojianshi'], 3);
      expect(next.expGained, 50);
      expect(next.realmAdvances, 1);
      expect(next.skillFragments, 1);
    });

    test('多关折叠：计数累加 + 同 defId 物品合并', () {
      var r = const SweepRecap.empty();
      r = r.accumulate(const SweepBattleOutcome(
        equipmentDrops: 1,
        itemsByDefId: {'item_silver': 100, 'mojianshi': 2},
        expGained: 30,
        realmAdvances: 0,
      ));
      r = r.accumulate(const SweepBattleOutcome(
        equipmentDrops: 3,
        itemsByDefId: {'item_silver': 50, 'xinxuejiejing': 1},
        expGained: 70,
        realmAdvances: 2,
        skillFragments: 2,
      ));
      expect(r.stagesCleared, 2);
      expect(r.equipmentDrops, 4);
      expect(r.itemsByDefId['item_silver'], 150); // 同 defId 合并
      expect(r.itemsByDefId['mojianshi'], 2);
      expect(r.itemsByDefId['xinxuejiejing'], 1);
      expect(r.expGained, 100);
      expect(r.realmAdvances, 2);
      expect(r.skillFragments, 2);
    });

    test('累加不可变：原账不被改写', () {
      const base = SweepRecap.empty();
      base.accumulate(const SweepBattleOutcome(
        equipmentDrops: 5,
        itemsByDefId: {'item_silver': 999},
        expGained: 1,
        realmAdvances: 1,
      ));
      // base 仍为空账（accumulate 返回新实例）
      expect(base.stagesCleared, 0);
      expect(base.itemsByDefId, isEmpty);
    });
  });
}
