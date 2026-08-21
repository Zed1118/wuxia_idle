import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'phase0a_profile_harness.dart';

/// Ch1 compatibility aliases. New production-content diagnostics should use
/// the generic profile harness directly.
typedef Phase0aCh1RunObservation = Phase0aProfileRunObservation;
typedef Phase0aCh1ProfileAggregate = Phase0aProfileAggregate;

Phase0aCh1RunObservation runPhase0aCh1Profile({
  required String profileId,
  required StageDef stage,
  required CombatantSnapshot playerSnapshot,
  required NumbersConfig numbers,
  required int seed,
  required double deltaSeconds,
  required int maxTicks,
}) {
  final mapping = Phase0aStageContentMapper.map(
    stage: stage,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
  );
  return runPhase0aProfile(
    profileId: profileId,
    contentId: stage.id,
    mapping: mapping,
    numbers: numbers,
    playerSnapshot: playerSnapshot,
    seed: seed,
    deltaSeconds: deltaSeconds,
    maxTicks: maxTicks,
  );
}
