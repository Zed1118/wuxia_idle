import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_observe_only_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/action_timeline.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/qi_resource.dart';
import 'package:yaml/yaml.dart';

typedef StageScenario = ({
  String id,
  bool isBoss,
  bool hasCharge,
  int baseSpeed,
  int enemyCount,
  List<String> skillIds,
});

typedef SkillSample = ({
  String id,
  String type,
  int power,
  int qiDelta,
  double cooldownSeconds,
});

typedef PostureCandidate = ({String id, PostureConfig config});

typedef PostureMetrics = ({
  double firstBreakSeconds,
  double breaksPerMinute,
  double vulnerabilityPercent,
  double suppressedHitsPerMinute,
});

typedef TimelineCandidate = ({
  String id,
  Map<WeaponType, ActionTimelineConfig> configs,
});

typedef TimelineMetrics = ({
  double feedbacksPerMinute,
  double completionsPerMinute,
  double meanFirstFeedbackMs,
  double activePercent,
  double threatCancelPercent,
  double preFeedbackInterruptPercent,
});

typedef TokenCandidate = ({String id, AttackTokenBudgets budgets});

typedef TokenMetrics = ({
  double grantsPerBatch,
  double grantPercent,
  double meanDeniedStreakBatches,
  double p95DeniedStreakBatches,
  Map<AttackTokenKind, double> grantPercentByKind,
});

enum QiRecoveryPolicy { basicOnly, weaponWeightedBasic, basicAndCappedKill }

typedef QiWeaponProfile = ({
  int capacity,
  int opening,
  int basicGain,
  int powerCost,
  int ultimateCost,
  int killGain,
  int killWindowCap,
});

typedef QiCandidate = ({
  String id,
  QiRecoveryPolicy recoveryPolicy,
  Map<WeaponType, QiWeaponProfile> weapons,
});

typedef QiMetrics = ({
  double skillsPerMinute,
  double insufficientPercent,
  double belowPowerCostPercent,
  double meanQi,
  double gainOverflowPercent,
});

final class ProductionCorpus {
  ProductionCorpus._({
    required this.fixedDeltaSeconds,
    required this.maxBattleSeconds,
    required this.playerAttackCooldownSeconds,
    required this.enemyAttackCooldownSeconds,
    required this.playerAttackRange,
    required this.playerAttackHalfArcRadians,
    required this.basicPower,
    required this.clearPower,
    required this.clearCooldownSeconds,
    required this.qiCapacity,
    required this.openingQi,
    required this.stages,
    required this.skills,
    required this.encounterEntries,
    required this.behaviors,
    required this.encounterActiveLimit,
  });

  factory ProductionCorpus.load() {
    final numbers = _yamlMap('data/numbers.yaml');
    final stagesYaml = _yamlMap('data/stages.yaml');
    final skillsYaml = _yamlMap('data/skills.yaml');
    final encounterYaml = _yamlMap(
      'data/combat/encounters/black_wind_ridge.yaml',
    );
    final bindingsYaml = _yamlMap('data/combat/runtime_bindings.yaml');

    final combat = numbers['combat'] as YamlMap;
    final qi = combat['qi'] as YamlMap;
    final arena = numbers['phase0a_arena'] as YamlMap;
    final simulation = arena['simulation'] as YamlMap;
    final player = arena['player'] as YamlMap;
    final enemy = arena['enemy'] as YamlMap;
    final moves = arena['moves'] as YamlMap;
    final mainlineWave = numbers['mainline_wave'] as YamlMap;
    final ordinaryWave = mainlineWave['ordinary'] as YamlMap;
    final bossWave = mainlineWave['boss'] as YamlMap;

    int enemyCountFor(bool boss) {
      final profile = boss ? bossWave : ordinaryWave;
      final waves = profile['waves'] as YamlList;
      final waveCount = waves.whereType<YamlMap>().fold<int>(
        0,
        (sum, wave) => sum + (wave['count'] as int),
      );
      return waveCount + (profile['boss_final_enemy_count'] as int);
    }

    final stages = <StageScenario>[];
    for (final raw in (stagesYaml['stages'] as YamlList).whereType<YamlMap>()) {
      if (raw['stageType'] != 'mainline') continue;
      final enemyTeam =
          (raw['enemyTeam'] as YamlList?)?.whereType<YamlMap>().toList(
            growable: false,
          ) ??
          const <YamlMap>[];
      if (enemyTeam.isEmpty) continue;
      final primary = enemyTeam.first;
      final isBoss = raw['isBossStage'] == true;
      final phases = primary['bossPhases'] as YamlList?;
      final phaseCharge =
          phases?.whereType<YamlMap>().any(
            (phase) => phase['onEnterMechanic'] == 'chargeCounter',
          ) ??
          false;
      stages.add((
        id: raw['id'] as String,
        isBoss: isBoss,
        hasCharge: primary['chargeSkillId'] != null || phaseCharge,
        baseSpeed: primary['baseSpeed'] as int,
        enemyCount: enemyCountFor(isBoss),
        skillIds:
            (primary['skillIds'] as YamlList?)?.whereType<String>().toList(
              growable: false,
            ) ??
            const <String>[],
      ));
    }

    final skills = <String, SkillSample>{};
    for (final raw in (skillsYaml['skills'] as YamlList).whereType<YamlMap>()) {
      final id = raw['id'] as String;
      skills[id] = (
        id: id,
        type: raw['type'] as String,
        power: raw['powerMultiplier'] as int,
        qiDelta: raw['qiDelta'] as int,
        cooldownSeconds: (raw['cooldownSeconds'] as num).toDouble(),
      );
    }

    final encounter = (encounterYaml['encounters'] as YamlList)
        .whereType<YamlMap>()
        .single;
    final bindings = (bindingsYaml['runtime_bindings'] as YamlList)
        .whereType<YamlMap>()
        .single;
    final behaviors = <String, YamlMap>{
      for (final behavior
          in (bindings['behaviors'] as YamlList).whereType<YamlMap>())
        behavior['id'] as String: behavior,
    };

    return ProductionCorpus._(
      fixedDeltaSeconds: (simulation['fixed_delta_seconds'] as num).toDouble(),
      maxBattleSeconds: (simulation['max_battle_seconds'] as num).toDouble(),
      playerAttackCooldownSeconds: (player['attack_cooldown_seconds'] as num)
          .toDouble(),
      enemyAttackCooldownSeconds: (enemy['attack_cooldown_seconds'] as num)
          .toDouble(),
      playerAttackRange: (player['attack_range'] as num).toDouble(),
      playerAttackHalfArcRadians: (player['attack_half_arc_radians'] as num)
          .toDouble(),
      basicPower: moves['basic_power_multiplier'] as int,
      clearPower: moves['clear_power_multiplier'] as int,
      clearCooldownSeconds: (player['clear_cooldown_seconds'] as num)
          .toDouble(),
      qiCapacity: qi['base_max'] as int,
      openingQi: qi['opening_qi'] as int,
      stages: stages,
      skills: skills,
      encounterEntries: (encounter['spawn_entries'] as YamlList)
          .whereType<YamlMap>()
          .toList(growable: false),
      behaviors: behaviors,
      encounterActiveLimit:
          (encounter['spawn_config'] as YamlMap)['active_limit'] as int,
    );
  }

  final double fixedDeltaSeconds;
  final double maxBattleSeconds;
  final double playerAttackCooldownSeconds;
  final double enemyAttackCooldownSeconds;
  final double playerAttackRange;
  final double playerAttackHalfArcRadians;
  final int basicPower;
  final int clearPower;
  final double clearCooldownSeconds;
  final int qiCapacity;
  final int openingQi;
  final List<StageScenario> stages;
  final Map<String, SkillSample> skills;
  final List<YamlMap> encounterEntries;
  final Map<String, YamlMap> behaviors;
  final int encounterActiveLimit;
}

void main() {
  late ProductionCorpus corpus;

  setUpAll(() {
    corpus = ProductionCorpus.load();
    expect(corpus.stages, hasLength(105));
    expect(corpus.stages.where((stage) => stage.isBoss), hasLength(42));
    expect(corpus.skills, hasLength(221));
    expect(corpus.encounterEntries, hasLength(40));
    expect(corpus.encounterActiveLimit, 12);
  });

  test('TUNE-POSTURE-01 generates three materially different candidates', () {
    final candidates = _postureCandidates();
    final results = {
      for (final candidate in candidates)
        candidate.id: _simulatePosture(corpus, candidate),
    };

    for (final candidate in candidates) {
      final metrics = results[candidate.id]!;
      debugPrint(
        'POSTURE ${candidate.id} '
        'params=${_postureParams(candidate)} '
        'firstBreak=${metrics.firstBreakSeconds.toStringAsFixed(2)}s '
        'breaksPerMin=${metrics.breaksPerMinute.toStringAsFixed(2)} '
        'vulnerable=${metrics.vulnerabilityPercent.toStringAsFixed(2)}% '
        'suppressedHitsPerMin=${metrics.suppressedHitsPerMinute.toStringAsFixed(2)}',
      );
    }

    expect(candidates.map(_postureParams).toSet(), hasLength(3));
    expect(
      results.values
          .map((result) => result.breaksPerMinute.toStringAsFixed(2))
          .toSet(),
      hasLength(3),
    );
  });

  test('TUNE-WEAPON-TIMELINE-01 generates complete five-weapon configs', () {
    final candidates = _timelineCandidates();
    final results = {
      for (final candidate in candidates)
        candidate.id: _simulateTimeline(corpus, candidate),
    };

    for (final candidate in candidates) {
      expect(candidate.configs.keys.toSet(), WeaponType.values.toSet());
      final metrics = results[candidate.id]!;
      debugPrint(
        'TIMELINE ${candidate.id} '
        'params=${_timelineParams(candidate)} '
        'feedbacksPerMin=${metrics.feedbacksPerMinute.toStringAsFixed(2)} '
        'completionsPerMin=${metrics.completionsPerMinute.toStringAsFixed(2)} '
        'meanFirstFeedback=${metrics.meanFirstFeedbackMs.toStringAsFixed(2)}ms '
        'active=${metrics.activePercent.toStringAsFixed(2)}% '
        'threatCancel=${metrics.threatCancelPercent.toStringAsFixed(2)}% '
        'preFeedbackInterrupt=${metrics.preFeedbackInterruptPercent.toStringAsFixed(2)}%',
      );
    }

    expect(candidates.map(_timelineParams).toSet(), hasLength(3));
    expect(
      results.values
          .map((result) => result.feedbacksPerMinute.toStringAsFixed(2))
          .toSet(),
      hasLength(3),
    );
  });

  test('TUNE-ATTACK-TOKEN-01 replays production 40-enemy role mix', () {
    final candidates = _tokenCandidates();
    final results = {
      for (final candidate in candidates)
        candidate.id: _simulateTokens(corpus, candidate),
    };

    for (final candidate in candidates) {
      final metrics = results[candidate.id]!;
      debugPrint(
        'TOKEN ${candidate.id} '
        'params=${_tokenParams(candidate)} '
        'grantsPerBatch=${metrics.grantsPerBatch.toStringAsFixed(2)} '
        'grant=${metrics.grantPercent.toStringAsFixed(2)}% '
        'meanDeniedStreak=${metrics.meanDeniedStreakBatches.toStringAsFixed(2)} '
        'p95DeniedStreak=${metrics.p95DeniedStreakBatches.toStringAsFixed(2)} '
        'byKind=${_kindMetrics(metrics.grantPercentByKind)}',
      );
    }

    expect(candidates.map(_tokenParams).toSet(), hasLength(3));
    expect(
      results.values
          .map((result) => result.grantPercent.toStringAsFixed(2))
          .toSet(),
      hasLength(3),
    );
  });

  test('TUNE-WEAPON-QI-01 replays production stage and skill cadence', () {
    final candidates = _qiCandidates(corpus);
    final results = {
      for (final candidate in candidates)
        candidate.id: _simulateQi(corpus, candidate),
    };

    for (final candidate in candidates) {
      final metrics = results[candidate.id]!;
      debugPrint(
        'QI ${candidate.id} '
        'policy=${candidate.recoveryPolicy.name} '
        'params=${_qiParams(candidate)} '
        'skillsPerMin=${metrics.skillsPerMinute.toStringAsFixed(2)} '
        'insufficient=${metrics.insufficientPercent.toStringAsFixed(2)}% '
        'belowPowerCost=${metrics.belowPowerCostPercent.toStringAsFixed(2)}% '
        'meanQi=${metrics.meanQi.toStringAsFixed(2)} '
        'gainOverflow=${metrics.gainOverflowPercent.toStringAsFixed(2)}%',
      );
    }

    expect(candidates.map(_qiParams).toSet(), hasLength(3));
    expect(
      results.values
          .map((result) => result.insufficientPercent.toStringAsFixed(2))
          .toSet(),
      hasLength(3),
    );
  });
}

List<PostureCandidate> _postureCandidates() => [
  (
    id: 'A',
    config: PostureConfig(
      capacity: 10,
      vulnerabilityTicks: 3,
      recoveryPolicy: PostureRecoveryPolicy.reset,
      postVulnerabilityAccumulated: 0,
      bossControlConversionFactor: 2,
    ),
  ),
  (
    id: 'B',
    config: PostureConfig(
      capacity: 14,
      vulnerabilityTicks: 4,
      recoveryPolicy: PostureRecoveryPolicy.recover,
      postVulnerabilityAccumulated: 4,
      bossControlConversionFactor: 3,
    ),
  ),
  (
    id: 'C',
    config: PostureConfig(
      capacity: 18,
      vulnerabilityTicks: 5,
      recoveryPolicy: PostureRecoveryPolicy.recover,
      postVulnerabilityAccumulated: 9,
      bossControlConversionFactor: 4,
    ),
  ),
];

PostureMetrics _simulatePosture(
  ProductionCorpus corpus,
  PostureCandidate candidate,
) {
  final bossStages = corpus.stages.where((stage) => stage.isBoss).toList();
  final ticks = (corpus.maxBattleSeconds / corpus.fixedDeltaSeconds).round();
  final basicCadence =
      (corpus.playerAttackCooldownSeconds / corpus.fixedDeltaSeconds).round();
  final clearCadence = (corpus.clearCooldownSeconds / corpus.fixedDeltaSeconds)
      .round();
  var totalBreaks = 0;
  var vulnerableTicks = 0;
  var suppressedHits = 0;
  var firstBreakSeconds = 0.0;

  for (final stage in bossStages) {
    var state = PostureState.initial(candidate.config);
    int? firstBreakTick;
    final stageSkills = stage.skillIds
        .map((id) => corpus.skills[id])
        .whereType<SkillSample>()
        .where((skill) => skill.type != 'normalAttack')
        .toList();
    final strongest = stageSkills.isEmpty
        ? null
        : (stageSkills..sort((a, b) => b.power.compareTo(a.power))).first;
    final skillCadence = strongest == null
        ? 0
        : math.max(
            1,
            (strongest.cooldownSeconds / corpus.fixedDeltaSeconds).round(),
          );

    for (var tick = 0; tick < ticks; tick++) {
      if (state.isVulnerable) {
        vulnerableTicks++;
        state = state.advance(1).state;
      }

      final damages = <({double damage, PostureHitKind kind})>[];
      if (tick % basicCadence == 0) {
        damages.add((damage: 1, kind: PostureHitKind.light));
      }
      if (strongest != null &&
          tick % skillCadence == _stableHash(stage.id) % skillCadence) {
        damages.add((
          damage: math.max(1, strongest.power / corpus.basicPower),
          kind: PostureHitKind.heavy,
        ));
      }
      if (tick % clearCadence ==
          _stableHash('${stage.id}.clear') % clearCadence) {
        final control = stage.hasCharge
            ? bossControlToPostureDamage(
                1,
                conversionFactor: candidate.config.bossControlConversionFactor,
              )
            : 0.0;
        damages.add((
          damage: corpus.clearPower / corpus.basicPower + control,
          kind: stage.hasCharge
              ? PostureHitKind.bossControl
              : PostureHitKind.heavy,
        ));
      }

      for (final hit in damages) {
        final transition = state.apply(hit.damage, hitKind: hit.kind);
        totalBreaks += transition.events
            .where(
              (event) => event.type == PostureEventType.vulnerabilityEntered,
            )
            .length;
        suppressedHits += transition.events
            .where(
              (event) =>
                  event.type ==
                  PostureEventType.postureDamageSuppressedDuringVulnerability,
            )
            .length;
        if (firstBreakTick == null &&
            transition.events.any(
              (event) => event.type == PostureEventType.vulnerabilityEntered,
            )) {
          firstBreakTick = tick;
        }
        state = transition.state;
      }
    }
    firstBreakSeconds += (firstBreakTick ?? ticks) * corpus.fixedDeltaSeconds;
  }

  final totalSeconds = bossStages.length * corpus.maxBattleSeconds;
  return (
    firstBreakSeconds: firstBreakSeconds / bossStages.length,
    breaksPerMinute: totalBreaks / totalSeconds * 60,
    vulnerabilityPercent: vulnerableTicks / (bossStages.length * ticks) * 100,
    suppressedHitsPerMinute: suppressedHits / totalSeconds * 60,
  );
}

List<TimelineCandidate> _timelineCandidates() => [
  (
    id: 'A',
    configs: _timelineSet(const {
      WeaponType.sword: [1, 2, 2, 1, 1, 3, 2, 1, 3],
      WeaponType.heavy: [2, 2, 2, 2, 2, 4, 3, 2, 4],
      WeaponType.flexible: [1, 3, 2, 1, 1, 4, 2, 1, 3],
      WeaponType.dual: [0, 3, 2, 0, 0, 3, 2, 1, 3],
      WeaponType.hidden: [0, 1, 3, 0, 0, 2, 2, 1, 3],
    }),
  ),
  (
    id: 'B',
    configs: _timelineSet(const {
      WeaponType.sword: [1, 2, 3, 1, 1, 4, 3, 2, 4],
      WeaponType.heavy: [2, 3, 3, 2, 2, 5, 4, 3, 5],
      WeaponType.flexible: [1, 4, 2, 1, 1, 4, 3, 2, 4],
      WeaponType.dual: [0, 4, 2, 0, 0, 4, 2, 1, 3],
      WeaponType.hidden: [0, 2, 3, 0, 0, 3, 2, 1, 3],
    }),
  ),
  (
    id: 'C',
    configs: _timelineSet(const {
      WeaponType.sword: [1, 3, 2, 1, 2, 4, 2, 2, 3],
      WeaponType.heavy: [2, 4, 2, 2, 3, 6, 3, 2, 4],
      WeaponType.flexible: [1, 5, 1, 1, 2, 5, 2, 2, 3],
      WeaponType.dual: [0, 5, 1, 0, 1, 5, 2, 1, 3],
      WeaponType.hidden: [0, 3, 2, 0, 1, 3, 2, 1, 3],
    }),
  ),
];

Map<WeaponType, ActionTimelineConfig> _timelineSet(
  Map<WeaponType, List<int>> values,
) => {
  for (final entry in values.entries)
    entry.key: ActionTimelineConfig(
      windupTicks: entry.value[0],
      activeTicks: entry.value[1],
      recoveryTicks: entry.value[2],
      firstEffectTick: entry.value[3],
      cancelWindowStartTick: entry.value[4],
      cancelWindowEndTick: entry.value[5],
      interruptedCooldownTicks: entry.value[6],
      cancelledCooldownTicks: entry.value[7],
      failedCooldownTicks: entry.value[8],
    ),
};

TimelineMetrics _simulateTimeline(
  ProductionCorpus corpus,
  TimelineCandidate candidate,
) {
  final ticks = (corpus.maxBattleSeconds / corpus.fixedDeltaSeconds).round();
  var feedbacks = 0;
  var completions = 0;
  var firstFeedbackTickSum = 0;
  var activeTicks = 0;
  var threatAttempts = 0;
  var cancelledThreats = 0;
  var interruptedBeforeFeedback = 0;

  for (final stage in corpus.stages) {
    for (final weapon in WeaponType.values) {
      final config = candidate.configs[weapon]!;
      ActionTimeline? timeline;
      var failureCooldown = 0;
      var emittedFeedback = false;
      final threatCadence = math.max(
        3,
        (corpus.enemyAttackCooldownSeconds /
                corpus.fixedDeltaSeconds *
                100 /
                stage.baseSpeed)
            .round(),
      );
      final threatOffset =
          _stableHash('${stage.id}.${weapon.name}') % threatCadence;

      for (var tick = 0; tick < ticks; tick++) {
        if (failureCooldown > 0) {
          failureCooldown--;
          continue;
        }
        if (timeline?.phase == ActionTimelinePhase.completed) {
          completions++;
        }
        if (timeline == null ||
            timeline.phase == ActionTimelinePhase.completed ||
            timeline.phase == ActionTimelinePhase.cancelled ||
            timeline.phase == ActionTimelinePhase.interrupted ||
            timeline.phase == ActionTimelinePhase.failed) {
          timeline = ActionTimeline(config)..start();
          emittedFeedback = false;
        }

        if (tick % threatCadence == threatOffset) {
          threatAttempts++;
          if (timeline.cancel()) {
            cancelledThreats++;
            failureCooldown = timeline.cooldownRemainingTicks;
            continue;
          }
          if (timeline.interrupt()) {
            if (!emittedFeedback) interruptedBeforeFeedback++;
            failureCooldown = timeline.cooldownRemainingTicks;
            continue;
          }
        }

        if (timeline.phase == ActionTimelinePhase.active) activeTicks++;
        final events = timeline.advance(1);
        for (final event in events) {
          if (event.type == ActionTimelineEventType.firstEffect) {
            feedbacks++;
            firstFeedbackTickSum += event.tick;
            emittedFeedback = true;
          }
        }
      }
    }
  }

  final streams = corpus.stages.length * WeaponType.values.length;
  final totalSeconds = streams * corpus.maxBattleSeconds;
  return (
    feedbacksPerMinute: feedbacks / totalSeconds * 60,
    completionsPerMinute: completions / totalSeconds * 60,
    meanFirstFeedbackMs: feedbacks == 0
        ? 0
        : firstFeedbackTickSum / feedbacks * corpus.fixedDeltaSeconds * 1000,
    activePercent: activeTicks / (streams * ticks) * 100,
    threatCancelPercent: threatAttempts == 0
        ? 0
        : cancelledThreats / threatAttempts * 100,
    preFeedbackInterruptPercent: threatAttempts == 0
        ? 0
        : interruptedBeforeFeedback / threatAttempts * 100,
  );
}

List<TokenCandidate> _tokenCandidates() => [
  (
    id: 'A',
    budgets: AttackTokenBudgets(melee: 1, ranged: 1, charge: 1, support: 1),
  ),
  (
    id: 'B',
    budgets: AttackTokenBudgets(melee: 2, ranged: 2, charge: 1, support: 1),
  ),
  (
    id: 'C',
    budgets: AttackTokenBudgets(melee: 3, ranged: 1, charge: 2, support: 1),
  ),
];

TokenMetrics _simulateTokens(
  ProductionCorpus corpus,
  TokenCandidate candidate,
) {
  final entryById = <String, YamlMap>{
    for (final entry in corpus.encounterEntries)
      entry['entry_id'] as String: entry,
  };
  final behaviorByActor = <String, YamlMap>{
    for (final entry in corpus.encounterEntries)
      entry['entry_id'] as String:
          corpus.behaviors[entry['behavior_id'] as String]!,
  };
  final observer = AttackTokenObserveOnlyObserver(
    director: const AttackTokenDirector(),
    budgets: candidate.budgets,
    requestMapper: (intent) {
      final behavior = behaviorByActor[intent.actorId]!;
      return AttackTokenRequest(
        actorId: intent.actorId,
        kind: AttackTokenKind.values.byName(behavior['token_policy'] as String),
        priority: behavior['priority'] as int,
        isOffscreen: behavior['is_offscreen'] as bool,
        isHighImpact: behavior['is_high_impact'] as bool,
        isUnblockableArea: behavior['is_unblockable_area'] as bool,
        spawnGraceTicksRemaining:
            behavior['spawn_grace_ticks_remaining'] as int,
        telegraphReady: behavior['telegraph_ready'] as bool,
      );
    },
  );
  final batches = (corpus.maxBattleSeconds / corpus.enemyAttackCooldownSeconds)
      .round();
  var grants = 0;
  var requests = 0;
  final kindGrants = {for (final kind in AttackTokenKind.values) kind: 0};
  final kindRequests = {for (final kind in AttackTokenKind.values) kind: 0};
  final currentDeniedStreak = <String, int>{};
  final deniedStreaks = <int>[];

  for (var batch = 0; batch < batches; batch++) {
    final active = <YamlMap>[
      for (var offset = 0; offset < corpus.encounterActiveLimit; offset++)
        corpus.encounterEntries[(batch + offset) %
            corpus.encounterEntries.length],
    ];
    final intents = [
      for (final entry in active)
        Phase0aAttackIntent(
          actorId: entry['entry_id'] as String,
          range: corpus.playerAttackRange,
          halfArcRadians: corpus.playerAttackHalfArcRadians,
          cooldownSeconds: corpus.enemyAttackCooldownSeconds,
          moveKind: Phase0aMoveKind.light,
          aimDirection: const ArenaVector(-1, 0),
          qiDelta: 0,
          postureDamage: 0,
          postureHitKind: PostureHitKind.light,
        ),
    ];
    observer.observe(
      Phase0aEnemyIntentObservation(tick: batch, enemyIntents: intents),
    );
    final allocation = observer.lastAllocation!;
    requests += allocation.decisions.length;
    grants += allocation.grantedCount;
    for (final decision in allocation.decisions) {
      final kind = AttackTokenKind.values.byName(
        behaviorByActor[decision.actorId]!['token_policy'] as String,
      );
      kindRequests[kind] = kindRequests[kind]! + 1;
      if (decision.granted) {
        kindGrants[kind] = kindGrants[kind]! + 1;
        final streak = currentDeniedStreak.remove(decision.actorId) ?? 0;
        if (streak > 0) deniedStreaks.add(streak);
      } else {
        currentDeniedStreak[decision.actorId] =
            (currentDeniedStreak[decision.actorId] ?? 0) + 1;
      }
    }
  }
  deniedStreaks.addAll(currentDeniedStreak.values.where((value) => value > 0));
  deniedStreaks.sort();

  expect(entryById, hasLength(40));
  return (
    grantsPerBatch: grants / batches,
    grantPercent: grants / requests * 100,
    meanDeniedStreakBatches: deniedStreaks.isEmpty
        ? 0
        : deniedStreaks.reduce((a, b) => a + b) / deniedStreaks.length,
    p95DeniedStreakBatches: _percentile(deniedStreaks, 0.95),
    grantPercentByKind: {
      for (final kind in AttackTokenKind.values)
        kind: kindRequests[kind] == 0
            ? 0
            : kindGrants[kind]! / kindRequests[kind]! * 100,
    },
  );
}

List<QiCandidate> _qiCandidates(ProductionCorpus corpus) {
  QiWeaponProfile profile({
    required int basic,
    required int power,
    required int ultimate,
    int kill = 0,
    int window = 0,
  }) => (
    capacity: corpus.qiCapacity,
    opening: corpus.openingQi,
    basicGain: basic,
    powerCost: power,
    ultimateCost: ultimate,
    killGain: kill,
    killWindowCap: window,
  );

  return [
    (
      id: 'A',
      recoveryPolicy: QiRecoveryPolicy.basicOnly,
      weapons: {
        for (final weapon in WeaponType.values)
          weapon: profile(basic: 20, power: 30, ultimate: 60),
      },
    ),
    (
      id: 'B',
      recoveryPolicy: QiRecoveryPolicy.weaponWeightedBasic,
      weapons: {
        WeaponType.sword: profile(basic: 22, power: 32, ultimate: 60),
        WeaponType.heavy: profile(basic: 28, power: 40, ultimate: 70),
        WeaponType.flexible: profile(basic: 24, power: 34, ultimate: 62),
        WeaponType.dual: profile(basic: 18, power: 28, ultimate: 54),
        WeaponType.hidden: profile(basic: 20, power: 30, ultimate: 56),
      },
    ),
    (
      id: 'C',
      recoveryPolicy: QiRecoveryPolicy.basicAndCappedKill,
      weapons: {
        WeaponType.sword: profile(
          basic: 20,
          power: 28,
          ultimate: 52,
          kill: 5,
          window: 15,
        ),
        WeaponType.heavy: profile(
          basic: 24,
          power: 34,
          ultimate: 60,
          kill: 5,
          window: 15,
        ),
        WeaponType.flexible: profile(
          basic: 22,
          power: 30,
          ultimate: 54,
          kill: 5,
          window: 15,
        ),
        WeaponType.dual: profile(
          basic: 18,
          power: 24,
          ultimate: 46,
          kill: 5,
          window: 15,
        ),
        WeaponType.hidden: profile(
          basic: 18,
          power: 26,
          ultimate: 48,
          kill: 5,
          window: 15,
        ),
      },
    ),
  ];
}

QiMetrics _simulateQi(ProductionCorpus corpus, QiCandidate candidate) {
  final powerSkills = corpus.skills.values
      .where((skill) => skill.type == 'powerSkill' && skill.cooldownSeconds > 0)
      .toList(growable: false);
  final ultimateSkills = corpus.skills.values
      .where((skill) => skill.type == 'ultimate' && skill.cooldownSeconds > 0)
      .toList(growable: false);
  final ticks = (corpus.maxBattleSeconds / corpus.fixedDeltaSeconds).round();
  final basicCadence =
      (corpus.playerAttackCooldownSeconds / corpus.fixedDeltaSeconds).round();
  var skillAttempts = 0;
  var skillCommits = 0;
  var insufficient = 0;
  var belowPowerCostTicks = 0;
  var totalTicks = 0;
  var qiSamples = 0;
  var rawGain = 0;
  var overflow = 0;

  for (var stageIndex = 0; stageIndex < corpus.stages.length; stageIndex++) {
    final stage = corpus.stages[stageIndex];
    for (final weapon in WeaponType.values) {
      final profile = candidate.weapons[weapon]!;
      final ledger = QiResourceLedger(
        capacity: profile.capacity,
        current: profile.opening,
      );
      final power =
          powerSkills[(stageIndex * WeaponType.values.length + weapon.index) %
              powerSkills.length];
      final ultimate =
          ultimateSkills[(stageIndex * 3 + weapon.index) %
              ultimateSkills.length];
      final powerCadence = math.max(
        1,
        (power.cooldownSeconds / corpus.fixedDeltaSeconds).round(),
      );
      final ultimateCadence = math.max(
        1,
        (ultimate.cooldownSeconds / corpus.fixedDeltaSeconds).round(),
      );
      final killTicks = <int>{
        for (var kill = 1; kill <= stage.enemyCount; kill++)
          (kill * ticks / (stage.enemyCount + 1)).round(),
      };
      var actionSequence = 0;

      void gainBasic() {
        rawGain += profile.basicGain;
        final result = ledger.gainAction(
          actionId: '${stage.id}.${weapon.name}.basic.${actionSequence++}',
          amount: profile.basicGain,
        );
        overflow += result.overflow;
      }

      void trySkill(int cost, String kind) {
        skillAttempts++;
        final id = '${stage.id}.${weapon.name}.$kind.${actionSequence++}';
        try {
          ledger.reserve(actionId: id, amount: cost);
          ledger.commit(id);
          skillCommits++;
        } on StateError {
          insufficient++;
        }
      }

      for (var tick = 0; tick < ticks; tick++) {
        if (tick % basicCadence == 0) gainBasic();
        if (tick % powerCadence ==
            _stableHash('${stage.id}.power') % powerCadence) {
          trySkill(profile.powerCost, 'power');
        }
        if (tick % ultimateCadence ==
            _stableHash('${stage.id}.ultimate') % ultimateCadence) {
          trySkill(profile.ultimateCost, 'ultimate');
        }
        if (profile.killGain > 0 && killTicks.contains(tick)) {
          rawGain += profile.killGain;
          final result = ledger.gainKill(
            actionId: '${stage.id}.${weapon.name}.kill.${actionSequence++}',
            windowId: '${stage.id}.${weapon.name}.wave',
            amount: profile.killGain,
            windowCap: profile.killWindowCap,
          );
          overflow += result.overflow;
        }
        if (ledger.current < profile.powerCost) belowPowerCostTicks++;
        qiSamples += ledger.current;
        totalTicks++;
      }
    }
  }

  final totalSeconds =
      corpus.stages.length * WeaponType.values.length * corpus.maxBattleSeconds;
  return (
    skillsPerMinute: skillCommits / totalSeconds * 60,
    insufficientPercent: skillAttempts == 0
        ? 0
        : insufficient / skillAttempts * 100,
    belowPowerCostPercent: belowPowerCostTicks / totalTicks * 100,
    meanQi: qiSamples / totalTicks,
    gainOverflowPercent: rawGain == 0 ? 0 : overflow / rawGain * 100,
  );
}

String _postureParams(PostureCandidate candidate) =>
    '${candidate.config.capacity.toStringAsFixed(0)}/'
    '${candidate.config.vulnerabilityTicks}/'
    '${candidate.config.recoveryPolicy.name}/'
    '${candidate.config.postVulnerabilityAccumulated.toStringAsFixed(0)}/'
    '${candidate.config.bossControlConversionFactor.toStringAsFixed(0)}';

String _timelineParams(TimelineCandidate candidate) => WeaponType.values
    .map((weapon) {
      final config = candidate.configs[weapon]!;
      return '${weapon.name}='
          '${config.windupTicks},${config.activeTicks},${config.recoveryTicks},'
          '${config.firstEffectTick},${config.cancelWindowStartTick},'
          '${config.cancelWindowEndTick},${config.interruptedCooldownTicks},'
          '${config.cancelledCooldownTicks},${config.failedCooldownTicks}';
    })
    .join(';');

String _tokenParams(TokenCandidate candidate) =>
    '${candidate.budgets.melee}/${candidate.budgets.ranged}/'
    '${candidate.budgets.charge}/${candidate.budgets.support}';

String _qiParams(QiCandidate candidate) => WeaponType.values
    .map((weapon) {
      final profile = candidate.weapons[weapon]!;
      return '${weapon.name}='
          '${profile.capacity},${profile.opening},${profile.basicGain},'
          '${profile.powerCost},${profile.ultimateCost},${profile.killGain},'
          '${profile.killWindowCap}';
    })
    .join(';');

String _kindMetrics(Map<AttackTokenKind, double> metrics) => AttackTokenKind
    .values
    .map((kind) => '${kind.name}:${metrics[kind]!.toStringAsFixed(2)}%')
    .join(',');

double _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index].toDouble();
}

int _stableHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

YamlMap _yamlMap(String path) =>
    loadYaml(File(path).readAsStringSync()) as YamlMap;
