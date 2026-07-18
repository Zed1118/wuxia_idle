/// 节点类型（§4.4）。险关是遭遇型的精英变体。
enum ExpeditionNodeType { caiYao, feiYi, zaoYu, yiJi, xianGuan }

/// 单个已生成节点（纯值对象；奖励在结算时按类型算，不预存）。
class ExpeditionNode {
  const ExpeditionNode({
    required this.index,
    required this.type,
    required this.durationMinutes,
  });

  final int index;
  final ExpeditionNodeType type;
  final int durationMinutes;

  bool get isBattle =>
      type == ExpeditionNodeType.zaoYu || type == ExpeditionNodeType.xianGuan;
}
