// Approved M0 production regression; semantic assertions always run.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/action_timeline.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

// Approved B/C values and the M3 coexistence mapping are external contracts.
const _firstEffectTicks = <WeaponArchetype, int>{
  WeaponArchetype.sword: 1,
  WeaponArchetype.heavy: 2,
  WeaponArchetype.flexible: 1,
  WeaponArchetype.dual: 0,
  WeaponArchetype.hidden: 0,
};
const _basicGains = <WeaponArchetype, int>{
  WeaponArchetype.sword: 20,
  WeaponArchetype.heavy: 24,
  WeaponArchetype.flexible: 22,
  WeaponArchetype.dual: 18,
  WeaponArchetype.hidden: 18,
};

const _intervalTicks = <WeaponArchetype, int>{
  WeaponArchetype.sword: 6,
  WeaponArchetype.heavy: 8,
  WeaponArchetype.flexible: 7,
  WeaponArchetype.dual: 6,
  WeaponArchetype.hidden: 6,
};

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());
  tearDownAll(GameRepository.resetForTest);

  for (final weapon in WeaponArchetype.values) {
    test(
      '${weapon.name}: actual production first effect and qi evidence',
      () async {
        final host = await _host(repository, weapon, openingQi: 0);
        await _approach(repository, host);
        final before = host.flow.state;
        final target = _nearest(host);
        final inputTick = before.tick + 1;
        final emitted = <Phase0aEvent>[];
        // Exactly one request; the real session must retain a delayed action.
        emitted.addAll(
          host.advanceManual(
            deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
            command: Phase0aPlayerCommand(
              attack: true,
              attackAimDirection: target.position - before.player.position,
              attackTargetId: target.id,
            ),
          ),
        );
        for (var index = 0; index < _firstEffectTicks[weapon]!; index++) {
          emitted.addAll(
            host.advanceManual(
              deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
              command: const Phase0aPlayerCommand(),
            ),
          );
        }
        final attacks = emitted
            .whereType<Phase0aAttackStarted>()
            .where((event) => event.actor == before.player.id)
            .toList();
        final hits = emitted
            .whereType<Phase0aHitLanded>()
            .where((event) => event.actor == before.player.id)
            .toList();
        final defeats = emitted.whereType<Phase0aEnemyDefeated>().length;
        expect(attacks, hasLength(1));
        expect(hits, hasLength(1));
        expect(attacks.single.weaponArchetype, weapon);
        expect(attacks.single.basicAttackSegment, isNull);
        expect(host.flow.state.player.position, before.player.position);
        final gained =
            host.flow.state.player.qiCurrent - before.player.qiCurrent;
        final basicQi = emitted
            .whereType<Phase0aQiChanged>()
            .where((e) => e.reason == Phase0aQiChangeReason.basic)
            .single;
        expect(basicQi.tick, hits.single.tick);
        expect(basicQi.applied, _basicGains[weapon]);
        final delay = hits.single.tick - inputTick;
        final expectedGain = _basicGains[weapon]! + math.min(defeats * 5, 15);
        print(
          'M0_PROBE ${jsonEncode({'weapon': weapon.name, 'inputTick': inputTick, 'effectTick': hits.single.tick, 'effectDelayTicks': delay, 'selectedEffectDelayTicks': _firstEffectTicks[weapon], 'qiGained': gained, 'selectedBasicAndKillGain': expectedGain, 'defeats': defeats, 'mappedBasicCooldownSeconds': host.mapping!.playerAdapter.attackCooldownSeconds, 'timelineMatches': delay == _firstEffectTicks[weapon], 'qiMatches': gained == expectedGain})}',
        );
        expect([delay, gained], [_firstEffectTicks[weapon], expectedGain]);
      },
    );

    test(
      '${weapon.name}: holding attack uses max timeline and M3 cooldown',
      () async {
        final host = await _host(repository, weapon, openingQi: 0);
        await _approach(repository, host);
        final position = host.flow.state.player.position;
        final starts = <Phase0aAttackStarted>[];
        for (var tick = 0; tick < 40; tick++) {
          final target = host.flow.state.enemies.isEmpty
              ? null
              : _nearest(host);
          final events = host.advanceManual(
            deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
            command: Phase0aPlayerCommand(
              attack: true,
              attackAimDirection: target == null
                  ? const ArenaVector(1, 0)
                  : target.position - host.flow.state.player.position,
              attackTargetId: target?.id,
            ),
          );
          starts.addAll(
            events.whereType<Phase0aAttackStarted>().where(
              (e) => e.actor == host.flow.state.player.id,
            ),
          );
          expect(host.flow.state.player.position, position);
        }
        expect(starts.length, greaterThanOrEqualTo(5));
        expect([
          for (var i = 1; i < 5; i++) starts[i].tick - starts[i - 1].tick,
        ], everyElement(_intervalTicks[weapon]));
      },
    );

    test(
      '${weapon.name}: one empty swing earns qi once after release',
      () async {
        final host = await _host(repository, weapon, openingQi: 0);
        final events = <Phase0aEvent>[];
        for (var tick = 0; tick < 12; tick++) {
          events.addAll(
            host.advanceManual(
              deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
              command: Phase0aPlayerCommand(
                attack: tick == 0,
                attackAimDirection: const ArenaVector(-1, 0),
                moveDirection: tick == 1 ? const ArenaVector(0, 1) : null,
              ),
            ),
          );
        }
        final playerId = host.flow.state.player.id;
        expect(
          events.whereType<Phase0aAttackStarted>().where(
            (e) => e.actor == playerId,
          ),
          hasLength(1),
        );
        expect(
          events.whereType<Phase0aHitLanded>().where(
            (e) => e.actor == playerId,
          ),
          isEmpty,
        );
        expect(events.whereType<Phase0aEnemyDefeated>(), isEmpty);
        expect(host.flow.state.player.qiCurrent, _basicGains[weapon]);
        expect(
          events.whereType<Phase0aQiChanged>().where(
            (e) => e.reason == Phase0aQiChangeReason.basic,
          ),
          hasLength(1),
        );
        expect(
          events.whereType<Phase0aActionTimelineChanged>().where(
            (e) => e.eventType == ActionTimelineEventType.completed,
          ),
          hasLength(1),
          reason: 'release and ordinary movement do not cancel a swing',
        );
      },
    );

    test(
      '${weapon.name}: Q request keeps its target and cannot pay twice on cooldown',
      () async {
        final host = await _host(repository, weapon, openingQi: 100);
        await _approach(repository, host);
        final before = host.flow.state;
        final point = _nearest(host).position;
        final command = Phase0aPlayerCommand(
          gather: true,
          gatherTargetPoint: point,
        );
        final first = host.advanceManual(
          deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
          command: command,
        );
        final after = host.flow.state;
        final second = host.advanceManual(
          deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
          command: command,
        );
        expect(first.whereType<Phase0aGatherStarted>(), hasLength(1));
        expect(
          first.whereType<Phase0aGatherStarted>().single.centerPosition,
          point,
        );
        expect(first.whereType<Phase0aGatherApplied>(), hasLength(1));
        expect(second.whereType<Phase0aGatherStarted>(), isEmpty);
        expect(second.whereType<Phase0aGatherApplied>(), isEmpty);
        final adapter = host.mapping!.playerAdapter;
        expect(before.player.qiCurrent - after.player.qiCurrent, 25);
        expect(host.flow.state.player.qiCurrent, after.player.qiCurrent);
        expect(
          after.skillSlots
              .singleWhere((slot) => slot.slot == adapter.gatherSlot)
              .cooldownRemaining,
          adapter.gatherCooldownSeconds,
        );
        print(
          'M0_COSTS ${jsonEncode({
            'weapon': weapon.name,
            'gather': adapter.gatherQiCost,
            'clear': adapter.clearQiCost,
            'numeric': {for (final binding in adapter.numericSkillBindings.equipped) binding.skill.id: binding.qiDelta},
            'qInputTick': before.tick + 1,
            'qEffectTick': first.whereType<Phase0aGatherApplied>().single.tick,
            'qPaymentTick': after.tick,
          })}',
        );
      },
    );

    test(
      '${weapon.name}: live controller and same-seed headless replays agree',
      () async {
        final live = await _host(repository, weapon, openingQi: 40);
        final headless = await _host(repository, weapon, openingQi: 40);
        final replay = await _host(repository, weapon, openingQi: 40);
        final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
        final limit = repository.numbers.phase0aArena.maxSimulationTicks;
        final controller = Phase0aBattleController(
          flow: live.flow,
          roster: Phase0aVisualRoster(visuals: const {}),
          fixedDeltaSeconds: delta,
        );
        addTearDown(controller.dispose);
        final bot = _bot(live);
        var ticks = 0;
        while (controller.outcome == Phase0aBattleOutcome.ongoing &&
            ticks < limit) {
          controller.step(bot.commandFor(controller.state));
          ticks++;
        }
        Phase0aHeadlessResult run(Phase0aEncounterHost host) =>
            Phase0aHeadlessRunner.runToEnd(
              flow: host.flow,
              bot: _bot(host),
              deltaSeconds: delta,
              maxTicks: limit,
            );
        final result = run(headless);
        final repeated = run(replay);
        expect(result.timedOut, isFalse);
        expect(ticks, result.ticks);
        expect(controller.outcome, result.outcome);
        expect(controller.state, result.finalState);
        expect(controller.events, result.events);
        expect(repeated.finalState, result.finalState);
        expect(repeated.events, result.events);
        expect(repeated.eventRecords, result.eventRecords);
        print(
          'M0_REPLAY ${jsonEncode({'weapon': weapon.name, 'ticks': ticks, 'outcome': result.outcome.name, 'events': result.events.length})}',
        );
      },
    );
  }

  test(
    'real reinforcements keep the encounter kill window capped at 15',
    () async {
      final host = await _host(
        repository,
        WeaponArchetype.dual,
        openingQi: 0,
        stageId: 'stage_02_02',
      );
      final bot = _bot(host);
      final events = <Phase0aEvent>[];
      var defeats = 0;
      for (
        var tick = 0;
        tick < repository.numbers.phase0aArena.maxSimulationTicks &&
            defeats < 12;
        tick++
      ) {
        final emitted = host.advanceManual(
          deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
          command: bot.commandFor(host.flow.state),
        );
        events.addAll(emitted);
        defeats += emitted.whereType<Phase0aEnemyDefeated>().length;
        final player = host.flow.state.player;
        expect(player.qiWindowSerial, 0);
        expect(
          player.qiLedger!.windowGains.values.fold(0, (a, b) => a + b),
          lessThanOrEqualTo(15),
        );
      }
      expect(defeats, greaterThanOrEqualTo(12));
      expect(
        events.whereType<Phase0aEnemyEntered>().length,
        greaterThan(10),
        reason:
            'real authored ecology must replenish beyond its ten active slots',
      );
      expect(host.flow.state.player.qiLedger!.windowGains.values.single, 15);
    },
  );

  test(
    'actual basic gain clamps the modifier while kill gain stays five',
    () async {
      final host = await _host(
        repository,
        WeaponArchetype.heavy,
        openingQi: 0,
        qiGainMultiplier: 2,
      );
      await _approach(repository, host);
      final target = _nearest(host);
      final events = <Phase0aEvent>[];
      for (var tick = 0; tick <= 2; tick++) {
        events.addAll(
          host.advanceManual(
            deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
            command: Phase0aPlayerCommand(
              attack: tick == 0,
              attackTargetId: target.id,
              attackAimDirection:
                  target.position - host.flow.state.player.position,
            ),
          ),
        );
      }
      expect(events.whereType<Phase0aEnemyDefeated>(), hasLength(1));
      expect(
        events
            .whereType<Phase0aQiChanged>()
            .singleWhere((e) => e.reason == Phase0aQiChangeReason.basic)
            .applied,
        36,
      );
      expect(
        events
            .whereType<Phase0aQiChanged>()
            .singleWhere((e) => e.reason == Phase0aQiChangeReason.kill)
            .applied,
        5,
      );
      expect(host.flow.state.player.qiCurrent, 41);
    },
  );

  for (final (weapon, power, ultimate) in const [
    (WeaponArchetype.sword, 28, 52),
    (WeaponArchetype.heavy, 34, 60),
    (WeaponArchetype.flexible, 30, 54),
    (WeaponArchetype.dual, 24, 46),
    (WeaponArchetype.hidden, 26, 48),
  ]) {
    test(
      '${weapon.name}: real numeric casts debit mapped power and ultimate once',
      () async {
        for (final (hotkey, cost) in [(1, power), (5, ultimate)]) {
          final host = await _host(repository, weapon, openingQi: 100);
          _expectPayment(
            repository,
            host,
            Phase0aPlayerCommand(skillHotkey: hotkey),
            cost,
          );
        }
      },
    );
  }
  test(
    'real modified casts preserve special costs and Q/R exemptions',
    () async {
      for (final id in [
        'skill_hui_xiu_hui_feng',
        'skill_chen_sha_yi_jue',
        'skill_zhi_shui_jue',
      ]) {
        final host = await _host(
          repository,
          WeaponArchetype.heavy,
          openingQi: 100,
          powerSkillId: id,
          qiCostReductionPct: 0.2,
        );
        _expectPayment(
          repository,
          host,
          const Phase0aPlayerCommand(skillHotkey: 1),
          31,
        );
      }
      for (final (command, cost) in const [
        (Phase0aPlayerCommand(gather: true), 20),
        (Phase0aPlayerCommand(clear: true), 40),
      ]) {
        final host = await _host(
          repository,
          WeaponArchetype.heavy,
          openingQi: 100,
          qiCostReductionPct: 0.2,
        );
        _expectPayment(repository, host, command, cost);
      }
    },
  );

  for (final interruption in [
    'dodge',
    'Q',
    'R',
    'numeric',
    'invalid-Q',
    'empty-slot',
  ]) {
    test('heavy windup: $interruption is accepted before cancelling', () async {
      final openingQi = ['Q', 'R', 'numeric'].contains(interruption) ? 100 : 0;
      final host = await _host(
        repository,
        WeaponArchetype.heavy,
        openingQi: openingQi,
      );
      await _approach(repository, host);
      final target = _nearest(host);
      final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
      final all = <Phase0aEvent>[
        ...host.advanceManual(
          deltaSeconds: delta,
          command: Phase0aPlayerCommand(
            attack: true,
            attackTargetId: target.id,
            attackAimDirection:
                target.position - host.flow.state.player.position,
          ),
        ),
      ];
      expect(
        all.whereType<Phase0aHitLanded>().where(
          (e) => e.actor == host.flow.state.player.id,
        ),
        isEmpty,
      );
      final interruptEvents = host.advanceManual(
        deltaSeconds: delta,
        command: switch (interruption) {
          'dodge' => const Phase0aPlayerCommand(
            defenseAction: Phase0aDefenseAction.dodge,
            defenseDirection: ArenaVector(0, 1),
          ),
          'Q' || 'invalid-Q' => Phase0aPlayerCommand(
            gather: true,
            gatherTargetPoint: target.position,
          ),
          'R' => const Phase0aPlayerCommand(clear: true),
          'numeric' => const Phase0aPlayerCommand(skillHotkey: 1),
          _ => const Phase0aPlayerCommand(skillHotkey: 2),
        },
      );
      all.addAll(interruptEvents);
      for (var i = 0; i < 10; i++) {
        all.addAll(
          host.advanceManual(
            deltaSeconds: delta,
            command: const Phase0aPlayerCommand(),
          ),
        );
      }
      final basicHits = all.whereType<Phase0aHitLanded>().where(
        (e) => e.actor == host.flow.state.player.id,
      );
      if (['dodge', 'Q', 'R', 'numeric'].contains(interruption)) {
        expect(
          basicHits,
          isEmpty,
          reason: 'no delayed basic effect after acceptance',
        );
        final cost = switch (interruption) {
          'Q' => 25,
          'R' => 50,
          'numeric' => 34,
          _ => 0,
        };
        expect(
          host.flow.state.player.qiCurrent,
          openingQi -
              cost +
              math.min(all.whereType<Phase0aEnemyDefeated>().length * 5, 15),
        );
        expect(
          interruptEvents.whereType<Phase0aActionTimelineChanged>().where(
            (e) => e.eventType == ActionTimelineEventType.interrupted,
          ),
          hasLength(1),
        );
        if (interruption == 'Q') {
          expect(
            interruptEvents.whereType<Phase0aGatherStarted>(),
            hasLength(1),
          );
        } else if (interruption == 'dodge') {
          expect(
            interruptEvents.whereType<Phase0aDefenseStarted>(),
            hasLength(1),
          );
        } else if (interruption == 'R') {
          expect(
            interruptEvents.whereType<Phase0aClearStarted>(),
            hasLength(1),
          );
        } else {
          expect(
            interruptEvents.whereType<Phase0aSkillStarted>(),
            hasLength(1),
          );
        }
      } else {
        expect(interruptEvents.whereType<Phase0aGatherStarted>(), isEmpty);
        expect(interruptEvents.whereType<Phase0aSkillStarted>(), isEmpty);
        expect(
          basicHits,
          hasLength(1),
          reason: 'rejected request keeps original action',
        );
        expect(
          host.flow.state.player.qiCurrent,
          24 + math.min(all.whereType<Phase0aEnemyDefeated>().length * 5, 15),
        );
      }
    });
  }
}

Future<Phase0aEncounterHost> _host(
  GameRepository repository,
  WeaponArchetype weapon, {
  required int openingQi,
  String stageId = 'stage_02_03',
  String powerSkillId = 'skill_gangmeng_jichu_skill',
  double qiCostReductionPct = 0,
  double qiGainMultiplier = 1,
}) async {
  final snapshot = testCombatantSnapshot(
    name: 'm0 control player',
    maxHp: 20000,
    internalForce: 15000,
    currentQi: openingQi,
    maxQi: 100,
    qiCostReductionPct: qiCostReductionPct,
    qiGainMultiplier: qiGainMultiplier,
    totalEquipmentAttack: 2000,
    defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
    weaponArchetype: weapon,
    includeProductionBasicAttack: true,
    skillLoadout: CombatantSkillLoadout(
      main1: repository.getSkill(powerSkillId),
      ultimate: repository.getSkill('skill_gangmeng_jichu_ult'),
    ),
  );
  final mapping = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: stageId,
    playerSnapshot: snapshot,
    numbers: repository.numbers,
  );
  final host = await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: repository.getStage(stageId),
      playerMapping: mapping,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: math.Random(734),
      runtimeBindingSource: Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader:
            ({required stageId, required encounterId, required cycleIndex}) =>
                buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                  stageId: stageId,
                  encounterId: encounterId,
                  cycleIndex: cycleIndex,
                  repository: repository,
                ),
      ),
      catalogOverride: repository.combatCatalog,
    ),
  );
  expect(host, isNotNull, reason: 'must use the migrated production factory');
  return host!;
}

Phase0aActor _nearest(Phase0aEncounterHost host) {
  final state = host.flow.state;
  final enemies = state.enemies.toList()
    ..sort(
      (left, right) => (left.position - state.player.position).lengthSquared
          .compareTo((right.position - state.player.position).lengthSquared),
    );
  return enemies.first;
}

Future<void> _approach(
  GameRepository repository,
  Phase0aEncounterHost host,
) async {
  final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
  for (
    var tick = 0;
    tick < repository.numbers.phase0aArena.maxSimulationTicks;
    tick++
  ) {
    final state = host.flow.state;
    final target = state.enemies.isEmpty ? null : _nearest(host);
    if (target != null &&
        (target.position - state.player.position).lengthSquared <=
            math.pow(host.mapping!.playerAdapter.attackRange * 0.8, 2)) {
      return;
    }
    host.advanceManual(
      deltaSeconds: delta,
      command: Phase0aPlayerCommand(
        moveDirection: target == null
            ? null
            : target.position - state.player.position,
      ),
    );
  }
  fail('real encounter did not produce a reachable enemy');
}

Phase0aPlayerBotAdapter _bot(Phase0aEncounterHost host) =>
    Phase0aPlayerBotAdapter(
      playerAdapter: host.mapping!.playerAdapter,
      policy: const Phase0aBotTacticPolicy.assault(),
      objectiveContinuationCommandBuilder:
          host.objectiveContinuationCommandBuilder,
    );

void _expectPayment(
  GameRepository repository,
  Phase0aEncounterHost host,
  Phase0aPlayerCommand command,
  int cost,
) {
  final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
  final before = host.flow.state.player.qiCurrent;
  final first = host.advanceManual(deltaSeconds: delta, command: command);
  final payments = first
      .whereType<Phase0aQiChanged>()
      .where((e) => e.reason == Phase0aQiChangeReason.skill)
      .toList();
  expect(payments, hasLength(1));
  expect(payments.single.applied, -cost);
  expect(payments.single.tick, host.flow.state.tick);
  final gains = first
      .whereType<Phase0aQiChanged>()
      .where((e) => e.reason != Phase0aQiChangeReason.skill)
      .fold(0, (sum, e) => sum + e.applied);
  expect(host.flow.state.player.qiCurrent, before - cost + gains);
  final second = host.advanceManual(deltaSeconds: delta, command: command);
  expect(
    second.whereType<Phase0aQiChanged>().where(
      (e) => e.reason == Phase0aQiChangeReason.skill,
    ),
    isEmpty,
  );
}
