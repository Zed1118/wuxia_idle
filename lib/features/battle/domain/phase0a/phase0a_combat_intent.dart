import 'arena_vector.dart';
import 'phase0a_combat_model.dart';

/// Phase 0A 统一输入协议:玩家适配器与敌 AI 适配器产生同型 intent,
/// 经同一 reducer 结算,不存在两套结算入口。
///
/// 全部调优数值(范围/角度/环半径/真气消耗/CD)由 intent 显式携带,
/// reducer 不提供默认值。
sealed class Phase0aIntent {
  const Phase0aIntent({required this.actorId});

  /// 出手者语义 id;reducer 按 id 稳定排序处理。
  final String actorId;
}

/// 移动请求:[direction] 为零向量时不改变位置与朝向。
final class Phase0aMoveIntent extends Phase0aIntent {
  const Phase0aMoveIntent({required super.actorId, required this.direction});

  final ArenaVector direction;
}

/// 普攻请求:距离 + 朝向扇区双条件由 reducer 用显式参数判定;
/// [aimDirection] 为出手者本拍瞄准方向(扇区中轴)。
final class Phase0aAttackIntent extends Phase0aIntent {
  const Phase0aAttackIntent({
    required super.actorId,
    required this.range,
    required this.halfArcRadians,
    required this.cooldownSeconds,
    required this.moveKind,
    required this.aimDirection,
  });

  final double range;
  final double halfArcRadians;
  final double cooldownSeconds;
  final Phase0aMoveKind moveKind;
  final ArenaVector aimDirection;
}

/// Q 聚怪请求:环内目标不推、环外投影到环上,逐目标结算 outcomes。
final class Phase0aGatherIntent extends Phase0aIntent {
  const Phase0aGatherIntent({
    required super.actorId,
    required this.slot,
    required this.ringRadius,
    required this.qiCost,
    required this.cooldownSeconds,
  });

  final String slot;
  final double ringRadius;
  final int qiCost;
  final double cooldownSeconds;
}

/// R 清场请求:对全体存活敌方单位结算,逐目标稳定顺序 outcomes。
final class Phase0aClearIntent extends Phase0aIntent {
  const Phase0aClearIntent({
    required super.actorId,
    required this.slot,
    required this.qiCost,
    required this.cooldownSeconds,
  });

  final String slot;
  final int qiCost;
  final double cooldownSeconds;
}
