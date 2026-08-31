import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
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
