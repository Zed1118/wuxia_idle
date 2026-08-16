import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/realtime_combat_rules.dart';

/// 玩家一拍输入快照:四向按键 + 动作请求(语义按键,非数值)。
final class Phase0aPlayerCommand {
  const Phase0aPlayerCommand({
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.attack = false,
    this.gather = false,
    this.clear = false,
  });

  final bool left;
  final bool right;
  final bool up;
  final bool down;

  /// 普攻请求。
  final bool attack;

  /// Q 聚怪请求。
  final bool gather;

  /// R 清场请求。
  final bool clear;
}

/// 玩家输入适配器:按键/动作请求 → 统一 intent。
///
/// 移动经 [normalizeMovementInput] 归一(对角单位长度);普攻瞄准方向取
/// 玩家当前朝向;全部调优数值(范围/角度/环半径/真气/CD)由构造方显式注入,
/// 本层不复制任何结算规则。
final class Phase0aPlayerInputAdapter {
  const Phase0aPlayerInputAdapter({
    required this.playerId,
    required this.attackRange,
    required this.attackHalfArcRadians,
    required this.attackCooldownSeconds,
    required this.gatherSlot,
    required this.gatherRingRadius,
    required this.gatherQiCost,
    required this.gatherCooldownSeconds,
    required this.clearSlot,
    required this.clearQiCost,
    required this.clearCooldownSeconds,
  });

  final String playerId;
  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;
  final String gatherSlot;
  final double gatherRingRadius;
  final int gatherQiCost;
  final double gatherCooldownSeconds;
  final String clearSlot;
  final int clearQiCost;
  final double clearCooldownSeconds;

  List<Phase0aIntent> intentsFor({
    required Phase0aArenaState state,
    required Phase0aPlayerCommand command,
  }) {
    final intents = <Phase0aIntent>[];
    final direction = normalizeMovementInput(
      left: command.left,
      right: command.right,
      up: command.up,
      down: command.down,
    );
    if (direction.lengthSquared > 0) {
      intents.add(
        Phase0aMoveIntent(actorId: playerId, direction: direction),
      );
    }
    if (command.attack) {
      intents.add(
        Phase0aAttackIntent(
          actorId: playerId,
          range: attackRange,
          halfArcRadians: attackHalfArcRadians,
          cooldownSeconds: attackCooldownSeconds,
          moveKind: Phase0aMoveKind.light,
          aimDirection: state.player.facing,
        ),
      );
    }
    if (command.gather) {
      intents.add(
        Phase0aGatherIntent(
          actorId: playerId,
          slot: gatherSlot,
          ringRadius: gatherRingRadius,
          qiCost: gatherQiCost,
          cooldownSeconds: gatherCooldownSeconds,
        ),
      );
    }
    if (command.clear) {
      intents.add(
        Phase0aClearIntent(
          actorId: playerId,
          slot: clearSlot,
          qiCost: clearQiCost,
          cooldownSeconds: clearCooldownSeconds,
        ),
      );
    }
    return intents;
  }
}
