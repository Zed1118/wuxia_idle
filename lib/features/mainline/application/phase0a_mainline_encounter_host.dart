import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/defs/combat_catalog_manifest_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/numbers_config.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/arena_vector.dart';
import 'phase0a_mainline_production_encounter_factory.dart';
import 'phase0a_mainline_repository_runtime_binding_adapter.dart';

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
    this.routeAuthority,
    this.catalogOverride,
  });

  final StageDef stage;
  final Phase0aPlayerRuntimeMapping playerMapping;
  final NumbersConfig numbers;
  final int cycleIndex;
  final Random rng;
  final Phase0aMainlineEncounterRuntimeBindingSource runtimeBindingSource;
  final Phase0aMainlineEncounterRouteAuthority? routeAuthority;
  final CombatCatalogManifestDef? catalogOverride;
}

enum Phase0aMainlineEncounterRouteMode { legacy, migrated }

typedef Phase0aMainlineEncounterRouteModeLoader =
    FutureOr<Phase0aMainlineEncounterRouteMode?> Function({
      required String stageId,
    });

final class Phase0aMainlineEncounterRouteAuthority {
  const Phase0aMainlineEncounterRouteAuthority({required this.loader});

  final Phase0aMainlineEncounterRouteModeLoader loader;

  Future<Phase0aMainlineEncounterRouteMode?> modeForStage({
    required String stageId,
  }) async => await loader(stageId: stageId);
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
    required int cycleIndex,
  });
}

typedef Phase0aMainlineEncounterRuntimeBindingLoader =
    FutureOr<Phase0aMainlineEncounterRuntimeBindingBundle> Function({
      required String stageId,
      required String encounterId,
      required int cycleIndex,
    });

final class Phase0aMainlineEncounterRuntimeBindingBundle {
  const Phase0aMainlineEncounterRuntimeBindingBundle({
    required this.stageId,
    required this.encounterId,
    required this.tickDuration,
    required this.actorBindingsByEntryId,
    this.defendedEntity,
  });

  final String stageId;
  final String encounterId;
  final Duration tickDuration;
  final Map<String, Phase0aEncounterActorRuntimeBinding> actorBindingsByEntryId;
  final Phase0aMainlineDefendedEntityRuntimeBinding? defendedEntity;
}

/// Typed non-persistent runtime closure for one defend_entity clause.
final class Phase0aMainlineDefendedEntityRuntimeBinding {
  const Phase0aMainlineDefendedEntityRuntimeBinding({
    required this.entityId,
    required this.position,
    required this.maxDurability,
    required this.damagePerHit,
    required this.requiredTicks,
    required this.attackerEntryIds,
  });

  final String entityId;
  final ArenaVector position;
  final int maxDurability;
  final int damagePerHit;
  final int requiredTicks;
  final Set<String> attackerEntryIds;
}

/// Adapter consumed by the live host and sweep. The Runtime Loader session
/// overrides the loader provider with its GameRepository typed-bundle reader;
/// application code does not parse YAML or duplicate the catalog.
final class Phase0aMainlineEncounterRuntimeBindingSourceAdapter
    implements Phase0aMainlineEncounterRuntimeBindingSource {
  const Phase0aMainlineEncounterRuntimeBindingSourceAdapter({
    required this.loader,
  });

  const Phase0aMainlineEncounterRuntimeBindingSourceAdapter.unconfigured()
    : loader = _unconfiguredRuntimeBindingLoader;

  final Phase0aMainlineEncounterRuntimeBindingLoader loader;

  @override
  Future<Phase0aMainlineEncounterRuntimeBindingBundle> load({
    required String stageId,
    required String encounterId,
    required int cycleIndex,
  }) async => await loader(
    stageId: stageId,
    encounterId: encounterId,
    cycleIndex: cycleIndex,
  );
}

Future<Phase0aMainlineEncounterRuntimeBindingBundle>
_unconfiguredRuntimeBindingLoader({
  required String stageId,
  required String encounterId,
  required int cycleIndex,
}) => Future<Phase0aMainlineEncounterRuntimeBindingBundle>.error(
  StateError(
    'migrated runtime bindings are not connected for $stageId/$encounterId',
  ),
);

final phase0aMainlineEncounterRuntimeBindingLoaderProvider =
    Provider<Phase0aMainlineEncounterRuntimeBindingLoader>(
      (ref) => loadPhase0aMainlineRuntimeBindingBundleFromRepository,
    );

final phase0aMainlineEncounterRuntimeBindingSourceProvider =
    Provider<Phase0aMainlineEncounterRuntimeBindingSource>(
      (ref) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader: ref.read(phase0aMainlineEncounterRuntimeBindingLoaderProvider),
      ),
    );

final phase0aMainlineEncounterRouteAuthorityProvider =
    Provider<Phase0aMainlineEncounterRouteAuthority>(
      (ref) => const Phase0aMainlineEncounterRouteAuthority(
        loader: _unknownRouteModeLoader,
      ),
    );

Future<Phase0aMainlineEncounterRouteMode?> _unknownRouteModeLoader({
  required String stageId,
}) async => null;

final phase0aMainlineEncounterHostFactoryProvider =
    Provider<Phase0aMainlineEncounterHostFactory>(
      (ref) =>
          (Phase0aMainlineEncounterHostBuildRequest request) =>
              createFreshPhase0aMainlineEncounter(request),
    );
