import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/lore_loader.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_coordinator.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/legacy_tower_session_reference.dart';
import '../../../support/phase0a_tower_endgame_profile.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory temp;
  late GameRepository repo;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tower_first_batch_');
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await temp.delete(recursive: true);
  });

  for (final profile in [
    (name: 'P3', maxFloor: 7, endgame: false),
    (name: 'legal endgame', maxFloor: 49, endgame: true),
  ]) {
    testWidgets(
      '${profile.name} production floors 1-${profile.maxFloor} preserve legacy first-clear rewards and durable facts',
      (tester) async {
        final routes = <bool, List<Map<String, Object?>>>{};
        for (final legacy in [true, false]) {
          final directory = Directory(
            '${temp.path}/${legacy ? 'legacy' : 'production'}',
          );
          final clock = (await _runIo(
            tester,
            () => _openFresh(directory, endgame: profile.endgame),
          ))!;
          late WidgetRef ref;
          await tester.pumpWidget(_harness((value) => ref = value, clock));
          final facts = <Map<String, Object?>>[];
          for (var floor = 1; floor <= profile.maxFloor; floor++) {
            facts.add(
              (await _runIo(tester, () async {
                await _clearFloor(ref, repo, floor, clock, legacy: legacy);
                return _facts();
              }))!,
            );
          }
          if (profile.endgame) {
            await _runIo(tester, () => _expectTerminalBoundary(repo));
          }
          routes[legacy] = facts;
          await tester.pumpWidget(const SizedBox.shrink());
          await _runIo(tester, () => _reopen(directory));
          expect(
            await _runIo(tester, _facts),
            facts.last,
            reason:
                'closing and reopening must preserve all reward/progress facts',
          );
          await _runIo(tester, () async {
            await IsarSetup.close();
            IsarSetup.resetForTest();
          });
        }
        expect(
          routes[false],
          routes[true],
          reason:
              'same production data, profile and seeds must preserve every floor settlement',
        );
      },
    );

    testWidgets(
      '${profile.name} real sweep and reopened durable replay cannot regrant floors 1-${profile.maxFloor} first clears',
      (tester) async {
        final clock = (await _runIo(
          tester,
          () => _openFresh(temp, endgame: profile.endgame),
        ))!;
        late WidgetRef ref;
        await tester.pumpWidget(_harness((value) => ref = value, clock));

        await _runIo(tester, () async {
          final unit = TowerSweepUnit(
            floor: repo.getTowerFloor(1),
            cycleIndex: 1,
          );
          await expectLater(
            unit.runPhase0aHeadless(
              ref,
              policy: const Phase0aBotTacticPolicy.production(),
            ),
            throwsA(isA<TowerAutomationRejectedException>()),
            reason: 'headless automation must not manufacture a first clear',
          );
          for (var floor = 1; floor <= profile.maxFloor; floor++) {
            await _clearFloor(ref, repo, floor, clock);
          }
        });
        final firstClearFacts = (await _runIo(tester, _facts))!;
        for (var floor = 1; floor <= profile.maxFloor; floor++) {
          await _runIo(tester, () async {
            await _restBeforeNextFight(clock);
            final beforeAttempt = await _facts();
            expect(
              beforeAttempt['firstClearClaims'],
              firstClearFacts['firstClearClaims'],
            );
            final unit = TowerSweepUnit(
              floor: repo.getTowerFloor(floor),
              cycleIndex: 1,
            );
            final result = await unit.runPhase0aHeadless(
              ref,
              policy: const Phase0aBotTacticPolicy.production(),
            );
            expect(result.timedOut, isFalse);
            expect(result.settlement?.result, BattleResult.leftWin);
            expect(result.expectedParticipantId, 1);
            final recap = await unit.settlePhase0a(ref, result);
            expect(recap, isNotNull);
            expect(recap!.equipmentDrops, 0);
            expect(recap.itemsByDefId, isEmpty);
            expect(recap.expGained, 0);
            expect(recap.realmAdvances, 0);
            final facts = await _facts();
            _expectNoFirstClearGrant(facts, beforeAttempt, profile.maxFloor);
            expect((facts['progress'] as List)[1], profile.maxFloor + floor);
          });
        }

        await _runIo(tester, () => _restBeforeNextFight(clock));
        final beforeDurable = (await _runIo(tester, _facts))!;
        expect(
          beforeDurable['firstClearClaims'],
          firstClearFacts['firstClearClaims'],
        );
        final floor = repo.getTowerFloor(profile.maxFloor);
        final runId = (await _runIo(
          tester,
          () => DurableActivityAutomationService(IsarSetup.instance).startTower(
            floor: floor,
            cycleIndex: 1,
            request: towerDurableDispatchRequest(
              floorIndex: profile.maxFloor,
              characterId: 1,
            ),
            now: clock.now(),
          ),
        ))!;
        await tester.pumpWidget(const SizedBox.shrink());
        await _runIo(tester, () => _reopen(temp));
        await tester.pumpWidget(_harness((value) => ref = value, clock));
        await _runIo(tester, () async {
          final result = await executeTowerDurableActivityAutomation(
            ref: ref,
            floor: floor,
            runId: runId,
          );
          expect(result.outcome, DurableActivityExecutionOutcome.victory);
          expect(result.run.phase, DurableActivityPhase.settlementApplied);
          expect(result.run.outcome, DurableActivityOutcome.victory);
          final personal = (await IsarSetup.instance.towerPersonalRecords
              .where()
              .findFirst())!;
          expect(
            personal.bestClearTimeMs,
            greaterThan(0),
            reason: 'durable execution owns a real elapsed duration',
          );
          final settled = await _facts();
          _expectNoFirstClearGrant(settled, beforeDurable, profile.maxFloor);
          expect((settled['progress'] as List)[1], 2 * profile.maxFloor + 1);
          final receiptCount = await IsarSetup.instance.rewardClaimReceipts
              .count();
          await expectLater(
            executeTowerDurableActivityAutomation(
              ref: ref,
              floor: floor,
              runId: runId,
            ),
            throwsStateError,
          );
          expect(
            await _facts(),
            settled,
            reason: 'settled durable dispatch cannot apply twice',
          );
          expect(
            await IsarSetup.instance.rewardClaimReceipts.count(),
            receiptCount,
          );
        });
        final finalFacts = await _runIo(tester, _facts);
        await tester.pumpWidget(const SizedBox.shrink());
        await _runIo(tester, () => _reopen(temp));
        expect(await _runIo(tester, _facts), finalFacts);
        final durable = await _runIo(
          tester,
          () => IsarSetup.instance.durableActivityCombatRuns.get(runId),
        );
        expect(durable!.phase, DurableActivityPhase.settlementApplied);
        expect(durable.outcome, DurableActivityOutcome.victory);
      },
    );
  }
}

Widget _harness(ValueChanged<WidgetRef> capture, _TowerClock clock) =>
    ProviderScope(
      overrides: [
        systemClockProvider.overrideWithValue(clock),
        rngProvider.overrideWithValue(DefaultRng(seed: 20260912)),
        mathRandomProvider.overrideWithValue(Random(20260912)),
      ],
      child: Consumer(
        builder: (_, ref, _) {
          capture(ref);
          return const SizedBox.shrink();
        },
      ),
    );

Future<_TowerClock> _openFresh(
  Directory directory, {
  required bool endgame,
}) async {
  await directory.create(recursive: true);
  await IsarSetup.init(directory: directory, inspector: false);
  if (endgame) {
    await seedPhase0aTowerEndgameProfile(isar: IsarSetup.instance);
  } else {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
  }
  final isar = IsarSetup.instance;
  final now = DateTime.now();
  final save = (await isar.saveDatas.get(0))!;
  await isar.writeTxn(() async {
    save
      ..founderCharacterId = 1
      ..activeCharacterIds = [1]
      ..lastOnlineAt = now;
    await isar.saveDatas.put(save);
  });
  final progress = await TowerProgressService(
    isar: isar,
  ).getOrCreate(saveDataId: save.slotId);
  expect(progress.highestClearedFloor, 0);
  expect(await isar.towerPersonalRecords.count(), 0);
  return _TowerClock(now);
}

Future<void> _reopen(Directory directory) async {
  await IsarSetup.close();
  IsarSetup.resetForTest();
  await IsarSetup.init(directory: directory, inspector: false);
}

// Preserve genuine admission and injury rules between sequential victories.
// The same clock drives recovery, passive growth and every later settlement.
// Explicit light-injury clearing remains false, as for an ordinary time tick.
final class _TowerClock extends SystemClock {
  _TowerClock(this.current);
  DateTime current;

  @override
  DateTime now() => current;
}

Future<void> _restBeforeNextFight(_TowerClock clock) async {
  final character = (await IsarSetup.instance.characters.get(1))!;
  if (character.injuryHoursRemaining <= 0) return;
  final hours = max(
    character.injuryHoursRemaining,
    character.innerBreathDisorderHoursRemaining,
  );
  clock.current = clock.current.add(
    Duration(microseconds: (hours * Duration.microsecondsPerHour).round()),
  );
  await OfflinePassiveService.settleWindow(
    isar: IsarSetup.instance,
    now: clock.now(),
    updatePresence: true,
  );
  final recovered = (await IsarSetup.instance.characters.get(1))!;
  expect(recovered.injuryHoursRemaining, 0);
}

Future<void> _clearFloor(
  WidgetRef ref,
  GameRepository repo,
  int index,
  _TowerClock clock, {
  bool legacy = false,
}) async {
  final floor = repo.getTowerFloor(index);
  await _restBeforeNextFight(clock);
  final participant = (await IsarSetup.instance.characters.get(1))!;
  final player =
      await resolveTowerParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: 1,
      ).catchError((Object error) {
        throw StateError(
          'floor=$index legacy=$legacy participant=1 '
          'realm=${participant.realmTier.name}/${participant.realmLayer.name} '
          'heavy=${participant.injuryHoursRemaining} '
          'disorder=${participant.innerBreathDisorderHoursRemaining} '
          'light=${participant.lightInjuryStacks} '
          'recoveryAt=${participant.recoverySettledAt}: $error',
        );
      });
  final session =
      await (legacy
          ? createLegacyTowerSessionForReference
          : createFreshPhase0aTowerCombatSession)(
        Phase0aTowerCombatSessionBuildRequest(
          contentRef: CombatContentRef.tower('tower_$index'),
          floor: floor,
          playerSnapshot: player,
          numbers: repo.numbers,
          cycleIndex: 1,
          rng: Random(100 + index),
          // The candidate consumes production defaults. The historical reference
          // lives entirely in test support and cannot enable a production fallback.
        ),
      );
  expect(
    session.routeMode,
    legacy
        ? Phase0aTowerEncounterRouteMode.legacy
        : Phase0aTowerEncounterRouteMode.migrated,
  );
  final result = Phase0aHeadlessRunner.runToEnd(
    flow: session.flow,
    bot: Phase0aPlayerBotAdapter(playerAdapter: session.playerAdapter),
    deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
    maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
  );
  expect(
    result.timedOut,
    isFalse,
    reason: 'floor $index must finish naturally',
  );
  final settlement = session.settle(
    outcome: result.outcome,
    finalState: result.finalState,
    events: result.events,
  );
  expect(
    settlement.result,
    BattleResult.leftWin,
    reason:
        'floor $index must be won by the persisted profile through real combat',
  );
  expect(settlement.playerCharacterId, 1);
  expect(settlement.totalDamage, greaterThan(0));
  final before = (await IsarSetup.instance.characters.get(1))!;
  final inventoryBefore = {
    for (final item
        in await IsarSetup.instance.inventoryItems.where().findAll())
      item.defId: item.quantity,
  };
  final applied = await applyTowerVictorySettlement(
    ref: ref,
    floor: floor,
    participantId: 1,
    elapsedMs: 0,
    settlementSnapshot: settlement,
    rewardOccurrenceId: 'first-batch-floor-$index',
    settlementAt: clock.now(),
  );
  expect(applied.clearResult.isFirstClear, isTrue);
  final after = (await IsarSetup.instance.characters.get(1))!;
  expect(after.realmTier, before.realmTier);
  expect(after.realmLayer, before.realmLayer);
  expect(after.experience - before.experience, floor.baseExpReward);
  for (final drop in floor.dropTable.whereType<ItemDrop>()) {
    if (drop.dropChance != 1) continue;
    final item = await IsarSetup.instance.inventoryItems.getByDefId(
      drop.inventoryItemDefId,
    );
    expect(item, isNotNull);
    expect(
      item!.quantity - (inventoryBefore[item.defId] ?? 0),
      inInclusiveRange(drop.quantityMin, drop.quantityMax),
      reason: 'configured guaranteed first-clear items must reach storage',
    );
  }
  final progress = (await IsarSetup.instance.towerProgress
      .where()
      .findFirst())!;
  expect(progress.highestClearedFloor, index);
  expect(progress.totalAttempts, index);
  expect(progress.totalDefeats, 0);
  expect(progress.perFloorClearTimes, hasLength(index));
  expect(progress.currentCycleIndex, 1);
  expect(progress.maxClearedCycle, index == repo.towerMaxFloor ? 1 : 0);
  final milestoneIds =
      (await IsarSetup.currentSaveData())!.grantedTicketMilestoneIds;
  expect(milestoneIds, [
    for (final milestone in TowerProgressService.ticketMilestoneFloors)
      if (milestone <= index) 'tower_floor_$milestone',
  ]);
  final personal = (await IsarSetup.instance.towerPersonalRecords
      .where()
      .findFirst())!;
  expect(personal.participantId, 1);
  expect(personal.highestClearedFloor, index);
  expect(
    personal.bestClearTimeMs,
    isNull,
    reason: 'headless simulation does not invent wall-clock clear times',
  );
  final exclusive =
      (await IsarSetup.instance.rewardClaimReceipts.where().findAll())
          .where((r) => r.layer == RewardLayer.firstClear)
          .toList();
  expect(exclusive, hasLength(index));
  expect(exclusive.every((r) => !r.isHistoricalTombstone), isTrue);
  final facts = await _facts();
  await expectLater(
    applyTowerVictorySettlement(
      ref: ref,
      floor: floor,
      participantId: 1,
      elapsedMs: 0,
      settlementSnapshot: settlement,
      rewardOccurrenceId: 'first-batch-floor-$index',
      settlementAt: clock.now(),
    ),
    throwsStateError,
  );
  expect(
    await _facts(),
    facts,
    reason: 'same victory occurrence must not grant twice',
  );
}

Future<void> _expectTerminalBoundary(GameRepository repo) async {
  expect(repo.towerMaxFloor, 49);
  final progress = (await IsarSetup.instance.towerProgress
      .where()
      .findFirst())!;
  expect(progress.highestClearedFloor, repo.towerMaxFloor);
  expect(progress.maxClearedCycle, 1);
  expect(
    TowerProgressService.availableFloor(progress, maxFloor: repo.towerMaxFloor),
    repo.towerMaxFloor,
  );
  expect(
    TowerProgressService.canChallenge(
      progress: progress,
      floorIndex: repo.towerMaxFloor,
      maxFloor: repo.towerMaxFloor,
    ),
    isTrue,
  );
  expect(
    TowerProgressService.canChallenge(
      progress: progress,
      floorIndex: repo.towerMaxFloor + 1,
      maxFloor: repo.towerMaxFloor,
    ),
    isFalse,
  );
  expect(() => repo.getTowerFloor(repo.towerMaxFloor + 1), throwsRangeError);
}

Future<Map<String, Object?>> _facts() async {
  final isar = IsarSetup.instance;
  final progress = (await isar.towerProgress.where().findFirst())!;
  final personal = await isar.towerPersonalRecords.where().findAll();
  final character = (await isar.characters.get(1))!;
  final inventory = await isar.inventoryItems.where().findAll();
  final equipment = await isar.equipments.where().exportJson();
  for (final row in equipment) {
    final definition = GameRepository.instance.getEquipment(
      row['defId'] as String,
    );
    final content = await LoreLoader.load(definition.id);
    for (final lore in row['lores'] as List) {
      final trigger = lore['triggerEventDesc'] as String;
      final List<String> allowed;
      final String normalized;
      if (trigger.startsWith('equipmentObtained:')) {
        final source = trigger.substring('equipmentObtained:'.length);
        allowed = content.continuedLoreObtainedPool
            .map((entry) => entry.text.replaceAll('{source}', source))
            .toList();
        if (content.isPlaceholder || allowed.isEmpty) {
          allowed.add(UiStrings.continuedLoreObtained(definition.name, source));
        }
        normalized = 'validated-authored-obtained-lore';
      } else if (trigger.startsWith('bossDefeated:tower_floor_')) {
        final index = int.parse(
          trigger.substring('bossDefeated:tower_floor_'.length),
        );
        final floor = GameRepository.instance.getTowerFloor(index);
        expect(floor.isBoss, isTrue);
        final stageName = UiStrings.towerFloorLabel(index);
        final bossName = floor.enemyTeam.isNotEmpty
            ? floor.enemyTeam.last.name
            : stageName;
        allowed = content.continuedLoreBossDefeatedPool
            .map(
              (entry) => entry.text
                  .replaceAll('{boss_name}', bossName)
                  .replaceAll('{stage_name}', stageName),
            )
            .toList();
        if (content.isPlaceholder || allowed.isEmpty) {
          allowed.add(UiStrings.continuedLoreBossDefeated(bossName, stageName));
        }
        normalized = 'validated-authored-boss-lore';
      } else {
        continue;
      }
      expect(
        lore['text'],
        isIn(allowed),
        reason: 'unseeded cosmetic lore still must come from its authored pool',
      );
      // GameEventService owns an independent random cosmetic variant. Validate
      // it above before normalizing; preserve its trigger identity and flags.
      lore['text'] = normalized;
    }
  }
  final techniques = await isar.techniques.where().exportJson();
  final receipts = await isar.rewardClaimReceipts.where().findAll();
  return {
    'progress': [
      progress.highestClearedFloor,
      progress.totalAttempts,
      progress.totalDefeats,
      progress.currentCycleIndex,
      progress.maxClearedCycle,
      progress.perFloorClearTimes,
      progress.bestClearTime,
    ],
    'personal': [
      for (final p in personal)
        [
          p.recordKey,
          p.participantId,
          p.highestClearedFloor,
          p.bestClearTimeMs,
        ],
    ],
    'experience': [
      character.realmTier.name,
      character.realmLayer.name,
      character.experience,
    ],
    'inventory': {for (final i in inventory) i.defId: i.quantity},
    'ticketMilestones':
        (await IsarSetup.currentSaveData())!.grantedTicketMilestoneIds,
    'equipment': _withoutWallClock(equipment),
    'techniques': _withoutWallClock(techniques),
    'firstClearClaims': [
      for (final r in receipts)
        if (r.layer == RewardLayer.firstClear) r.claimKey,
    ],
    'claims': [for (final r in receipts) r.claimKey],
  };
}

// Loot and technique owners timestamp acquisitions with their own wall clock.
// Only those timestamps differ between independent databases; full item payloads
// (including affixes, ownership, skill usage and cultivation) remain compared.
Object? _withoutWallClock(Object? value) {
  if (value is List) return value.map(_withoutWallClock).toList();
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.key != 'obtainedAt' &&
            entry.key != 'learnedAt' &&
            entry.key != 'addedAt')
          entry.key: _withoutWallClock(entry.value),
    };
  }
  return value;
}

void _expectNoFirstClearGrant(
  Map<String, Object?> after,
  Map<String, Object?> first,
  int highestFloor,
) {
  for (final key in [
    'experience',
    'inventory',
    'ticketMilestones',
    'firstClearClaims',
  ]) {
    expect(after[key], first[key], reason: 'replay must not regrant $key');
  }
  _expectOnlyEquippedBattleCountProgress(
    after['equipment'],
    first['equipment'],
  );
  expect((after['progress'] as List)[0], highestFloor);
  expect(
    (after['progress'] as List).skip(2),
    (first['progress'] as List).skip(2),
  );
  expect(
    (after['personal'] as List).single.take(3),
    (first['personal'] as List).single.take(3),
  );
}

void _expectOnlyEquippedBattleCountProgress(Object? after, Object? before) {
  final beforeRows = before as List;
  final afterRows = after as List;
  expect(
    afterRows,
    hasLength(beforeRows.length),
    reason: 'replay grants no equipment',
  );
  for (var index = 0; index < beforeRows.length; index++) {
    final first = Map<String, Object?>.from(beforeRows[index] as Map);
    final current = Map<String, Object?>.from(afterRows[index] as Map);
    final previousBattles = first.remove('battleCount') as int;
    final currentBattles = current.remove('battleCount') as int;
    expect(
      currentBattles,
      previousBattles + (first['ownerCharacterId'] == 1 ? 1 : 0),
    );
    expect(
      current,
      first,
      reason: 'replay preserves every other equipment field',
    );
  }
}

// Preserve the first IO/assertion failure instead of continuing after runAsync
// reports it and returns null; later settlement must not run on a failed setup.
Future<T?> _runIo<T>(WidgetTester tester, Future<T> Function() action) async {
  T? result;
  Object? failure;
  StackTrace? trace;
  await tester.runAsync(() async {
    try {
      result = await action();
    } catch (error, stack) {
      failure = error;
      trace = stack;
    }
  });
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return result;
}
