import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_presentation_tokens.dart';

/// Drives the debug Boss acceptance route through the real reducer.
///
/// The first real clear action demonstrates that a single R only contributes
/// posture. Basic attacks then finish the same posture bar, and the driver
/// freezes as soon as the Boss enters the unified vulnerability state.
final class Phase0aBossMechanicsRouteDriver {
  Phase0aBossMechanicsRouteDriver({required this.fixedDeltaSeconds}) {
    if (!(fixedDeltaSeconds.isFinite && fixedDeltaSeconds > 0)) {
      throw ArgumentError.value(
        fixedDeltaSeconds,
        'fixedDeltaSeconds',
        'must be finite and positive',
      );
    }
  }

  final double fixedDeltaSeconds;

  int _guardedHoldTicks = 0;
  int _chargeHoldTicks = 0;
  bool _clearSent = false;
  bool _completed = false;

  bool get completed => _completed;

  void advance(Phase0aBattleController controller) {
    if (_completed) return;
    if (controller.outcome != Phase0aBattleOutcome.ongoing ||
        controller.state.enemies.isEmpty) {
      _completed = true;
      return;
    }

    final boss = controller.state.enemies.first;
    if (boss.posture?.isVulnerable ?? false) {
      _completed = true;
      return;
    }

    if (!_clearSent) {
      if (controller.events.isEmpty) {
        final requiredGuardedTicks =
            (Phase0aPresentationTokens.bossFixtureGuardedHoldSeconds /
                    fixedDeltaSeconds)
                .ceil();
        if (_guardedHoldTicks++ < requiredGuardedTicks) return;
      }

      if (boss.chargingCast == null) {
        controller.step();
        return;
      }

      final requiredChargeHoldTicks =
          (Phase0aPresentationTokens.bossFixtureChargeHoldSeconds /
                  fixedDeltaSeconds)
              .ceil();
      if (_chargeHoldTicks++ < requiredChargeHoldTicks) return;

      _clearSent = true;
      controller.step(const Phase0aPlayerCommand(clear: true));
    } else {
      controller.step(const Phase0aPlayerCommand(attack: true));
    }

    if (controller.outcome != Phase0aBattleOutcome.ongoing ||
        controller.state.enemies.isEmpty ||
        (controller.state.enemies.first.posture?.isVulnerable ?? false)) {
      _completed = true;
    }
  }
}
