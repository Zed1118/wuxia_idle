import 'dart:math';

import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';

/// Stable test profile. Percentiles use nearest-rank: rank=ceil(p*n), 1-based.
final class Phase0aCh1RunObservation {
  Phase0aCh1RunObservation({
    required this.profileId,
    required this.stageId,
    required this.seed,
    required this.outcome,
    required this.ticks,
    required this.seconds,
    required this.hpStart,
    required this.hpEnd,
    required this.qiStart,
    required this.qiMax,
    required this.qiEnd,
    required this.basicCasts,
    required this.basicHits,
    required this.basicDamage,
    required this.gatherCasts,
    required this.gatherDamage,
    required this.clearCasts,
    required this.clearDamage,
    required List<int> numericCasts,
    required List<int> numericHits,
    required List<int> numericDamage,
    required this.totalPlayerDamage,
    required this.criticalHits,
    required this.maxResolvedDamage,
  }) : numericCasts = List.unmodifiable(numericCasts),
       numericHits = List.unmodifiable(numericHits),
       numericDamage = List.unmodifiable(numericDamage);
  final String profileId;
  final String stageId;
  final int seed,
      ticks,
      hpStart,
      hpEnd,
      qiStart,
      qiMax,
      qiEnd,
      basicCasts,
      basicHits,
      basicDamage,
      gatherCasts,
      gatherDamage,
      clearCasts,
      clearDamage,
      totalPlayerDamage,
      criticalHits;
  final int maxResolvedDamage;
  final double seconds;
  final String outcome;
  final List<int> numericCasts, numericHits, numericDamage;
  double get hpEndRatio => hpStart == 0 ? 0 : hpEnd / hpStart;
  double get qiEndRatio => qiMax == 0 ? 0 : qiEnd / qiMax;
  @override
  bool operator ==(Object o) =>
      o is Phase0aCh1RunObservation &&
      profileId == o.profileId &&
      stageId == o.stageId &&
      seed == o.seed &&
      outcome == o.outcome &&
      ticks == o.ticks &&
      seconds == o.seconds &&
      hpStart == o.hpStart &&
      hpEnd == o.hpEnd &&
      qiStart == o.qiStart &&
      qiMax == o.qiMax &&
      qiEnd == o.qiEnd &&
      basicCasts == o.basicCasts &&
      basicHits == o.basicHits &&
      basicDamage == o.basicDamage &&
      gatherCasts == o.gatherCasts &&
      gatherDamage == o.gatherDamage &&
      clearCasts == o.clearCasts &&
      clearDamage == o.clearDamage &&
      _same(numericCasts, o.numericCasts) &&
      _same(numericHits, o.numericHits) &&
      _same(numericDamage, o.numericDamage) &&
      totalPlayerDamage == o.totalPlayerDamage &&
      criticalHits == o.criticalHits &&
      maxResolvedDamage == o.maxResolvedDamage;

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length && a.indexed.every((e) => e.$2 == b[e.$1]);
  @override
  int get hashCode => Object.hashAll([
    profileId,
    stageId,
    seed,
    outcome,
    ticks,
    seconds,
    hpStart,
    hpEnd,
    qiStart,
    qiMax,
    qiEnd,
    basicCasts,
    basicHits,
    basicDamage,
    gatherCasts,
    gatherDamage,
    clearCasts,
    clearDamage,
    ...numericCasts,
    ...numericHits,
    ...numericDamage,
    totalPlayerDamage,
    criticalHits,
    maxResolvedDamage,
  ]);
  @override
  String toString() =>
      '$profileId/$stageId/$seed/$outcome/$ticks/$hpStart/$hpEnd/$qiStart/$qiMax/$qiEnd/$basicCasts/$basicHits/$basicDamage/$gatherCasts/$gatherDamage/$clearCasts/$clearDamage/$numericCasts/$numericHits/$numericDamage/$totalPlayerDamage/$criticalHits/$maxResolvedDamage';
}

final class Phase0aCh1ProfileAggregate {
  const Phase0aCh1ProfileAggregate(this.runs);
  final List<Phase0aCh1RunObservation> runs;
  int get wins => runs.where((r) => r.outcome == 'victory').length;
  int get defeats => runs.where((r) => r.outcome == 'defeat').length;
  int get timeouts => runs.where((r) => r.outcome == 'timeout').length;
  double get winRate => runs.isEmpty ? 0 : wins / runs.length;
  double _mean(Iterable<num> x) {
    final a = x.toList();
    return a.isEmpty ? 0 : a.reduce((a, b) => a + b) / a.length;
  }

  double _p(Iterable<num> x, double p) {
    final a = x.toList()..sort();
    if (a.isEmpty) return 0;
    return a[(p * a.length).ceil().clamp(1, a.length) - 1].toDouble();
  }

  double get meanTicks => _mean(runs.map((r) => r.ticks));
  double get p50Ticks => _p(runs.map((r) => r.ticks), .5);
  double get p90Ticks => _p(runs.map((r) => r.ticks), .9);
  double get meanHpEndRatio => _mean(runs.map((r) => r.hpEndRatio));
  double get meanQiEndRatio => _mean(runs.map((r) => r.qiEndRatio));
  int get totalBasicCasts => runs.fold(0, (s, r) => s + r.basicCasts);
  int get totalBasicDamage => runs.fold(0, (s, r) => s + r.basicDamage);
  int get totalGatherCasts => runs.fold(0, (s, r) => s + r.gatherCasts);
  int get totalClearCasts => runs.fold(0, (s, r) => s + r.clearCasts);
  int get totalGatherDamage => runs.fold(0, (s, r) => s + r.gatherDamage);
  int get totalClearDamage => runs.fold(0, (s, r) => s + r.clearDamage);
  int get totalPlayerDamage => runs.fold(0, (s, r) => s + r.totalPlayerDamage);
  int get maxResolvedDamage =>
      runs.fold(0, (maxDamage, run) => max(maxDamage, run.maxResolvedDamage));
  List<int> totalNumericCasts() => [
    for (var i = 0; i < 6; i++) runs.fold(0, (s, r) => s + r.numericCasts[i]),
  ];
  List<int> totalNumericDamage() => [
    for (var i = 0; i < 6; i++) runs.fold(0, (s, r) => s + r.numericDamage[i]),
  ];
}

Phase0aCh1RunObservation runPhase0aCh1Profile({
  required String profileId,
  required StageDef stage,
  required CombatantSnapshot playerSnapshot,
  required NumbersConfig numbers,
  required int seed,
  required double deltaSeconds,
  required int maxTicks,
}) {
  final mapping = Phase0aStageContentMapper.map(
    stage: stage,
    playerSnapshot: playerSnapshot,
    numbers: numbers,
  );
  final flow = Phase0aProductionFlowAssembler.assemble(
    initialState: mapping.initialState,
    waves: mapping.waves,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    numbers: numbers,
    rng: Random(seed),
    playerAdapter: mapping.playerAdapter,
    enemyAiAdapter: mapping.enemyAiAdapter,
  );
  final result = Phase0aHeadlessRunner.runToEnd(
    flow: flow,
    bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
    deltaSeconds: deltaSeconds,
    maxTicks: maxTicks,
  );
  var basicC = 0,
      basicH = 0,
      basicD = 0,
      gatherC = 0,
      gatherD = 0,
      clearC = 0,
      clearD = 0,
      total = 0,
      crit = 0,
      maxDamage = 0;
  final nc = List.filled(6, 0), nh = List.filled(6, 0), nd = List.filled(6, 0);
  for (final e in result.events) {
    if (e is Phase0aAttackStarted && e.actor == 'player') basicC++;
    if (e is Phase0aHitLanded && e.actor == 'player') {
      basicH++;
      basicD += e.resolvedDamage;
      total += e.resolvedDamage;
      maxDamage = max(maxDamage, e.resolvedDamage);
      if (e.isCritical) crit++;
    }
    if (e is Phase0aGatherStarted && e.actor == 'player') gatherC++;
    if (e is Phase0aGatherApplied && e.actor == 'player') {
      for (final o in e.outcomes) {
        gatherD += o.resolvedDamage;
        total += o.resolvedDamage;
        maxDamage = max(maxDamage, o.resolvedDamage);
        if (o.isCritical) crit++;
      }
    }
    if (e is Phase0aClearStarted && e.actor == 'player') clearC++;
    if (e is Phase0aClearApplied && e.actor == 'player') {
      for (final o in e.outcomes) {
        clearD += o.resolvedDamage;
        total += o.resolvedDamage;
        maxDamage = max(maxDamage, o.resolvedDamage);
        if (o.isCritical) crit++;
      }
    }
    if (e is Phase0aSkillStarted && e.actor == 'player') {
      if (e.hotkey >= 1 && e.hotkey <= 6) nc[e.hotkey - 1]++;
    }
    if (e is Phase0aSkillApplied && e.actor == 'player') {
      final i = e.hotkey >= 1 && e.hotkey <= 6 ? e.hotkey - 1 : -1;
      for (final o in e.outcomes) {
        total += o.resolvedDamage;
        maxDamage = max(maxDamage, o.resolvedDamage);
        if (o.isCritical) crit++;
        if (i >= 0) {
          nd[i] += o.resolvedDamage;
          if (o.resolvedDamage > 0) nh[i]++;
        }
      }
    }
  }
  if (result.timedOut) {
    return Phase0aCh1RunObservation(
      profileId: profileId,
      stageId: stage.id,
      seed: seed,
      outcome: 'timeout',
      ticks: result.ticks,
      seconds: result.ticks * deltaSeconds,
      hpStart: playerSnapshot.currentHp,
      hpEnd: result.finalState.player.currentHealth,
      qiStart: playerSnapshot.currentQi,
      qiMax: playerSnapshot.maxQi,
      qiEnd: result.finalState.player.qiCurrent,
      basicCasts: basicC,
      basicHits: basicH,
      basicDamage: basicD,
      gatherCasts: gatherC,
      gatherDamage: gatherD,
      clearCasts: clearC,
      clearDamage: clearD,
      numericCasts: nc,
      numericHits: nh,
      numericDamage: nd,
      totalPlayerDamage: total,
      criticalHits: crit,
      maxResolvedDamage: maxDamage,
    );
  }
  return Phase0aCh1RunObservation(
    profileId: profileId,
    stageId: stage.id,
    seed: seed,
    outcome: result.outcome.name,
    ticks: result.ticks,
    seconds: result.ticks * deltaSeconds,
    hpStart: playerSnapshot.currentHp,
    hpEnd: result.finalState.player.currentHealth,
    qiStart: playerSnapshot.currentQi,
    qiMax: playerSnapshot.maxQi,
    qiEnd: result.finalState.player.qiCurrent,
    basicCasts: basicC,
    basicHits: basicH,
    basicDamage: basicD,
    gatherCasts: gatherC,
    gatherDamage: gatherD,
    clearCasts: clearC,
    clearDamage: clearD,
    numericCasts: nc,
    numericHits: nh,
    numericDamage: nd,
    totalPlayerDamage: total,
    criticalHits: crit,
    maxResolvedDamage: maxDamage,
  );
}
