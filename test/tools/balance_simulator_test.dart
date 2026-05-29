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
//   - 玩家走真 build(2026-05-29 升级 · 用户拍「活跃玩家」模型):造 tier-cap 真
//     Equipment(从 equipmentDefs · midpoint base · 中等强化 ½ 上限 · 共鸣度默契
//     battleCount=400)+ tier-cap 主修 Technique(techniqueDefs)+ Attributes(总
//     ~22)→ BattleCharacter.fromCharacter(生产同一 derived_stats 路径 · founder
//     buff 享 · 默契解锁人剑合一)。替换旧 _synthPlayer 线性硬编码 scale。
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
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart' show RealmUtils;

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
    _buildRealPlayer(repo, playerTier, slot: 0, name: '玩家', isFounder: true),
    _buildRealPlayer(repo, playerTier, slot: 1, name: '徒弟一', isFounder: false),
    _buildRealPlayer(repo, playerTier, slot: 2, name: '徒弟二', isFounder: false),
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

/// 活跃玩家代表 build(2026-05-29 升真 · 用户拍 B 模型):走生产
/// [BattleCharacter.fromCharacter] derived_stats 路径,而非旧 _synthPlayer
/// 线性硬编码 scale。模型「会玩、会配装的活跃玩家」:tier-cap 真装备
/// (midpoint base + 中等强化 ½ 上限 + 共鸣度默契)+ tier-cap 主修心法 daCheng
/// + 属性总 ~22 + founder buff(玩家在门派、祖师在世 → 全员享)。
/// slot 0 = 祖师(isFounder),1-2 = 弟子。
BattleCharacter _buildRealPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required String name,
  required bool isFounder,
}) {
  const layer = RealmLayer.huaJing; // 代表性中高层(沿旧 _synthPlayer 体例)
  const school = TechniqueSchool.gangMeng; // 固定刚猛(流派分布留局限)
  const moqiBattleCount = 400; // 默契段 [300,2000) → 共鸣 ×1.20 + 解锁人剑合一
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel =
      (realmDef.absoluteLevel * 0.5).round(); // 中等强化 = ½ 上限(GDD §6.2 cap=absLevel)

  // tier-cap 真装备(weapon/armor/accessory · 从 production equipmentDefs 选)。
  final eqTierCap = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final wantSlot in [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final defs = repo.equipmentDefs.values;
    final EquipmentDef def = defs.firstWhere(
      (d) => d.tier == eqTierCap && d.slot == wantSlot,
      orElse: () => defs.firstWhere(
        (d) => d.slot == wantSlot,
        orElse: () =>
            throw StateError('balance_sim: 无 ${wantSlot.name} 装备 def'),
      ),
    );
    equipped.add(Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 5, 29),
      obtainedFrom: 'balance_sim',
      school: school,
      baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
      baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
      baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
      enhanceLevel: enhanceLevel,
      battleCount: moqiBattleCount,
    ));
  }

  // tier-cap 主修心法(从 production techniqueDefs 选 · defId 须真 →
  // fromCharacter getTechnique(defId).skillIds 取真招式)。
  final techTierCap = RealmUtils.techniqueTierCapOf(tier);
  final defsT = repo.techniqueDefs.values;
  final TechniqueDef techDef = defsT.firstWhere(
    (d) => d.tier == techTierCap,
    orElse: () =>
        throw StateError('balance_sim: 无 ${techTierCap.name} 心法 def'),
  );
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 5, 29),
    cultivationLayer: CultivationLayer.daCheng, // 活跃玩家主修 大成
  );

  final attributes = Attributes()
    ..constitution = 6 // 偏血量
    ..agility = 6 // 偏速度/暴击/闪避
    ..enlightenment = 5
    ..fortune = 5; // 总 22(活跃玩家偏上 · §4.1 总和 16-24)

  final character = Character.create(
    name: name,
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 5, 29),
    internalForce: realmDef.internalForceMax, // 进战满内力
    internalForceMax: realmDef.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = 999 + slot;

  // founderBuffActive=true:活跃玩家在门派、祖师在世 → 全员享(§12.2 #11
  // apply_to_disciples_only=false)。生产经 FounderBuffService 算,sim 直给 true。
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: true,
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
  buf.writeln('- **玩家走真 build**(2026-05-29 升级):`BattleCharacter.fromCharacter` '
      'derived_stats 生产路径 · 活跃玩家模型(tier-cap 真装备 midpoint base + '
      '中等强化 ½ 上限 + 共鸣默契 ×1.20 解锁人剑合一 + 主修 daCheng + founder buff)');
  buf.writeln('- **单一代表 build**:只跑「活跃玩家」一档,不验欠配置 floor / '
      '满配 ceiling 区间(留 C 方案双 build 对照扩展)');
  buf.writeln('- **不含辅修 synergy**(心法相生):只主修单本,SynergyService 未注入');
  buf.writeln('- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布');
  buf.writeln('- **playerTier = requiredRealm + 1**(既有校准偏移「玩家超阶挑战」):'
      '真 build 下可能与超阶叠加偏易 → 校准复核候选(本批只换 build 真实性不动偏移)');
  buf.writeln('- maxTicks=200 兜底(timeout = 不分胜负)');
  buf.writeln('');
  buf.writeln('**用途**:卡点 / 秒杀点 **方向性**诊断 · 真 build 后数值更贴近活跃玩家实战。');
  return buf.toString();
}
