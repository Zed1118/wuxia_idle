import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/boss_gauntlet_config.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../boss_gauntlet/application/gauntlet_providers.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';
import '../domain/gauntlet_location_detail.dart';

/// 为断魂庄地点详情核验三关与敌队引用，不在展示层猜测缺失配置。
List<GauntletLocationStageSummary> validatedGauntletLocationStages(
  BossGauntletConfig config,
) {
  if (config.stages.length != 3 || config.supplyCap <= 0) {
    throw StateError('Gauntlet location detail has invalid stage contract');
  }

  var eliteCount = 0;
  var bossCount = 0;
  final summaries = <GauntletLocationStageSummary>[];
  for (var index = 0; index < config.stages.length; index++) {
    final stage = config.stages[index];
    final isBoss = switch (stage.role) {
      'elite' => false,
      'boss' => true,
      _ => throw StateError(
        'Gauntlet location detail has invalid stage role: ${stage.role}',
      ),
    };
    if (isBoss) {
      bossCount += 1;
    } else {
      eliteCount += 1;
    }

    final enemies = config.enemiesForTeam(stage.enemyTeamId);
    if (stage.enemyTeamId.isEmpty || enemies.isEmpty) {
      throw StateError(
        'Gauntlet location detail has missing enemy team: '
        '${stage.enemyTeamId}',
      );
    }
    summaries.add(
      GauntletLocationStageSummary(
        ordinal: index + 1,
        isBoss: isBoss,
        enemies: List.unmodifiable([
          for (final enemy in enemies)
            GauntletLocationEnemySummary(
              name: enemy.name,
              school: enemy.school,
            ),
        ]),
      ),
    );
  }

  if (eliteCount != 2 || bossCount != 1) {
    throw StateError('Gauntlet location detail has invalid stage roles');
  }
  return List.unmodifiable(summaries);
}

final gauntletLocationDetailProvider = FutureProvider<GauntletLocationDetail>(
  (ref) async {
    final isar = ref.watch(isarProvider);
    if (isar == null) {
      throw StateError(
        'Gauntlet location detail unavailable: Isar not initialized',
      );
    }

    final save = await isar.saveDatas.get(0);
    if (save == null || !save.jianghuJourneyUnlocked) {
      throw StateError('Gauntlet location detail is not unlocked');
    }

    final config = ref.watch(gauntletConfigProvider);
    if (config == null) {
      throw StateError('Gauntlet location detail config unavailable');
    }
    final stages = validatedGauntletLocationStages(config);
    final recommendedRealm = config.stages
        .expand((stage) => config.enemiesForTeam(stage.enemyTeamId))
        .map((enemy) => enemy.realmTier)
        .reduce((a, b) => a.index >= b.index ? a : b);

    final repository = GameRepository.instance;
    final rewardSkill = repository.getSkill(config.firstClearRewardSkillId);
    final rewardEquipmentNames = [
      for (final defId in config.rewardCandidateEquipmentIds)
        repository.getEquipment(defId).name,
    ];
    if (config.firstClearRewardSkillId.isEmpty ||
        rewardEquipmentNames.length != 3 ||
        config.firstClearRewardExp < 0 ||
        config.firstClearRewardInsight < 0 ||
        config.eliteRewardExp < 0) {
      throw StateError('Gauntlet location detail has invalid reward contract');
    }

    final active = await ref.watch(activeGauntletProvider.future);
    final loadout = await ref.watch(gauntletLoadoutInfoProvider.future);
    final candidates = await ref.watch(gauntletCandidatesProvider.future);
    if (loadout.ticketCount < 0 || loadout.clearedCyclesMax < 0) {
      throw StateError('Gauntlet location detail has invalid progress');
    }

    final activeParticipantNames = <String>[];
    if (active != null) {
      if (active.currentStage < 1 ||
          active.currentStage > stages.length ||
          active.sessionPhase == GauntletPhase.settled ||
          active.members.isEmpty) {
        throw StateError('Gauntlet location detail has invalid active run');
      }
      final seen = <int>{};
      for (final member in active.members) {
        if (member.characterId <= 0 || !seen.add(member.characterId)) {
          throw StateError(
            'Gauntlet location detail has invalid active participant',
          );
        }
        final character = await isar.characters.get(member.characterId);
        if (character == null) {
          throw StateError(
            'Gauntlet location detail participant disappeared: '
            '${member.characterId}',
          );
        }
        activeParticipantNames.add(character.name);
      }
    }

    return GauntletLocationDetail(
      clearedCyclesMax: loadout.clearedCyclesMax,
      totalStages: stages.length,
      activeStage: active?.currentStage,
      activePhase: active?.sessionPhase,
      recommendedRealm: recommendedRealm,
      stages: stages,
      rewardSkillName: rewardSkill.name,
      rewardEquipmentNames: List.unmodifiable(rewardEquipmentNames),
      firstClearRewardExp: config.firstClearRewardExp,
      firstClearRewardInsight: config.firstClearRewardInsight,
      eliteRewardExp: config.eliteRewardExp,
      ticketCount: loadout.ticketCount,
      supplyCap: config.supplyCap,
      candidateCount: candidates.length,
      availableCandidateCount: candidates
          .where((item) => item.selectable)
          .length,
      activeParticipantNames: List.unmodifiable(activeParticipantNames),
    );
  },
  dependencies: [
    isarProvider,
    gauntletConfigProvider,
    activeGauntletProvider,
    gauntletLoadoutInfoProvider,
    gauntletCandidatesProvider,
  ],
);
