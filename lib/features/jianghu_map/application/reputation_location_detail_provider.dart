import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/faction_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../jianghu/domain/reputation.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/domain/onboarding_gate.dart';
import '../domain/reputation_location_detail.dart';

List<ReputationLocationTierSummary> validatedReputationLocationTiers(
  List<ReputationTierDef> source,
) {
  if (source.length != 7) {
    throw StateError('Reputation location detail requires seven tiers');
  }
  final tiers = source.toList(growable: false)
    ..sort((left, right) => left.min.compareTo(right.min));
  final ids = <String>{};
  for (var index = 0; index < tiers.length; index++) {
    final tier = tiers[index];
    if (tier.tier.isEmpty ||
        tier.label.isEmpty ||
        !ids.add(tier.tier) ||
        tier.min < -100 ||
        tier.max > 100 ||
        tier.min > tier.max ||
        (index == 0 && tier.min != -100) ||
        (index > 0 && tiers[index - 1].max + 1 != tier.min) ||
        (index == tiers.length - 1 && tier.max != 100)) {
      throw StateError('Reputation location detail has invalid tiers');
    }
  }
  return List.unmodifiable([
    for (final tier in tiers)
      ReputationLocationTierSummary(
        tier: tier.tier,
        label: tier.label,
        min: tier.min,
        max: tier.max,
      ),
  ]);
}

void _validateTriggers(JianghuTriggers triggers) {
  if (triggers.stageBossKillDelta <= 0 ||
      triggers.stageBossKillDelta > 100 ||
      triggers.stageBossKillRivalDelta <= 0 ||
      triggers.stageBossKillRivalDelta > 100 ||
      triggers.encounterNpcDeltaMin < -100 ||
      triggers.encounterNpcDeltaMax > 100 ||
      triggers.encounterNpcDeltaMin > triggers.encounterNpcDeltaMax) {
    throw StateError('Reputation location detail has invalid triggers');
  }
}

List<ReputationLocationFactionSummary> _validatedFactions({
  required Map<String, FactionDef> definitions,
  required List<Reputation> reputations,
  required List<ReputationLocationTierSummary> tiers,
  required String Function(int value) tierOf,
}) {
  if (definitions.isEmpty) {
    throw StateError('Reputation location detail has no factions');
  }
  const alignments = {'orthodox', 'neutral', 'evil'};
  final definitionIds = <String>{};
  for (final entry in definitions.entries) {
    final definition = entry.value;
    final npcIds = <String>{};
    if (entry.key.isEmpty ||
        definition.id != entry.key ||
        definition.name.isEmpty ||
        !alignments.contains(definition.alignment) ||
        !definitionIds.add(definition.id) ||
        definition.npcIds.any((id) => id.isEmpty || !npcIds.add(id))) {
      throw StateError('Reputation location detail has invalid faction');
    }
  }

  final byFaction = <String, Reputation>{};
  for (final reputation in reputations) {
    if (reputation.id <= 0 ||
        reputation.playerId != 1 ||
        !definitions.containsKey(reputation.factionId) ||
        reputation.value < -100 ||
        reputation.value > 100 ||
        byFaction.putIfAbsent(reputation.factionId, () => reputation) !=
            reputation) {
      throw StateError('Reputation location detail has invalid reputation');
    }
  }

  return List.unmodifiable([
    for (final definition in definitions.values)
      () {
        final reputation = byFaction[definition.id];
        if (reputation == null) {
          return ReputationLocationFactionSummary(
            id: definition.id,
            name: definition.name,
            alignment: definition.alignment,
            value: null,
            tier: null,
            tierLabel: null,
          );
        }
        final tierId = tierOf(reputation.value);
        final matching = tiers.where((tier) => tier.tier == tierId).toList();
        if (matching.length != 1 ||
            reputation.value < matching.single.min ||
            reputation.value > matching.single.max) {
          throw StateError(
            'Reputation location detail tier mapping is inconsistent',
          );
        }
        return ReputationLocationFactionSummary(
          id: definition.id,
          name: definition.name,
          alignment: definition.alignment,
          value: reputation.value,
          tier: tierId,
          tierLabel: matching.single.label,
        );
      }(),
  ]);
}

final reputationLocationDetailProvider =
    FutureProvider<ReputationLocationDetail>(
      (ref) async {
        final progress = await ref.watch(mainlineProgressProvider.future);
        if (!progress.clearedStageIds.contains(kFirstChapterFinalStageId)) {
          throw StateError('Reputation location detail is not unlocked');
        }

        final repository = GameRepository.instanceOrNull;
        final service = ref.watch(reputationServiceProvider);
        if (repository == null || service == null) {
          throw StateError('Reputation location detail is unavailable');
        }

        final numbers = ref.watch(numbersConfigProvider);
        final tiers = validatedReputationLocationTiers(
          numbers.jianghu.reputationTiers,
        );
        final triggers = numbers.jianghu.triggers;
        _validateTriggers(triggers);
        final reputations = await ref.watch(
          reputationsForCurrentPlayerProvider.future,
        );
        final factions = _validatedFactions(
          definitions: repository.factionDefs,
          reputations: reputations,
          tiers: tiers,
          tierOf: service.tierOf,
        );

        return ReputationLocationDetail(
          factions: factions,
          tiers: tiers,
          stageBossKillDelta: triggers.stageBossKillDelta,
          stageBossKillRivalDelta: triggers.stageBossKillRivalDelta,
          encounterNpcDeltaMin: triggers.encounterNpcDeltaMin,
          encounterNpcDeltaMax: triggers.encounterNpcDeltaMax,
        );
      },
      dependencies: [
        mainlineProgressProvider,
        numbersConfigProvider,
        reputationServiceProvider,
        reputationsForCurrentPlayerProvider,
      ],
    );
