import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../battle/application/phase0a/phase0a_battle_flow.dart';
import '../../battle/application/phase0a/phase0a_encounter_flow.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'battle_frame_profile.dart';
import 'production_battle_frame_profile.dart';
import 'production_profile_keyboard_driver.dart';

abstract final class Phase0aProductionProfile {
  static Widget wrap({
    required Widget child,
    required String mode,
    required String contentId,
    required String runtimeKind,
    required Phase0aBattleController controller,
    Map<String, Object?> configuration = const {},
    Phase0aBattleFlow? flow,
  }) {
    if (kReleaseMode) return child;
    final config = BattleFrameProfileProbe.productionConfigFor(contentId);
    if (config == null) return child;
    final keyboardPolicy = config.keyboardPolicy;
    final keyboardStrategy = keyboardPolicy == null
        ? null
        : ProductionProfileKeyboardStrategy.values.byName(keyboardPolicy);
    final basicAttackRange = child is Phase0aBattleScreen
        ? child.basicAttackRange
        : null;
    if (keyboardStrategy != null && basicAttackRange == null) {
      throw StateError(
        'Keyboard profiling requires the production battle screen attack range.',
      );
    }
    return ProductionBattleFrameProfile(
      key: const ValueKey('production_battle_frame_profile'),
      owner: controller,
      isCombatOngoing: () => controller.outcome == Phase0aBattleOutcome.ongoing,
      config: config,
      keyboardDriverFactory: keyboardStrategy == null
          ? null
          : (isForeground) => ProductionProfileKeyboardDriver(
              controller: controller,
              basicAttackRange: basicAttackRange!,
              isForeground: isForeground,
              strategy: keyboardStrategy,
            ),
      scene: {
        'mode': mode,
        'content_id': contentId,
        'runtime_kind': runtimeKind,
        'legal_character': config.legalCharacter,
        if (keyboardStrategy != null)
          'keyboard_input': ProductionProfileKeyboardDriver.configurationFor(
            strategy: keyboardStrategy,
            fixedDeltaSeconds: controller.fixedDeltaSeconds,
          ),
        'configuration': Map<String, Object?>.unmodifiable(configuration),
      },
      readWorkload: () {
        final state = controller.state;
        final activeEnemyIds = state.enemies
            .where((enemy) => enemy.isAlive)
            .map((enemy) => enemy.id)
            .toList(growable: false);
        return {
          'tick': state.tick,
          'active_enemies': activeEnemyIds.length,
          'active_enemy_ids': activeEnemyIds,
          'resident_enemies': state.enemies.length,
          'combat_ongoing': controller.outcome == Phase0aBattleOutcome.ongoing,
          'outcome': controller.outcome.name,
          'event_count': controller.events.length,
          'last_tick_feedback_entries': controller.feedback.length,
          if (runtimeKind == 'typed_encounter' &&
              flow is Phase0aEncounterFlow) ...{
            'spawn_active': flow.spawnState.activeCount,
            'spawn_warning': flow.spawnState.warningCount,
            'spawn_pending': flow.spawnState.pendingCount,
            'spawn_removed': flow.spawnState.removedCount,
            'spawn_total': flow.spawnState.totalCount,
          },
        };
      },
      child: child,
    );
  }
}
