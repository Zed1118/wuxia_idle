import '../../domain/phase0a/objective_controller.dart';
import 'phase0a_attack_token_lease_batch_receipt.dart';

final class Phase0aEncounterRuntimeObservation {
  const Phase0aEncounterRuntimeObservation({
    required this.objectiveProgress,
    required this.lastAttackTokenLeaseBatchReceipt,
  });

  final ObjectiveControllerProgress? objectiveProgress;
  final Phase0aAttackTokenLeaseBatchReceipt? lastAttackTokenLeaseBatchReceipt;
}

abstract interface class Phase0aEncounterRuntimeObservationSource {
  Phase0aEncounterRuntimeObservation get runtimeObservation;
}
