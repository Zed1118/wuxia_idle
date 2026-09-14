import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_startup.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_startup_gate.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/application/online_presence_controller.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';
import '../../support/phase0a_production_headless_benchmark.dart';

/// Observes the genuine production battle and returns its unchanged settlement.
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
    records.add({
      'node': node.index,
      'seed': nodeSeed,
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

class _ObservedService extends ExpeditionService {
  _ObservedService(super.isar, this.records, this.results)
    : super(rng: DefaultRng(seed: 73));
  final List<Map<String, Object?>> records;
  final List<ExpeditionSettlementResult> results;

  @override
  Future<ExpeditionSettlementResult> settleToNow({
    required ExpeditionCombat combat,
    required ExpeditionConfig config,
    DateTime? now,
    int maxNodesPerBatch = ExpeditionService.defaultMaxNodesPerBatch,
    int maxBatches = 4096,
  }) async {
    final result = await super.settleToNow(
      combat: combat is _ObservedCombat
          ? combat
          : _ObservedCombat(combat as Phase0aExpeditionCombatRunner, records),
      config: config,
      now: now,
      maxNodesPerBatch: maxNodesPerBatch,
      maxBatches: maxBatches,
    );
    results.add(result);
    return result;
  }
}

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

List<String> _differences(Object? a, Object? b, [String path = r'$']) {
  if (a == b) return const [];
  // Only fractional accrual carries floating-point roundoff. Integer balances,
  // battle state/events and every other exported field stay exact.
  if ((path == r'$.stored.save[0].passiveMojianshiRemainder' ||
          path == r'$.stored.characters[0].passiveExperienceRemainder') &&
      a is num &&
      b is num &&
      (a - b).abs() < 1e-7) {
    return const [];
  }
  if (a is Map && b is Map) {
    return [
      for (final key in {...a.keys, ...b.keys})
        if (!a.containsKey(key) || !b.containsKey(key))
          '$path.$key: missing key'
        else
          ..._differences(a[key], b[key], '$path.$key'),
    ];
  }
  if (a is List && b is List) {
    return [
      if (a.length != b.length) '$path.length: ${a.length} != ${b.length}',
      for (var i = 0; i < a.length && i < b.length; i++)
        ..._differences(a[i], b[i], '$path[$i]'),
    ];
  }
  return ['$path: $a != $b'];
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
    directory = await Directory.systemTemp.createTemp('expedition_passive_');
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  for (final nearBoundary in [false, true]) {
    test(
      '72h startup order and node timeline agree (near boundary: $nearBoundary)',
      () async {
        final seedDirectory = await Directory(
          '${directory.path}/seed',
        ).create();
        await IsarSetup.init(directory: seedDirectory, inspector: false);
        final profile = await seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: 'gang_meng',
          originId: 'mountain_wanderer',
          fateId: 'balanced_seed',
          rngSeed: 20260820,
        );
        var departedAt = DateTime.now().toUtc();
        // Establish the passive clock through the production service. Do not edit
        // experience, realms, rewards, cleared milestones or saved run counters.
        await OfflinePassiveService.settleWindow(
          isar: IsarSetup.instance,
          now: departedAt,
          updatePresence: true,
        );
        if (nearBoundary) {
          final character = (await IsarSetup.instance.characters.get(
            profile.snapshot.characterId,
          ))!;
          final threshold = repository
              .getRealm(character.realmTier, character.realmLayer)
              .experienceToNext;
          final config = repository.numbers.passiveIdle;
          final hourly =
              config.baseExpPerHour * config.realmScaleFor(character.realmTier);
          final preludeHours = (threshold - character.experience) / hourly - 1;
          expect(preludeHours, greaterThan(0));
          departedAt = departedAt.add(
            Duration(
              microseconds: (preludeHours * Duration.microsecondsPerHour)
                  .floor(),
            ),
          );
          await OfflinePassiveService.settleWindow(
            isar: IsarSetup.instance,
            now: departedAt,
            updatePresence: true,
          );
          final grown = (await IsarSetup.instance.characters.get(
            character.id,
          ))!;
          expect(grown.realmLayer, character.realmLayer);
          expect(threshold - grown.experience, closeTo(hourly, 1));
        }
        final service = ExpeditionService(IsarSetup.instance);
        Future<int> dispatch() => service.dispatchRequest(
          request: ExpeditionService.dispatchRequestFor(
            characterId: profile.snapshot.characterId,
          ),
          policy: ExpeditionPolicy.yiZhanLiXing,
          now: departedAt,
        );
        await dispatch();
        final immediateReturn = await service.recall(now: departedAt);
        expect(immediateReturn.returned, isTrue);
        expect(immediateReturn.deepestNode, 0);
        expect(immediateReturn.grantedRewards, isEmpty);
        await dispatch();
        expect((await service.activeRun())!.seed, 2);
        final initial = await _storedFacts();
        await IsarSetup.close();
        final source = File('${seedDirectory.path}/wuxia_save_slot1.isar');
        final sourceBytes = await source.readAsBytes();
        final now = departedAt.add(const Duration(hours: 72));

        Future<Map<String, Object?>> run(String mode) async {
          final passiveFirst = mode != 'expedition-first';
          final copyDirectory = await Directory(
            '${directory.path}/$mode',
          ).create();
          final copy = await source.copy(
            '${copyDirectory.path}/wuxia_save_slot1.isar',
          );
          expect(await copy.readAsBytes(), sourceBytes);
          await IsarSetup.init(directory: copyDirectory, inspector: false);
          expect(await _storedFacts(), initial);
          final records = <Map<String, Object?>>[];
          final results = <ExpeditionSettlementResult>[];
          late _ObservedService currentService;
          late ProviderContainer container;
          late _ObservedCombat combat;
          Future<void> bindOpenedSave() async {
            currentService = _ObservedService(
              IsarSetup.instance,
              records,
              results,
            );
            container = ProviderContainer(
              overrides: [
                expeditionServiceProvider.overrideWith((ref) => currentService),
                onlinePresenceControllerProvider.overrideWith((ref) {
                  final controller = OnlinePresenceController(
                    ref,
                    clock: () => now,
                  );
                  ref.onDispose(controller.dispose);
                  return controller;
                }),
              ],
            );
            final active = (await currentService.activeRun())!;
            combat = _ObservedCombat(
              Phase0aExpeditionCombatRunner(
                IsarSetup.instance,
                expectedMember: active.members.single,
              ),
              records,
            );
          }

          Future<void> reopen() async {
            container.dispose();
            await IsarSetup.close();
            await IsarSetup.init(directory: copyDirectory, inspector: false);
            await bindOpenedSave();
          }

          await bindOpenedSave();
          try {
            var reportedExperience = 0;
            var reportedMojianshi = 0;
            Future<void> passive({DateTime? at, bool recover = true}) async {
              final yield_ = await container
                  .read(onlinePresenceControllerProvider)
                  .settlePassiveWindow(
                    now: at ?? now,
                    recoverInjuries: recover,
                  );
              reportedExperience += yield_?.experience ?? 0;
              reportedMojianshi += yield_?.mojianshi ?? 0;
            }

            Future<void> expedition() async {
              await settleActiveExpeditionOnOpen(
                service: currentService,
                combat: combat,
                config: repository.expeditionConfig!,
                now: now,
              );
            }

            if (mode == 'node-timeline' || mode == 'cold-node-timeline') {
              // Check the first four ordinary node boundaries while present, then
              // close until the same final observation time as both offline copies.
              // Every path automatically returns at the first gate's logical time;
              // no manual milestone is cleared.
              final config = repository.expeditionConfig!;
              for (var index = 1; index <= 4; index++) {
                final at = departedAt.add(
                  Duration(
                    minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
                      index,
                      normalMinutes: config.normalNodeMinutes,
                      eliteMinutes: config.eliteNodeMinutes,
                    ),
                  ),
                );
                await passive(at: at, recover: false);
                final step = await settleActiveExpeditionOnOpen(
                  service: currentService,
                  combat: combat,
                  config: config,
                  now: at,
                );
                expect(step.currentNode, index);
                expect(step.defeated, isFalse);
                expect(step.manualMilestoneGate, isNull);
                if (mode == 'cold-node-timeline') await reopen();
              }
            }

            if (mode == 'presence-write-between') {
              final at = departedAt.add(const Duration(hours: 3));
              await settleActiveExpeditionOnOpen(
                service: currentService,
                combat: combat,
                config: repository.expeditionConfig!,
                now: at,
              );
              // Reward writers update presence to protect injury timing, but
              // do not display a passive recap. Their transaction must retain
              // any already awarded slices for the actual presence consumer.
              await IsarSetup.instance.writeTxn(
                () => OfflinePassiveService.settleWithinTxn(
                  isar: IsarSetup.instance,
                  now: at,
                  updatePresence: true,
                ),
              );
              expect(
                (await IsarSetup.instance.saveDatas.get(
                  0,
                ))!.pendingPassiveRecapExperience,
                greaterThan(0),
              );
              await reopen();
            }

            Map<String, Object?>? interruptedBattle;
            if (mode == 'interrupted-node') {
              final config = repository.expeditionConfig!;
              // Reach the first real battle legally. Throw only after its genuine
              // headless result, leaving the committed passive slice but no node
              // reward or combat growth. Reopen the actual Isar file, then retry.
              while (true) {
                final run = (await currentService.activeRun())!;
                final next = ExpeditionRules.generateNode(
                  saveId: run.saveDataId,
                  runSerial: run.seed,
                  node: run.currentNode + 1,
                  policy: run.policy,
                  normalMinutes: config.normalNodeMinutes,
                  eliteMinutes: config.eliteNodeMinutes,
                );
                final at = departedAt.add(
                  Duration(
                    minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
                      next.index,
                      normalMinutes: config.normalNodeMinutes,
                      eliteMinutes: config.eliteNodeMinutes,
                    ),
                  ),
                );
                if (!next.isBattle) {
                  await currentService.settle(
                    combat: combat,
                    config: config,
                    now: at,
                    maxNodesPerBatch: 1,
                  );
                  continue;
                }
                final beforeRun = await IsarSetup.instance.expeditionRuns
                    .where()
                    .exportJson();
                final beforeReceipts = await IsarSetup
                    .instance
                    .rewardClaimReceipts
                    .where()
                    .exportJson();
                await expectLater(
                  currentService.settle(
                    combat: combat,
                    config: config,
                    now: at,
                    maxNodesPerBatch: 1,
                    beforeCommitForTest: () async => throw StateError(
                      'interrupt after genuine headless battle',
                    ),
                  ),
                  throwsStateError,
                );
                expect(
                  await IsarSetup.instance.expeditionRuns.where().exportJson(),
                  beforeRun,
                );
                expect(
                  await IsarSetup.instance.rewardClaimReceipts
                      .where()
                      .exportJson(),
                  beforeReceipts,
                );
                final prepared = (await IsarSetup.instance.saveDatas.get(0))!;
                expect(prepared.passiveLastSettledAt!.toUtc(), at);
                expect(prepared.pendingPassiveRecapExperience, greaterThan(0));
                interruptedBattle = records.removeLast();
                await reopen();
                expect(
                  (await IsarSetup.instance.saveDatas.get(
                    0,
                  ))!.pendingPassiveRecapExperience,
                  prepared.pendingPassiveRecapExperience,
                );
                break;
              }
            }

            // The real startup coordinator accepts already-running writer futures.
            // Deterministic completion delays model either asynchronous dependency
            // becoming ready first; neither writer's implementation is replaced.
            final simultaneous = mode == 'simultaneous-startup';
            final first = simultaneous
                ? null
                : passiveFirst
                ? passive()
                : expedition();
            await runMainMenuStartupSequence(
              offlineRecap: simultaneous
                  ? passive()
                  : passiveFirst
                  ? first!
                  : first!.then((_) => passive()),
              monthlyTick: Future<void>.value(),
              expeditionSettlement: simultaneous
                  ? expedition()
                  : passiveFirst
                  ? first!.then((_) => expedition())
                  : first!,
              journeyUnlock: Future<void>.value(),
              observeProgressiveUnlocks: () async {},
            );
            expect(currentService.results.every((r) => r.caughtUp), isTrue);
            final returns = currentService.results
                .where((r) => r.automaticReturn != null)
                .toList();
            expect(returns, hasLength(1));
            expect(returns.single.currentNode, 4);
            expect(returns.single.manualMilestoneGate?.nodeIndex, 5);
            expect(returns.single.automaticReturn!.returned, isTrue);
            expect(await currentService.activeRun(), isNull);
            expect(
              (await currentService.pendingManualMilestone())!.nodeIndex,
              5,
            );
            expect(records.length, 2);
            if (interruptedBattle != null) {
              expect(records.first, interruptedBattle);
            }
            for (final record in records) {
              final player = (record['players'] as List).single as Map;
              expect(player['max_hp'], nearBoundary ? 4164 : 4000);
            }
            expect(records.every((r) => r['timedOut'] == false), isTrue);
            final save = (await IsarSetup.instance.saveDatas.get(0))!;
            expect(save.passiveLastSettledAt!.toUtc(), now);
            expect(save.totalPassiveExperience, greaterThan(0));
            expect(save.baicaoMaxDepth, 4);
            expect(save.pendingPassiveRecapExperience, 0);
            expect(save.pendingPassiveRecapMojianshi, 0);
            expect(save.pendingPassiveRecapStartedAt, isNull);
            final initialSave = (initial['save'] as List).single as Map;
            expect(
              reportedExperience,
              save.totalPassiveExperience -
                  (initialSave['totalPassiveExperience'] as num),
            );
            expect(
              reportedMojianshi,
              save.totalPassiveMojianshi -
                  (initialSave['totalPassiveMojianshi'] as num),
            );
            final stored = await _storedFacts();
            final result = {
              'records': records,
              'stored': stored,
              'nodes': save.baicaoMaxDepth,
              'reportedExperience': reportedExperience,
              'reportedMojianshi': reportedMojianshi,
            };
            stdout.writeln(
              'expedition-passive-startup ${jsonEncode({
                'mode': mode,
                'nearBoundary': nearBoundary,
                'hours': 72,
                'nodes': save.baicaoMaxDepth,
                'passiveExperience': save.totalPassiveExperience,
                'players': [for (final r in records) r['players']],
                'ticks': [for (final r in records) r['ticks']],
                'outcomes': [for (final r in records) r['outcome']],
              })}',
            );
            await passive();
            expect(await _storedFacts(), stored);
            expect((await currentService.recall(now: now)).returned, isFalse);
            expect(await _storedFacts(), stored);
            return result;
          } finally {
            container.dispose();
            await IsarSetup.close();
          }
        }

        final passiveFirst = await run('passive-first');
        final expeditionFirst = await run('expedition-first');
        final timeline = await run('node-timeline');
        final coldTimeline = await run('cold-node-timeline');
        final interrupted = await run('interrupted-node');
        final simultaneous = await run('simultaneous-startup');
        final presenceWrite = await run('presence-write-between');
        final comparisons = {
          'startup-order': _differences(passiveFirst, expeditionFirst),
          'cold-node-timeline': _differences(passiveFirst, coldTimeline),
          'interrupted-node': _differences(passiveFirst, interrupted),
          'simultaneous-startup': _differences(passiveFirst, simultaneous),
          'presence-write-between': _differences(passiveFirst, presenceWrite),
          'passive-first-vs-timeline': _differences(passiveFirst, timeline),
          'expedition-first-vs-timeline': _differences(
            expeditionFirst,
            timeline,
          ),
        };
        final differences = [
          for (final entry in comparisons.entries)
            for (final path in entry.value) '${entry.key}: $path',
        ];
        stdout.writeln(
          'expedition-passive-comparisons ${jsonEncode({'nearBoundary': nearBoundary, 'comparisons': comparisons})}',
        );
        expect(await source.readAsBytes(), sourceBytes);
        expect(
          differences.isEmpty,
          isTrue,
          reason:
              '${differences.length} full-field differences; first paths:\n'
              '${differences.take(25).join('\n')}',
        );
      },
    );
  }
}
