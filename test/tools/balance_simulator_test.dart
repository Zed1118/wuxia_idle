// ignore_for_file: avoid_print
//
// M15-16 D4 数值再平衡 PoC · balance_simulator
//
// 5h 挂机 Batch A2-A3:跑 30 关 mainline × N seed = ~1500 模拟,统计通关率
// + 难度曲线 + 卡点/秒杀点诊断。输出 csv 到 test/tools/output/balance_simulation_*.csv。
//
// 与生产战斗体例镜像:
//   - GameRepository.loadAllDefs(loader: File) 接 production stages.yaml
//   - StageBattleSetup.buildEnemyTeam(stage.enemyTeam) 静态构造敌方
//   - 玩家合成 BattleCharacter:按 stage.requiredRealm 自动 scale build
//   - BattleEngine.runToEnd(initial, rng, maxTicks=200) 推到终态
//
// 跑法:flutter test test/tools/balance_simulator_test.dart
//
// 输出 csv schema:
//   stage_id, requiredRealm, isBossStage, chapterIndex, seed,
//   result, ticks, playerHpEnd, enemyHpRemain
//
// **不破现有 1519 测族**(纯加新 test,无修改 lib/)。
// **不动 numbers.yaml**(tune 候选走 A4 diff doc 待用户拍后再 apply)。

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

const int _seedsPerStage = 50;
const int _maxTicks = 200;
const String _outputDir = 'test/tools/output';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('balance simulation · 30 mainline × $_seedsPerStage seeds', () async {
    final mainlines = repo.stageDefs.values
        .where((s) => s.stageType == StageType.mainline)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    expect(mainlines.length, greaterThanOrEqualTo(25),
        reason: 'Demo §8.4 15-20 主线 + Ch4-6 P2 扩 = 30 关');

    final results = <_SimResult>[];
    for (final stage in mainlines) {
      if (stage.enemyTeam.isEmpty) continue; // 剧情关跳过
      for (var seed = 0; seed < _seedsPerStage; seed++) {
        final result = _simulateStage(stage, seed, repo);
        results.add(result);
      }
    }

    final outputPath = '$_outputDir/balance_simulation_2026-05-29.csv';
    _writeCsv(outputPath, results);
    final summary = _summarize(results, mainlines);
    final summaryPath = '$_outputDir/balance_summary_2026-05-29.md';
    File(summaryPath).writeAsStringSync(summary);
    print('balance_simulator done · ${results.length} runs · csv=$outputPath');
    print('summary=$summaryPath');

    expect(results.length, greaterThan(0));
  });
}

class _SimResult {
  final String stageId;
  final String requiredRealm;
  final bool isBossStage;
  final int? chapterIndex;
  final int seed;
  final String result; // leftWin / rightWin / draw / timeout
  final int ticks;
  final int playerHpEnd;
  final int enemyHpRemain;

  _SimResult({
    required this.stageId,
    required this.requiredRealm,
    required this.isBossStage,
    required this.chapterIndex,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.playerHpEnd,
    required this.enemyHpRemain,
  });
}

_SimResult _simulateStage(StageDef stage, int seed, GameRepository repo) {
  // 校准 v2:3v3 体例 + 玩家境界 = stage.requiredRealm + 1(玩家通常超阶挑战)
  final tierIndex = RealmTier.values.indexOf(stage.requiredRealm);
  final playerTier = RealmTier.values[(tierIndex + 1).clamp(0, RealmTier.values.length - 1)];
  final players = [
    _synthPlayer(playerTier, slot: 0, name: '玩家'),
    _synthPlayer(playerTier, slot: 1, name: '徒弟一'),
    _synthPlayer(playerTier, slot: 2, name: '徒弟二'),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final rng = Random(seed);
  final terminal = BattleEngine.runToEnd(initial, repo.numbers,
      maxTicks: _maxTicks, rng: rng);

  final playerHpEnd = terminal.leftTeam
      .where((p) => p.isAlive)
      .fold<int>(0, (sum, p) => sum + p.currentHp);
  final enemyHpRemain = terminal.rightTeam
      .where((e) => e.isAlive)
      .fold<int>(0, (sum, e) => sum + e.currentHp);
  final resultStr = terminal.result == null
      ? 'timeout'
      : terminal.result!.name;

  return _SimResult(
    stageId: stage.id,
    requiredRealm: stage.requiredRealm.name,
    isBossStage: stage.isBossStage,
    chapterIndex: stage.chapterIndex,
    seed: seed,
    result: resultStr,
    ticks: terminal.tick,
    playerHpEnd: playerHpEnd,
    enemyHpRemain: enemyHpRemain,
  );
}

/// 按境界合成玩家 BattleCharacter。数值参 GDD §5.2-5.6 + numbers.yaml 各阶 cap。
/// 校准 v2(2026-05-29):提升基础数值匹配真玩家进 stage 时的实际 build
/// (装备 + 心法成长 + 闭关产出累积),3v3 体例。
BattleCharacter _synthPlayer(RealmTier tier, {required int slot, required String name}) {
  final tierIndex = RealmTier.values.indexOf(tier);
  // 玩家进 stage 时通常 HP 拉满 + 装备已强化几次 + 心法 daCheng+ → 数值偏高
  final maxHp = 5000 + tierIndex * 3500; // 5000 / 8500 / 12000 / 15500 / 19000(接近 §5.4 20000 cap)
  final maxIf = 2000 + tierIndex * 2200; // 2000 / 4200 / 6400 / 8600 / 10800 / 13000 / 15000
  final speed = 130 + tierIndex * 30;
  final eqAtk = 200 + tierIndex * 320; // 200/520/840/1160/1480/1800(接近 §5.4 2000 cap)
  final defenseRate = 0.05 + tierIndex * 0.05; // 5% → 35%(GDD §5.5)
  final cultLayer = CultivationLayer.values[(tierIndex * 1.3).round().clamp(0, 8)];

  return BattleCharacter(
    characterId: 999 + slot,
    name: name,
    realmTier: tier,
    realmLayer: RealmLayer.huaJing,
    school: TechniqueSchool.gangMeng,
    maxHp: maxHp,
    currentHp: maxHp,
    maxInternalForce: maxIf,
    currentInternalForce: maxIf,
    speed: speed,
    criticalRate: 0.15, // 玩家有共鸣度 + 武器开锋加成假设
    evasionRate: 0.05,
    defenseRate: defenseRate,
    totalEquipmentAttack: eqAtk,
    mainCultivationLayer: cultLayer,
    availableSkills: <SkillDef>[
      _normalAttack(),
      _powerSkill(tier),
    ],
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: 0,
    isAlive: true,
    teamSide: 0,
    slotIndex: slot,
  );
}

SkillDef _normalAttack() => const SkillDef(
      id: 'sim_normal',
      name: '普攻',
      description: '',
      type: SkillType.normalAttack,
      powerMultiplier: 500,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      parentTechniqueDefId: null,
      visualEffect: '',
    );

SkillDef _powerSkill(RealmTier tier) {
  final tierIndex = RealmTier.values.indexOf(tier);
  final mult = 1000 + tierIndex * 500; // 1000/1500/2000/2500/3000/3500/4000
  return SkillDef(
    id: 'sim_power',
    name: '大招',
    description: '',
    type: SkillType.powerSkill,
    powerMultiplier: mult,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    parentTechniqueDefId: null,
    visualEffect: '',
  );
}

void _writeCsv(String path, List<_SimResult> results) {
  final buf = StringBuffer();
  buf.writeln('stage_id,requiredRealm,isBossStage,chapterIndex,seed,'
      'result,ticks,playerHpEnd,enemyHpRemain');
  for (final r in results) {
    buf.writeln('${r.stageId},${r.requiredRealm},${r.isBossStage},'
        '${r.chapterIndex ?? ""},${r.seed},${r.result},${r.ticks},'
        '${r.playerHpEnd},${r.enemyHpRemain}');
  }
  File(path).writeAsStringSync(buf.toString());
}

String _summarize(List<_SimResult> results, List<StageDef> stages) {
  final byStage = <String, List<_SimResult>>{};
  for (final r in results) {
    byStage.putIfAbsent(r.stageId, () => []).add(r);
  }

  final buf = StringBuffer();
  buf.writeln('# Balance Simulation Summary · 2026-05-29');
  buf.writeln('');
  buf.writeln('5h 挂机 Batch A3 · $_seedsPerStage seed × ${byStage.length} mainline = '
      '${results.length} runs · maxTicks=$_maxTicks');
  buf.writeln('');
  buf.writeln('## 通关率(玩家胜率 = leftWin / total)');
  buf.writeln('');
  buf.writeln('| stage_id | requiredRealm | isBoss | chap | leftWin | rightWin | draw | timeout | winRate | avgTicks |');
  buf.writeln('|---|---|---|---|---|---|---|---|---|---|');

  final cardinals = <String, double>{};
  for (final stage in stages) {
    if (stage.enemyTeam.isEmpty) continue;
    final list = byStage[stage.id] ?? [];
    if (list.isEmpty) continue;
    final left = list.where((r) => r.result == 'leftWin').length;
    final right = list.where((r) => r.result == 'rightWin').length;
    final draw = list.where((r) => r.result == 'draw').length;
    final timeout = list.where((r) => r.result == 'timeout').length;
    final winRate = left / list.length;
    final avgTicks = list.fold<int>(0, (s, r) => s + r.ticks) / list.length;
    cardinals[stage.id] = winRate;
    buf.writeln('| ${stage.id} | ${stage.requiredRealm.name} | '
        '${stage.isBossStage ? "Boss" : "—"} | ${stage.chapterIndex ?? "—"} | '
        '$left | $right | $draw | $timeout | '
        '${(winRate * 100).toStringAsFixed(1)}% | ${avgTicks.toStringAsFixed(1)} |');
  }

  buf.writeln('');
  buf.writeln('## 卡点 / 秒杀点诊断');
  buf.writeln('');
  buf.writeln('- **卡点**(winRate < 30%):玩家难过 → 数值上调候选');
  for (final entry in cardinals.entries) {
    if (entry.value < 0.30) {
      buf.writeln('  - ${entry.key}:${(entry.value * 100).toStringAsFixed(1)}%');
    }
  }
  buf.writeln('');
  buf.writeln('- **秒杀点**(winRate > 95%):玩家无脑过 → 数值下调候选(若是 Boss)');
  for (final entry in cardinals.entries) {
    if (entry.value > 0.95) {
      buf.writeln('  - ${entry.key}:${(entry.value * 100).toStringAsFixed(1)}%');
    }
  }
  buf.writeln('');
  buf.writeln('## 期望区间');
  buf.writeln('');
  buf.writeln('- 普通关 winRate ∈ [60%, 90%](玩家上手有挑战不卡死)');
  buf.writeln('- Boss 关 winRate ∈ [40%, 70%](章末压力 + 留余裕)');
  buf.writeln('');
  buf.writeln('## 数据局限');
  buf.writeln('');
  buf.writeln('- 玩家合成模型简化:1 角色 vs 1-3 敌(不 3v3)· 数值按 RealmTier 线性 scale');
  buf.writeln('- 不接 Isar(无装备 / 心法搭配 / 师徒 / 共鸣度 / founder buff)');
  buf.writeln('- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布');
  buf.writeln('- maxTicks=200 兜底(timeout = 不分胜负)');
  buf.writeln('');
  buf.writeln('**用途**:卡点 / 秒杀点 **方向性**诊断,精确 tune 需接真玩家路径(Isar 体例)。');
  return buf.toString();
}
