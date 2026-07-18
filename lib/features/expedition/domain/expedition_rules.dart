import '../../../core/domain/reward_entry.dart';
import '../../../shared/utils/rng.dart';
import 'expedition_node.dart';
import 'expedition_run.dart' show ExpeditionPolicy;
import 'expedition_seed.dart';

/// 百草岭节点/瘴蚀/权重纯规则（§4.2-§4.5）。无 Isar、无副作用。
class ExpeditionRules {
  const ExpeditionRules._();

  /// 每 5 的倍数节点为险关（§4.2）。
  static bool isEliteNode(int node) => node > 0 && node % 5 == 0;

  /// 节点 [node]（1-based）的时长：险关取 [eliteMinutes]，否则 [normalMinutes]（§4.2）。
  static int nodeDurationMinutes(
    int node, {
    required int normalMinutes,
    required int eliteMinutes,
  }) => isEliteNode(node) ? eliteMinutes : normalMinutes;

  /// 从出发累计到「完成节点 [node]」所需分钟（node ≤ 0 → 0）。节点按 1..node 逐个
  /// 求和，险关按 [eliteMinutes] 计入。settle 的完成节点判定与总览「下一节点剩余
  /// 时间」共用此单调曲线（绝对时间锚定，§7.1/§10）。
  static int cumulativeMinutesToCompleteNode(
    int node, {
    required int normalMinutes,
    required int eliteMinutes,
  }) {
    if (node <= 0) return 0;
    var total = 0;
    for (var n = 1; n <= node; n++) {
      total += nodeDurationMinutes(
        n,
        normalMinutes: normalMinutes,
        eliteMinutes: eliteMinutes,
      );
    }
    return total;
  }

  /// 距「下一节点」完成尚余多少（总览显示，§7.1）。已完成 [completedNodes] 个节点时，
  /// 下一节点是第 `completedNodes+1` 个；其完成时刻 = [departedAt] + 累计时长（与
  /// settle 同曲线绝对锚定）。返回非负 Duration；[now] 已越过该时刻（可结算未追平）
  /// → [Duration.zero]。
  static Duration nextNodeRemaining({
    required DateTime departedAt,
    required int completedNodes,
    required DateTime now,
    required int normalMinutes,
    required int eliteMinutes,
  }) {
    final targetMinutes = cumulativeMinutesToCompleteNode(
      completedNodes + 1,
      normalMinutes: normalMinutes,
      eliteMinutes: eliteMinutes,
    );
    final completionTime = departedAt.add(Duration(minutes: targetMinutes));
    final remaining = completionTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 普通节点四类权重（方针偏移，§4.3）。险关不走此表。
  /// 权重和为正；数值填表见 expeditions.yaml（此处为规则骨架默认）。
  static Map<ExpeditionNodeType, int> _normalWeights(ExpeditionPolicy policy) {
    // 基础均衡（各 10），方针把对应类型抬到 25。
    final w = {
      ExpeditionNodeType.caiYao: 10,
      ExpeditionNodeType.feiYi: 10,
      ExpeditionNodeType.zaoYu: 10,
      ExpeditionNodeType.yiJi: 10,
    };
    switch (policy) {
      case ExpeditionPolicy.yanJingCaiYao:
        w[ExpeditionNodeType.caiYao] = 25;
      case ExpeditionPolicy.xunJiFangYou:
        w[ExpeditionNodeType.yiJi] = 25;
      case ExpeditionPolicy.yiZhanLiXing:
        w[ExpeditionNodeType.zaoYu] = 25;
    }
    return w;
  }

  /// 生成指定节点（稳定：同 saveId/runSerial/node 结果一致）。
  static ExpeditionNode generateNode({
    required int saveId,
    required int runSerial,
    required int node,
    required ExpeditionPolicy policy,
    int normalMinutes = 90,
    int eliteMinutes = 180,
  }) {
    if (isEliteNode(node)) {
      return ExpeditionNode(
        index: node,
        type: ExpeditionNodeType.xianGuan,
        durationMinutes: eliteMinutes,
      );
    }
    final rng = DefaultRng(
      seed: ExpeditionSeed.forNode(
        saveId: saveId,
        runSerial: runSerial,
        node: node,
      ),
    );
    final weights = _normalWeights(policy);
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (final e in weights.entries) {
      if (roll < e.value) {
        return ExpeditionNode(
          index: node,
          type: e.key,
          durationMinutes: normalMinutes,
        );
      }
      roll -= e.value;
    }
    return ExpeditionNode(
      index: node,
      type: ExpeditionNodeType.caiYao,
      durationMinutes: normalMinutes,
    );
  }

  /// 瘴蚀层数（§4.5）：第 31 节点起每 5 节点 +1 层，恢复减益 5%/层封顶 100%。
  static int zhangshiLayers(int deepestCompletedNode) {
    if (deepestCompletedNode <= 30) return 0;
    return ((deepestCompletedNode - 30) / 5).floor();
  }

  /// 瘴蚀后的恢复乘子（1.0 → 0.0，§4.5）。
  static double recoveryMultiplier(int layers, {double perLayer = 0.05}) {
    final reduction = (layers * perLayer).clamp(0.0, 1.0);
    return 1.0 - reduction;
  }

  /// 固定里程碑：第 10/20/30… 节点各一张断魂帖（§4.4）。
  static bool isTicketMilestone(int node) => node > 0 && node % 10 == 0;

  /// 单节点奖励（§4.4/§6.1）。exp/材料 defId 与数量走 rewardKey；
  /// 第 30 节点后 exp 系数封顶（§4.5），深度 >30 不再随节点增长。
  /// saveId/runSerial 预留给未来按节点 seed 抖动奖励量（batch3 探针）。
  static List<RewardEntry> rewardsForNode({
    required ExpeditionNode node,
    required int saveId,
    required int runSerial,
    int baseExpPerBattle =
        170, // batch3 探针拍板中档;生产走 expeditions.yaml base_exp_per_battle
    int baseExpCapNode = 30,
  }) {
    final rewards = <RewardEntry>[];
    final capNode = node.index > baseExpCapNode ? baseExpCapNode : node.index;

    switch (node.type) {
      case ExpeditionNodeType.caiYao:
        rewards.add(
          RewardEntry()
            ..rewardKey = 'item_yaocao'
            ..quantity = 1,
        );
        rewards.add(
          RewardEntry()
            ..rewardKey = 'item_lingquanshui'
            ..quantity = 1,
        );
      case ExpeditionNodeType.feiYi:
        rewards.add(
          RewardEntry()
            ..rewardKey = 'item_silver'
            ..quantity = 50,
        );
      case ExpeditionNodeType.zaoYu:
      case ExpeditionNodeType.xianGuan:
        final mult = node.type == ExpeditionNodeType.xianGuan ? 3 : 1;
        rewards.add(
          RewardEntry()
            ..rewardKey = 'exp'
            ..quantity = baseExpPerBattle * mult * (capNode ~/ 5 + 1) ~/ 7,
        );
      case ExpeditionNodeType.yiJi:
        rewards.add(
          RewardEntry()
            ..rewardKey = 'item_silver'
            ..quantity = 30,
        );
    }
    if (isTicketMilestone(node.index)) {
      rewards.add(
        RewardEntry()
          ..rewardKey = 'item_duanhuntie'
          ..quantity = 1,
      );
    }
    return rewards;
  }
}
