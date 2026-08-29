import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';

/// Drives the real combat path toward a deterministic victory terminal state.
///
/// Presentation tests use the terminal state to verify retry, focus, and audio
/// contracts; they must not depend on a stationary basic attack remaining a
/// balance-proof victory strategy.
Phase0aPlayerCommand phase0aVictoryTerminalCommand(
  Phase0aBattleController controller,
) {
  final player = controller.state.player.position;
  final enemies = controller.state.enemies;
  final target = enemies.isEmpty ? null : enemies.first;
  final dx = target == null ? 0.0 : target.position.x - player.x;
  final dy = target == null ? 0.0 : target.position.y - player.y;
  return Phase0aPlayerCommand(
    attack: true,
    clear: true,
    right: dx > 1,
    left: dx < -1,
    down: dy > 1,
    up: dy < -1,
  );
}
