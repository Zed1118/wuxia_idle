import '../../../shared/utils/rng.dart';
import 'expedition_node.dart';
import 'expedition_run.dart' show ExpeditionPolicy;
import 'expedition_seed.dart';

/// 百草岭节点/瘴蚀/权重纯规则（§4.2-§4.5）。无 Isar、无副作用。
class ExpeditionRules {
  const ExpeditionRules._();

  /// 每 5 的倍数节点为险关（§4.2）。
  static bool isEliteNode(int node) => node > 0 && node % 5 == 0;

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
          durationMinutes: eliteMinutes);
    }
    final rng = DefaultRng(
        seed: ExpeditionSeed.forNode(
            saveId: saveId, runSerial: runSerial, node: node));
    final weights = _normalWeights(policy);
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (final e in weights.entries) {
      if (roll < e.value) {
        return ExpeditionNode(
            index: node, type: e.key, durationMinutes: normalMinutes);
      }
      roll -= e.value;
    }
    return ExpeditionNode(
        index: node,
        type: ExpeditionNodeType.caiYao,
        durationMinutes: normalMinutes);
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
}
