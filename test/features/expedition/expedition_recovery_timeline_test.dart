import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_timeline.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';
import 'package:wuxia_idle/features/injury/application/character_recovery_service.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// Deterministic terminal seam isolates recovery chronology from combat balance.
/// The service still applies the genuine shared combat ledger after each node.
class _RecoveryCombat implements ExpeditionCombat {
  _RecoveryCombat(this.isar, this.startedAt);
  final Isar isar;
  final DateTime startedAt;
  final observations = <({double injury, double disorder, Duration elapsed})>[];
  var battles = 0;

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async {
    final character = (await isar.characters.get(ids.single))!;
    observations.add((
      injury: character.injuryHoursRemaining,
      disorder: character.innerBreathDisorderHoursRemaining,
      elapsed: character.recoverySettledAt!.difference(startedAt),
    ));
    return {ids.single: const ExpeditionMemberCaps(maxHp: 100, maxQi: 100)};
  }

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    battles++;
    final id = memberStates.keys.single;
    return ExpeditionNodeOutcome(
      leftWin: true,
      survivorHp: {id: 100},
      survivorQi: {id: 100},
      combatSettlement: CombatSettlementSnapshot(
        result: BattleResult.leftWin,
        totalTicks: 1,
        hadActions: true,
        playerCharacterId: id,
        participants: [
          CombatParticipantSnapshot(
            characterId: id,
            currentHp: 100,
            maxHp: 100,
          ),
        ],
        skillCasts: const [],
        totalDamage: 1,
        criticalCount: 0,
        damageByCharacterId: {id: 1},
      ),
    );
  }
}

void main() {
  late Directory directory;
  late Isar isar;
  late DateTime startedAt;
  late ExpeditionService service;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'expedition_recovery_clock_',
    );
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    await Phase2SeedService(isar: isar).seedP3();
    service = ExpeditionService(isar);
    startedAt = DateTime.now().toUtc();
    await isar.writeTxn(() async {
      final character = (await isar.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..currentRetreatSessionId = null
        ..recoverySettledAt = startedAt
        ..injuryHoursRemaining = 12
        ..innerBreathDisorderHoursRemaining = 12
        ..lightInjuryStacks = 2;
      await isar.characters.put(character);
    });
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  for (final segmented in [false, true]) {
    test(
      'node recovery uses nodeAt before combat, segmented=$segmented',
      () async {
        final config = GameRepository.instance.expeditionConfig!;
        await service.dispatch(
          characterIds: [1],
          policy: ExpeditionPolicy.yiZhanLiXing,
          now: startedAt,
        );
        final combat = _RecoveryCombat(isar, startedAt);
        final minutes = config.normalNodeMinutes;
        final end = startedAt.add(Duration(minutes: 4 * minutes));
        if (segmented) {
          for (var node = 1; node <= 4; node++) {
            await service.settle(
              combat: combat,
              config: config,
              now: startedAt.add(Duration(minutes: node * minutes)),
            );
          }
        } else {
          await service.settle(combat: combat, config: config, now: end);
        }
        expect(combat.observations, hasLength(4));
        expect(combat.battles, greaterThan(0));
        var previousBattles = 0;
        final run = (await service.activeRun())!;
        final battleRecovery = GameRepository
            .instance
            .numbers
            .innerBreathDisorder
            .battleRecoveryHours;
        for (var i = 0; i < 4; i++) {
          final hours = (i + 1) * minutes / 60;
          final observed = combat.observations[i];
          expect(observed.elapsed, Duration(minutes: (i + 1) * minutes));
          expect(observed.injury, closeTo(12 - hours, 1e-9));
          expect(
            observed.disorder,
            closeTo(12 - hours - previousBattles * battleRecovery, 1e-9),
          );
          final node = ExpeditionRules.generateNode(
            saveId: run.saveDataId,
            runSerial: run.seed,
            node: i + 1,
            policy: run.policy,
            normalMinutes: config.normalNodeMinutes,
            eliteMinutes: config.eliteNodeMinutes,
          );
          if (node.isBattle) previousBattles++;
        }
        final character = (await isar.characters.get(1))!;
        expect(
          character.innerBreathDisorderHoursRemaining,
          closeTo(
            12 - 4 * minutes / 60 - combat.battles * battleRecovery,
            1e-9,
          ),
        );
        expect(character.lightInjuryStacks, 2);
        expect(character.recoverySettledAt!.toUtc(), end);
        final once = await isar.characters.where().exportJson();
        await service.settle(combat: combat, config: config, now: end);
        await service.settle(combat: combat, config: config, now: startedAt);
        expect(await isar.characters.where().exportJson(), once);
      },
    );
  }

  test(
    'dispatch rollback respects a recovery clock ahead of passive time',
    () async {
      final recoveredAt = startedAt.add(const Duration(hours: 13));
      await isar.writeTxn(() async {
        final character = (await isar.characters.get(1))!..isFounder = true;
        await isar.characters.put(character);
        final save = (await isar.saveDatas.get(0))!
          ..founderCharacterId = 1
          ..activeCharacterIds = [1]
          ..passiveLastSettledAt = startedAt;
        await isar.saveDatas.put(save);
        // A character-only natural recovery boundary need not advance the
        // resource ledger, as with a targeted recovery action outside a run.
        await CharacterRecoveryService.settleWithinTxn(
          isar: isar,
          now: recoveredAt,
          characterIds: [1],
        );
      });
      expect((await isar.characters.get(1))!.injuryHoursRemaining, 0);
      expect(
        (await isar.saveDatas.get(0))!.passiveLastSettledAt!.toUtc(),
        startedAt,
      );

      final runId = await service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: 1),
        policy: ExpeditionPolicy.yiZhanLiXing,
        now: startedAt.add(const Duration(hours: 1)),
      );
      final run = (await isar.expeditionRuns.get(runId))!;
      expect(run.departedAt.toUtc(), recoveredAt);
      final config = GameRepository.instance.expeditionConfig!;
      final nodeAt = recoveredAt.add(
        Duration(minutes: config.normalNodeMinutes),
      );
      final result = await service.settle(
        combat: _RecoveryCombat(isar, recoveredAt),
        config: config,
        now: nodeAt,
      );
      expect(result.nodesSettled, 1);
      expect(result.currentNode, 1);
      expect(
        (await isar.characters.get(1))!.recoverySettledAt!.toUtc(),
        nodeAt,
      );
    },
  );

  test(
    'future character recovery rejects historical node replay without writes',
    () async {
      final config = GameRepository.instance.expeditionConfig!;
      await service.dispatch(
        characterIds: [1],
        policy: ExpeditionPolicy.yiZhanLiXing,
        now: startedAt,
      );
      final future = startedAt.add(
        Duration(minutes: config.normalNodeMinutes * 2),
      );
      await isar.writeTxn(() async {
        final character = (await isar.characters.get(1))!
          ..recoverySettledAt = future;
        await isar.characters.put(character);
      });
      final before = await isar.characters.where().exportJson();
      await expectLater(
        service.settle(
          combat: _RecoveryCombat(isar, startedAt),
          config: config,
          now: future,
        ),
        throwsA(
          isA<ExpeditionTimelineConflict>()
              .having((error) => error.characterId, 'recovery owner', 1)
              .having(
                (error) => error.recoveryAt!.toUtc(),
                'recovery clock',
                future,
              )
              .having((error) => error.passiveAt, 'not passive clock', isNull),
        ),
      );
      expect(await isar.characters.where().exportJson(), before);
      expect((await service.activeRun())!.currentNode, 0);
    },
  );

  test(
    'manual defeat settles elapsed recovery before battle recovery',
    () async {
      final config = GameRepository.instance.expeditionConfig!;
      final nodeSeed = ExpeditionSeed.forNode(saveId: 0, runSerial: 1, node: 5);
      final milestoneId = config
          .teamForNode(nodeSeed: nodeSeed, elite: true)
          .id;
      final key = ExpeditionMilestoneRecord.canonicalKey(
        saveDataId: 1,
        routeId: ExpeditionService.contentId,
        milestoneId: milestoneId,
      );
      await isar.writeTxn(() async {
        final character = (await isar.characters.get(1))!
          ..injuryHoursRemaining = 0
          ..isFounder = true;
        await isar.characters.put(character);
        final save = (await isar.saveDatas.get(0))!
          ..founderCharacterId = 1
          ..activeCharacterIds = [1];
        await isar.saveDatas.put(save);
        await isar.expeditionMilestoneRecords.put(
          ExpeditionMilestoneRecord()
            ..recordKey = key
            ..saveDataId = 1
            ..routeId = ExpeditionService.contentId
            ..milestoneId = milestoneId
            ..nodeIndex = 5
            ..nodeSeed = nodeSeed
            ..cycleIndex = 1
            ..sourceRunId = 99
            ..sourceParticipantId = 1
            ..discoveredAt = startedAt,
        );
      });
      final plan = await service.prepareManualMilestone(
        request: ExpeditionService.manualMilestoneRequestFor(
          milestoneId: milestoneId,
          characterId: 1,
        ),
        now: startedAt,
      );
      final at = startedAt.add(const Duration(hours: 2));
      expect(
        await service.completeManualMilestone(
          plan: plan,
          now: at,
          settlement: CombatSettlementSnapshot(
            result: BattleResult.rightWin,
            totalTicks: 1,
            hadActions: true,
            playerCharacterId: 1,
            participants: [
              CombatParticipantSnapshot(
                characterId: 1,
                currentHp: 0,
                maxHp: plan.playerSnapshot.maxHp,
              ),
            ],
            skillCasts: const [],
            totalDamage: 1,
            criticalCount: 0,
            damageByCharacterId: const {1: 1},
          ),
        ),
        isFalse,
      );
      final character = (await isar.characters.get(1))!;
      expect(
        character.innerBreathDisorderHoursRemaining,
        closeTo(
          10 -
              GameRepository
                  .instance
                  .numbers
                  .innerBreathDisorder
                  .battleRecoveryHours,
          1e-9,
        ),
      );
      expect(character.recoverySettledAt!.toUtc(), at);
      expect(character.lightInjuryStacks, 2);
      expect((await service.pendingManualMilestone())!.recordKey, key);
    },
  );
}
