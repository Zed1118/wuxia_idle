import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'phase0a_mainline_production_encounter_factory.dart';

/// Request passed from the mainline presentation host to the production data
/// session. The session decides whether a migrated assignment exists; there is
/// no stage-ID switch in the battle host.
final class Phase0aMainlineEncounterHostBuildRequest {
  const Phase0aMainlineEncounterHostBuildRequest({
    required this.stage,
    required this.playerMapping,
    required this.numbers,
    required this.cycleIndex,
    required this.rng,
    required this.runtimeBindingSource,
  });

  final StageDef stage;
  final Phase0aPlayerRuntimeMapping playerMapping;
  final NumbersConfig numbers;
  final int cycleIndex;
  final Random rng;
  final Phase0aMainlineEncounterRuntimeBindingSource runtimeBindingSource;
}

/// Production binding seam for migrated mainline encounters.
///
/// Return null only for an explicit legacy assignment. A runtime loader must
/// provide the typed bundle for every migrated assignment; missing migrated
/// data is a setup error and never a legacy fallback.
typedef Phase0aMainlineEncounterHostFactory =
    FutureOr<Phase0aEncounterHost?> Function(
      Phase0aMainlineEncounterHostBuildRequest request,
    );

abstract interface class Phase0aMainlineEncounterRuntimeBindingSource {
  Future<Phase0aMainlineEncounterRuntimeBindingBundle> load({
    required String stageId,
    required String encounterId,
  });
}

final class Phase0aMainlineEncounterRuntimeBindingBundle {
  const Phase0aMainlineEncounterRuntimeBindingBundle({
    required this.stageId,
    required this.encounterId,
    required this.tickDuration,
    required this.actorBindingsByEntryId,
  });

  final String stageId;
  final String encounterId;
  final Duration tickDuration;
  final Map<String, Phase0aEncounterActorRuntimeBinding> actorBindingsByEntryId;
}

final class MissingPhase0aMainlineEncounterRuntimeBindingSource
    implements Phase0aMainlineEncounterRuntimeBindingSource {
  const MissingPhase0aMainlineEncounterRuntimeBindingSource();

  @override
  Future<Phase0aMainlineEncounterRuntimeBindingBundle> load({
    required String stageId,
    required String encounterId,
  }) => Future<Phase0aMainlineEncounterRuntimeBindingBundle>.error(
    StateError('migrated encounter runtime bindings are not installed'),
  );
}

final phase0aMainlineEncounterRuntimeBindingSourceProvider =
    Provider<Phase0aMainlineEncounterRuntimeBindingSource>(
      (ref) => const MissingPhase0aMainlineEncounterRuntimeBindingSource(),
    );

final phase0aMainlineEncounterHostFactoryProvider =
    Provider<Phase0aMainlineEncounterHostFactory>(
      (ref) =>
          (Phase0aMainlineEncounterHostBuildRequest request) =>
              createFreshPhase0aMainlineEncounter(request),
    );
