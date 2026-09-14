import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_production_headless_benchmark.dart';

void main() {
  late GameRepository repository;
  late CombatantSnapshot player;
  late HeadlessBenchmarkRun reference;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    final directory = await Directory.systemTemp.createTemp(
      'headless_contract_',
    );
    try {
      await IsarSetup.init(directory: directory, inspector: false);
      player = (await seedPhase0aCh1FounderProfile(
        isar: IsarSetup.instance,
        schoolId: 'gang_meng',
        originId: 'mountain_wanderer',
        fateId: 'balanced_seed',
        rngSeed: 20260820,
      )).snapshot;
    } finally {
      await IsarSetup.close();
      IsarSetup.resetForTest();
      await directory.delete(recursive: true);
    }
    reference = await measureProductionHeadless(
      repository: repository,
      content: const CombatContentRef.mainline('stage_01_03'),
      player: player,
      seed: 73,
      mode: HeadlessBenchmarkMode.sync,
    );
  });

  test('manifest covers current 105 mainline and 49 tower entries exactly', () {
    final manifest = productionHeadlessManifest(repository);
    expect(
      manifest.where((entry) => entry.kind == CombatContentKind.mainline),
      hasLength(105),
    );
    expect(
      manifest.where((entry) => entry.kind == CombatContentKind.tower),
      hasLength(49),
    );
    expect(manifest.toSet(), hasLength(154));
    expect(manifest.last, const CombatContentRef.tower('tower_49'));
  });

  for (final entry in {
    const CombatContentRef.mainline('stage_01_03'): 'typed_mainline',
    const CombatContentRef.tower('tower_1'): 'typed_tower',
    const CombatContentRef.tower('tower_7'): 'typed_tower',
    const CombatContentRef.tower('tower_8'): 'legacy_tower',
    const CombatContentRef.tower('tower_49'): 'legacy_tower',
  }.entries) {
    test(
      '${entry.key.contentId} measures production route and preserves async/replay result',
      () async {
        final sync = await measureProductionHeadless(
          repository: repository,
          content: entry.key,
          player: player,
          seed: 73,
          mode: HeadlessBenchmarkMode.sync,
        );
        final async = await measureProductionHeadless(
          repository: repository,
          content: entry.key,
          player: player,
          seed: 73,
          mode: HeadlessBenchmarkMode.async,
        );
        expect(sync.route, entry.value);
        requireSameHeadlessResult(sync, async);
        expect(sync.result.ticks, greaterThan(0));
        expect(sync.simulationMicroseconds, greaterThan(0));
        expect(sync.assemblyMicroseconds, greaterThan(0));
        expect(async.simulationMicroseconds, greaterThan(0));
        final json = sync.toJson(
          repository.numbers.phase0aArena.fixedDeltaSeconds,
        );
        expect(
          json['simulated_seconds'],
          sync.result.ticks * repository.numbers.phase0aArena.fixedDeltaSeconds,
        );
        expect(json['simulation_microseconds'], sync.simulationMicroseconds);
      },
    );
  }

  test(
    'budget exhaustion remains a timeout with no terminal settlement',
    () async {
      final zero = await measureProductionHeadless(
        repository: repository,
        content: const CombatContentRef.tower('tower_8'),
        player: player,
        seed: 0,
        mode: HeadlessBenchmarkMode.async,
        maxTicks: 0,
      );
      expect(zero.result.timedOut, isTrue);
      expect(zero.result.ticks, 0);
      expect(zero.settlement, isNull);
      expect(zero.toJson(.1)['timed_out'], isTrue);
    },
  );

  test('equal event counts cannot conceal a changed event', () {
    final r = reference.result;
    expect(r.events, isNotEmpty);
    final changed = _copy(
      reference,
      result: Phase0aHeadlessResult(
        outcome: r.outcome,
        ticks: r.ticks,
        finalState: r.finalState,
        events: [
          const Phase0aBattleVictory(seq: -1, tick: -1),
          ...r.events.skip(1),
        ],
        eventRecords: r.eventRecords,
      ),
    );
    expect(
      () => requireSameHeadlessResult(reference, changed),
      throwsStateError,
    );
  });

  test('ordered event records are checked independently of events', () {
    final r = reference.result;
    expect(r.eventRecords, hasLength(greaterThan(1)));
    final changed = _copy(
      reference,
      result: Phase0aHeadlessResult(
        outcome: r.outcome,
        ticks: r.ticks,
        finalState: r.finalState,
        events: r.events,
        eventRecords: r.eventRecords.reversed.toList(),
      ),
    );
    expect(
      () => requireSameHeadlessResult(reference, changed),
      throwsStateError,
    );
  });

  test('full arena fields are checked beyond outcome and ticks', () {
    final r = reference.result, s = r.finalState;
    final changed = _copy(
      reference,
      result: Phase0aHeadlessResult(
        outcome: r.outcome,
        ticks: r.ticks,
        finalState: Phase0aArenaState(
          tick: s.tick,
          nextSeq: s.nextSeq + 1,
          player: s.player,
          enemies: s.enemies,
          skillSlots: s.skillSlots,
          defendedEntity: s.defendedEntity,
          winCondition: s.winCondition,
        ),
        events: r.events,
        eventRecords: r.eventRecords,
      ),
    );
    expect(
      () => requireSameHeadlessResult(reference, changed),
      throwsStateError,
    );
  });

  test('settlement attribution is checked even when total damage matches', () {
    final s = reference.settlement!;
    final changed = _copy(
      reference,
      settlement: CombatSettlementSnapshot(
        result: s.result,
        totalTicks: s.totalTicks,
        hadActions: s.hadActions,
        playerCharacterId: s.playerCharacterId,
        participants: s.participants,
        skillCasts: s.skillCasts,
        totalDamage: s.totalDamage,
        criticalCount: s.criticalCount,
        damageByCharacterId: {...s.damageByCharacterId, -99: 1},
      ),
    );
    expect(
      () => requireSameHeadlessResult(reference, changed),
      throwsStateError,
    );
  });

  test('wall-clock noise does not enter deterministic domain equality', () {
    final changed = _copy(
      reference,
      simulationMicroseconds: reference.simulationMicroseconds + 1000000,
    );
    requireSameHeadlessResult(reference, changed);
  });

  test(
    'spawn and objective progress cannot be concealed by equal arena state',
    () {
      expect(reference.encounterFacts, isNotNull);
      final changed = _copy(reference, encounterFacts: '{}');
      expect(
        () => requireSameHeadlessResult(reference, changed),
        throwsStateError,
      );
    },
  );

  test('comparison inputs bind actual player values and skill uses', () {
    final before = headlessPlayerFacts(player);
    final changed = headlessPlayerFacts(
      player.copyWith(
        currentHp: player.currentHp - 1,
        skillUses: {'probe': 99},
      ),
    );
    expect(changed['current_hp'], isNot(before['current_hp']));
    expect(changed['skill_uses'], isNot(before['skill_uses']));
  });
}

HeadlessBenchmarkRun _copy(
  HeadlessBenchmarkRun run, {
  Phase0aHeadlessResult? result,
  CombatSettlementSnapshot? settlement,
  int? simulationMicroseconds,
  String? encounterFacts,
}) => HeadlessBenchmarkRun(
  route: run.route,
  mode: run.mode,
  result: result ?? run.result,
  settlement: settlement ?? run.settlement,
  assemblyMicroseconds: run.assemblyMicroseconds,
  simulationMicroseconds: simulationMicroseconds ?? run.simulationMicroseconds,
  settlementMicroseconds: run.settlementMicroseconds,
  encounterFacts: encounterFacts ?? run.encounterFacts,
);
