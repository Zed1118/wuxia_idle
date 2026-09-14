import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/character_occupancy_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';
import '../../support/phase0a_production_headless_benchmark.dart';

/// Observes the actual production runner without choosing or changing outcomes.
/// It returns the same shared settlement consumed by ExpeditionService.
class _ObservedCombat implements ExpeditionCombat {
  _ObservedCombat(this.runner, this.records);

  final Phase0aExpeditionCombatRunner runner;
  final List<Map<String, Object?>> records;

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) =>
      runner.memberCaps(ids);

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    final result = await runner.fightDetailed(
      node: node,
      memberStates: memberStates,
      nodeSeed: nodeSeed,
      cycleIndex: cycleIndex,
    );
    final member = memberStates.entries.single;
    expect(result.mapping.initialState.player.currentHealth, member.value.hp);
    expect(result.mapping.initialState.player.qiCurrent, member.value.qi);
    records.add({
      'node': node.index,
      'type': node.type.name,
      'seed': nodeSeed,
      'cycle': cycleIndex,
      'inputVitals': {
        for (final entry in memberStates.entries)
          entry.key: [entry.value.hp, entry.value.qi],
      },
      'players': [
        for (final combatant in result.mapping.combatants)
          if (combatant.actorId == result.mapping.initialState.player.id)
            headlessPlayerFacts(combatant.snapshot),
      ],
      'outcome': result.headless.outcome.name,
      'timedOut': result.headless.timedOut,
      'ticks': result.headless.ticks,
      'state': result.headless.finalState,
      'events': result.headless.events,
      'eventRecords': result.headless.eventRecords,
      'settlement': headlessSettlementFacts(
        result.nodeOutcome.combatSettlement!,
      ),
    });
    return result.nodeOutcome;
  }
}

Map<String, Object?>? _gateFacts(ExpeditionManualMilestoneGate? gate) =>
    gate == null
    ? null
    : {
        'key': gate.recordKey,
        'route': gate.routeId,
        'milestone': gate.milestoneId,
        'node': gate.nodeIndex,
        'seed': gate.nodeSeed,
        'cycle': gate.cycleIndex,
        'run': gate.sourceRunId,
        'participant': gate.sourceParticipantId,
      };

Map<String, Object?> _returnFacts(ExpeditionReturnResult result) => {
  'returned': result.returned,
  'participant': result.participantCharacterId,
  'name': result.participantName,
  'deepest': result.deepestNode,
  'rewards': {
    for (final reward in result.grantedRewards)
      reward.rewardKey: reward.quantity,
  },
  'downed': result.downedCount,
  'defeated': result.defeated,
  'gate': _gateFacts(result.manualMilestoneGate),
};

/// Complete exported rows of the stores this lifecycle consumes or changes.
/// Timestamps and receipt identities are compared, not filtered out.
Future<Map<String, Object?>> _storedFacts() async {
  final isar = IsarSetup.instance;
  return {
    'save': await isar.saveDatas.where().exportJson(),
    'characters': await isar.characters.where().exportJson(),
    'equipment': await isar.equipments.where().exportJson(),
    'techniques': await isar.techniques.where().exportJson(),
    'inventory': await isar.inventoryItems.where().exportJson(),
    'runs': await isar.expeditionRuns.where().exportJson(),
    'milestones': await isar.expeditionMilestoneRecords.where().exportJson(),
    'receipts': await isar.rewardClaimReceipts.where().exportJson(),
  };
}

// Preserve complete equality while reporting paths rather than dumping both
// databases and all event records into an assertion's failure message.
List<String> _differences(
  Object? expected,
  Object? actual, [
  String path = r'$',
]) {
  if (expected == actual) return const [];
  if (expected is Map && actual is Map) {
    return [
      for (final key in {...expected.keys, ...actual.keys})
        if (!expected.containsKey(key) || !actual.containsKey(key))
          '$path.$key: missing key'
        else
          ..._differences(expected[key], actual[key], '$path.$key'),
    ];
  }
  if (expected is List && actual is List) {
    return [
      if (expected.length != actual.length)
        '$path.length: ${expected.length} != ${actual.length}',
      for (
        var index = 0;
        index < expected.length && index < actual.length;
        index++
      )
        ..._differences(expected[index], actual[index], '$path[$index]'),
    ];
  }
  return ['$path: $expected != $actual'];
}

void main() {
  late Directory directory;
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expedition_lifecycle_');
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  for (final school in ['gang_meng', 'ling_qiao', 'yin_rou']) {
    for (final policy in ExpeditionPolicy.values) {
      for (final runSerial in [1, 2]) {
        test(
          '$school/${policy.name}/run$runSerial batch and cold-resume lifecycle agree',
          () async {
            final seedDirectory = await Directory(
              '${directory.path}/seed',
            ).create();
            await IsarSetup.init(directory: seedDirectory, inspector: false);
            final profile = await seedPhase0aCh1FounderProfile(
              isar: IsarSetup.instance,
              schoolId: school,
              originId: 'mountain_wanderer',
              fateId: 'balanced_seed',
              rngSeed: 20260820,
            );
            // Dispatch through the real typed request. No unlocks, stat edits,
            // weakened enemies, fabricated victories or skipped preceding nodes.
            final departedAt = DateTime.utc(2026, 9, 14);
            final service = ExpeditionService(IsarSetup.instance);
            // A real immediate recall advances the second scenario's serial without
            // clearing any node, opening a manual gate, or editing saved counters.
            for (var prior = 1; prior < runSerial; prior++) {
              await service.dispatchRequest(
                request: ExpeditionService.dispatchRequestFor(
                  characterId: profile.snapshot.characterId,
                ),
                policy: policy,
                now: departedAt,
              );
              final earlyReturn = await service.recall(now: departedAt);
              expect(earlyReturn.returned, isTrue);
              expect(earlyReturn.deepestNode, 0);
              expect(earlyReturn.grantedRewards, isEmpty);
              expect(await service.activeRun(), isNull);
            }
            await service.dispatchRequest(
              request: ExpeditionService.dispatchRequestFor(
                characterId: profile.snapshot.characterId,
              ),
              policy: policy,
              now: departedAt,
            );
            final entry = (await service.activeRun())!;
            expect(entry.seed, runSerial);
            expect(entry.currentNode, 0);
            expect(entry.stagedRewards, isEmpty);
            final initial = await _storedFacts();
            final initialReceiptKeys = {
              for (final receipt
                  in await IsarSetup.instance.rewardClaimReceipts
                      .where()
                      .findAll())
                receipt.claimKey,
            };
            await IsarSetup.close();
            final source = File('${seedDirectory.path}/wuxia_save_slot1.isar');
            final sourceBytes = await source.readAsBytes();

            final config = repository.expeditionConfig!;
            // First manual milestone bounds this legal new-profile route. Reaching
            // that gate is not a clear; a natural defeat can stop it sooner.
            final now = departedAt.add(
              Duration(
                minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
                  5,
                  normalMinutes: config.normalNodeMinutes,
                  eliteMinutes: config.eliteNodeMinutes,
                ),
              ),
            );
            Future<Map<String, Object?>> run({
              required bool cold,
              bool singleBatch = false,
            }) async {
              final copyDirectory = await Directory(
                '${directory.path}/${cold
                    ? 'cold'
                    : singleBatch
                    ? 'bounded'
                    : 'batch'}',
              ).create();
              final copy = await source.copy(
                '${copyDirectory.path}/wuxia_save_slot1.isar',
              );
              expect(await copy.readAsBytes(), sourceBytes);
              await IsarSetup.init(directory: copyDirectory, inspector: false);
              expect(await _storedFacts(), initial);
              final records = <Map<String, Object?>>[];
              final rng = DefaultRng(seed: 73);
              var totalNodes = 0;
              ExpeditionSettlementResult? last;
              Phase0aExpeditionCombatRunner? retainedRunner;
              // maxBatches=1 exposes each existing service transaction to the cold
              // replay. The ordinary route retains the production batch defaults.
              for (var batch = 0; batch < 6; batch++) {
                final currentService = ExpeditionService(
                  IsarSetup.instance,
                  rng: rng,
                );
                final active = (await currentService.activeRun())!;
                if (cold) retainedRunner = null;
                final combat = _ObservedCombat(
                  retainedRunner ??= Phase0aExpeditionCombatRunner(
                    IsarSetup.instance,
                    expectedMember: active.members.single,
                  ),
                  records,
                );
                last = await currentService.settleToNow(
                  combat: combat,
                  config: config,
                  now: now,
                  maxNodesPerBatch: cold
                      ? 1
                      : ExpeditionService.defaultMaxNodesPerBatch,
                  maxBatches: cold || singleBatch ? 1 : 4096,
                );
                if (singleBatch &&
                    runSerial == 2 &&
                    policy != ExpeditionPolicy.xunJiFangYou &&
                    batch == 0) {
                  expect(last.nodesSettled, 1);
                  expect(last.caughtUp, isFalse);
                  expect(last.manualMilestoneGate, isNull);
                }
                totalNodes += last.nodesSettled;
                if (cold) {
                  final beforeClose = await _storedFacts();
                  await IsarSetup.close();
                  await IsarSetup.init(
                    directory: copyDirectory,
                    inspector: false,
                  );
                  expect(await _storedFacts(), beforeClose);
                }
                if (last.caughtUp) break;
                expect(last.nodesSettled, greaterThan(0));
              }
              expect(last!.caughtUp, isTrue);
              expect(last.defeated || last.manualMilestoneGate != null, isTrue);
              final expectedBattleNodes = [
                for (
                  var index = 1;
                  index <= totalNodes + (last.defeated ? 1 : 0);
                  index++
                )
                  ExpeditionRules.generateNode(
                    saveId: entry.saveDataId,
                    runSerial: entry.seed,
                    node: index,
                    policy: policy,
                    normalMinutes: config.normalNodeMinutes,
                    eliteMinutes: config.eliteNodeMinutes,
                  ),
              ].where((node) => node.isBattle).toList();
              expect(
                [
                  for (final record in records)
                    [record['node'], record['type'], record['seed']],
                ],
                [
                  for (final node in expectedBattleNodes)
                    [
                      node.index,
                      node.type.name,
                      ExpeditionSeed.forNode(
                        saveId: entry.saveDataId,
                        runSerial: entry.seed,
                        node: node.index,
                      ),
                    ],
                ],
                reason:
                    'Every real battle before the stop must run exactly once',
              );
              expect(
                records.every((record) => record['timedOut'] == false),
                isTrue,
                reason:
                    'A timeout-adapted defeat is not a completed battle sample',
              );
              final currentService = ExpeditionService(
                IsarSetup.instance,
                rng: rng,
              );
              final beforeReturn = await _storedFacts();
              final recordCount = records.length;
              if (last.defeated) {
                final active = (await currentService.activeRun())!;
                expect(active.defeated, isTrue);
                final retry = await currentService.settleToNow(
                  combat: _ObservedCombat(
                    Phase0aExpeditionCombatRunner(
                      IsarSetup.instance,
                      expectedMember: active.members.single,
                    ),
                    records,
                  ),
                  config: config,
                  now: now,
                );
                expect(retry.nodesSettled, 0);
                expect(retry.defeated, isTrue);
                expect(
                  records.length,
                  recordCount,
                  reason: 'No replay after defeat',
                );
                expect(await _storedFacts(), beforeReturn);
              }
              final returned =
                  last.automaticReturn ?? await currentService.recall(now: now);
              expect(returned.returned, isTrue);
              expect(returned.deepestNode, totalNodes);
              expect(returned.defeated, last.defeated);
              expect(await currentService.activeRun(), isNull);
              expect(
                (await CharacterOccupancyService(
                  IsarSetup.instance,
                ).snapshot()).isCharacterOccupied(profile.snapshot.characterId),
                isFalse,
              );
              final afterReturn = await _storedFacts();
              final receipts = await IsarSetup.instance.rewardClaimReceipts
                  .where()
                  .findAll();
              expect(receipts.length, initialReceiptKeys.length + 2);
              final newReceipts = receipts
                  .where(
                    (receipt) => !initialReceiptKeys.contains(receipt.claimKey),
                  )
                  .toList();
              expect(newReceipts.map((receipt) => receipt.layer).toSet(), {
                RewardLayer.repeat,
                RewardLayer.personalGrowth,
              });
              for (final receipt in newReceipts) {
                expect(receipt.key.contentKind, RewardContentKind.expedition);
                expect(receipt.contentId, ExpeditionService.contentId);
                expect(receipt.participantId, profile.snapshot.characterId);
                expect(receipt.occurrenceId, entry.id.toString());
                expect(
                  receipt.sourceSettlementId,
                  'expedition-run:${entry.id}',
                );
                expect(receipt.createdAt.toUtc(), now);
                expect(receipt.isHistoricalTombstone, isFalse);
              }
              final duplicate = await currentService.recall(now: now);
              expect(duplicate.returned, isFalse);
              expect(
                await _storedFacts(),
                afterReturn,
                reason: 'Second return cannot award or mutate any ledger twice',
              );
              await IsarSetup.close();
              return {
                'nodes': totalNodes,
                'defeated': last.defeated,
                'gate': _gateFacts(last.manualMilestoneGate),
                'records': records,
                'beforeReturn': beforeReturn,
                'return': _returnFacts(returned),
                'afterReturn': afterReturn,
              };
            }

            final batch = await run(cold: false);
            final cold = await run(cold: true);
            final bounded = await run(cold: false, singleBatch: true);
            expect(
              _differences(batch, cold),
              isEmpty,
              reason:
                  'Compare raw battles, durable HP/Qi, growth, rewards and receipts',
            );
            expect(
              _differences(batch, bounded),
              isEmpty,
              reason:
                  'The batch limit reports unfinished work and later calls resume it',
            );
            expect(await source.readAsBytes(), sourceBytes);
            stdout.writeln(
              'expedition-lifecycle ${jsonEncode({
                'school': school,
                'policy': policy.name,
                'runSerial': runSerial,
                'nodesCompleted': batch['nodes'],
                'defeated': batch['defeated'],
                'manualGate': batch['gate'],
                'battleCount': (batch['records']! as List).length,
                'outcomes': [for (final record in batch['records']! as List) (record as Map)['outcome']],
                'inputQi': [for (final record in batch['records']! as List) (((record as Map)['inputVitals'] as Map).values.single as List)[1]],
                'batchColdEqual': true,
                'boundedEqual': true,
              })}',
            );
          },
        );
      }
    }
  }
}
