// ignore_for_file: avoid_print
//
// 首通可读节奏诊断。
//
// 只读模拟：不改 numbers / stages / 战斗逻辑。用于量化当前
// combat.readable_first_clear 调节后的主线战斗时长、伤害构成、内力消耗。

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

import '../support/progression_battle_probe.dart';
import '../support/test_data.dart';

const _seedsPerStage = 50;
const _readableVictoryHandoffSeconds = 1.2;
const _reportDate = '2026-07-09';
const _outputDir = 'test/tools/output';
const readableProfiles = [
  ProgressionBuildProfile.undergeared,
  ProgressionBuildProfile.nearMax,
];

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    Directory(_outputDir).createSync(recursive: true);
  });

  test(
    '首通可读节奏诊断:35 mainline × undergeared/nearMax × $_seedsPerStage seed',
    () {
      final stages =
          repo.stageDefs.values
              .where(
                (s) =>
                    s.stageType == StageType.mainline && s.enemyTeam.isNotEmpty,
              )
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));

      final rows = <_TempoRun>[];
      for (final stage in stages) {
        for (final profile in readableProfiles) {
          for (var seed = 0; seed < _seedsPerStage; seed++) {
            rows.add(_simulate(stage, repo, profile, seed));
          }
        }
      }

      _assertExperienceRatchet(stages, rows);

      final csv = '$_outputDir/readable_first_clear_tempo_$_reportDate.csv';
      final md = '$_outputDir/readable_first_clear_tempo_$_reportDate.md';
      _writeCsv(csv, rows);
      final summary = _summarize(stages, rows, repo);
      File(md).writeAsStringSync(summary);

      print(summary);
      print('readable tempo diagnostic done · csv=$csv · summary=$md');

      expect(rows, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

void _assertExperienceRatchet(List<StageDef> stages, List<_TempoRun> rows) {
  final byStageProfile = <String, List<_TempoRun>>{};
  for (final row in rows) {
    byStageProfile
        .putIfAbsent('${row.stageId}/${row.profile.name}', () => [])
        .add(row);
  }

  double averageActions(String stageId, ProgressionBuildProfile profile) {
    final samples =
        byStageProfile['$stageId/${profile.name}'] ?? const <_TempoRun>[];
    expect(samples, isNotEmpty, reason: '$stageId/${profile.name} 缺首通节奏样本');
    return samples.fold<double>(0, (sum, row) => sum + row.actionRows) /
        samples.length;
  }

  for (var chapter = 1; chapter <= 9; chapter++) {
    final stageId = 'stage_${chapter.toString().padLeft(2, '0')}_05';
    final undergeared = averageActions(
      stageId,
      ProgressionBuildProfile.undergeared,
    );
    final nearMax = averageActions(stageId, ProgressionBuildProfile.nearMax);
    expect(
      undergeared,
      greaterThanOrEqualTo(6),
      reason: '$stageId undergeared 平均动作行 $undergeared 低于渐进门槛 6',
    );
    expect(
      undergeared,
      greaterThanOrEqualTo(nearMax),
      reason: '$stageId undergeared=$undergeared 不应短于 nearMax=$nearMax',
    );
  }

  // 终章门槛(2026-07-24):终章 = 当前最末主线章 = Ch16(stage_16_05·接关人/凉州词·宗师段首章)。
  // (2026-07-20 Ch9 起本处随「最末主线章」滚动更新·Ch10/11 曾漏更留 stage_09_05·Ch12 补正)
  final finalChapterUndergeared = averageActions(
    'stage_16_05',
    ProgressionBuildProfile.undergeared,
  );
  expect(
    finalChapterUndergeared,
    greaterThanOrEqualTo(8),
    reason:
        'stage_16_05 undergeared 平均动作行 '
        '$finalChapterUndergeared 低于终章门槛 8',
  );

  final missingBossMechanic = <String>[];
  for (final stage in stages) {
    final hasBossPhaseConfig = stage.enemyTeam.any(
      (enemy) => enemy.bossPhases != null && enemy.bossPhases!.isNotEmpty,
    );
    if (!stage.isBossStage || !hasBossPhaseConfig) continue;
    for (final profile in readableProfiles) {
      final samples =
          byStageProfile['${stage.id}/${profile.name}'] ?? const <_TempoRun>[];
      if (samples.isEmpty) continue;
      final phaseRows = samples.fold<int>(
        0,
        (sum, row) => sum + row.bossPhaseRows,
      );
      final chargeRows = samples.fold<int>(
        0,
        (sum, row) => sum + row.chargeStartRows + row.chargingRows,
      );
      if (phaseRows <= 0 || chargeRows <= 0) {
        missingBossMechanic.add('${stage.id}/${profile.name}');
      }
    }
  }
  expect(
    missingBossMechanic,
    isEmpty,
    reason: '配置了阶段但首通不可见的 Boss 机制: $missingBossMechanic',
  );
}

_TempoRun _simulate(
  StageDef stage,
  GameRepository repo,
  ProgressionBuildProfile profile,
  int seed,
) {
  final run = runProgressionMainlineStage(
    repository: repo,
    stage: stage,
    profile: profile,
    seed: seed,
  );
  return _TempoRun.fromBattle(
    stage: stage,
    profile: profile,
    seed: seed,
    initial: run.initial,
    terminal: run.terminal,
  );
}

class _TempoRun {
  final String stageId;
  final int? chapterIndex;
  final bool isBoss;
  final String requiredRealm;
  final ProgressionBuildProfile profile;
  final int seed;
  final String result;
  final int ticks;
  final int actionRows;
  final int attackRows;
  final int playerAttackRows;
  final int enemyAttackRows;
  final int bossPhaseRows;
  final int chargeStartRows;
  final int chargingRows;
  final int interruptRows;
  final int breakWindowRows;
  final int playerNormalDamage;
  final int playerPowerDamage;
  final int playerUltimateDamage;
  final int playerNormalKills;
  final int playerSkillKills;
  final int initialPlayerHp;
  final int playerHpEnd;
  final int initialPlayerIf;
  final int playerIfEnd;

  const _TempoRun({
    required this.stageId,
    required this.chapterIndex,
    required this.isBoss,
    required this.requiredRealm,
    required this.profile,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.actionRows,
    required this.attackRows,
    required this.playerAttackRows,
    required this.enemyAttackRows,
    required this.bossPhaseRows,
    required this.chargeStartRows,
    required this.chargingRows,
    required this.interruptRows,
    required this.breakWindowRows,
    required this.playerNormalDamage,
    required this.playerPowerDamage,
    required this.playerUltimateDamage,
    required this.playerNormalKills,
    required this.playerSkillKills,
    required this.initialPlayerHp,
    required this.playerHpEnd,
    required this.initialPlayerIf,
    required this.playerIfEnd,
  });

  int get playerSkillDamage => playerPowerDamage + playerUltimateDamage;
  int get playerTotalDamage => playerNormalDamage + playerSkillDamage;

  factory _TempoRun.fromBattle({
    required StageDef stage,
    required ProgressionBuildProfile profile,
    required int seed,
    required BattleState initial,
    required BattleState terminal,
  }) {
    var normalDamage = 0;
    var powerDamage = 0;
    var ultimateDamage = 0;
    var normalKills = 0;
    var skillKills = 0;
    final hpById = <int, int>{
      for (final c in [...initial.leftTeam, ...initial.rightTeam])
        c.characterId: c.currentHp,
    };

    for (final action in terminal.actionLog) {
      final result = action.attackResult;
      final skill = action.skill;
      final targetId = action.targetId;
      if (result == null || skill == null || targetId == null) continue;
      final before = hpById[targetId] ?? 0;
      final after = max(0, before - result.finalDamage);
      hpById[targetId] = after;
      final isPlayer = action.actorId > 0;
      if (!isPlayer) continue;
      switch (skill.type) {
        case SkillType.normalAttack:
          normalDamage += result.finalDamage;
          break;
        case SkillType.powerSkill:
        case SkillType.jointSkill:
          powerDamage += result.finalDamage;
          break;
        case SkillType.ultimate:
          ultimateDamage += result.finalDamage;
          break;
      }
      if (before > 0 && after <= 0) {
        if (skill.type == SkillType.normalAttack) {
          normalKills++;
        } else {
          skillKills++;
        }
      }
    }

    final attackRows = terminal.actionLog
        .where((a) => a.attackResult != null)
        .length;
    final playerAttackRows = terminal.actionLog
        .where((a) => a.actorId > 0 && a.attackResult != null)
        .length;
    final enemyAttackRows = terminal.actionLog
        .where((a) => a.actorId < 0 && a.attackResult != null)
        .length;
    final bossPhaseRows = terminal.actionLog
        .where((a) => a.bossPhaseTransitionTo != null)
        .length;
    final chargeStartRows = terminal.actionLog
        .where((a) => a.description.contains('凝气蓄势'))
        .length;
    final chargingRows = terminal.actionLog
        .where((a) => a.description.contains('蓄力中'))
        .length;
    final interruptRows = terminal.actionLog.where((a) => a.interrupted).length;
    final breakWindowRows = terminal.actionLog
        .where((a) => a.openedBreakWindow)
        .length;
    return _TempoRun(
      stageId: stage.id,
      chapterIndex: stage.chapterIndex,
      isBoss: stage.isBossStage,
      requiredRealm: stage.requiredRealm.name,
      profile: profile,
      seed: seed,
      result: terminal.result?.name ?? 'timeout',
      ticks: terminal.tick,
      actionRows: terminal.actionLog.length,
      attackRows: attackRows,
      playerAttackRows: playerAttackRows,
      enemyAttackRows: enemyAttackRows,
      bossPhaseRows: bossPhaseRows,
      chargeStartRows: chargeStartRows,
      chargingRows: chargingRows,
      interruptRows: interruptRows,
      breakWindowRows: breakWindowRows,
      playerNormalDamage: normalDamage,
      playerPowerDamage: powerDamage,
      playerUltimateDamage: ultimateDamage,
      playerNormalKills: normalKills,
      playerSkillKills: skillKills,
      initialPlayerHp: initial.leftTeam.fold(0, (sum, c) => sum + c.maxHp),
      playerHpEnd: terminal.leftTeam
          .where((c) => c.isAlive)
          .fold(0, (sum, c) => sum + c.currentHp),
      initialPlayerIf: initial.leftTeam.fold(
        0,
        (sum, c) => sum + c.currentInternalForce,
      ),
      playerIfEnd: terminal.leftTeam.fold(
        0,
        (sum, c) => sum + c.currentInternalForce,
      ),
    );
  }
}

void _writeCsv(String path, List<_TempoRun> rows) {
  final buf = StringBuffer()
    ..writeln(
      'stage_id,chapter,realm,is_boss,profile,seed,result,ticks,action_rows,'
      'attack_rows,player_attack_rows,enemy_attack_rows,boss_phase_rows,'
      'charge_start_rows,charging_rows,interrupt_rows,break_window_rows,'
      'player_normal_damage,'
      'player_skill_damage,player_ultimate_damage,player_normal_kills,'
      'player_skill_kills,player_hp_end_pct,player_if_spent_pct',
    );
  for (final r in rows) {
    final hpPct = r.initialPlayerHp == 0
        ? 0
        : r.playerHpEnd / r.initialPlayerHp;
    final ifSpent = r.initialPlayerIf == 0
        ? 0
        : (r.initialPlayerIf - r.playerIfEnd) / r.initialPlayerIf;
    buf.writeln(
      '${r.stageId},${r.chapterIndex ?? ""},${r.requiredRealm},${r.isBoss},'
      '${r.profile.name},${r.seed},${r.result},${r.ticks},${r.actionRows},'
      '${r.attackRows},${r.playerAttackRows},${r.enemyAttackRows},'
      '${r.bossPhaseRows},${r.chargeStartRows},${r.chargingRows},'
      '${r.interruptRows},${r.breakWindowRows},'
      '${r.playerNormalDamage},${r.playerSkillDamage},'
      '${r.playerUltimateDamage},${r.playerNormalKills},${r.playerSkillKills},'
      '${hpPct.toStringAsFixed(4)},${ifSpent.toStringAsFixed(4)}',
    );
  }
  File(path).writeAsStringSync(buf.toString());
}

String _summarize(
  List<StageDef> stages,
  List<_TempoRun> rows,
  GameRepository repo,
) {
  final byStageProfile = <String, List<_TempoRun>>{};
  for (final row in rows) {
    byStageProfile
        .putIfAbsent('${row.stageId}/${row.profile.name}', () => [])
        .add(row);
  }

  String pct(double value) => '${(value * 100).toStringAsFixed(1)}%';
  double avgNum(Iterable<num> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, v) => sum + v) / list.length;
  }

  final readable = repo.numbers.combat.readableFirstClear;
  final readableActionSeconds =
      repo.numbers.animation.readableActionIntervalMs / 1000.0;
  final minVisibleSeconds =
      repo.numbers.animation.readableVictoryMinMs / 1000.0;
  double estVisibleSeconds(_TempoRun r) {
    final shown = r.actionRows * readableActionSeconds;
    final fill = minVisibleSeconds > shown ? minVisibleSeconds - shown : 0.0;
    final delay = fill > _readableVictoryHandoffSeconds
        ? fill
        : _readableVictoryHandoffSeconds;
    return shown + delay;
  }

  final buf = StringBuffer()
    ..writeln('# 首通可读节奏诊断 · $_reportDate')
    ..writeln()
    ..writeln(
      '$_seedsPerStage seed × ${stages.length} mainline × 2 profile。'
      '敌方使用 `readableFirstClearTuning=true`，即普通 HP × '
      '${readable.normalEnemyHpMultiplier}、Boss HP × '
      '${readable.bossEnemyHpMultiplier}、攻击 × '
      '${readable.enemyAttackMultiplier}、自动技能开局冷却 '
      '${readable.openingAutoSkillCooldownTurns} 拍、自动技能倍率 × '
      '${readable.autoSkillPowerMultiplier}。'
      '估算展示秒数 = actionLog 行数 × ${readableActionSeconds.toStringAsFixed(1)}s，'
      '并计入首通最短 ${minVisibleSeconds.toStringAsFixed(1)}s 观看兜底。',
    )
    ..writeln()
    ..writeln(
      '| stage | Boss | profile | win | avg actions | est sec | player atk | '
      'enemy atk | phase | charge | break | normal dmg | skill dmg | '
      'normal kills | skill kills | HP end | IF spent |',
    )
    ..writeln(
      '|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|',
    );

  for (final stage in stages) {
    for (final profile in readableProfiles) {
      final list = byStageProfile['${stage.id}/${profile.name}'] ?? const [];
      if (list.isEmpty) continue;
      final wins = list
          .where((r) => r.result == BattleResult.leftWin.name)
          .length;
      final normalDamage = list.fold<int>(
        0,
        (sum, r) => sum + r.playerNormalDamage,
      );
      final skillDamage = list.fold<int>(
        0,
        (sum, r) => sum + r.playerSkillDamage,
      );
      final totalDamage = normalDamage + skillDamage;
      final normalKills = list.fold<int>(
        0,
        (sum, r) => sum + r.playerNormalKills,
      );
      final skillKills = list.fold<int>(
        0,
        (sum, r) => sum + r.playerSkillKills,
      );
      final totalKills = normalKills + skillKills;
      final hpEnd = avgNum(
        list.map(
          (r) => r.initialPlayerHp == 0 ? 0 : r.playerHpEnd / r.initialPlayerHp,
        ),
      );
      final ifSpent = avgNum(
        list.map(
          (r) => r.initialPlayerIf == 0
              ? 0
              : (r.initialPlayerIf - r.playerIfEnd) / r.initialPlayerIf,
        ),
      );
      final avgActions = avgNum(list.map((r) => r.actionRows));
      final avgVisibleSeconds = avgNum(list.map(estVisibleSeconds));
      final avgChargeRows = avgNum(
        list.map((r) => r.chargeStartRows + r.chargingRows),
      );
      buf.writeln(
        '| ${stage.id} | ${stage.isBossStage ? "Boss" : "—"} | '
        '${profile.name} | ${pct(wins / list.length)} | '
        '${avgActions.toStringAsFixed(1)} | '
        '${avgVisibleSeconds.toStringAsFixed(1)} | '
        '${avgNum(list.map((r) => r.playerAttackRows)).toStringAsFixed(1)} | '
        '${avgNum(list.map((r) => r.enemyAttackRows)).toStringAsFixed(1)} | '
        '${avgNum(list.map((r) => r.bossPhaseRows)).toStringAsFixed(1)} | '
        '${avgChargeRows.toStringAsFixed(1)} | '
        '${avgNum(list.map((r) => r.interruptRows)).toStringAsFixed(1)} | '
        '${totalDamage == 0 ? "0.0%" : pct(normalDamage / totalDamage)} | '
        '${totalDamage == 0 ? "0.0%" : pct(skillDamage / totalDamage)} | '
        '${totalKills == 0 ? "0.0%" : pct(normalKills / totalKills)} | '
        '${totalKills == 0 ? "0.0%" : pct(skillKills / totalKills)} | '
        '${pct(hpEnd)} | ${pct(ifSpent)} |',
      );
    }
  }

  final all = rows;
  final normalDamage = all.fold<int>(0, (sum, r) => sum + r.playerNormalDamage);
  final skillDamage = all.fold<int>(0, (sum, r) => sum + r.playerSkillDamage);
  final totalDamage = normalDamage + skillDamage;
  final normalKills = all.fold<int>(0, (sum, r) => sum + r.playerNormalKills);
  final skillKills = all.fold<int>(0, (sum, r) => sum + r.playerSkillKills);
  final totalKills = normalKills + skillKills;
  final avgActions = avgNum(all.map((r) => r.actionRows));
  final avgVisibleSeconds = avgNum(all.map(estVisibleSeconds));
  final bossRows = rows.where((r) => r.isBoss).toList();
  final avgBossPhaseRows = avgNum(bossRows.map((r) => r.bossPhaseRows));
  final avgBossChargeRows = avgNum(
    bossRows.map((r) => r.chargeStartRows + r.chargingRows),
  );
  final avgBossInterruptRows = avgNum(bossRows.map((r) => r.interruptRows));
  final tooShort = <String>[];
  final missingBossMechanic = <String>[];
  for (final stage in stages) {
    for (final profile in readableProfiles) {
      final list = byStageProfile['${stage.id}/${profile.name}'] ?? const [];
      if (list.isEmpty) continue;
      final actions = avgNum(list.map((r) => r.actionRows));
      final threshold = stage.isBossStage ? 9 : 6;
      if (actions < threshold) tooShort.add('${stage.id}/${profile.name}');
      final hasBossPhaseConfig = stage.enemyTeam.any(
        (enemy) => enemy.bossPhases != null && enemy.bossPhases!.isNotEmpty,
      );
      final phaseRows = avgNum(list.map((r) => r.bossPhaseRows));
      final chargeRows = avgNum(
        list.map((r) => r.chargeStartRows + r.chargingRows),
      );
      if (stage.isBossStage &&
          hasBossPhaseConfig &&
          (phaseRows <= 0 || chargeRows <= 0)) {
        missingBossMechanic.add('${stage.id}/${profile.name}');
      }
    }
  }

  buf
    ..writeln()
    ..writeln('## 汇总')
    ..writeln()
    ..writeln(
      '- 平均展示动作行: ${avgActions.toStringAsFixed(1)}，估算 '
      '${avgVisibleSeconds.toStringAsFixed(1)} 秒。',
    )
    ..writeln(
      '- 玩家普攻伤害占比: '
      '${totalDamage == 0 ? "0.0%" : pct(normalDamage / totalDamage)}。',
    )
    ..writeln(
      '- 玩家技能伤害占比: '
      '${totalDamage == 0 ? "0.0%" : pct(skillDamage / totalDamage)}。',
    )
    ..writeln(
      '- 玩家普攻击杀占比: '
      '${totalKills == 0 ? "0.0%" : pct(normalKills / totalKills)}。',
    )
    ..writeln(
      '- 玩家技能击杀占比: '
      '${totalKills == 0 ? "0.0%" : pct(skillKills / totalKills)}。',
    )
    ..writeln(
      '- Boss 转阶段平均行: ${avgBossPhaseRows.toStringAsFixed(1)}；'
      '蓄力可见平均行: ${avgBossChargeRows.toStringAsFixed(1)}；'
      '破招平均行: ${avgBossInterruptRows.toStringAsFixed(1)}。',
    )
    ..writeln(
      '- 低于动作目标候选(普通 <6 / Boss <9): '
      '${tooShort.isEmpty ? "无" : tooShort.join(" / ")}',
    )
    ..writeln(
      '- 配了阶段但可见机制不足候选: '
      '${missingBossMechanic.isEmpty ? "无" : missingBossMechanic.join(" / ")}',
    )
    ..writeln()
    ..writeln('## 读法')
    ..writeln()
    ..writeln('- `normal dmg / skill dmg` 只统计玩家方直伤；DoT、反震等不纳入。')
    ..writeln('- `phase / charge / break` 统计转阶段、Boss 蓄力、玩家破招的可见动作行。')
    ..writeln('- `est sec` 是首通 UI 常速 + 胜利保底的视觉估算，不代表扫荡/快进时长。')
    ..writeln('- 本表使用 3 人队 on-level build，后续若调 solo 早期节奏，应另跑 solo 剖面。');

  return buf.toString();
}
