import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/battle_result.dart';
import '../../../shared/utils/math_random.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../battle/application/phase0a/phase0a_bot_tactic.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/presentation/stage_entry_flow.dart'
    show
        DurableActivityCombatSettlementDependencies,
        applyParticipantDefeatResolution,
        applyVictoryResolution;
import '../../tutorial/application/tutorial_providers.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../sweep/application/phase0a_sweep_headless_runner.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/presentation/tower_entry_flow.dart';
import '../domain/durable_activity_combat_run.dart';
import 'durable_activity_automation_providers.dart';
import 'durable_activity_automation_service.dart';

enum DurableActivityExecutionOutcome { victory, defeat, timeout }

final class DurableActivityExecutionResult {
  const DurableActivityExecutionResult({
    required this.outcome,
    required this.run,
  });

  final DurableActivityExecutionOutcome outcome;
  final DurableActivityCombatRun run;
}

final class DurableActivityAutomationExecutionDependencies {
  const DurableActivityAutomationExecutionDependencies({
    required this.service,
    required this.settlement,
  });

  final DurableActivityAutomationService service;
  final DurableActivityCombatSettlementDependencies settlement;
}

/// 从已落库 durable run 恢复并执行同一个生产 mapper/assembler/headless/settlement。
Future<DurableActivityExecutionResult> executeDurableActivityAutomation({
  WidgetRef? ref,
  DurableActivityAutomationExecutionDependencies? dependencies,
  required StageDef stage,
  required int runId,
}) async {
  if (ref == null && dependencies == null) {
    throw ArgumentError('Execution requires WidgetRef or dependencies');
  }
  final service =
      dependencies?.service ??
      ref!.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    throw StateError('Durable activity automation storage is unavailable');
  }
  final settlementDependencies =
      dependencies?.settlement ??
      DurableActivityCombatSettlementDependencies(
        numbers: ref!.read(numbersConfigProvider),
        dropService: ref.read(dropServiceProvider),
        rng: ref.read(rngProvider),
        skillDropRng: ref.read(mathRandomProvider),
        tutorialService: ref.read(tutorialServiceProvider),
        reputationService: ref.read(reputationServiceProvider),
      );
  final admission = await service.admit(runId: runId, stage: stage);
  final runner = Phase0aSweepHeadlessRunner(
    isar: IsarSetup.instance,
    numbers: settlementDependencies.numbers,
    rng: newMathRandom(seed: admission.run.seed),
    botPolicy: const Phase0aBotTacticPolicy.production(),
  );
  final result = switch (admission.run.kind) {
    DurableActivityKind.tower => throw StateError(
      'tower uses executeTowerDurableActivityAutomation',
    ),
    DurableActivityKind.lightFoot => await runner.runLightFoot(
      stage: stage,
      admission: admission,
    ),
    DurableActivityKind.massBattle => await runner.runMassBattle(
      stage: stage,
      admission: admission,
    ),
  };
  if (result.timedOut) {
    final current = await service.runById(runId);
    if (current == null) {
      throw StateError('Timed-out durable activity run disappeared');
    }
    ref?.invalidate(durableActivityRunProvider(admission.run.kind));
    return DurableActivityExecutionResult(
      outcome: DurableActivityExecutionOutcome.timeout,
      run: current,
    );
  }
  final settlement = result.settlement;
  if (settlement == null ||
      !settlement.isFinished ||
      settlement.playerCharacterId != admission.snapshot.characterId) {
    throw StateError('Durable activity produced an invalid settlement');
  }
  final context = DurableActivitySettlementContext(
    service: service,
    runId: admission.run.id,
  );
  final executionOutcome = settlement.result == BattleResult.leftWin
      ? DurableActivityExecutionOutcome.victory
      : DurableActivityExecutionOutcome.defeat;
  if (executionOutcome == DurableActivityExecutionOutcome.victory) {
    await applyVictoryResolution(
      ref: ref,
      stage: stage,
      cycle: admission.run.cycleIndex,
      settlementSnapshot: settlement,
      expectedParticipantId: admission.snapshot.characterId,
      durableActivitySettlement: context,
      durableActivityDependencies: settlementDependencies,
    );
  } else {
    await applyParticipantDefeatResolution(
      ref: ref,
      stage: stage,
      settlementSnapshot: settlement,
      expectedParticipantId: admission.snapshot.characterId,
      durableActivitySettlement: context,
      durableActivityDependencies: settlementDependencies,
    );
  }
  if (ref != null) {
    invalidateAfterCombatSettlement(ref.invalidate);
    ref.invalidate(mainlineProgressProvider);
    ref.invalidate(durableActivityRunProvider(admission.run.kind));
  }
  final current = await service.runById(runId);
  if (current == null ||
      current.phase != DurableActivityPhase.settlementApplied) {
    throw StateError('Durable activity receipt was not persisted');
  }
  return DurableActivityExecutionResult(
    outcome: executionOutcome,
    run: current,
  );
}

/// Resumes one persisted tower dispatch through the existing tower mapper,
/// Phase 0A headless runner and tower settlement owners.
Future<DurableActivityExecutionResult> executeTowerDurableActivityAutomation({
  required WidgetRef ref,
  required TowerFloorDef floor,
  required int runId,
  Future<Phase0aSweepRunResult> Function(
    DurableActivityAutomationAdmission admission,
  )?
  runnerForTest,
}) async {
  final service = ref.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    throw StateError('Tower durable dispatch storage is unavailable');
  }
  final admission = await service.admitTower(runId: runId, floor: floor);
  final runner = Phase0aSweepHeadlessRunner(
    isar: IsarSetup.instance,
    numbers: ref.read(numbersConfigProvider),
    rng: newMathRandom(seed: admission.run.seed),
    botPolicy: const Phase0aBotTacticPolicy.production(),
  );
  final result = runnerForTest == null
      ? await runner.runTowerDurable(floor: floor, admission: admission)
      : await runnerForTest(admission);
  if (result.timedOut) {
    final current = await service.runById(runId);
    if (current == null) {
      throw StateError('Timed-out tower durable run disappeared');
    }
    return DurableActivityExecutionResult(
      outcome: DurableActivityExecutionOutcome.timeout,
      run: current,
    );
  }
  final settlement = result.settlement;
  if (settlement == null ||
      !settlement.isFinished ||
      settlement.playerCharacterId != admission.snapshot.characterId) {
    throw StateError('Tower durable dispatch produced invalid settlement');
  }
  final context = DurableActivitySettlementContext(
    service: service,
    runId: admission.run.id,
  );
  final outcome = settlement.result == BattleResult.leftWin
      ? DurableActivityExecutionOutcome.victory
      : DurableActivityExecutionOutcome.defeat;
  if (outcome == DurableActivityExecutionOutcome.victory) {
    final elapsed = DateTime.now().difference(admission.run.startedAt);
    await applyTowerVictorySettlement(
      ref: ref,
      floor: floor,
      participantId: admission.snapshot.characterId,
      elapsedMs: elapsed.inMilliseconds,
      settlementSnapshot: settlement,
      rewardOccurrenceId: 'tower_durable_run_${admission.run.id}',
      durableActivitySettlement: context,
    );
  } else {
    final progress = TowerProgressService(isar: IsarSetup.instance);
    final disposition = await service.commitSettlement(
      runId: admission.run.id,
      outcome: DurableActivityOutcome.defeat,
      applyInTxn: () async {
        await applyTowerCombatResolution(
          ref: ref,
          floor: floor,
          grantsFirstClearExperience: false,
          expectedParticipantId: admission.snapshot.characterId,
          settlementSnapshot: settlement,
          transactionOwned: true,
        );
        await progress.recordDefeatInTxn(now: DateTime.now());
      },
    );
    if (disposition != DurableActivitySettlementDisposition.applied) {
      throw StateError('Tower durable defeat was already applied');
    }
  }
  final current = await service.runById(runId);
  if (current == null ||
      current.phase != DurableActivityPhase.settlementApplied) {
    throw StateError('Tower durable receipt was not persisted');
  }
  return DurableActivityExecutionResult(outcome: outcome, run: current);
}
