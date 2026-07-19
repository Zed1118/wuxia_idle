import 'package:wuxia_idle/data/defs/realm_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart'
    show ExpeditionPolicy;

/// 百草岭×断魂庄×装备强化 联合经济模型（纯函数，诊断探针用）。
///
/// plan `docs/superpowers/plans/2026-07-15-baicao-duanhun-joint-economy-probe.md`
/// 五段吞吐链纯函数建模。无 Isar/无副作用，可单测。命名装备助炼仍是显式占位段；
/// `gauntletWinRate` 已由断魂庄三档生产战斗探针回填。

/// 百草岭远征每小时期望产出（沿一条确定 seed 路径 node 1..avgDepth 累加
/// `ExpeditionRules.rewardsForNode`，按累计节点时长换算每小时）。
class BaicaoHourlyYield {
  const BaicaoHourlyYield({
    required this.expPerHour,
    required this.ticketPerHour,
    required this.silverPerHour,
    required this.herbPerHour,
    required this.totalHours,
  });

  /// 经验/小时。
  final double expPerHour;

  /// 断魂帖/小时（每 10 节点 1 张里程碑）。
  final double ticketPerHour;

  /// 银两/小时。
  final double silverPerHour;

  /// 补给原料(药草+灵泉水)/小时（疗伤丹/行囊补给的产线上游）。
  final double herbPerHour;

  /// 该深度一趟远征的总时长（小时）。
  final double totalHours;
}

BaicaoHourlyYield baicaoHourlyYield({
  required ExpeditionPolicy policy,
  required int avgDepth,
  int baseExpPerBattle = 170,
  int normalMinutes = 90,
  int eliteMinutes = 180,
  int saveId = 1,
  int runSerial = 1,
}) {
  var totalMinutes = 0;
  var exp = 0;
  var tickets = 0;
  var silver = 0;
  var herb = 0;
  for (var node = 1; node <= avgDepth; node++) {
    final n = ExpeditionRules.generateNode(
      saveId: saveId,
      runSerial: runSerial,
      node: node,
      policy: policy,
      normalMinutes: normalMinutes,
      eliteMinutes: eliteMinutes,
    );
    totalMinutes += n.durationMinutes;
    final rewards = ExpeditionRules.rewardsForNode(
      node: n,
      saveId: saveId,
      runSerial: runSerial,
      baseExpPerBattle: baseExpPerBattle,
    );
    for (final r in rewards) {
      switch (r.rewardKey) {
        case 'exp':
          exp += r.quantity;
        case 'item_duanhuntie':
          tickets += r.quantity;
        case 'item_silver':
          silver += r.quantity;
        case 'item_yaocao':
        case 'item_lingquanshui':
          herb += r.quantity;
      }
    }
  }
  final totalHours = totalMinutes / 60.0;
  double perHour(int total) => totalHours == 0 ? 0 : total / totalHours;
  return BaicaoHourlyYield(
    expPerHour: perHour(exp),
    ticketPerHour: perHour(tickets),
    silverPerHour: perHour(silver),
    herbPerHour: perHour(herb),
    totalHours: totalHours,
  );
}

/// 断魂庄入场频率（帖库存 ÷ 每战耗 1 帖 起步 + 产帖率稳态封顶）。
class GauntletEntryRate {
  const GauntletEntryRate({
    required this.sustainableEntriesPerDay,
    required this.startupEntries,
  });

  /// 稳态可持续每日入场：受产帖率封顶（每战耗 1 帖，长期入场率 ≤ 产帖率×24）。
  final double sustainableEntriesPerDay;

  /// 起步一次性入场：已有帖库存 ÷ 每战 1 帖（前期突发，用完转稳态）。
  final int startupEntries;
}

GauntletEntryRate gauntletEntryRate({
  required int ticketStock,
  required double ticketPerHour,
  int ticketPerEntry = 1,
}) {
  return GauntletEntryRate(
    sustainableEntriesPerDay: ticketPerHour * 24 / ticketPerEntry,
    startupEntries: ticketStock ~/ ticketPerEntry,
  );
}

/// 断魂庄阵容档位（入门 / 推荐 / 满配）。
enum GauntletLoadout { ruMen, tuiJian, manPei }

/// 断魂庄三档阵容胜率。固定 50 seeds、三流派真实队伍、三关继承 HP/真气/冷却，
/// 不使用补给；由 `test/tools/gauntlet_balance_probe_test.dart` 同源守卫。
double gauntletWinRate(GauntletLoadout loadout) => switch (loadout) {
  GauntletLoadout.ruMen => 0.02,
  GauntletLoadout.tuiJian => 0.50,
  GauntletLoadout.manPei => 1.00,
};

/// 单件装备强化到达 +30/+40/+49 的预期天数：保底策略结晶消耗 ÷ 每日结晶净流入。
/// [guaranteeCrystalCost] 由 [guaranteeCrystalCostTo] 按 `success_curve` 算得。
/// 净流入 ≤0 → 不可达（infinity），供不变式「无强制等待」判定。
double enhanceReachDays({
  required int guaranteeCrystalCost,
  required double crystalPerDay,
}) {
  if (crystalPerDay <= 0) return double.infinity;
  return guaranteeCrystalCost / crystalPerDay;
}

/// 用心血结晶保底策略把单件装备强化到 [targetLevel] 的总结晶消耗。
/// 逐级累加 `success_curve` 的 [EnhancementConfig.crystalCostToGuarantee]（仅
/// +14 以后各段有保底成本，低段返回 null 走磨剑石不计入）。对齐
/// `enhancement_material_supply_test` 的 guaranteeCrystalCost 口径。
int guaranteeCrystalCostTo(EnhancementConfig config, int targetLevel) {
  var cost = 0;
  for (var level = 1; level <= targetLevel; level++) {
    final c = config.crystalCostToGuarantee(level);
    if (c != null) cost += c;
  }
  return cost;
}

/// 同一命名装备反复选做「助炼来源」的累计强化贡献（百分点）。**占位建模**——
/// 命名装备助炼机制的真实曲线待 Phase C 定案；此处线性累加并封顶 [cap]，
/// 封顶值刻意留在不变式①红线 25pp 之下，保证「堆同一件命名装备助炼不压倒
/// 收藏/多样性」。改占位须维持 cap<25。
double namedEquipAidContribution(
  int sameDefStack, {
  double perPiece = 5.0,
  double cap = 20.0,
}) {
  if (sameDefStack <= 0) return 0;
  final raw = sameDefStack * perPiece;
  return raw > cap ? cap : raw;
}

/// 挂机推进指定经验量所需天数：总经验 ÷ (每小时经验 × 24)。
/// 每小时经验 ≤0 → 不可达（infinity），供节奏判定。
double daysToTraverse({required int totalExp, required double expPerHour}) {
  if (expPerHour <= 0) return double.infinity;
  return totalExp / (expPerHour * 24);
}

/// 从绝对境界层 [fromAbs] 挂机推进到 [toAbs]（不含）所需累计经验：逐层累加各层
/// [RealmDef.experienceToNext]。Lv100→170 = abs 层 10→17（当前 cap=17）。
int expToTraverseAbsLevels({
  required RealmDef Function(int) realmByAbs,
  required int fromAbs,
  required int toAbs,
}) {
  var total = 0;
  for (var abs = fromAbs; abs < toAbs; abs++) {
    total += realmByAbs(abs).experienceToNext;
  }
  return total;
}
