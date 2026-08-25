import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late int leaderId;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tower_automation_production_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final save = await IsarSetup.instance.saveDatas.get(0);
    final leader = await IsarSetup.instance.characters.where().findFirst();
    leaderId = leader!.id;
    await IsarSetup.instance.writeTxn(() async {
      save!
        ..founderCharacterId = leaderId
        ..activeCharacterIds = [leaderId];
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.towerProgress.put(
        TowerProgress()
          ..saveDataId = save.slotId
          ..highestClearedFloor = GameRepository.instance.towerMaxFloor
          ..highestClearedAt = DateTime(2026, 8, 25)
          ..createdAt = DateTime(2026, 8, 25)
          ..currentCycleIndex = 1
          ..maxClearedCycle = 1,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets(
    'player reachable tower unit consumes typed admission and shared settlement',
    (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
      );
      final unit = TowerSweepUnit(
        floor: GameRepository.instance.towerFloors.first,
        cycleIndex: 1,
      );
      final beforeTechniques = await tester.runAsync(
        () => IsarSetup.instance.techniques
            .filter()
            .ownerCharacterIdEqualTo(leaderId)
            .findAll(),
      );
      final usageBefore = beforeTechniques!
          .expand((technique) => technique.skillUsageCount)
          .fold<int>(0, (sum, entry) => sum + entry.count);
      final result = await tester.runAsync(
        () => unit.runPhase0aHeadless(
          ref,
          policy: const Phase0aBotTacticPolicy.assault(),
        ),
      );

      expect(result, isNotNull);
      expect(result!.timedOut, isFalse);
      expect(result.settlement?.result, BattleResult.leftWin);
      expect(result.expectedParticipantId, leaderId);
      expect(result.participantName, isNotEmpty);
      expect(result.towerAutomationAdmission?.participantCharacterId, leaderId);

      final outcome = await tester.runAsync(
        () => unit.settlePhase0a(ref, result),
      );
      expect(outcome, isNotNull);
      final progress = await tester.runAsync(
        () => IsarSetup.instance.towerProgress.where().findFirst(),
      );
      expect(progress!.totalAttempts, 1);
      expect(
        progress.highestClearedFloor,
        GameRepository.instance.towerMaxFloor,
      );
      final afterTechniques = await tester.runAsync(
        () => IsarSetup.instance.techniques
            .filter()
            .ownerCharacterIdEqualTo(leaderId)
            .findAll(),
      );
      final usageAfter = afterTechniques!
          .expand((technique) => technique.skillUsageCount)
          .fold<int>(0, (sum, entry) => sum + entry.count);
      expect(usageAfter, greaterThan(usageBefore));
    },
  );

  testWidgets(
    'wrong participant settlement fails before tower progress mutation',
    (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
      );
      final unit = TowerSweepUnit(
        floor: GameRepository.instance.towerFloors.first,
        cycleIndex: 1,
      );
      final result = await tester.runAsync(
        () => unit.runPhase0aHeadless(
          ref,
          policy: const Phase0aBotTacticPolicy.assault(),
        ),
      );
      final wrongSettlement = CombatSettlementSnapshot(
        result: BattleResult.leftWin,
        totalTicks: 1,
        hadActions: true,
        participants: const [
          CombatParticipantSnapshot(
            characterId: 999999,
            currentHp: 1,
            maxHp: 1,
          ),
        ],
        skillCasts: const [],
        totalDamage: 1,
        criticalCount: 0,
        damageByCharacterId: const {999999: 1},
      );

      await tester.runAsync(() async {
        await expectLater(
          settleTowerSweepVictory(
            ref: ref,
            floor: GameRepository.instance.towerFloors.first,
            settlementSnapshot: wrongSettlement,
            admission: result!.towerAutomationAdmission,
          ),
          throwsStateError,
        );
      });
      final progress = await tester.runAsync(
        () => IsarSetup.instance.towerProgress.where().findFirst(),
      );
      expect(progress!.totalAttempts, 0);
    },
  );

  testWidgets(
    'missing or stale admission fails before tower progress mutation',
    (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(child: _RefHarness(onReady: (value) => ref = value)),
      );
      final unit = TowerSweepUnit(
        floor: GameRepository.instance.towerFloors.first,
        cycleIndex: 1,
      );
      final result = await tester.runAsync(
        () => unit.runPhase0aHeadless(
          ref,
          policy: const Phase0aBotTacticPolicy.assault(),
        ),
      );

      await tester.runAsync(() async {
        await expectLater(
          settleTowerSweepVictory(
            ref: ref,
            floor: GameRepository.instance.towerFloors.first,
            settlementSnapshot: result!.settlement,
          ),
          throwsStateError,
        );
      });

      final leader = await tester.runAsync(
        () => IsarSetup.instance.characters.get(leaderId),
      );
      await tester.runAsync(() async {
        await IsarSetup.instance.writeTxn(() async {
          leader!.name = '${leader.name}·已变更';
          await IsarSetup.instance.characters.put(leader);
        });
        await expectLater(unit.settlePhase0a(ref, result!), throwsStateError);
      });

      final progress = await tester.runAsync(
        () => IsarSetup.instance.towerProgress.where().findFirst(),
      );
      expect(progress!.totalAttempts, 0);
    },
  );
}

class _RefHarness extends ConsumerWidget {
  const _RefHarness({required this.onReady});

  final ValueChanged<WidgetRef> onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}
