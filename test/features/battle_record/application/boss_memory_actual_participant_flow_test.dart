import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/system_clock_provider.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_key.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// Keep optional drops/encounters deterministic while retaining their production
/// services and every guaranteed reward. No clear-recorder or Boss hook stubs.
class _NoOptionalRollRng implements Rng, math.Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.999999;

  @override
  int nextInt(int max) => max - 1;

  @override
  T pick<T>(List<T> list) => list.last;
}

void main() {
  final at = DateTime(2026, 9, 22, 12);
  late Directory directory;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('boss_actual_roster_');
    await IsarSetup.init(directory: directory, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<List<Character>> seedCharacters() async {
    final characters = [
      for (final (index, name) in [
        '掌门留守',
        '替补甲',
        '替补乙',
        '首胜门人',
        '重打门人',
      ].indexed)
        Character.create(
          name: name,
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: index == 0 ? LineageRole.founder : LineageRole.disciple,
          isFounder: index == 0,
          isActive: index < 3,
          createdAt: at.subtract(const Duration(days: 1)),
          recoverySettledAt: at,
          portraitPath: 'assets/portraits/roster_test_$index.png',
          internalForce: 3000,
        ),
    ];
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll(characters);
      final save = (await isar.saveDatas.get(0))!
        ..createdAt = at.subtract(const Duration(days: 1))
        ..lastOnlineAt = at
        ..passiveLastSettledAt = at
        ..founderCharacterId = characters.first.id
        ..activeCharacterIds = characters.take(3).map((c) => c.id).toList();
      await isar.saveDatas.put(save);
    });
    return characters;
  }

  Future<({WidgetRef ref, BuildContext context})> mountHost(
    WidgetTester tester,
  ) async {
    late WidgetRef ref;
    late BuildContext context;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      try {
        // The real victory panel starts Isar reads from FutureBuilder.build.
        // Drain native replies and their widget-zone continuations while the
        // test binding is active; global tearDown can no longer pump widgets.
        var closed = false;
        late Future<void> close;
        await tester.runAsync(() async {
          close = IsarSetup.close().whenComplete(() => closed = true);
        });
        for (var attempt = 0; attempt < 100 && !closed; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        expect(
          closed,
          isTrue,
          reason: 'Native Isar reads must drain before close',
        );
        await tester.runAsync(() => close);
      } finally {
        await tester.binding.setSurfaceSize(null);
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          systemClockProvider.overrideWithValue(SystemClock.fixed(at)),
          rngProvider.overrideWithValue(_NoOptionalRollRng()),
          mathRandomProvider.overrideWithValue(_NoOptionalRollRng()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (currentContext, currentRef, _) {
                context = currentContext;
                ref = currentRef;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    return (ref: ref, context: context);
  }

  CombatSettlementSnapshot victory(Character character, {int damage = 321}) =>
      CombatSettlementSnapshot(
        result: BattleResult.leftWin,
        totalTicks: 12,
        hadActions: true,
        playerCharacterId: character.id,
        participants: [
          CombatParticipantSnapshot(
            characterId: character.id,
            currentHp: 7000,
            maxHp: 8000,
          ),
        ],
        skillCasts: const [],
        totalDamage: damage,
        criticalCount: 2,
        damageByCharacterId: {character.id: damage},
      );

  Future<BossMemory> readMemory(String key) async => (await IsarSetup
      .instance
      .bossMemorys
      .filter()
      .bossKeyEqualTo(key)
      .findFirst())!;

  TowerFloorDef towerBoss() {
    final real = GameRepository.instance.getTowerFloor(4);
    // Narrative routes are outside this roster regression. Retain the real
    // Boss identity, enemies, and reward data while avoiding story navigation.
    return TowerFloorDef(
      floorIndex: real.floorIndex,
      requiredRealm: real.requiredRealm,
      enemyTeam: real.enemyTeam,
      bossKind: real.bossKind,
      dropTable: real.dropTable,
      baseExpReward: real.baseExpReward,
      dropSkillFragmentId: real.dropSkillFragmentId,
      sceneBackgroundPath: real.sceneBackgroundPath,
    );
  }

  Future<void> unlockTowerBoss(TowerFloorDef floor) async {
    final service = TowerProgressService(isar: IsarSetup.instance);
    await service.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    for (var index = 1; index < floor.floorIndex; index++) {
      await service.recordClear(
        floorIndex: index,
        now: at,
        elapsedMs: 1000,
        maxFloor: GameRepository.instance.towerMaxFloor,
      );
    }
  }

  Future<void> runRealTowerFlow(
    WidgetTester tester, {
    required WidgetRef ref,
    required BuildContext context,
    required TowerFloorDef floor,
    required Character participant,
    int damage = 321,
  }) async {
    var completed = false;
    Object? failure;
    StackTrace? failureStack;
    late Future<void> flow;
    await tester.runAsync(() async {
      flow =
          runTowerFlow(
            context: context,
            ref: ref,
            floor: floor,
            participantId: participant.id,
            phase0aBattleOutcomeForTest: () async => (
              won: true,
              surrendered: false,
              settlement: victory(participant, damage: damage),
            ),
          ).then(
            (_) => completed = true,
            onError: (Object error, StackTrace stack) {
              failure = error;
              failureStack = stack;
              completed = true;
            },
          );
    });
    // Let real Isar work progress in runAsync, and animate/dismiss the actual
    // victory presentation in the widget clock. Await the entire caller flow.
    for (var pump = 0; pump < 500 && !completed; pump++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final confirm = find.text(UiStrings.towerVictoryConfirm);
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await tester.pump();
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
    expect(
      completed,
      isTrue,
      reason: 'Real tower flow must finish its dialogs',
    );
    await tester.runAsync(() => flow);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'durable mainline Boss memory includes only the actual disciple',
    (tester) async {
      final host = await mountHost(tester);
      final evidence = (await tester.runAsync(() async {
        final characters = await seedCharacters();
        final participant = characters[3];
        final stage = GameRepository.instance.getStage('stage_01_05');
        final service = MainlineSettlementJournalService(IsarSetup.instance);
        final identity = MainlineSettlementIdentity(
          runId: 'actual-roster-mainline',
          stageId: stage.id,
          loadoutVersion: 1,
          participantId: participant.id,
        );
        await service.prepare(
          saveDataId: IsarSetup.currentSlotId,
          identity: identity,
          loadoutSnapshotId: 'actual-roster-loadout',
          now: at,
        );
        final outcome = await applyVictoryResolution(
          ref: host.ref,
          stage: stage,
          settlementSnapshot: victory(participant),
          durableSettlement: (service: service, identity: identity),
          expectedParticipantId: participant.id,
          settlementAt: at,
        );
        return (
          outcome: outcome,
          phase: (await service.journalFor(identity))!.phase,
          clearedIds:
              (await IsarSetup.instance.mainlineProgress.where().findFirst())!
                  .clearedStageIds,
          stageId: stage.id,
          receiptCount: await IsarSetup.instance.rewardClaimReceipts.count(),
          activeIds: (await IsarSetup.currentSaveData())!.activeCharacterIds,
          originalActiveIds: characters.take(3).map((c) => c.id).toList(),
          participant: participant,
          memory: await readMemory(mainlineBossKey(stage.id)),
        );
      }))!;
      expect(evidence.outcome, isNotNull);
      expect(evidence.phase, MainlineSettlementPhase.coreApplied);
      expect(evidence.clearedIds, contains(evidence.stageId));
      expect(evidence.receiptCount, greaterThan(0));
      expect(evidence.activeIds, evidence.originalActiveIds);
      expect(evidence.memory.defeatCount, 1);
      expect(evidence.memory.rosterNames, [evidence.participant.name]);
      expect(evidence.memory.rosterPortraits, [
        evidence.participant.portraitPath,
      ]);
    },
  );

  testWidgets('real tower clear and hook record a non-active disciple alone', (
    tester,
  ) async {
    final host = await mountHost(tester);
    final characters = (await tester.runAsync(seedCharacters))!;
    final participant = characters[3];
    final floor = towerBoss();
    await tester.runAsync(() => unlockTowerBoss(floor));
    await runRealTowerFlow(
      tester,
      ref: host.ref,
      context: host.context,
      floor: floor,
      participant: participant,
    );
    final evidence = (await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      return (
        progress: (await isar.towerProgress.where().findFirst())!,
        participantExperience: (await isar.characters.get(
          participant.id,
        ))!.experience,
        founderExperience: (await isar.characters.get(
          characters.first.id,
        ))!.experience,
        activeIds: (await IsarSetup.currentSaveData())!.activeCharacterIds,
        memory: await readMemory(towerBossKey(floor.floorIndex)),
      );
    }))!;
    expect(evidence.progress.highestClearedFloor, floor.floorIndex);
    expect(evidence.progress.totalAttempts, floor.floorIndex);
    expect(evidence.participantExperience, floor.baseExpReward);
    expect(evidence.founderExperience, 0);
    expect(evidence.activeIds, isNot(contains(participant.id)));
    expect(evidence.memory.defeatCount, 1);
    expect(evidence.memory.rosterNames, [participant.name]);
    expect(evidence.memory.rosterPortraits, [participant.portraitPath]);
  });

  testWidgets(
    'another tower winner increments count without rewriting first-victory identity',
    (tester) async {
      final host = await mountHost(tester);
      final characters = (await tester.runAsync(seedCharacters))!;
      final firstWinner = characters[3];
      final repeatWinner = characters[4];
      final floor = towerBoss();
      await tester.runAsync(() => unlockTowerBoss(floor));
      await runRealTowerFlow(
        tester,
        ref: host.ref,
        context: host.context,
        floor: floor,
        participant: firstWinner,
      );
      final first = (await tester.runAsync(
        () => readMemory(towerBossKey(floor.floorIndex)),
      ))!;
      final receiptsBefore = (await tester.runAsync(
        () => IsarSetup.instance.rewardClaimReceipts
            .filter()
            .layerEqualTo(RewardLayer.firstClear)
            .exportJson(),
      ))!;
      await runRealTowerFlow(
        tester,
        ref: host.ref,
        context: host.context,
        floor: floor,
        participant: repeatWinner,
        damage: 987,
      );
      final evidence = (await tester.runAsync(
        () async => (
          repeat: await readMemory(towerBossKey(floor.floorIndex)),
          experience: (await IsarSetup.instance.characters.get(
            repeatWinner.id,
          ))!.experience,
          receipts: await IsarSetup.instance.rewardClaimReceipts
              .filter()
              .layerEqualTo(RewardLayer.firstClear)
              .exportJson(),
        ),
      ))!;
      final repeat = evidence.repeat;
      expect(repeat.id, first.id);
      expect(repeat.defeatCount, 2);
      expect(repeat.firstClearedAt, first.firstClearedAt);
      expect(repeat.rosterNames, first.rosterNames);
      expect(repeat.rosterPortraits, first.rosterPortraits);
      expect(repeat.totalDamage, first.totalDamage);
      expect(repeat.topContributorName, first.topContributorName);
      expect(evidence.experience, 0);
      expect(evidence.receipts, receiptsBefore);
      expect(repeat.rosterNames, [firstWinner.name]);
      expect(repeat.rosterPortraits, [firstWinner.portraitPath]);
    },
  );
}
