import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_participant_snapshot_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_settlement.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/current_leader_resolver.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'settlement_participant_diagnosis_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets(
    '纯净新档真打 stage_01_05 后主线与 headless 结算都接受显式玩家参与者',
    (tester) async {
      final repository = GameRepository.instance;
      final stage = repository.getStage('stage_01_05');
      late int expectedParticipantId;
      late MainlineRun run;
      late CombatantSnapshot playerSnapshot;

      await tester.runAsync(() async {
        final config = repository.founderCreation;
        final created =
            await OnboardingService(
              isar: IsarSetup.instance,
              rng: DefaultRng(seed: 20260820),
            ).createFoundingMaster(
              selection: FounderCreationSelection(
                school: config.schools.singleWhere((e) => e.id == 'gang_meng'),
                origin: config.origins.singleWhere(
                  (e) => e.id == 'mountain_wanderer',
                ),
                fate: config.fatePool.singleWhere(
                  (e) => e.id == 'balanced_seed',
                ),
              ),
            );
        expect(created, isTrue, reason: '必须由空 Isar 走生产新档创建服务');

        final isar = IsarSetup.instance;
        final save = (await isar.saveDatas.get(0))!;
        expectedParticipantId = await CurrentLeaderResolver.resolve(
          save: save,
          characterExists: (id) async => await isar.characters.get(id) != null,
        );
        expect(expectedParticipantId, 1);
        expect(save.activeCharacterIds, [expectedParticipantId]);

        final progressService = MainlineProgressService(isar: isar);
        await progressService.getOrCreate(saveDataId: IsarSetup.currentSlotId);
        for (final stageId in const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
        ]) {
          await progressService.recordVictory(
            stageId: stageId,
            now: DateTime.utc(2026, 8, 26),
          );
        }
        final MainlineProgress progress = await progressService.getOrCreate(
          saveDataId: IsarSetup.currentSlotId,
        );
        final stageEntry = MainlineProgressService.availableStages(
          progress: progress,
          chapterIndex: 1,
        ).singleWhere((entry) => entry.def.id == stage.id);
        expect(stageEntry.status, StageStatus.available);
        expect(progress.clearedStageIds, isNot(contains(stage.id)));

        final resolved = await MainlineParticipantSnapshotService(isar).resolve(
          ActivityParticipationRequest(
            contentId: stage.id,
            contentKind: ActivityContentKind.mainline,
            characterId: expectedParticipantId,
            loadoutPlanId: mainlineLoadoutPlanId(
              stageId: stage.id,
              characterId: expectedParticipantId,
            ),
            participation: ActivityParticipationMode.direct,
            controller: ActivityController.human,
            clock: ActivityClock.realtime,
            entryKind: ActivityEntryKind.firstClear,
          ),
        );
        playerSnapshot = resolved.snapshot;
        run = MainlineRun.begin(
          runId: 'diagnosis-clean-save-stage-01-05',
          participantId: expectedParticipantId,
          stageId: stage.id,
          loadoutSnapshotId: 'diagnosis-clean-save-loadout-1',
        );
        expect(playerSnapshot.characterId, run.participantId);
      });

      WidgetRef? ref;
      CombatSettlementSnapshot? terminalSettlement;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, widgetRef, _) {
                ref = widgetRef;
                return Phase0aMainlineBattleHost(
                  stage: stage,
                  playerSnapshot: playerSnapshot,
                  seedForTest: 0,
                  controller: ActivityController.human,
                  onVictory: (settlement) => terminalSettlement = settlement,
                  onDefeat: (settlement) => terminalSettlement = settlement,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      var simulatedSeconds = 0;
      while (terminalSettlement == null && simulatedSeconds < 180) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pump(const Duration(seconds: 1));
        simulatedSeconds += 1;
      }

      final settlement = terminalSettlement!;
      expect(settlement.result, BattleResult.leftWin);
      expect(settlement.isFinished, isTrue);
      expect(settlement.playerCharacterId, run.participantId);
      expect(settlement.participantCharacterIds, {-2, -1, 1});
      expect(settlement.participantCharacterIds, hasLength(3));
      expect(settlement.participants, hasLength(3));
      expect(settlement.participantCharacterIds.where((id) => id > 0).toSet(), {
        run.participantId,
      });

      await tester.runAsync(() async {
        await applyVictoryResolution(
          ref: ref!,
          stage: stage,
          settlementSnapshot: settlement,
          expectedParticipantId: run.participantId,
        );
        await settleMainlineHeadlessReplayVictory(
          ref: ref!,
          stage: stage,
          cycle: 1,
          settlementSnapshot: settlement,
          expectedParticipantId: run.participantId,
        );
      });

      await tester.runAsync(() async {
        final progress = await MainlineProgressService(
          isar: IsarSetup.instance,
        ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
        expect(
          progress.clearedStageIds,
          contains(stage.id),
          reason: '显式玩家参与者应允许主线胜利结算写入通关进度',
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
