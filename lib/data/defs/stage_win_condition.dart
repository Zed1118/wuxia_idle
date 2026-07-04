/// 关卡胜负条件（终局机制型 Boss 批次3）。
///
/// - [StageWinConditionType.defeatAll]（默认）：击败全部敌人即胜（现状语义）。
/// - [StageWinConditionType.surviveTicks]：撑满 [surviveTicksRequired] tick 且我方
///   存活即胜；**且**击败全部敌人也算胜（两通道任一，由 strategy 逐 tick 判定）。
///
/// 挂在 [StageDef.winCondition]（yaml 可选，缺省 null = defeatAll 旧行为），
/// 透传进 [BattleState.winCondition] 供 strategy 消费。
enum StageWinConditionType { defeatAll, surviveTicks }

class StageWinCondition {
  final StageWinConditionType type;

  /// 仅 [StageWinConditionType.surviveTicks] 有效：需撑过的 tick 数（>0）。
  final int? surviveTicksRequired;

  const StageWinCondition({
    required this.type,
    this.surviveTicksRequired,
  });

  factory StageWinCondition.fromYaml(Map<String, dynamic> y) {
    final typeStr = y['type'] as String?;
    if (typeStr == null) {
      throw StateError('winCondition 缺 type');
    }
    final type = StageWinConditionType.values.byName(typeStr);
    if (type == StageWinConditionType.surviveTicks) {
      final ticks = (y['ticks'] as num?)?.toInt();
      if (ticks == null || ticks <= 0) {
        throw StateError('winCondition surviveTicks 须配 ticks>0（实为 $ticks）');
      }
      return StageWinCondition(
        type: type,
        surviveTicksRequired: ticks,
      );
    }
    return StageWinCondition(type: type);
  }

  @override
  String toString() =>
      'StageWinCondition(${type.name}'
      '${surviveTicksRequired != null ? ', ticks=$surviveTicksRequired' : ''})';
}
