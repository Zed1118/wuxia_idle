import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart' show Phase0aBattleOutcome;
import 'phase0a_battle_flow.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_wave_battle_flow.dart';

/// Compatibility seam for the future encounter flow.
///
/// This wrapper deliberately delegates to the legacy wave flow. It does not
/// create another session/reducer, consume encounter directors, or infer any
/// production policy.
final class Phase0aEncounterFlow implements Phase0aBattleFlow {
  Phase0aEncounterFlow.compatibility({required Phase0aWaveBattleFlow legacy})
    : _legacy = legacy;

  final Phase0aWaveBattleFlow _legacy;

  @override
  Phase0aArenaState get state => _legacy.state;

  @override
  Phase0aBattleOutcome get outcome => _legacy.outcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      _legacy.lastOrderedEventRecords;

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) => _legacy.advance(deltaSeconds: deltaSeconds, command: command);
}
