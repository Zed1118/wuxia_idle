import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_coordinator.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_automation_policy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_content_providers.dart';
import 'package:wuxia_idle/features/jianghu/application/jianghu_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart'
    show DurableActivityCombatSettlementDependencies;
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late Character leader;
  late DurableActivityAutomationService service;

  setUpAll(() async {
    initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_durable_activity_coordinator_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    leader = (await IsarSetup.instance.characters.where().findFirst())!;
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.founderCharacterId = leader.id;
      save.activeCharacterIds = [leader.id];
      await IsarSetup.instance.saveDatas.put(save);
      final rows = await IsarSetup.instance.mainlineProgress.where().findAll();
      final progress = rows.firstOrNull ?? MainlineProgress();
      progress.saveDataId = save.slotId;
      progress.clearedStageIds = {
        ...progress.clearedStageIds,
        'stage_light_foot_01',
        'stage_mass_battle_01',
      }.toList();
      progress.clearedAt = List.of(progress.clearedAt);
      await IsarSetup.instance.mainlineProgress.put(progress);
    });
    service = DurableActivityAutomationService(IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真实轻功 durable run 经共享 headless 与结算原子落 receipt', () async {
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final request = ActivityParticipationRequest(
      contentId: stage.id,
      contentKind: ActivityContentKind.lightFoot,
      characterId: leader.id,
      loadoutPlanId: durableActivityLoadoutPlanId(
        kind: DurableActivityKind.lightFoot,
        stageId: stage.id,
        characterId: leader.id,
      ),
      participation: ActivityParticipationMode.dispatch,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.offlineResume,
    );
    final runId = await service.start(
      kind: DurableActivityKind.lightFoot,
      stage: stage,
      cycleIndex: 1,
      request: request,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final result = await executeDurableActivityAutomation(
      dependencies: DurableActivityAutomationExecutionDependencies(
        service: service,
        settlement: DurableActivityCombatSettlementDependencies(
          numbers: container.read(numbersConfigProvider),
          dropService: container.read(dropServiceProvider),
          rng: container.read(rngProvider),
          skillDropRng: container.read(mathRandomProvider),
          tutorialService: container.read(tutorialServiceProvider),
          reputationService: container.read(reputationServiceProvider),
        ),
      ),
      stage: stage,
      runId: runId,
    );

    expect(result.outcome, isNot(DurableActivityExecutionOutcome.timeout));
    expect(result.run.phase, DurableActivityPhase.settlementApplied);
    expect(result.run.settlementAppliedAt, isNotNull);
    expect(result.run.members.single.characterId, leader.id);
    expect(
      (await service.runById(runId))!.phase,
      DurableActivityPhase.settlementApplied,
    );
    final receipts = await IsarSetup.instance.rewardClaimReceipts
        .where()
        .findAll();
    expect(receipts, hasLength(2));
    expect(receipts.map((receipt) => receipt.contentKind).toSet(), {
      RewardContentKind.lightFoot,
    });
  });

  test('真实守城 durable run 消费持久阵型并经共享结算原子落 receipt', () async {
    final stage = GameRepository.instance.getStage('stage_mass_battle_01');
    final request = ActivityParticipationRequest(
      contentId: stage.id,
      contentKind: ActivityContentKind.massBattle,
      characterId: leader.id,
      loadoutPlanId: durableActivityLoadoutPlanId(
        kind: DurableActivityKind.massBattle,
        stageId: stage.id,
        characterId: leader.id,
      ),
      participation: ActivityParticipationMode.dispatch,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.offlineResume,
    );
    final runId = await service.start(
      kind: DurableActivityKind.massBattle,
      stage: stage,
      cycleIndex: 1,
      request: request,
      formation: Formation.baGua,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final result = await executeDurableActivityAutomation(
      dependencies: DurableActivityAutomationExecutionDependencies(
        service: service,
        settlement: DurableActivityCombatSettlementDependencies(
          numbers: container.read(numbersConfigProvider),
          dropService: container.read(dropServiceProvider),
          rng: container.read(rngProvider),
          skillDropRng: container.read(mathRandomProvider),
          tutorialService: container.read(tutorialServiceProvider),
          reputationService: container.read(reputationServiceProvider),
        ),
      ),
      stage: stage,
      runId: runId,
    );

    expect(result.outcome, isNot(DurableActivityExecutionOutcome.timeout));
    expect(result.run.phase, DurableActivityPhase.settlementApplied);
    expect(result.run.formation, Formation.baGua);
    expect(result.run.settlementAppliedAt, isNotNull);
    expect(result.run.members.single.characterId, leader.id);
    final receipts = await IsarSetup.instance.rewardClaimReceipts
        .where()
        .findAll();
    expect(receipts, hasLength(2));
    expect(receipts.map((receipt) => receipt.contentKind).toSet(), {
      RewardContentKind.massBattle,
    });
  });
}
