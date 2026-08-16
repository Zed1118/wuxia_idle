import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';

/// 敌方 AI 适配器:从同一只读 state 产生与玩家同型的 intent,
/// 供同一 reducer 结算(在线=离线:手动与无头共用同一模拟核)。
///
/// 策略最小口径:射程外朝玩家移动,射程内普攻;目标选择与命中判定
/// 全部在 reducer 内完成,本层不复制任何结算规则。
final class Phase0aEnemyAiAdapter {
  const Phase0aEnemyAiAdapter({
    required this.attackRange,
    required this.attackHalfArcRadians,
    required this.attackCooldownSeconds,
  });

  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;

  List<Phase0aIntent> intentsFor({required Phase0aArenaState state}) {
    final player = state.player;
    if (!player.isAlive) return const [];
    final intents = <Phase0aIntent>[];
    final enemies = List<Phase0aActor>.of(state.enemies)
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;
      final delta = player.position - enemy.position;
      if (delta.lengthSquared > attackRange * attackRange) {
        intents.add(
          Phase0aMoveIntent(
            actorId: enemy.id,
            direction: delta.normalized(),
          ),
        );
        continue;
      }
      intents.add(
        Phase0aAttackIntent(
          actorId: enemy.id,
          range: attackRange,
          halfArcRadians: attackHalfArcRadians,
          cooldownSeconds: attackCooldownSeconds,
          moveKind: Phase0aMoveKind.light,
          aimDirection: delta.lengthSquared > 0
              ? delta.normalized()
              : ArenaVector.zero,
        ),
      );
    }
    return intents;
  }
}
