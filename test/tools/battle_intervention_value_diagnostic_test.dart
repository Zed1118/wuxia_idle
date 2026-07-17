// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/qi_cycle.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _reportDate = '2026-07-18';
const _seeds = 12;
const _maxTicks = progressionBattleMaxTicks;
const _outputDir = 'test/tools/output';
const _stageIds = ['stage_01_03', 'stage_03_05', 'stage_06_05'];
const _profiles = [
  ProgressionBuildProfile.standard,
  ProgressionBuildProfile.nearMax,
];

enum _Policy { auto, windowIntervention }

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    Directory(_outputDir).createSync(recursive: true);
  });

  test(
    '战斗干预价值诊断:3 关 × 2 profile × $_seeds seed × 自动/窗口干预',
    () {
      final stages = [for (final id in _stageIds) repository.stageDefs[id]!];
      expect(stages.every((stage) => stage.enemyTeam.isNotEmpty), isTrue);

      final rows = <_RunMetric>[];
      for (final stage in stages) {
        for (final profile in _profiles) {
          for (var seed = 0; seed < _seeds; seed++) {
            for (final policy in _Policy.values) {
              rows.add(
                _run(
                  repository: repository,
                  stage: stage,
                  profile: profile,
                  seed: seed,
                  policy: policy,
                ),
              );
            }
          }
        }
      }

      final deterministicA = _run(
        repository: repository,
        stage: stages.last,
        profile: ProgressionBuildProfile.standard,
        seed: 7,
        policy: _Policy.windowIntervention,
      );
      final deterministicB = _run(
        repository: repository,
        stage: stages.last,
        profile: ProgressionBuildProfile.standard,
        seed: 7,
        policy: _Policy.windowIntervention,
      );
      expect(deterministicA.signature, deterministicB.signature);

      expect(rows, hasLength(stages.length * _profiles.length * _seeds * 2));
      expect(rows.any((row) => row.playerSkillCasts > 0), isTrue);
      expect(rows.any((row) => row.interventionReadyUnitTicks > 0), isTrue);
      for (final row in rows) {
        expect(
          row.playerCasts,
          row.slotCasts.values.fold<int>(0, (sum, value) => sum + value),
        );
        expect(row.playerCasts, row.playerNormalCasts + row.playerSkillCasts);
      }

      final csvPath = '$_outputDir/battle_intervention_value_$_reportDate.csv';
      final summaryPath =
          '$_outputDir/battle_intervention_value_$_reportDate.md';
      File(csvPath).writeAsStringSync(_toCsv(rows));
      final summary = _summarize(stages, rows);
      File(summaryPath).writeAsStringSync(summary);
      print(summary);
      print('battle intervention diagnostic done · csv=$csvPath');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

_RunMetric _run({
  required GameRepository repository,
  required StageDef stage,
  required ProgressionBuildProfile profile,
  required int seed,
  required _Policy policy,
}) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      StageBattleSetup.debugApplyReadableFirstClearTuning(
        buildProgressionPlayer(
          repository: repository,
          tier: stage.requiredRealm,
          slot: slot,
          isFounder: slot == 0,
          profile: profile,
        ),
      ),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    readableFirstClearTuning: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final rng = Random(seed);
  var state = initial;
  final metric = _RunMetric(
    stageId: stage.id,
    isBoss: stage.isBossStage,
    profile: profile,
    seed: seed,
    policy: policy,
  );

  while (!state.isFinished && state.tick < _maxTicks) {
    if (state.actorQueue.isNotEmpty) {
      throw StateError('diagnostic must sample at tick boundary');
    }
    metric.sampleBoundary(state, repository);
    if (policy == _Policy.windowIntervention) {
      final choice = _pickWindowIntervention(state, repository);
      if (choice != null) {
        final beforeRows = state.actionLog.length;
        state = defaultGroundStrategy.interveneNow(
          state,
          choice.actor.characterId,
          choice.skill,
          targetId: choice.targetId,
          n: repository.numbers,
          rng: rng,
        );
        if (state.actionLog.length > beforeRows) metric.manualCasts++;
      }
    }
    state = defaultGroundStrategy.tick(state, repository.numbers, rng: rng);
  }
  if (!state.isFinished) {
    state = state.copyWith(result: BattleResult.draw);
  }
  metric.finish(state);
  return metric;
}

_ManualChoice? _pickWindowIntervention(
  BattleState state,
  GameRepository repository,
) {
  final charging = state.rightTeam
      .where((enemy) => enemy.isAlive && enemy.chargingSkill != null)
      .toList();
  if (charging.isNotEmpty) {
    for (final actor in state.leftTeam.where(_canInterveneActor)) {
      final interruptSkills =
          actor.availableSkills
              .where(
                (skill) =>
                    skill.type != SkillType.normalAttack &&
                    skill.canInterrupt &&
                    _isUsable(actor, skill, repository),
              )
              .toList()
            ..sort((a, b) => b.powerMultiplier.compareTo(a.powerMultiplier));
      if (interruptSkills.isNotEmpty) {
        return _ManualChoice(
          actor,
          interruptSkills.first,
          charging.first.characterId,
        );
      }
    }
  }

  final staggered = state.rightTeam
      .where((enemy) => enemy.isAlive && enemy.staggerTicksRemaining > 0)
      .toList();
  if (staggered.isEmpty) return null;
  _ManualChoice? best;
  for (final actor in state.leftTeam.where(_canInterveneActor)) {
    for (final skill in actor.availableSkills) {
      if (skill.type == SkillType.normalAttack) continue;
      if (!_isUsable(actor, skill, repository)) continue;
      final choice = _ManualChoice(actor, skill, staggered.first.characterId);
      if (best == null || skill.powerMultiplier > best.skill.powerMultiplier) {
        best = choice;
      }
    }
  }
  return best;
}

bool _canInterveneActor(BattleCharacter actor) =>
    actor.isAlive &&
    actor.actionPoint > 0 &&
    actor.staggerTicksRemaining <= 0 &&
    actor.chargingSkill == null;

bool _isUsable(
  BattleCharacter actor,
  SkillDef skill,
  GameRepository repository,
) {
  if (!_canInterveneActor(actor)) return false;
  if ((actor.skillCooldowns[skill.id] ?? 0) > 0) return false;
  return actor.currentQi >= _effectiveCost(actor, skill, repository);
}

int _effectiveCost(
  BattleCharacter actor,
  SkillDef skill,
  GameRepository repository,
) => -QiCycle.effectiveSkillDelta(
  baseDelta: -skill.qiCost,
  gainMultiplier: actor.qiGainMultiplier,
  gainMultiplierCap: repository.numbers.combat.qi.gainMultiplierCap,
  costReductionPct: actor.qiCostReductionPct,
  costReductionCap: repository.numbers.combat.qi.costReductionCap,
);

class _ManualChoice {
  const _ManualChoice(this.actor, this.skill, this.targetId);

  final BattleCharacter actor;
  final SkillDef skill;
  final int targetId;
}

class _RunMetric {
  _RunMetric({
    required this.stageId,
    required this.isBoss,
    required this.profile,
    required this.seed,
    required this.policy,
  });

  final String stageId;
  final bool isBoss;
  final ProgressionBuildProfile profile;
  final int seed;
  final _Policy policy;
  String result = '';
  int ticks = 0;
  int playerCasts = 0;
  int playerNormalCasts = 0;
  int playerSkillCasts = 0;
  int manualCasts = 0;
  int playerUnitTicks = 0;
  int interventionReadyUnitTicks = 0;
  int maxQiUnitTicks = 0;
  int qiShortageUnitTicks = 0;
  int enemyChargeTicks = 0;
  int interruptCoveredTicks = 0;
  int enemyStaggerTicks = 0;
  int burstCoveredTicks = 0;
  final Map<int, int> slotCasts = {0: 0, 1: 0, 2: 0};

  String get signature => [
    result,
    ticks,
    playerCasts,
    playerNormalCasts,
    playerSkillCasts,
    manualCasts,
    playerUnitTicks,
    interventionReadyUnitTicks,
    maxQiUnitTicks,
    qiShortageUnitTicks,
    enemyChargeTicks,
    interruptCoveredTicks,
    enemyStaggerTicks,
    burstCoveredTicks,
    slotCasts[0],
    slotCasts[1],
    slotCasts[2],
  ].join('/');

  void sampleBoundary(BattleState state, GameRepository repository) {
    final enemies = state.rightTeam.where((enemy) => enemy.isAlive).toList();
    final hasCharge = enemies.any((enemy) => enemy.chargingSkill != null);
    final hasStagger = enemies.any((enemy) => enemy.staggerTicksRemaining > 0);
    if (hasCharge) enemyChargeTicks++;
    if (hasStagger) enemyStaggerTicks++;

    var interruptCovered = false;
    var burstCovered = false;
    for (final actor in state.leftTeam.where((actor) => actor.isAlive)) {
      playerUnitTicks++;
      if (actor.currentQi >= actor.maxQi) maxQiUnitTicks++;
      final skills = actor.availableSkills
          .where((skill) => skill.type != SkillType.normalAttack)
          .toList();
      final usable = [
        for (final skill in skills)
          if (_isUsable(actor, skill, repository)) skill,
      ];
      if (usable.isNotEmpty) interventionReadyUnitTicks++;
      if (skills.any(
        (skill) =>
            (actor.skillCooldowns[skill.id] ?? 0) <= 0 &&
            actor.currentQi < _effectiveCost(actor, skill, repository),
      )) {
        qiShortageUnitTicks++;
      }
      if (usable.any((skill) => skill.canInterrupt)) interruptCovered = true;
      if (usable.isNotEmpty) burstCovered = true;
    }
    if (hasCharge && interruptCovered) interruptCoveredTicks++;
    if (hasStagger && burstCovered) burstCoveredTicks++;
  }

  void finish(BattleState terminal) {
    result = terminal.result?.name ?? 'timeout';
    ticks = terminal.tick;
    String? previousKey;
    for (final action in terminal.actionLog) {
      if (action.actorId <= 0 || action.attackResult == null) {
        previousKey = null;
        continue;
      }
      final key = '${action.tick}/${action.actorId}/${action.skill?.id ?? ''}';
      if (key == previousKey) continue;
      previousKey = key;
      playerCasts++;
      final actor = terminal.leftTeam
          .where((candidate) => candidate.characterId == action.actorId)
          .firstOrNull;
      if (actor != null) {
        slotCasts[actor.slotIndex] = (slotCasts[actor.slotIndex] ?? 0) + 1;
      }
      if (action.skill?.type == SkillType.normalAttack) {
        playerNormalCasts++;
      } else {
        playerSkillCasts++;
      }
    }
  }
}

String _toCsv(List<_RunMetric> rows) {
  final out = StringBuffer()
    ..writeln(
      'stage_id,is_boss,profile,seed,policy,result,ticks,player_casts,'
      'normal_casts,skill_casts,manual_casts,slot0_casts,slot1_casts,'
      'slot2_casts,player_unit_ticks,intervention_ready_unit_ticks,'
      'max_qi_unit_ticks,qi_shortage_unit_ticks,enemy_charge_ticks,'
      'interrupt_covered_ticks,enemy_stagger_ticks,burst_covered_ticks',
    );
  for (final row in rows) {
    out.writeln(
      [
        row.stageId,
        row.isBoss,
        row.profile.name,
        row.seed,
        row.policy.name,
        row.result,
        row.ticks,
        row.playerCasts,
        row.playerNormalCasts,
        row.playerSkillCasts,
        row.manualCasts,
        row.slotCasts[0],
        row.slotCasts[1],
        row.slotCasts[2],
        row.playerUnitTicks,
        row.interventionReadyUnitTicks,
        row.maxQiUnitTicks,
        row.qiShortageUnitTicks,
        row.enemyChargeTicks,
        row.interruptCoveredTicks,
        row.enemyStaggerTicks,
        row.burstCoveredTicks,
      ].join(','),
    );
  }
  return out.toString();
}

String _summarize(List<StageDef> stages, List<_RunMetric> rows) {
  final groups = <String, List<_RunMetric>>{};
  for (final row in rows) {
    groups.putIfAbsent('${row.stageId}/${row.profile.name}', () => []).add(row);
  }
  double average(Iterable<num> values) {
    final list = values.toList();
    return list.isEmpty
        ? 0
        : list.fold<double>(0, (sum, value) => sum + value) / list.length;
  }

  String pct(num part, num whole) =>
      whole == 0 ? '—' : '${(part / whole * 100).toStringAsFixed(1)}%';
  String winRate(List<_RunMetric> values) => pct(
    values.where((row) => row.result == BattleResult.leftWin.name).length,
    values.length,
  );

  final out = StringBuffer()
    ..writeln('# 战斗节奏与手动干预价值诊断 · $_reportDate')
    ..writeln()
    ..writeln(
      '${stages.length} 关 × ${_profiles.length} profile × $_seeds seed × '
      'auto/windowIntervention。真实 YAML + 首通调优配装 + '
      '`DefaultGroundStrategy`。',
    )
    ..writeln()
    ..writeln(
      '| stage | profile | auto win | manual win | auto tick | manual tick | '
      'skill cast | slot 0/1/2 | ready | max qi | qi short | charge cover | '
      'break cover | manual casts |',
    )
    ..writeln(
      '|---|---|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|',
    );

  for (final stage in stages) {
    for (final profile in _profiles) {
      final group = groups['${stage.id}/${profile.name}']!;
      final auto = group.where((row) => row.policy == _Policy.auto).toList();
      final manual = group
          .where((row) => row.policy == _Policy.windowIntervention)
          .toList();
      final autoCasts = auto.fold<int>(0, (sum, row) => sum + row.playerCasts);
      final skillCasts = auto.fold<int>(
        0,
        (sum, row) => sum + row.playerSkillCasts,
      );
      final slots = [
        for (var slot = 0; slot < 3; slot++)
          pct(
            auto.fold<int>(0, (sum, row) => sum + (row.slotCasts[slot] ?? 0)),
            autoCasts,
          ),
      ];
      final unitTicks = auto.fold<int>(
        0,
        (sum, row) => sum + row.playerUnitTicks,
      );
      final chargeTicks = auto.fold<int>(
        0,
        (sum, row) => sum + row.enemyChargeTicks,
      );
      final staggerTicks = auto.fold<int>(
        0,
        (sum, row) => sum + row.enemyStaggerTicks,
      );
      out.writeln(
        '| ${stage.id} | ${profile.name} | ${winRate(auto)} | '
        '${winRate(manual)} | ${average(auto.map((row) => row.ticks)).toStringAsFixed(1)} | '
        '${average(manual.map((row) => row.ticks)).toStringAsFixed(1)} | '
        '${pct(skillCasts, autoCasts)} | ${slots.join('/')} | '
        '${pct(auto.fold<int>(0, (sum, row) => sum + row.interventionReadyUnitTicks), unitTicks)} | '
        '${pct(auto.fold<int>(0, (sum, row) => sum + row.maxQiUnitTicks), unitTicks)} | '
        '${pct(auto.fold<int>(0, (sum, row) => sum + row.qiShortageUnitTicks), unitTicks)} | '
        '${pct(auto.fold<int>(0, (sum, row) => sum + row.interruptCoveredTicks), chargeTicks)} | '
        '${pct(auto.fold<int>(0, (sum, row) => sum + row.burstCoveredTicks), staggerTicks)} | '
        '${average(manual.map((row) => row.manualCasts)).toStringAsFixed(1)} |',
      );
    }
  }
  out
    ..writeln()
    ..writeln('## 口径')
    ..writeln()
    ..writeln('- `skill cast`：纯自动中非普攻施放数 / 玩家总施放数；AOE 多目标只计一次。')
    ..writeln(
      '- `ready/max qi/qi short`：纯自动每个存活玩家单位每 tick 边界的采样比例；'
      '`ready` 另要求 AP 已重新积累为正。',
    )
    ..writeln('- `charge cover`：敌方蓄力 tick 中至少一个破招技可立即下发的比例。')
    ..writeln('- `break cover`：敌方处于破绽 tick 中至少一个非普攻技可立即下发的比例。')
    ..writeln('- `windowIntervention`：每 tick 最多一次，只在破招/破绽窗口插队；不代表真人最优操作。');
  return out.toString();
}
