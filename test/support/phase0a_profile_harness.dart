import 'dart:math';

import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';

/// Stable headless profile observation for any already-mapped production content.
/// Percentiles use nearest-rank: rank=ceil(p*n), 1-based.
final class Phase0aProfileRunObservation {
  Phase0aProfileRunObservation({
    required this.profileId,
    String? contentId,
    String? stageId,
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
  }) : contentId =
           contentId ??
           stageId ??
           (throw ArgumentError('contentId is required')),
       numericCasts = List.unmodifiable(numericCasts),
       numericHits = List.unmodifiable(numericHits),
       numericDamage = List.unmodifiable(numericDamage);

  final String profileId, contentId;

  /// Compatibility name for the original Ch1 stage-oriented consumer.
  String get stageId => contentId;
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
      criticalHits,
      maxResolvedDamage;
  final double seconds;
  final String outcome;
  final List<int> numericCasts, numericHits, numericDamage;
  double get hpEndRatio => hpStart == 0 ? 0 : hpEnd / hpStart;
  double get qiEndRatio => qiMax == 0 ? 0 : qiEnd / qiMax;

  @override
  bool operator ==(Object other) =>
      other is Phase0aProfileRunObservation &&
      profileId == other.profileId &&
      contentId == other.contentId &&
      seed == other.seed &&
      outcome == other.outcome &&
      ticks == other.ticks &&
      seconds == other.seconds &&
      hpStart == other.hpStart &&
      hpEnd == other.hpEnd &&
      qiStart == other.qiStart &&
      qiMax == other.qiMax &&
      qiEnd == other.qiEnd &&
      basicCasts == other.basicCasts &&
      basicHits == other.basicHits &&
      basicDamage == other.basicDamage &&
      gatherCasts == other.gatherCasts &&
      gatherDamage == other.gatherDamage &&
      clearCasts == other.clearCasts &&
      clearDamage == other.clearDamage &&
      _same(numericCasts, other.numericCasts) &&
      _same(numericHits, other.numericHits) &&
      _same(numericDamage, other.numericDamage) &&
      totalPlayerDamage == other.totalPlayerDamage &&
      criticalHits == other.criticalHits &&
      maxResolvedDamage == other.maxResolvedDamage;

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length && a.indexed.every((e) => e.$2 == b[e.$1]);

  @override
  int get hashCode => Object.hashAll([
    profileId,
    contentId,
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
      '$profileId/$contentId/$seed/$outcome/$ticks/$hpStart/$hpEnd/$qiStart/$qiMax/$qiEnd/$basicCasts/$basicHits/$basicDamage/$gatherCasts/$gatherDamage/$clearCasts/$clearDamage/$numericCasts/$numericHits/$numericDamage/$totalPlayerDamage/$criticalHits/$maxResolvedDamage';
}

final class Phase0aProfileAggregate {
  const Phase0aProfileAggregate(this.runs);
  final List<Phase0aProfileRunObservation> runs;
  int get wins => runs.where((r) => r.outcome == 'victory').length;
  int get defeats => runs.where((r) => r.outcome == 'defeat').length;
  int get timeouts => runs.where((r) => r.outcome == 'timeout').length;
  double get winRate => runs.isEmpty ? 0 : wins / runs.length;
  double _mean(Iterable<num> values) {
    final list = values.toList();
    return list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
  }

  double _p(Iterable<num> values, double p) {
    final list = values.toList()..sort();
    if (list.isEmpty) return 0;
    return list[(p * list.length).ceil().clamp(1, list.length) - 1].toDouble();
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
      runs.fold(0, (m, r) => max(m, r.maxResolvedDamage));
  List<int> totalNumericCasts() => [
    for (var i = 0; i < 6; i++) runs.fold(0, (s, r) => s + r.numericCasts[i]),
  ];
  List<int> totalNumericDamage() => [
    for (var i = 0; i < 6; i++) runs.fold(0, (s, r) => s + r.numericDamage[i]),
  ];
}

Phase0aProfileRunObservation runPhase0aProfile({
  required String profileId,
  required String contentId,
  required Phase0aStageMapping mapping,
  required NumbersConfig numbers,
  required CombatantSnapshot playerSnapshot,
  required int seed,
  required double deltaSeconds,
  required int maxTicks,
}) {
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
    if (e is Phase0aSkillStarted &&
        e.actor == 'player' &&
        e.hotkey >= 1 &&
        e.hotkey <= 6) {
      nc[e.hotkey - 1]++;
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
  return Phase0aProfileRunObservation(
    profileId: profileId,
    contentId: contentId,
    seed: seed,
    outcome: result.timedOut ? 'timeout' : result.outcome.name,
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
