import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/expedition_config.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/cycle_realm_gate.dart';
import '../../expedition/application/expedition_providers.dart';
import '../../expedition/domain/expedition_node.dart';
import '../../expedition/domain/expedition_rules.dart';
import '../domain/expedition_location_detail.dart';

List<ExpeditionLocationEnemyTeamSummary> validatedExpeditionLocationEnemyTeams(
  ExpeditionConfig config, {
  required bool elite,
}) {
  if (config.normalNodeMinutes <= 0 ||
      config.eliteNodeMinutes <= 0 ||
      config.baseExpPerBattle <= 0 ||
      config.hpRecoverPctPerNode < 0 ||
      config.hpRecoverPctPerNode > 1 ||
      config.qiRecoverPctPerNode < 0 ||
      config.qiRecoverPctPerNode > 1 ||
      config.zhangshiPctPerLayer < 0 ||
      config.zhangshiPctPerLayer > 1 ||
      config.depthCurve == null ||
      config.normalEnemyTeams.isEmpty ||
      config.eliteEnemyTeams.isEmpty) {
    throw StateError('Expedition location detail has invalid config');
  }

  final allTeamIds = <String>{};
  for (final team in [...config.normalEnemyTeams, ...config.eliteEnemyTeams]) {
    if (team.id.isEmpty || !allTeamIds.add(team.id) || team.enemies.isEmpty) {
      throw StateError('Expedition location detail has invalid enemy team');
    }
    for (final enemy in team.enemies) {
      if (enemy.id.isEmpty ||
          enemy.name.isEmpty ||
          enemy.baseHp <= 0 ||
          enemy.baseAttack < 0 ||
          enemy.baseSpeed <= 0) {
        throw StateError('Expedition location detail has invalid enemy');
      }
    }
  }

  final teams = elite ? config.eliteEnemyTeams : config.normalEnemyTeams;
  return List.unmodifiable([
    for (final team in teams)
      ExpeditionLocationEnemyTeamSummary(
        id: team.id,
        enemies: List.unmodifiable([
          for (final enemy in team.enemies)
            ExpeditionLocationEnemySummary(
              name: enemy.name,
              realmTier: enemy.realmTier,
              school: enemy.school,
            ),
        ]),
      ),
  ]);
}

({List<String> itemNames, bool includesExperience})
validatedExpeditionLocationRewards(
  ExpeditionConfig config,
  GameRepository repository,
) {
  final rewardKeys = <String>{};
  for (final type in ExpeditionNodeType.values) {
    final node = ExpeditionNode(
      index: type == ExpeditionNodeType.xianGuan ? 10 : 1,
      type: type,
      durationMinutes: type == ExpeditionNodeType.xianGuan
          ? config.eliteNodeMinutes
          : config.normalNodeMinutes,
    );
    for (final reward in ExpeditionRules.rewardsForNode(
      node: node,
      saveId: 0,
      runSerial: 0,
      baseExpPerBattle: config.baseExpPerBattle,
    )) {
      if (reward.rewardKey.isEmpty || reward.quantity <= 0) {
        throw StateError('Expedition location detail has invalid reward');
      }
      rewardKeys.add(reward.rewardKey);
    }
  }

  final includesExperience = rewardKeys.remove('exp');
  if (!includesExperience || rewardKeys.isEmpty) {
    throw StateError('Expedition location detail has incomplete rewards');
  }
  final itemNames = <String>[];
  for (final key in rewardKeys) {
    final item = repository.itemDefs[key];
    if (item == null || item.name.isEmpty) {
      throw StateError(
        'Expedition location detail reward definition missing: $key',
      );
    }
    itemNames.add(item.name);
  }
  return (
    itemNames: List.unmodifiable(itemNames),
    includesExperience: includesExperience,
  );
}

final expeditionLocationDetailProvider =
    FutureProvider<ExpeditionLocationDetail>(
      (ref) async {
        final isar = ref.watch(isarProvider);
        if (isar == null) {
          throw StateError(
            'Expedition location detail unavailable: Isar not initialized',
          );
        }

        final save = await isar.saveDatas.get(0);
        if (save == null || !save.jianghuJourneyUnlocked) {
          throw StateError('Expedition location detail is not unlocked');
        }
        if (save.baicaoMaxDepth < 0) {
          throw StateError('Expedition location detail has invalid progress');
        }

        final config = ref.watch(expeditionConfigProvider);
        if (config == null) {
          throw StateError('Expedition location detail config unavailable');
        }
        final normalTeams = validatedExpeditionLocationEnemyTeams(
          config,
          elite: false,
        );
        final eliteTeams = validatedExpeditionLocationEnemyTeams(
          config,
          elite: true,
        );
        final allEnemies = <EnemyDef>[
          for (final team in config.normalEnemyTeams) ...team.enemies,
          for (final team in config.eliteEnemyTeams) ...team.enemies,
        ];
        final recommendedRealm = CycleRealmGate.maxEnemyTierOf(allEnemies);
        final rewards = validatedExpeditionLocationRewards(
          config,
          GameRepository.instance,
        );

        final historicalMaxDepth = await ref.watch(
          expeditionMaxDepthProvider.future,
        );
        if (historicalMaxDepth < 0 ||
            historicalMaxDepth != save.baicaoMaxDepth) {
          throw StateError(
            'Expedition location detail progress is inconsistent',
          );
        }

        final active = await ref.watch(activeExpeditionProvider.future);
        final candidates = await ref.watch(expeditionCandidatesProvider.future);
        final candidateIds = <int>{};
        for (final candidate in candidates) {
          if (candidate.character.id <= 0 ||
              candidate.character.name.isEmpty ||
              !candidateIds.add(candidate.character.id)) {
            throw StateError(
              'Expedition location detail has invalid candidate',
            );
          }
        }

        final activeParticipantNames = <String>[];
        int? activeCycleIndex;
        if (active != null) {
          if (active.saveDataId != save.id ||
              active.currentNode < 0 ||
              active.cycleIndex < 0 ||
              active.members.length != 1) {
            throw StateError(
              'Expedition location detail has invalid active run',
            );
          }
          final member = active.members.single;
          if (member.characterId <= 0) {
            throw StateError(
              'Expedition location detail has invalid active participant',
            );
          }
          final character = await isar.characters.get(member.characterId);
          if (character == null || character.name.isEmpty) {
            throw StateError(
              'Expedition location detail participant disappeared: '
              '${member.characterId}',
            );
          }
          activeParticipantNames.add(character.name);
          activeCycleIndex = active.cycleIndex == 0 ? 1 : active.cycleIndex;
        }

        return ExpeditionLocationDetail(
          historicalMaxDepth: historicalMaxDepth,
          activeDepth: active?.currentNode,
          activePolicy: active?.policy,
          activeCycleIndex: activeCycleIndex,
          activeDefeated: active?.defeated ?? false,
          recommendedRealm: recommendedRealm,
          normalNodeMinutes: config.normalNodeMinutes,
          eliteNodeMinutes: config.eliteNodeMinutes,
          normalEnemyTeams: normalTeams,
          eliteEnemyTeams: eliteTeams,
          coreRewardItemNames: rewards.itemNames,
          includesExperienceReward: rewards.includesExperience,
          candidateCount: candidates.length,
          availableCandidateCount: candidates
              .where((candidate) => candidate.dispatchable)
              .length,
          activeParticipantNames: List.unmodifiable(activeParticipantNames),
        );
      },
      dependencies: [
        isarProvider,
        expeditionConfigProvider,
        expeditionMaxDepthProvider,
        activeExpeditionProvider,
        expeditionCandidatesProvider,
      ],
    );
