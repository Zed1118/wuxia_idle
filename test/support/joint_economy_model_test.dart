import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart'
    show ExpeditionPolicy;

import 'joint_economy_model.dart';
import 'test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  group('baicaoHourlyYield', () {
    test('断魂帖速率 = 里程碑张数 / 总时长(深度10)', () {
      final y = baicaoHourlyYield(
        policy: ExpeditionPolicy.yanJingCaiYao,
        avgDepth: 10,
      );
      // 深度10：node10 唯一里程碑(每10节点1张断魂帖)；
      // 总时长 = 8普通×90 + 2险关(node5,10)×180 = 1080min = 18h。
      expect(y.totalHours, closeTo(18.0, 0.001));
      expect(y.ticketPerHour, closeTo(1 / 18, 0.0001));
    });
  });

  group('gauntletEntryRate', () {
    test('稳态入场 = 产帖率×24, 起步入场 = 库存÷每战1帖', () {
      final r = gauntletEntryRate(ticketStock: 5, ticketPerHour: 0.05);
      // 每战耗 1 帖：稳态每日入场受产帖率封顶 = 0.05×24 = 1.2 战/天；
      // 已有库存 5 帖 = 起步可立即入场 5 战。
      expect(r.sustainableEntriesPerDay, closeTo(1.2, 0.0001));
      expect(r.startupEntries, 5);
    });
  });

  group('gauntletWinRate (占位表·C1.3 对齐)', () {
    test('单调: 满配>推荐>入门, 均∈[0,1]', () {
      final entry = gauntletWinRate(GauntletLoadout.ruMen);
      final rec = gauntletWinRate(GauntletLoadout.tuiJian);
      final maxed = gauntletWinRate(GauntletLoadout.manPei);
      expect(entry, inInclusiveRange(0.0, 1.0));
      expect(maxed, inInclusiveRange(0.0, 1.0));
      expect(maxed, greaterThan(rec));
      expect(rec, greaterThan(entry));
    });
  });

  group('enhanceReachDays', () {
    test('= 保底结晶消耗 / 每日结晶净流入', () {
      // +49 保底需 264 颗结晶；每日净流入 8 颗 → 33 天到达。
      expect(
        enhanceReachDays(guaranteeCrystalCost: 264, crystalPerDay: 8.0),
        closeTo(33.0, 0.001),
      );
    });
    test('每日净流入 ≤0 → 不可达(infinity)', () {
      expect(
        enhanceReachDays(guaranteeCrystalCost: 264, crystalPerDay: 0),
        double.infinity,
      );
    });
  });

  group('guaranteeCrystalCostTo (接 success_curve)', () {
    test('+49 保底结晶消耗 = 264 (对齐 enhancement_material_supply)', () {
      expect(guaranteeCrystalCostTo(repo.numbers.enhancement, 49), 264);
    });
    test('单调递增: +49 ≥ +40 ≥ +30 ≥ 0', () {
      final to30 = guaranteeCrystalCostTo(repo.numbers.enhancement, 30);
      final to40 = guaranteeCrystalCostTo(repo.numbers.enhancement, 40);
      final to49 = guaranteeCrystalCostTo(repo.numbers.enhancement, 49);
      expect(to30, greaterThan(0));
      expect(to40, greaterThanOrEqualTo(to30));
      expect(to49, greaterThanOrEqualTo(to40));
    });
  });

  group('namedEquipAidContribution (占位·Phase C 对齐)', () {
    test('单调有界: 0件→0, 递增, 任意堆叠封顶(留余量<25pp 红线)', () {
      expect(namedEquipAidContribution(0), 0);
      expect(
        namedEquipAidContribution(2),
        greaterThan(namedEquipAidContribution(1)),
      );
      // 不变式①红线 ≤25pp；占位 cap 留余量 <25，堆叠再多不压倒收藏/多样性。
      expect(namedEquipAidContribution(100), lessThan(25.0));
    });
  });

  group('daysToTraverse', () {
    test('= 总经验 / (每小时经验×24)', () {
      // 总需 48000 exp；每小时 1000 exp → 每天 24000 → 2 天。
      expect(
        daysToTraverse(totalExp: 48000, expPerHour: 1000),
        closeTo(2.0, 0.0001),
      );
    });
    test('每小时经验 ≤0 → 不可达(infinity)', () {
      expect(daysToTraverse(totalExp: 48000, expPerHour: 0), double.infinity);
    });
  });

  group('expToTraverseAbsLevels', () {
    test('可加性: exp(10→17) = exp(10→14) + exp(14→17), 且 >0', () {
      int span(int from, int to) => expToTraverseAbsLevels(
        realmByAbs: repo.getRealmByAbsoluteLevel,
        fromAbs: from,
        toAbs: to,
      );
      expect(span(10, 17), span(10, 14) + span(14, 17));
      expect(span(10, 17), greaterThan(0));
    });
    test('空跨度 = 0', () {
      expect(
        expToTraverseAbsLevels(
          realmByAbs: repo.getRealmByAbsoluteLevel,
          fromAbs: 10,
          toAbs: 10,
        ),
        0,
      );
    });
  });
}
