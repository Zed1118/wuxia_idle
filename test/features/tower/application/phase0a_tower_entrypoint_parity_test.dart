import 'dart:io';
import 'dart:math';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock_receipt.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_snapshot.dart';
import 'package:wuxia_idle/features/pvp/domain/pvp_record.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/jianghu/domain/npc_relation.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/phase0a_tower_battle_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory temp;
  late GameRepository repo;
  late int participantId;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('tower_target_parity_');
    await IsarSetup.init(directory: temp, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    participantId =
        (await IsarSetup.instance.characters.where().findFirst())!.id;
    await IsarSetup.instance.writeTxn(() async {
      save
        ..founderCharacterId = participantId
        ..activeCharacterIds = [participantId];
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.towerProgress.put(
        TowerProgress()
          ..saveDataId = save.slotId
          ..highestClearedFloor = repo.towerMaxFloor
          ..currentCycleIndex = 1
          ..maxClearedCycle = 2
          ..createdAt = DateTime(2026, 9, 11),
      );
    });
    await resolveTowerParticipantSnapshot(
      isar: IsarSetup.instance,
      requestedParticipantId: participantId,
    );
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await temp.delete(recursive: true);
  });

  for (final floorIndex in [1, 2, 3, 4, 5, 6, 7, 14, 32, 42, 49]) {
    for (final cycle in [1, 2]) {
      testWidgets(
        'real visible / immediate / reopened durable parity $floorIndex/$cycle',
        (tester) async {
          final floor = repo.getTowerFloor(floorIndex);
          await tester.runAsync(() => _cycle(cycle));
          final instantTrace = _FactoryTrace();
          final instant = (await tester.runAsync(
            () => _runner(repo, instantTrace).runTower(
              floor: floor,
              cycleIndex: cycle,
              request: _request(floorIndex, participantId),
            ),
          ))!;
          expect(instant.timedOut, isFalse);
          expect(instantTrace.calls, 1);
          expect(
            instantTrace.session!.routeMode,
            Phase0aTowerEncounterRouteMode.migrated,
          );
          expect(instant.expectedParticipantId, participantId);

          // Compare the complete immutable actors and every emitted combat event,
          // not just the final outcome or selected mechanic labels.
          final original = instantTrace.request!;
          final legacy = await createFreshPhase0aTowerCombatSession(
            Phase0aTowerCombatSessionBuildRequest(
              contentRef: original.contentRef,
              floor: floor,
              playerSnapshot: original.playerSnapshot,
              numbers: repo.numbers,
              cycleIndex: cycle,
              rng: Random(1),
              routeAuthority:
                  Phase0aTowerEncounterRouteAuthority.migratedFloors({}),
            ),
          );
          final legacyFlow = _TraceFlow(legacy.flow);
          final legacyResult = Phase0aHeadlessRunner.runToEnd(
            flow: legacyFlow,
            bot: Phase0aPlayerBotAdapter(playerAdapter: legacy.playerAdapter),
            deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
            maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
          );
          expect(
            instantTrace.trace!.states.map(
              (s) => _canonicalState(s, instantTrace.session!),
            ),
            legacyFlow.states.map((s) => _canonicalState(s, legacy)),
          );
          expect(
            _combatEvents(instantTrace.trace!.events),
            _combatEvents(legacyFlow.events),
          );
          _expectObjectiveWaveSplit(
            contentId: instantTrace.session!.contentRef.contentId,
            typedFlow: instantTrace.session!.flow,
            typedEvents: instantTrace.trace!.events,
            legacyEvents: legacyFlow.events,
            terminal: legacyResult.outcome == Phase0aBattleOutcome.victory,
          );
          expect(
            _combatants(instantTrace.session!, canonical: true),
            _combatants(legacy, canonical: true),
          );
          expect(
            _settlement(instant.settlement!),
            _settlement(
              legacy.settle(
                outcome: legacyResult.outcome,
                finalState: legacyResult.finalState,
                events: legacyResult.events,
              ),
            ),
          );

          final durableTrace = _FactoryTrace();
          final admission = (await tester.runAsync(
            () => _reopenedAdmission(floor, cycle, participantId, temp),
          ))!;
          expect(admission.run.seed, 1);
          final before = await tester.runAsync(_databaseFacts);
          final durable = (await tester.runAsync(
            () => _runner(
              repo,
              durableTrace,
            ).runTowerDurable(floor: floor, admission: admission),
          ))!;
          expect(durableTrace.calls, 1);
          expect(durable.timedOut, isFalse);
          _expectTraceEqual(durableTrace, instantTrace);
          expect(
            _settlement(durable.settlement!),
            _settlement(instant.settlement!),
          );

          final visibleTrace = _FactoryTrace();
          final callbacks = <CombatSettlementSnapshot>[];
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                phase0aTowerCombatSessionFactoryProvider.overrideWithValue(
                  visibleTrace.create,
                ),
              ],
              child: MaterialApp(
                home: Phase0aTowerBattleHost(
                  floor: floor,
                  participantId: participantId,
                  playerSnapshotForTest: original.playerSnapshot,
                  cycleIndexForTest: cycle,
                  seedForTest: 1,
                  onVictory: callbacks.add,
                  onDefeat: callbacks.add,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(visibleTrace.calls, 1);
          final controller = tester
              .widget<Phase0aBattleScreen>(find.byType(Phase0aBattleScreen))
              .controller;
          final bot = Phase0aPlayerBotAdapter(
            playerAdapter: visibleTrace.session!.playerAdapter,
          );
          while (controller.outcome == Phase0aBattleOutcome.ongoing &&
              controller.state.tick <
                  repo.numbers.phase0aArena.maxSimulationTicks) {
            controller.step(bot.commandFor(controller.state));
          }
          expect(callbacks, hasLength(1));
          expect(
            _settlement(callbacks.single),
            _settlement(instant.settlement!),
          );
          _expectTraceEqual(visibleTrace, instantTrace);
          controller.step();
          expect(
            callbacks,
            hasLength(1),
            reason: 'terminal callbacks remain idempotent',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          expect(tester.takeException(), isNull);
          expect(
            await tester.runAsync(_databaseFacts),
            before,
            reason: 'combat hosts must not take over reward/progress ownership',
          );
        },
      );
    }
  }

  for (final cycle in [1, 2]) {
    test(
      'authored vulnerability opens, takes damage and recovers cycle $cycle',
      () async {
        final floor = repo.getTowerFloor(32);
        // Lower player output leaves the authored boss alive long enough to
        // exercise the window. No enemy, skill, posture or damage rule is changed.
        final player = testCombatantSnapshot(
          realmTier: RealmTier.wuSheng,
          maxHp: 20000,
          defenseRate: 0.9,
          includeProductionBasicAttack: true,
        );
        Future<Phase0aTowerCombatSession> build(Set<int> migrated) =>
            createFreshPhase0aTowerCombatSession(
              Phase0aTowerCombatSessionBuildRequest(
                contentRef: const CombatContentRef.tower('tower_32'),
                floor: floor,
                playerSnapshot: player,
                numbers: repo.numbers,
                cycleIndex: cycle,
                rng: Random(20260912),
                routeAuthority:
                    Phase0aTowerEncounterRouteAuthority.migratedFloors(
                      migrated,
                    ),
              ),
            );
        final typed = await build({32});
        final legacy = await build({});
        final bossId = typed.flow.state.enemies.firstWhere((e) => e.isBoss).id;
        final bossSnapshot = typed.combatants
            .firstWhere((entry) => entry.actorId == bossId)
            .snapshot;
        expect(bossSnapshot.vulnerabilityMult, isNotNull);
        expect(bossSnapshot.vulnerabilityMult, lessThan(1));
        final events = <Phase0aEvent>[];
        final legacyEvents = <Phase0aEvent>[];
        var sawGuardedHit = false;
        var sawWindowHit = false;
        var sawRecovery = false;
        while (typed.flow.outcome == Phase0aBattleOutcome.ongoing &&
            typed.flow.state.tick <
                repo.numbers.phase0aArena.maxSimulationTicks &&
            !sawRecovery) {
          final state = typed.flow.state;
          final boss = state.enemies.firstWhere((e) => e.id == bossId);
          final vulnerable = boss.posture?.isVulnerable ?? false;
          final offset = boss.position - state.player.position;
          final aim = offset.length > 0
              ? offset.normalized()
              : state.player.facing;
          // Attack the actual boss through the normal input adapter. R is saved
          // for an already open window, then input stops to observe its expiry.
          final command = sawWindowHit
              ? const Phase0aPlayerCommand()
              : Phase0aPlayerCommand(
                  moveDirection: offset.length > typed.playerAdapter.attackRange
                      ? aim
                      : null,
                  attack: !vulnerable,
                  attackAimDirection: aim,
                  attackTargetId: bossId,
                  clear: vulnerable,
                );
          final emitted = typed.flow.advance(
            deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
            command: command,
          );
          events.addAll(emitted);
          legacyEvents.addAll(
            legacy.flow.advance(
              deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
              command: command,
            ),
          );
          expect(
            _canonicalState(typed.flow.state, typed),
            _canonicalState(legacy.flow.state, legacy),
          );
          expect(typed.flow.outcome, legacy.flow.outcome);
          final bossHit = emitted.whereType<Phase0aHitLanded>().any(
            (event) => event.target == bossId && event.resolvedDamage > 0,
          );
          final clearHit = emitted.whereType<Phase0aClearApplied>().any(
            (event) => event.outcomes.any(
              (outcome) =>
                  outcome.target == bossId && outcome.resolvedDamage > 0,
            ),
          );
          sawGuardedHit |= bossHit && !vulnerable;
          sawWindowHit |=
              clearHit &&
              vulnerable &&
              boss.posture!.vulnerabilityTicksRemaining > 1;
          sawRecovery =
              sawWindowHit &&
              typed.flow.state.enemies.any(
                (enemy) =>
                    enemy.id == bossId &&
                    enemy.isAlive &&
                    !(enemy.posture?.isVulnerable ?? false),
              );
        }
        expect(
          events.whereType<Phase0aPostureChanged>().where(
            (event) =>
                event.target == bossId &&
                event.eventType == PostureEventType.vulnerabilityEntered,
          ),
          isNotEmpty,
        );
        expect(sawGuardedHit, isTrue);
        expect(
          sawWindowHit,
          isTrue,
          reason: 'an observed window must also consume a real damaging action',
        );
        expect(sawRecovery, isTrue);
        expect(typed.flow.outcome, Phase0aBattleOutcome.ongoing);
        expect(_combatEvents(events), _combatEvents(legacyEvents));
        _expectObjectiveWaveSplit(
          contentId: typed.contentRef.contentId,
          typedFlow: typed.flow,
          typedEvents: events,
          legacyEvents: legacyEvents,
          terminal: false,
        );
      },
    );

    test(
      'authored guardian interception coop and phase windows retain behavior cycle $cycle',
      () async {
        final floor = repo.getTowerFloor(42);
        // Endurance fixture isolates mechanics without changing authored enemies,
        // skills, damage resolution or objectives. It is not a difficulty test.
        final player = testCombatantSnapshot(
          realmTier: RealmTier.wuSheng,
          maxHp: 20000,
          internalForce: 15000,
          totalEquipmentAttack: 2000,
          mainCultivationLayer: CultivationLayer.yuanMan,
          defenseRate: 0.9,
          includeProductionBasicAttack: true,
        );
        final typed = await createFreshPhase0aTowerCombatSession(
          Phase0aTowerCombatSessionBuildRequest(
            contentRef: const CombatContentRef.tower('tower_42'),
            floor: floor,
            playerSnapshot: player,
            numbers: repo.numbers,
            cycleIndex: cycle,
            rng: Random(20260911),
            routeAuthority: Phase0aTowerEncounterRouteAuthority.migratedFloors({
              42,
            }),
          ),
        );
        final legacy = await createFreshPhase0aTowerCombatSession(
          Phase0aTowerCombatSessionBuildRequest(
            contentRef: const CombatContentRef.tower('tower_42'),
            floor: floor,
            playerSnapshot: player,
            numbers: repo.numbers,
            cycleIndex: cycle,
            rng: Random(20260911),
            routeAuthority: Phase0aTowerEncounterRouteAuthority.migratedFloors(
              {},
            ),
          ),
        );
        final events = <Phase0aEvent>[];
        final legacyEvents = <Phase0aEvent>[];
        final bot = Phase0aPlayerBotAdapter(playerAdapter: typed.playerAdapter);
        var clearSent = false;
        while (typed.flow.outcome == Phase0aBattleOutcome.ongoing &&
            typed.flow.state.tick <
                repo.numbers.phase0aArena.maxSimulationTicks) {
          final state = typed.flow.state;
          final boss = state.enemies.firstWhere((e) => e.isBoss);
          final mechanicsSeen =
              events.whereType<Phase0aGuardianCoopStrike>().isNotEmpty &&
              events.whereType<Phase0aGuardIntercepted>().isNotEmpty;
          final clear = !clearSent && boss.chargingCast != null;
          if (clear) clearSent = true;
          final command = mechanicsSeen
              ? bot.commandFor(state)
              : Phase0aPlayerCommand(gather: state.tick == 0, clear: clear);
          events.addAll(
            typed.flow.advance(
              deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
              command: command,
            ),
          );
          legacyEvents.addAll(
            legacy.flow.advance(
              deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
              command: command,
            ),
          );
          expect(
            _canonicalState(typed.flow.state, typed),
            _canonicalState(legacy.flow.state, legacy),
          );
          expect(typed.flow.outcome, legacy.flow.outcome);
        }
        expect(events.whereType<Phase0aGuardIntercepted>(), isNotEmpty);
        expect(events.whereType<Phase0aGuardianCoopStrike>(), isNotEmpty);
        expect(events.whereType<Phase0aBossChargeStarted>(), isNotEmpty);
        expect(events.whereType<Phase0aBossPhaseChanged>(), hasLength(2));
        expect(events.whereType<Phase0aPostureChanged>(), isNotEmpty);
        expect(typed.flow.outcome, Phase0aBattleOutcome.victory);
        expect(typed.flow.state.enemies.where((e) => e.isAlive), isEmpty);
        expect(_combatEvents(events), _combatEvents(legacyEvents));
        _expectObjectiveWaveSplit(
          contentId: typed.contentRef.contentId,
          typedFlow: typed.flow,
          typedEvents: events,
          legacyEvents: legacyEvents,
          terminal: true,
        );
        expect(
          _settlement(
            typed.settle(
              outcome: typed.flow.outcome,
              finalState: typed.flow.state,
              events: events,
            ),
          ),
          _settlement(
            legacy.settle(
              outcome: legacy.flow.outcome,
              finalState: legacy.flow.state,
              events: legacyEvents,
            ),
          ),
        );
      },
    );
  }

  for (final invalid in ['survive', 'subset', 'any']) {
    testWidgets(
      'all real entries reject $invalid without callback reward or fallback',
      (tester) async {
        final floor = repo.getTowerFloor(42);
        final instant = _FactoryTrace(invalid: invalid);
        final beforeInstant = await tester.runAsync(_databaseFacts);
        await tester.runAsync(() async {
          await expectLater(
            _runner(repo, instant).runTower(
              floor: floor,
              cycleIndex: 1,
              request: _request(42, participantId),
            ),
            throwsStateError,
          );
        });
        expect(instant.calls, 1);
        expect(instant.session, isNull);
        expect(await tester.runAsync(_databaseFacts), beforeInstant);
        final player = instant.request!.playerSnapshot;

        final admission = (await tester.runAsync(
          () => _reopenedAdmission(floor, 1, participantId, temp),
        ))!;
        final before = await tester.runAsync(_databaseFacts);
        final durable = _FactoryTrace(invalid: invalid);
        await tester.runAsync(() async {
          await expectLater(
            _runner(
              repo,
              durable,
            ).runTowerDurable(floor: floor, admission: admission),
            throwsStateError,
          );
        });
        expect(durable.calls, 1);
        expect(durable.session, isNull);

        final visible = _FactoryTrace(invalid: invalid);
        var callbacks = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              phase0aTowerCombatSessionFactoryProvider.overrideWithValue(
                visible.create,
              ),
            ],
            child: MaterialApp(
              home: Phase0aTowerBattleHost(
                floor: floor,
                participantId: participantId,
                playerSnapshotForTest: player,
                cycleIndexForTest: 1,
                seedForTest: 1,
                onVictory: (_) => callbacks++,
                onDefeat: (_) => callbacks++,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(visible.calls, 1);
        expect(visible.session, isNull);
        expect(find.byType(Phase0aBattleScreen), findsNothing);
        final error = tester
            .widget<SelectableText>(find.byType(SelectableText))
            .data!;
        expect(error, contains('tower objective'));
        expect(
          error,
          startsWith(UiStrings.battleSetupFailed('').split('\n').first),
        );
        expect(callbacks, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
        expect(await tester.runAsync(_databaseFacts), before);
      },
    );
  }
}

Future<void> _cycle(int cycle) async {
  final progress = (await IsarSetup.instance.towerProgress
      .where()
      .findFirst())!;
  await IsarSetup.instance.writeTxn(() async {
    progress.currentCycleIndex = cycle;
    await IsarSetup.instance.towerProgress.put(progress);
  });
}

Future<DurableActivityAutomationAdmission> _reopenedAdmission(
  TowerFloorDef floor,
  int cycle,
  int participantId,
  Directory temp,
) async {
  final id = await DurableActivityAutomationService(IsarSetup.instance)
      .startTower(
        floor: floor,
        cycleIndex: cycle,
        request: towerDurableDispatchRequest(
          floorIndex: floor.floorIndex,
          characterId: participantId,
        ),
      );
  await IsarSetup.close();
  IsarSetup.resetForTest();
  await IsarSetup.init(directory: temp, inspector: false);
  return DurableActivityAutomationService(
    IsarSetup.instance,
  ).admitTower(runId: id, floor: floor);
}

Future<Map<String, Object?>> _databaseFacts() async {
  final isar = IsarSetup.instance;
  final facts = <String, Object?>{
    'SaveData': await isar.saveDatas.where().exportJson(),
    'Character': await isar.characters.where().exportJson(),
    'Equipment': await isar.equipments.where().exportJson(),
    'Technique': await isar.techniques.where().exportJson(),
    'InventoryItem': await isar.inventoryItems.where().exportJson(),
    'GameEvent': await isar.gameEvents.where().exportJson(),
    'MainlineProgress': await isar.mainlineProgress.where().exportJson(),
    'MainlineSettlementJournal': await isar.mainlineSettlementJournals
        .where()
        .exportJson(),
    'TowerProgress': await isar.towerProgress.where().exportJson(),
    'TowerPersonalRecord': await isar.towerPersonalRecords.where().exportJson(),
    'RetreatSession': await isar.retreatSessions.where().exportJson(),
    'EncounterProgress': await isar.encounterProgress.where().exportJson(),
    'Reputation': await isar.reputations.where().exportJson(),
    'NpcRelation': await isar.npcRelations.where().exportJson(),
    'Sect': await isar.sects.where().exportJson(),
    'SectEvent': await isar.sectEvents.where().exportJson(),
    'PvpRecord': await isar.pvpRecords.where().exportJson(),
    'PvpSnapshot': await isar.pvpSnapshots.where().exportJson(),
    'BossMemory': await isar.bossMemorys.where().exportJson(),
    'EquipmentCatalogEntry': await isar.equipmentCatalogEntrys
        .where()
        .exportJson(),
    'ExpeditionRun': await isar.expeditionRuns.where().exportJson(),
    'ExpeditionMilestoneRecord': await isar.expeditionMilestoneRecords
        .where()
        .exportJson(),
    'BossGauntletRun': await isar.bossGauntletRuns.where().exportJson(),
    'DurableActivityCombatRun': await isar.durableActivityCombatRuns
        .where()
        .exportJson(),
    'RewardClaimReceipt': await isar.rewardClaimReceipts.where().exportJson(),
    'ProgressiveUnlockReceipt': await isar.progressiveUnlockReceipts
        .where()
        .exportJson(),
  };
  expect(
    facts.keys.toSet(),
    IsarSetup.schemasForTesting.map((s) => s.name).toSet(),
  );
  return facts;
}

ActivityParticipationRequest _request(int floor, int participantId) =>
    ActivityParticipationRequest(
      contentId: towerAutomationContentId(floor),
      contentKind: ActivityContentKind.tower,
      characterId: participantId,
      loadoutPlanId: towerAutomationLoadoutPlanId(
        floorIndex: floor,
        characterId: participantId,
      ),
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.sweep,
    );

Phase0aSweepHeadlessRunner _runner(GameRepository repo, _FactoryTrace trace) =>
    Phase0aSweepHeadlessRunner(
      isar: IsarSetup.instance,
      numbers: repo.numbers,
      rng: Random(1),
      towerSessionFactory: trace.create,
      botPolicy: const Phase0aBotTacticPolicy.production(),
    );

final class _FactoryTrace {
  _FactoryTrace({this.invalid});
  final String? invalid;
  int calls = 0;
  Phase0aTowerCombatSessionBuildRequest? request;
  Phase0aTowerCombatSession? session;
  _TraceFlow? trace;
  Future<Phase0aTowerCombatSession> create(
    Phase0aTowerCombatSessionBuildRequest incoming,
  ) async {
    calls++;
    request = incoming;
    final built = await createFreshPhase0aTowerCombatSession(
      Phase0aTowerCombatSessionBuildRequest(
        contentRef: incoming.contentRef,
        floor: incoming.floor,
        playerSnapshot: incoming.playerSnapshot,
        numbers: incoming.numbers,
        cycleIndex: incoming.cycleIndex,
        rng: incoming.rng,
        // Migrated floors must use the authority supplied by the real entrypoint.
        // Later representative floors still exercise the opt-in parity fixture.
        routeAuthority: invalid == null && incoming.floor.floorIndex <= 7
            ? incoming.routeAuthority
            : Phase0aTowerEncounterRouteAuthority.migratedFloors({
                incoming.floor.floorIndex,
              }),
        definitionSource: invalid == null
            ? const Phase0aDerivedTowerEncounterDefinitionSource()
            : _InvalidObjectives(invalid!),
      ),
    );
    session = built;
    trace = _TraceFlow(built.flow);
    return Phase0aTowerCombatSession(
      contentRef: built.contentRef,
      routeMode: built.routeMode,
      flow: trace!,
      combatants: built.combatants,
      playerAdapter: built.playerAdapter,
      sourceEnemyDefIdByActorId: built.sourceEnemyDefIdByActorId,
      sourceEnemyDefIdsInEntryOrder: built.sourceEnemyDefIdsInEntryOrder,
      encounterCount: built.encounterCount,
      activeLimit: built.activeLimit,
      settle: built.settle,
    );
  }
}

final class _InvalidObjectives
    implements Phase0aTowerEncounterDefinitionSource {
  const _InvalidObjectives(this.kind);
  final String kind;
  @override
  CombatEncounterDef load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    final original = const Phase0aDerivedTowerEncounterDefinitionSource().load(
      contentRef: contentRef,
      floor: floor,
    );
    return CombatEncounterDef(
      id: original.id,
      spawnConfig: original.spawnConfig,
      tokenBudgets: original.tokenBudgets,
      spawnEntries: original.spawnEntries,
      objectives: CombatObjectiveCompositionRef(
        completionRule: kind == 'any'
            ? CombatObjectiveCompletionRule.any
            : CombatObjectiveCompletionRule.all,
        clauses: [
          CombatObjectiveClauseRef(
            id: 'invalid',
            primitive: kind == 'survive'
                ? CombatSurviveDurationRef(requiredTicks: 1)
                : CombatDefeatTargetsRef(
                    original.spawnEntries.take(1).map((e) => e.entryId),
                  ),
          ),
        ],
      ),
    );
  }
}

// This observer delegates every command unchanged to the production reducer.
final class _TraceFlow implements Phase0aBattleFlow {
  _TraceFlow(this.inner) : states = [inner.state];
  final Phase0aBattleFlow inner;
  final List<Phase0aArenaState> states;
  final events = <Phase0aEvent>[];
  @override
  Phase0aArenaState get state => inner.state;
  @override
  Phase0aBattleOutcome get outcome => inner.outcome;
  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      inner.lastOrderedEventRecords;
  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final emitted = inner.advance(deltaSeconds: deltaSeconds, command: command);
    states.add(inner.state);
    events.addAll(emitted);
    return emitted;
  }
}

void _expectTraceEqual(_FactoryTrace actual, _FactoryTrace expected) {
  expect(actual.trace!.states, expected.trace!.states);
  expect(actual.trace!.events, expected.trace!.events);
  expect(_combatants(actual.session!), _combatants(expected.session!));
  expect(
    actual.session!.sourceEnemyDefIdByActorId,
    expected.session!.sourceEnemyDefIdByActorId,
  );
}

List<Object?> _combatants(
  Phase0aTowerCombatSession session, {
  bool canonical = false,
}) => [
  for (final binding in session.combatants)
    [
      binding.actorId,
      _snapshot(
        canonical
            ? binding.snapshot.copyWith(
                guardianDefIds: _guardianIds(
                  binding.snapshot.guardianDefIds,
                  session,
                ),
              )
            : binding.snapshot,
      ),
    ],
];

// SkillDef is immutable and deliberately compared by exact object identity:
// matching ids alone could hide loss of power, timing, Qi or behavior fields.
List<Object?> _snapshot(CombatantSnapshot s) => [
  s.characterId,
  s.name,
  s.realmTier,
  s.realmLayer,
  s.school,
  s.maxHp,
  s.currentHp,
  s.internalForce,
  s.maxQi,
  s.currentQi,
  s.qiGainMultiplier,
  s.qiCostReductionPct,
  s.autoUltimate,
  s.speed,
  s.criticalRate,
  s.evasionRate,
  s.defenseRate,
  s.totalEquipmentAttack,
  s.mainCultivationLayer,
  s.weaponArchetype,
  s.skillLoadout.basicAttack,
  [for (final slot in CombatantSkillSlot.values) s.skillLoadout.skillFor(slot)],
  s.availableSkills,
  s.openingSkillCooldowns,
  s.skillUses,
  s.activeBuffs,
  s.swordSongResonanceActive,
  s.iconPath,
  s.attackPowerMultiplier,
  s.outputMultiplier,
  s.isBoss,
  s.chargeSkillId,
  s.bossPhases
      ?.map(
        (p) => [
          p.hpThresholdPct,
          p.unlockSkillIds,
          p.aiMode,
          p.onEnterMechanic,
          p.titleKey,
        ],
      )
      .toList(),
  s.bossPhaseUnlockSkills,
  s.schoolDamageTakenMult,
  s.lineageRole,
  s.forgingPiercePct,
  s.forgingLifestealPct,
  s.enemyDefId,
  s.guardianWardMult,
  s.guardianDefIds,
  s.vulnerabilityMult,
  s.guardInterceptsInterrupt,
];

List<Object?> _settlement(CombatSettlementSnapshot s) => [
  s.result,
  s.totalTicks,
  s.hadActions,
  s.playerCharacterId,
  [
    for (final p in s.participants) [p.characterId, p.currentHp, p.maxHp],
  ],
  [
    for (final c in s.skillCasts) [c.tick, c.characterId, c.skillId],
  ],
  s.totalDamage,
  s.criticalCount,
  s.damageByCharacterId,
];

// Legacy emits wave lifecycle records and carries source guardian ids; typed
// emits encounter objectives and carries exact runtime guardian ids. Normalize
// only these representational differences, retaining tick, actors and payloads.
List<Phase0aEvent> _combatEvents(List<Phase0aEvent> events) => [
  for (final e in events)
    if (e is! Phase0aWaveStarted && e is! Phase0aWaveCleared)
      _withoutSequence(e),
];

/// 目标层在两条路径上不对称，不能做 1:1 事件比对：legacy 用波次生命周期事件
/// 表达进度，typed 不发任何目标事件 —— 进度活在 objective controller 里，只有
/// 完成时才落 [Phase0aBattleVictory]。
///
/// [_combatEvents] 因此丢掉波次事件。丢弃本身没错，但「只丢不查」留下一个口子：
/// typed 若哪天也开始发波次事件，会被一并静默丢掉而无人发现。这里既断言丢弃所
/// 依赖的前提，也把两侧的进度语义做映射比对。
///
/// 映射口径（2026-09-12 实测塔第 1 层：clause 单条 `tower_1_defeat_all`）：
/// typed 侧读公开的 [Phase0aEncounterFlow.objectiveProgress]；legacy 侧没有目标层，
/// 用「WaveCleared 数是否追平 WaveStarted 数」代表同一件事（全波清空 = 全灭目标
/// 达成）。终局片段两侧必须都算达成，未终局片段两侧必须都算未达成。
///
/// clause 形状按生产公式精确钉住：塔的默认派生定义只产一条
/// `<contentId>_defeat_all`（见 phase0a_tower_encounter_host.dart 的 objectives），
/// 所以这里直接比对 clause id 列表，改名或拆成多条都必须红。上一版只断言
/// 「列表非空 + 每个 id 非空」，改名和拆条都能过，而注释却声称钉住了 —— 那是
/// 假绿，已由外部侦察的负对照复现后修正。
///
/// 终局再把 satisfied 集与实际 [Phase0aEnemyDefeated] 事件数交叉核对：目标声称
/// 达成的目标数必须等于本场真正死掉的敌人数，且每个 satisfied id 都落在
/// `<contentId>_entry_` 命名下。legacy 侧没有 entry 概念，这一层只能这样自证，
/// 但它咬得住「目标集合被换掉」和「少杀一个也算达成」。
void _expectObjectiveWaveSplit({
  required String contentId,
  required Phase0aBattleFlow typedFlow,
  required List<Phase0aEvent> typedEvents,
  required List<Phase0aEvent> legacyEvents,
  required bool terminal,
}) {
  expect(
    typedEvents.where(
      (e) => e is Phase0aWaveStarted || e is Phase0aWaveCleared,
    ),
    isEmpty,
    reason: 'typed 不应发波次事件；一旦开始发会被 _combatEvents 静默丢掉',
  );
  final legacyStarts = legacyEvents.whereType<Phase0aWaveStarted>().toList();
  final legacyClears = legacyEvents.whereType<Phase0aWaveCleared>().toList();
  expect(legacyStarts, isNotEmpty, reason: 'legacy 侧被丢弃的波次事件必须确实存在，否则这层丢弃是空操作');

  // —— typed 目标进度：公开 getter，非 null 才谈得上比对 ——
  expect(typedFlow, isA<Phase0aEncounterFlow>());
  final progress = (typedFlow as Phase0aEncounterFlow).objectiveProgress;
  expect(
    progress,
    isNotNull,
    reason: 'typed 的 objectiveProgress 为 null 说明目标层没接上，映射比对无意义',
  );
  expect(
    progress!.clauses.map((c) => c.id).toList(),
    ['${contentId}_defeat_all'],
    reason:
        '塔的默认派生目标必须恰好一条 defeat-all clause；'
        '改名或拆条都要在这里红，不能只检查 id 非空',
  );

  // —— 映射比对：typed 目标达成 ⇔ legacy 全波清空 ——
  final legacyAllWavesCleared = legacyClears.length == legacyStarts.length;
  expect(
    progress.completed,
    legacyAllWavesCleared,
    reason:
        'typed 目标达成=${progress.completed} 与 legacy 全波清空'
        '=$legacyAllWavesCleared 不一致（started=${legacyStarts.length} '
        'cleared=${legacyClears.length}）',
  );
  expect(
    progress.completed,
    terminal,
    reason: '终局片段=$terminal，typed 目标达成必须与之一致',
  );

  if (!terminal) return;
  final typedVictories = typedEvents.whereType<Phase0aBattleVictory>().toList();
  final legacyVictories = legacyEvents
      .whereType<Phase0aBattleVictory>()
      .toList();
  expect(
    typedVictories,
    hasLength(1),
    reason: 'typed 的 victory 由目标完成驱动，终局片段必须恰好一次',
  );
  expect(legacyVictories, hasLength(1));
  expect(typedVictories.single.tick, legacyVictories.single.tick);
  // legacy 的波次在 victory 当拍或更早清完；晚于 victory 说明两侧终局语义错位。
  expect(legacyClears, isNotEmpty, reason: 'legacy 终局片段必须清过波次');
  expect(
    legacyClears.last.tick,
    lessThanOrEqualTo(legacyVictories.single.tick),
  );

  // satisfied 集 x 实际击杀事件：少杀一个也算达成，或目标集合被换掉，都在这里红。
  final satisfied = progress.clauses.single.progress.satisfied;
  final typedDefeats = typedEvents.whereType<Phase0aEnemyDefeated>().length;
  final legacyDefeats = legacyEvents.whereType<Phase0aEnemyDefeated>().length;
  expect(typedDefeats, legacyDefeats);
  expect(
    satisfied,
    hasLength(typedDefeats),
    reason:
        '目标声称达成 ${satisfied.length} 个，实际击杀 $typedDefeats 个敌人，'
        '两者必须一致',
  );
  expect(
    satisfied,
    everyElement(startsWith('${contentId}_entry_')),
    reason: 'satisfied 必须是本内容的 entry id，命名漂移要在这里红',
  );
}

Phase0aEvent _withoutSequence(Phase0aEvent e) => switch (e) {
  Phase0aActionTimelineChanged() => Phase0aActionTimelineChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    actionId: e.actionId,
    eventType: e.eventType,
    phase: e.phase,
    actionTick: e.actionTick,
  ),
  Phase0aQiChanged() => Phase0aQiChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    actionId: e.actionId,
    reason: e.reason,
    applied: e.applied,
    overflow: e.overflow,
    current: e.current,
    windowId: e.windowId,
  ),
  Phase0aAttackStarted() => Phase0aAttackStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    moveKind: e.moveKind,
    basicAttackSegment: e.basicAttackSegment,
    weaponArchetype: e.weaponArchetype,
    visualSchool: e.visualSchool,
  ),
  Phase0aHitLanded() => Phase0aHitLanded(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    moveKind: e.moveKind,
    isCritical: e.isCritical,
    isUltimate: e.isUltimate,
    resolvedDamage: e.resolvedDamage,
    remainingHealth: e.remainingHealth,
    actorPosition: e.actorPosition,
    targetPosition: e.targetPosition,
    basicAttackSegment: e.basicAttackSegment,
    weaponArchetype: e.weaponArchetype,
    visualSchool: e.visualSchool,
  ),
  Phase0aDefendedEntityHit() => Phase0aDefendedEntityHit(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    resolvedDamage: e.resolvedDamage,
    remainingDurability: e.remainingDurability,
    actorPosition: e.actorPosition,
    targetPosition: e.targetPosition,
  ),
  Phase0aDefendedEntityDestroyed() => Phase0aDefendedEntityDestroyed(
    seq: 0,
    tick: e.tick,
    target: e.target,
    targetPosition: e.targetPosition,
  ),
  Phase0aStatusDamageApplied() => Phase0aStatusDamageApplied(
    seq: 0,
    tick: e.tick,
    source: e.source,
    target: e.target,
    statusType: e.statusType,
    resolvedDamage: e.resolvedDamage,
    remainingHealth: e.remainingHealth,
    targetPosition: e.targetPosition,
  ),
  Phase0aEnemyDefeated() => Phase0aEnemyDefeated(
    seq: 0,
    tick: e.tick,
    target: e.target,
    defeatKind: e.defeatKind,
    targetPosition: e.targetPosition,
  ),
  Phase0aBossPhaseChanged() => Phase0aBossPhaseChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    phaseIndex: e.phaseIndex,
    unlockedSkillIds: e.unlockedSkillIds,
  ),
  Phase0aBossChargeStarted() => Phase0aBossChargeStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    chargeTicks: e.chargeTicks,
  ),
  Phase0aGuardianCoopStrike() => Phase0aGuardianCoopStrike(
    seq: 0,
    tick: e.tick,
    mainGuardian: e.mainGuardian,
    partner: e.partner,
    boss: e.boss,
    target: e.target,
    mainGuardianDamage: e.mainGuardianDamage,
    mainGuardianCritical: e.mainGuardianCritical,
    totalDamage: e.totalDamage,
    mainGuardianPosition: e.mainGuardianPosition,
    partnerPosition: e.partnerPosition,
    bossPosition: e.bossPosition,
    targetPosition: e.targetPosition,
  ),
  Phase0aGuardIntercepted() => Phase0aGuardIntercepted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    boss: e.boss,
    guardian: e.guardian,
    skillId: e.skillId,
    resolvedDamage: e.resolvedDamage,
    bossPosition: e.bossPosition,
    guardianPosition: e.guardianPosition,
  ),
  Phase0aPostureChanged() => Phase0aPostureChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    eventType: e.eventType,
    amount: e.amount,
    accumulated: e.accumulated,
    capacity: e.capacity,
    vulnerabilityTicksRemaining: e.vulnerabilityTicksRemaining,
    hitKind: e.hitKind,
    targetPosition: e.targetPosition,
  ),
  Phase0aEnemySkillStarted() => Phase0aEnemySkillStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
  ),
  Phase0aGatherStarted() => Phase0aGatherStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    actorPosition: e.actorPosition,
    centerPosition: e.centerPosition,
  ),
  Phase0aGatherApplied() => Phase0aGatherApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    outcomes: e.outcomes,
  ),
  Phase0aClearStarted() => Phase0aClearStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    actorPosition: e.actorPosition,
  ),
  Phase0aClearApplied() => Phase0aClearApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    outcomes: e.outcomes,
  ),
  Phase0aSkillStarted() => Phase0aSkillStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    hotkey: e.hotkey,
    skillId: e.skillId,
  ),
  Phase0aSkillApplied() => Phase0aSkillApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    hotkey: e.hotkey,
    skillId: e.skillId,
    outcomes: e.outcomes,
  ),
  Phase0aSkillAvailabilityChanged() => Phase0aSkillAvailabilityChanged(
    seq: 0,
    tick: e.tick,
    slot: e.slot,
    availability: e.availability,
    cooldownRemaining: e.cooldownRemaining,
    qiCurrent: e.qiCurrent,
    qiRequired: e.qiRequired,
  ),
  Phase0aWaveStarted() => Phase0aWaveStarted(
    seq: 0,
    tick: e.tick,
    waveIndex: e.waveIndex,
    waveTotal: e.waveTotal,
  ),
  Phase0aWaveCleared() => Phase0aWaveCleared(
    seq: 0,
    tick: e.tick,
    waveIndex: e.waveIndex,
  ),
  Phase0aSpawnWarningStarted() => Phase0aSpawnWarningStarted(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aEnemyEntered() => Phase0aEnemyEntered(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aSpawnGraceExpired() => Phase0aSpawnGraceExpired(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aBattleVictory() => Phase0aBattleVictory(seq: 0, tick: e.tick),
  Phase0aBattleDefeat() => Phase0aBattleDefeat(seq: 0, tick: e.tick),
  Phase0aDefenseStarted() => Phase0aDefenseStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    action: e.action,
    fromPosition: e.fromPosition,
    toPosition: e.toPosition,
    windowTicks: e.windowTicks,
    shieldAbsorption: e.shieldAbsorption,
  ),
  Phase0aDefenseResolved() => Phase0aDefenseResolved(
    seq: 0,
    tick: e.tick,
    attackId: e.attackId,
    attacker: e.attacker,
    target: e.target,
    branch: e.branch,
    incomingDamage: e.incomingDamage,
    counterDamage: e.counterDamage,
    shieldRemaining: e.shieldRemaining,
    nonRecursive: e.nonRecursive,
    targetPosition: e.targetPosition,
  ),
};

List<String> _guardianIds(
  List<String> ids,
  Phase0aTowerCombatSession session,
) => [
  for (final id in ids)
    session.sourceEnemyDefIdByActorId.containsKey(id)
        ? id
        : session.sourceEnemyDefIdByActorId.entries
              .singleWhere((e) => e.value == id)
              .key,
];
Phase0aArenaState _canonicalState(
  Phase0aArenaState s,
  Phase0aTowerCombatSession session,
) => Phase0aArenaState(
  tick: s.tick,
  nextSeq: 0,
  player: s.player,
  enemies: [for (final a in s.enemies) _canonicalActor(a, session)],
  skillSlots: s.skillSlots,
  defendedEntity: s.defendedEntity,
  winCondition: s.winCondition,
);
Phase0aActor _canonicalActor(
  Phase0aActor a,
  Phase0aTowerCombatSession session,
) => Phase0aActor(
  id: a.id,
  side: a.side,
  position: a.position,
  facing: a.facing,
  maxHealth: a.maxHealth,
  currentHealth: a.currentHealth,
  moveSpeed: a.moveSpeed,
  qiCurrent: a.qiCurrent,
  qiMax: a.qiMax,
  attackCooldownRemaining: a.attackCooldownRemaining,
  defeatKind: a.defeatKind,
  isBoss: a.isBoss,
  autoUltimate: a.autoUltimate,
  bossPhases: a.bossPhases,
  bossPhaseIndex: a.bossPhaseIndex,
  unlockedEnemySkillIds: a.unlockedEnemySkillIds,
  enemySkillCooldowns: a.enemySkillCooldowns,
  chargeCast: a.chargeCast,
  phaseChargeCasts: a.phaseChargeCasts,
  staggerTicksTotal: a.staggerTicksTotal,
  guardianDefIds: _guardianIds(a.guardianDefIds, session),
  guardianWardMult: a.guardianWardMult,
  guardInterceptsInterrupt: a.guardInterceptsInterrupt,
  guardianCoopUsedInCharge: a.guardianCoopUsedInCharge,
  vulnerabilityMult: a.vulnerabilityMult,
  chargingCast: a.chargingCast,
  chargingDefenseFlags: a.chargingDefenseFlags,
  chargeTicksRemaining: a.chargeTicksRemaining,
  staggerTicksRemaining: a.staggerTicksRemaining,
  gatherControlTicksRemaining: a.gatherControlTicksRemaining,
  posture: a.posture,
  shieldRemaining: a.shieldRemaining,
  shieldTicksRemaining: a.shieldTicksRemaining,
  parryTicksRemaining: a.parryTicksRemaining,
  dodgeTicksRemaining: a.dodgeTicksRemaining,
  defenseCooldownRemaining: a.defenseCooldownRemaining,
  parryCounterDamage: a.parryCounterDamage,
  parryCounterBudgetRemaining: a.parryCounterBudgetRemaining,
  statusLedger: a.statusLedger,
  basicAttackSegmentIndex: a.basicAttackSegmentIndex,
  basicAction: a.basicAction,
  qiLedger: a.qiLedger,
  killQiGain: a.killQiGain,
  killQiWindowCap: a.killQiWindowCap,
  qiWindowSerial: a.qiWindowSerial,
);
