import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/action_timeline.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_factory.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_service.dart';
import 'package:wuxia_idle/features/sweep/application/phase0a_sweep_headless_runner.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/isar_test_support.dart';
import '../../../../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });

  for (final (weapon, delay, gain) in const [
    (WeaponArchetype.sword, 1, 20),
    (WeaponArchetype.heavy, 2, 24),
    (WeaponArchetype.flexible, 1, 22),
    (WeaponArchetype.dual, 0, 18),
    (WeaponArchetype.hidden, 0, 18),
  ]) {
    test(
      '${weapon.name}: actual tower factory retains one delayed basic effect',
      () async {
        final tower = await _tower(repo, _player(repo, weapon), 812);
        final flow = tower.flow;
        final delta = repo.numbers.phase0aArena.fixedDeltaSeconds;
        for (var tick = 0; tick < 200; tick++) {
          final enemy = flow.state.enemies.first;
          if ((enemy.position - flow.state.player.position).length <=
              tower.playerAdapter.attackRange * 0.8) {
            break;
          }
          flow.advance(
            deltaSeconds: delta,
            command: Phase0aPlayerCommand(
              moveDirection: enemy.position - flow.state.player.position,
            ),
          );
        }
        final before = flow.state;
        final target = before.enemies.first;
        final events = <Phase0aEvent>[];
        for (var tick = 0; tick <= delay; tick++) {
          events.addAll(
            flow.advance(
              deltaSeconds: delta,
              command: Phase0aPlayerCommand(
                attack: tick == 0,
                attackTargetId: target.id,
                attackAimDirection: target.position - before.player.position,
              ),
            ),
          );
        }
        final hits = events
            .whereType<Phase0aHitLanded>()
            .where((e) => e.actor == before.player.id)
            .toList();
        final firstEffect = events
            .whereType<Phase0aActionTimelineChanged>()
            .singleWhere(
              (e) => e.eventType == ActionTimelineEventType.firstEffect,
            );
        expect(firstEffect.tick - (before.tick + 1), delay);
        final basicQi = events.whereType<Phase0aQiChanged>().singleWhere(
          (e) => e.reason == Phase0aQiChangeReason.basic,
        );
        expect(basicQi.tick, firstEffect.tick);
        expect(basicQi.applied, gain);
        // firstEffect is the real attack judgment, including a legal miss.
        expect(hits.length, lessThanOrEqualTo(1));
        expect(hits.map((e) => e.tick), everyElement(firstEffect.tick));
        expect(
          events.whereType<Phase0aAttackStarted>().where(
            (e) => e.actor == before.player.id,
          ),
          hasLength(1),
        );
        expect(flow.state.player.position, before.player.position);
        final kills = events.whereType<Phase0aEnemyDefeated>().length;
        expect(
          flow.state.player.qiCurrent - before.player.qiCurrent,
          gain + min(kills * 5, 15),
        );
      },
    );
  }

  test(
    'real session fork preserves in-flight action and immutable qi ledger',
    () {
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: _player(repo, WeaponArchetype.heavy),
        numbers: repo.numbers,
      );
      Phase0aCombatSession create() {
        final bundle = Phase0aBattleSnapshotFactory(numbers: repo.numbers)
            .create(
              combatants: mapping.combatants,
              moveBindings: mapping.moveBindings,
            );
        final damage = Phase0aDamageCalculatorAdapter(
          combatants: bundle.combatants,
          moveBindings: bundle.moveBindings,
          numbers: repo.numbers,
          rng: Random(334),
        );
        return Phase0aCombatSession(
          initialState: mapping.initialState,
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
          damageResolver: damage,
          enemySkillDamageResolver: damage,
        );
      }

      final original = create();
      var rebuilt = create();
      final delta = repo.numbers.phase0aArena.fixedDeltaSeconds;
      const input = Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: ArenaVector(-1, 0),
      );
      expect(
        rebuilt.advance(deltaSeconds: delta, command: input),
        original.advance(deltaSeconds: delta, command: input),
      );
      final checkpoint = rebuilt.state;
      expect(checkpoint.player.basicAction, isNotNull);
      expect(checkpoint.player.qiCurrent, 0);
      rebuilt = rebuilt.forkWithState(checkpoint);
      expect(rebuilt.state, checkpoint);
      for (var tick = 0; tick < 12; tick++) {
        expect(
          rebuilt.advance(
            deltaSeconds: delta,
            command: const Phase0aPlayerCommand(),
          ),
          original.advance(
            deltaSeconds: delta,
            command: const Phase0aPlayerCommand(),
          ),
        );
        expect(rebuilt.state, original.state);
      }
      expect(rebuilt.state.player.qiCurrent, 24);
      expect(checkpoint.player.qiCurrent, 0);
      expect(
        checkpoint.player.qiLedger!.gainActionIds,
        isEmpty,
        reason: 'later grants must not mutate the saved immutable state',
      );
    },
  );

  test(
    'real wave transition opens a new kill window and preserves ledger history',
    () {
      final mapping = Phase0aStageContentMapper.mapMainline(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: _player(repo, WeaponArchetype.dual),
        numbers: repo.numbers,
      );
      expect(mapping.waves.length, greaterThan(1));
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: repo.numbers,
        rng: Random(42),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
        waveTransitionPolicy: mapping.waveTransitionPolicy,
      );
      final bot = Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter);
      final starts = <Phase0aWaveStarted>[];
      while (flow.outcome == Phase0aBattleOutcome.ongoing &&
          flow.state.tick < repo.numbers.phase0aArena.maxSimulationTicks) {
        final beforeSerial = flow.state.player.qiWindowSerial;
        final events = flow.advance(
          deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
          command: bot.commandFor(flow.state),
        );
        final nextWaves = events.whereType<Phase0aWaveStarted>().toList();
        starts.addAll(nextWaves);
        expect(
          flow.state.player.qiWindowSerial,
          beforeSerial + nextWaves.where((e) => e.waveIndex > 1).length,
        );
        expect(
          flow.state.player.qiLedger!.windowGains.values,
          everyElement(lessThanOrEqualTo(15)),
        );
      }
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(starts, hasLength(mapping.waves.length));
      expect(flow.state.player.qiWindowSerial, mapping.waves.length - 1);
      expect(
        flow.state.player.qiLedger!.windowGains.values.fold(0, (a, b) => a + b),
        greaterThan(15),
        reason: 'later real waves must earn their own kill budget',
      );
      final terminal = flow.state;
      expect(
        flow.advance(
          deltaSeconds: 1,
          command: const Phase0aPlayerCommand(attack: true),
        ),
        isEmpty,
      );
      expect(
        flow.state,
        terminal,
        reason: 'terminal replay cannot grant qi again',
      );
    },
  );

  test(
    'dual held basic preserves six ticks across two real wave boundaries',
    () {
      final mapping = Phase0aStageContentMapper.mapMainline(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: _player(repo, WeaponArchetype.dual),
        numbers: repo.numbers,
      );
      expect(mapping.waves.length, greaterThanOrEqualTo(3));
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: repo.numbers,
        rng: Random(42),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
        waveTransitionPolicy: mapping.waveTransitionPolicy,
      );
      final events = <Phase0aEvent>[];
      while (flow.outcome == Phase0aBattleOutcome.ongoing &&
          flow.state.tick < repo.numbers.phase0aArena.maxSimulationTicks) {
        final state = flow.state;
        final enemies = state.enemies.toList()
          ..sort(
            (a, b) => (a.position - state.player.position).lengthSquared
                .compareTo((b.position - state.player.position).lengthSquared),
          );
        final target = enemies.first;
        final direction = target.position - state.player.position;
        final emitted = flow.advance(
          deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
          command: Phase0aPlayerCommand(
            attack: true,
            attackTargetId: target.id,
            attackAimDirection: direction,
            moveDirection:
                direction.length > mapping.playerAdapter.attackRange * 0.8
                ? direction
                : null,
          ),
        );
        events.addAll(emitted);
        if (emitted.whereType<Phase0aWaveStarted>().any(
          (e) => e.waveIndex > 1,
        )) {
          expect(
            flow.state.player.basicAction,
            isNotNull,
            reason:
                'wave replacement must preserve the clearing attack recovery',
          );
        }
      }
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      final starts = events
          .whereType<Phase0aAttackStarted>()
          .where((e) => e.actor == flow.state.player.id)
          .toList();
      final boundaries = events
          .whereType<Phase0aWaveStarted>()
          .where((e) => e.waveIndex > 1)
          .take(2)
          .toList();
      expect(boundaries, hasLength(2));
      for (final boundary in boundaries) {
        final clearingAttack = starts.lastWhere((e) => e.tick <= boundary.tick);
        final nextAttack = starts.firstWhere((e) => e.tick > boundary.tick);
        expect(
          clearingAttack.tick,
          boundary.tick,
          reason: 'dual firstEffect kills the last enemy on the accepted tick',
        );
        expect(nextAttack.tick - clearingAttack.tick, 6);
      }
      final hits = events
          .whereType<Phase0aHitLanded>()
          .where((e) => e.actor == flow.state.player.id)
          .toList();
      expect(hits.map((e) => e.remainingHealth), everyElement(0));
      expect(
        hits.length,
        mapping.waves.fold(0, (n, wave) => n + wave.enemies.length),
      );
      expect(hits.map((e) => e.tick).toSet(), hasLength(hits.length));
    },
  );

  group('durable production tower replay', () {
    late Directory temp;
    late int participantId;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('phase0a_m0_durable_');
      await IsarSetup.init(directory: temp, inspector: false);
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final isar = IsarSetup.instance;
      participantId = (await isar.characters.where().findFirst())!.id;
      await isar.writeTxn(() async {
        final save = (await isar.saveDatas.get(0))!;
        save
          ..founderCharacterId = participantId
          ..activeCharacterIds = [participantId];
        await isar.saveDatas.put(save);
        await isar.towerProgress.put(
          TowerProgress()
            ..saveDataId = save.slotId
            ..highestClearedFloor = repo.towerMaxFloor
            ..currentCycleIndex = 1
            ..maxClearedCycle = 1
            ..createdAt = DateTime(2026, 9, 11),
        );
      });
      final weapon = EquipmentFactory.fromDef(
        repo.getEquipment('weapon_xunchang_tie_jian'),
        rng: DefaultRng(seed: 901),
        obtainedAt: DateTime(2026, 9, 11),
        obtainedFrom: 'M0 temporary fixture',
      );
      await isar.writeTxn(() => isar.equipments.put(weapon));
      expect(
        await EquipmentService(
          isar: isar,
        ).equip(characterId: participantId, equipmentId: weapon.id),
        EquipOutcome.success,
      );
    });
    tearDown(() async {
      await IsarSetup.close();
      IsarSetup.resetForTest();
      await temp.delete(recursive: true);
    });

    test(
      'reopened Isar admission uses identical live/durable qi and action histories',
      () async {
        final floor = repo.getTowerFloor(1);
        final runId = await DurableActivityAutomationService(IsarSetup.instance)
            .startTower(
              floor: floor,
              cycleIndex: 1,
              request: towerDurableDispatchRequest(
                floorIndex: 1,
                characterId: participantId,
              ),
            );
        Future<DurableActivityAutomationAdmission> reopen() async {
          await IsarSetup.close();
          IsarSetup.resetForTest();
          await IsarSetup.init(directory: temp, inspector: false);
          return DurableActivityAutomationService(
            IsarSetup.instance,
          ).admitTower(runId: runId, floor: floor);
        }

        final admission = await reopen();
        expect(admission.snapshot.weaponArchetype, WeaponArchetype.sword);
        final traces = <_TraceFlow>[];
        Future<Phase0aTowerCombatSession> traced(
          Phase0aTowerCombatSessionBuildRequest request,
        ) async {
          final built = await createFreshPhase0aTowerCombatSession(request);
          final trace = _TraceFlow(built.flow);
          traces.add(trace);
          return Phase0aTowerCombatSession(
            contentRef: built.contentRef,
            routeMode: built.routeMode,
            flow: trace,
            combatants: built.combatants,
            playerAdapter: built.playerAdapter,
            sourceEnemyDefIdByActorId: built.sourceEnemyDefIdByActorId,
            sourceEnemyDefIdsInEntryOrder: built.sourceEnemyDefIdsInEntryOrder,
            encounterCount: built.encounterCount,
            activeLimit: built.activeLimit,
            settle: built.settle,
          );
        }

        Future<void> durable(DurableActivityAutomationAdmission current) async {
          final result = await Phase0aSweepHeadlessRunner(
            isar: IsarSetup.instance,
            numbers: repo.numbers,
            rng: Random(current.run.seed),
            botPolicy: const Phase0aBotTacticPolicy.production(),
            towerSessionFactory: traced,
          ).runTowerDurable(floor: floor, admission: current);
          expect(result.timedOut, isFalse);
          expect(result.settlement, isNotNull);
        }

        await durable(admission);
        final live = await _tower(repo, admission.snapshot, admission.run.seed);
        final controller = Phase0aBattleController(
          flow: live.flow,
          roster: Phase0aVisualRoster(visuals: const {}),
          fixedDeltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
        );
        addTearDown(controller.dispose);
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: live.playerAdapter,
          policy: const Phase0aBotTacticPolicy.production(),
        );
        while (controller.outcome == Phase0aBattleOutcome.ongoing &&
            controller.state.tick <
                repo.numbers.phase0aArena.maxSimulationTicks) {
          controller.step(bot.commandFor(controller.state));
        }
        expect(controller.events, traces.single.events);
        expect(controller.state, traces.single.state);
        expect(controller.state.player.qiLedger, isNotNull);
        expect(
          controller.events.whereType<Phase0aAttackStarted>().where(
            (e) => e.actor == controller.state.player.id,
          ),
          isNotEmpty,
        );
        await durable(await reopen());
        expect(traces[1].states, traces[0].states);
        expect(traces[1].events, traces[0].events);
        expect(
          traces[1].state.player.qiLedger,
          traces[0].state.player.qiLedger,
        );
      },
    );
  });
}

CombatantSnapshot _player(GameRepository repo, WeaponArchetype weapon) =>
    testCombatantSnapshot(
      maxHp: 20000,
      internalForce: 15000,
      totalEquipmentAttack: 2000,
      currentQi: 0,
      defenseRate: repo.numbers.cycleEvolution.defenseRateCap,
      weaponArchetype: weapon,
      includeProductionBasicAttack: true,
    );

Future<Phase0aTowerCombatSession> _tower(
  GameRepository repo,
  CombatantSnapshot player,
  int seed,
) => createFreshPhase0aTowerCombatSession(
  Phase0aTowerCombatSessionBuildRequest(
    contentRef: const CombatContentRef.tower('tower_1'),
    floor: repo.getTowerFloor(1),
    playerSnapshot: player,
    numbers: repo.numbers,
    cycleIndex: 1,
    rng: Random(seed),
  ),
);

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
