// ignore_for_file: avoid_print
//
// M15-16 D4 数值再平衡 PoC · balance_simulator
//
// 跑 30 关 mainline × N seed × 2 build profile = 模拟,统计 floor/ceiling 通关率
// bracket + 难度诊断。输出 csv 到 test/tools/output/balance_simulation_*.csv。
//
// 与生产战斗体例镜像:
//   - GameRepository.loadAllDefs(loader: File) 接 production stages.yaml
//   - StageBattleSetup.buildEnemyTeam(stage.enemyTeam) 静态构造敌方
//   - 玩家走真 build(2026-05-29 升级):造 tier-cap 真 Equipment(从 equipmentDefs
//     · midpoint base)+ tier-cap 主修 Technique(techniqueDefs)→
//     BattleCharacter.fromCharacter(生产同一 derived_stats 路径)。替换旧
//     _synthPlayer 线性硬编码 scale。**C 方案 floor+ceiling bracket**:每关跑两档
//     剖面(_BuildProfile · floor 欠配置 / ceiling 活跃玩家),隔离配装/投入轴。
//   - BattleEngine.runToEnd(initial, rng, maxTicks=200) 推到终态
//
// 跑法:flutter test test/tools/balance_simulator_test.dart
//
// 输出 csv schema:
//   stage_id, requiredRealm, isBossStage, chapterIndex, profile, seed,
//   result, ticks, playerHpEnd, enemyHpRemain
//
// **不破现有 1519 测族**(纯加新 test,无修改 lib/)。
// **不动 numbers.yaml**(tune 候选走 A4 diff doc 待用户拍后再 apply)。

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
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
      for (final profile in _BuildProfile.values) {
        for (var seed = 0; seed < _seedsPerStage; seed++) {
          results.add(_simulateStage(stage, seed, repo, profile));
        }
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

  // 可玩性 P1a:熟练度 +30% 对真解 Boss 关 winRate 实测影响(同 seed A/B 隔离熟练度)。
  // 相对 cap(<=1.30)已数学保证;此处看高熟练度是否破甜区。单调断言 airtight
  // (+30% 伤害只增不减);floor 档(欠配置)见真实提升,ceiling 常已 100%(不超 100% 过强)。
  test('P1a 熟练度 winRate 影响:max 熟练(uses=800) vs fresh(uses=0)', () async {
    const stages = ['stage_01_05', 'stage_02_05', 'stage_03_05'];
    const seeds = 40;
    final lines = <String>[];
    for (final profile in _BuildProfile.values) {
      for (final sid in stages) {
        final stage = repo.stageDefs[sid];
        if (stage == null) continue;
        int winAt(int uses) {
          var w = 0;
          for (var seed = 0; seed < seeds; seed++) {
            final r = _simulateStage(stage, seed, repo, profile,
                proficiencyUses: uses);
            if (r.result == 'leftWin') w++;
          }
          return w;
        }
        final fresh = winAt(0);
        final maxed = winAt(800);
        lines.add('[${profile.name}] $sid: '
            'fresh=${(fresh / seeds * 100).round()}% '
            '-> maxProf=${(maxed / seeds * 100).round()}% '
            '(delta ${((maxed - fresh) / seeds * 100).round()}pt)');
        expect(maxed, greaterThanOrEqualTo(fresh),
            reason: '$sid[${profile.name}] 熟练度不应降低 winRate');
      }
    }
    print('=== P1a 熟练度 winRate 影响(floor/ceiling · $seeds seeds/档) ===');
    for (final l in lines) {
      print(l);
    }
  });
}

class _SimResult {
  final String stageId;
  final String requiredRealm;
  final bool isBossStage;
  final int? chapterIndex;
  final int seed;
  final _BuildProfile profile;
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
    required this.profile,
    required this.result,
    required this.ticks,
    required this.playerHpEnd,
    required this.enemyHpRemain,
  });
}

_SimResult _simulateStage(
    StageDef stage, int seed, GameRepository repo, _BuildProfile profile,
    {int proficiencyUses = 0}) {
  // 玩家境界 = stage.requiredRealm(on-level 诚实基线 · 2026-05-29 去 +1 confound):
  // 原 +1「玩家超阶」是旧假 _synthPlayer 时代的补偿 hack;真 build 下 +1 与同阶
  // 敌人叠加 → 玩家凭空 1 阶优势(差1阶 attacker×1.4/defender×0.7)把后段全冲成
  // trivial,掩盖真难度。on-level = 玩家恰在 required 阶 = 诚实「最低规格」读数。
  // 过度练级(挂机/grind 到 +1)只会更易,不影响「能否在达标阶通关」的下限判断。
  final tierIndex = RealmTier.values.indexOf(stage.requiredRealm);
  final playerTier = RealmTier.values[tierIndex.clamp(0, RealmTier.values.length - 1)];
  final players = [
    _buildRealPlayer(repo, playerTier,
        slot: 0, name: '玩家', isFounder: true, profile: profile,
        proficiencyUses: proficiencyUses),
    _buildRealPlayer(repo, playerTier,
        slot: 1, name: '徒弟一', isFounder: false, profile: profile,
        proficiencyUses: proficiencyUses),
    _buildRealPlayer(repo, playerTier,
        slot: 2, name: '徒弟二', isFounder: false, profile: profile,
        proficiencyUses: proficiencyUses),
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
    profile: profile,
    result: resultStr,
    ticks: terminal.tick,
    playerHpEnd: playerHpEnd,
    enemyHpRemain: enemyHpRemain,
  );
}

/// sim 玩家 build 剖面(C 方案 floor+ceiling bracket · 2026-05-29):隔离
/// 「配装/投入」轴,给每关一个 winRate 区间而非单点。
enum _BuildProfile {
  floor, // 欠配置/中位:0 强化 + 生疏共鸣 + 无 founder buff + 主修 zhongCheng + 属性 20
  ceiling, // 活跃玩家:½ 强化 + 默契共鸣 + founder buff + 主修 daCheng + 属性 22
}

/// 玩家代表 build(2026-05-29 升真 · C 方案 floor+ceiling):走生产
/// [BattleCharacter.fromCharacter] derived_stats 路径,而非旧 _synthPlayer
/// 线性硬编码 scale。两档剖面隔离「配装/投入」轴(playerTier=on-level 两档一致,
/// 只变 build profile):
///   - ceiling 活跃玩家:tier-cap 装备 ½ 强化 + 共鸣默契 ×1.20 + founder buff
///     + 主修 daCheng + 属性 22。「会玩、会配装」上限。
///   - floor 欠配置/中位:同 tier-cap 装备但 0 强化 + 生疏共鸣 ×1.0 + 无 founder
///     buff + 主修 zhongCheng + 属性 20。「刚达标、没怎么投入」下限。
/// slot 0 = 祖师(isFounder),1-2 = 弟子。
BattleCharacter _buildRealPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required String name,
  required bool isFounder,
  required _BuildProfile profile,
  int proficiencyUses = 0,
}) {
  const layer = RealmLayer.huaJing; // 代表性中高层(沿旧 _synthPlayer 体例)
  const school = TechniqueSchool.gangMeng; // 固定刚猛(流派分布留局限)
  final ceiling = profile == _BuildProfile.ceiling;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  // ceiling 中等强化 ½ 上限(GDD §6.2 cap=absLevel)/ floor 0 强化
  final enhanceLevel = ceiling ? (realmDef.absoluteLevel * 0.5).round() : 0;
  // ceiling 默契段 [300,2000) ×1.20 解锁人剑合一 / floor 生疏 ×1.0
  final battleCount = ceiling ? 400 : 0;

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
      battleCount: battleCount,
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
    // ceiling 主修 大成 / floor 中成(§4.3 修炼度 9 层)
    cultivationLayer:
        ceiling ? CultivationLayer.daCheng : CultivationLayer.zhongCheng,
  );
  // 可玩性 P1a:seed 主修各招 skillUsageCount → fromCharacter 快照 skillUses
  // → 战中按熟练阶应用伤害倍率。默认 0(fresh · 不扰既有 sweep)。
  if (proficiencyUses > 0) {
    for (final sid in techDef.skillIds) {
      mainTech.skillUsageCount.increment(sid, proficiencyUses);
    }
  }

  // ceiling 属性 22(投入偏上)/ floor 20(均值 · §4.1 μ=5.5 总和 16-24)
  final attributes = Attributes()
    ..constitution = ceiling ? 6 : 5
    ..agility = ceiling ? 6 : 5
    ..enlightenment = 5
    ..fortune = 5;

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

  // ceiling=玩家在门派、祖师在世 → 全员享 founder buff(§12.2 #11
  // apply_to_disciples_only=false);floor=未享(没怎么投入门派)。
  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: ceiling,
  );
}

void _writeCsv(String path, List<_SimResult> results) {
  final buf = StringBuffer();
  buf.writeln('stage_id,requiredRealm,isBossStage,chapterIndex,profile,seed,'
      'result,ticks,playerHpEnd,enemyHpRemain');
  for (final r in results) {
    buf.writeln('${r.stageId},${r.requiredRealm},${r.isBossStage},'
        '${r.chapterIndex ?? ""},${r.profile.name},${r.seed},${r.result},'
        '${r.ticks},${r.playerHpEnd},${r.enemyHpRemain}');
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
  buf.writeln('$_seedsPerStage seed × ${byStage.length} mainline × 2 profile'
      '(floor/ceiling) = ${results.length} runs · maxTicks=$_maxTicks');
  buf.writeln('');
  // 每关分 floor / ceiling 两档算 winRate(C 方案 bracket)。
  double winRateOf(List<_SimResult> list, _BuildProfile p) {
    final sub = list.where((r) => r.profile == p).toList();
    if (sub.isEmpty) return double.nan;
    return sub.where((r) => r.result == 'leftWin').length / sub.length;
  }

  buf.writeln('## 通关率 bracket(floor 欠配置 — ceiling 活跃玩家)');
  buf.writeln('');
  buf.writeln('| stage_id | requiredRealm | isBoss | chap | floor winRate | ceiling winRate |');
  buf.writeln('|---|---|---|---|---|---|');

  final floorWin = <String, double>{};
  final ceilWin = <String, double>{};
  for (final stage in stages) {
    if (stage.enemyTeam.isEmpty) continue;
    final list = byStage[stage.id] ?? [];
    if (list.isEmpty) continue;
    final fw = winRateOf(list, _BuildProfile.floor);
    final cw = winRateOf(list, _BuildProfile.ceiling);
    floorWin[stage.id] = fw;
    ceilWin[stage.id] = cw;
    buf.writeln('| ${stage.id} | ${stage.requiredRealm.name} | '
        '${stage.isBossStage ? "Boss" : "—"} | ${stage.chapterIndex ?? "—"} | '
        '${(fw * 100).toStringAsFixed(1)}% | ${(cw * 100).toStringAsFixed(1)}% |');
  }

  buf.writeln('');
  buf.writeln('## 难度诊断(bracket 解读)');
  buf.writeln('');
  buf.writeln('- **过难**(连 ceiling 活跃玩家都 < 50%):满配玩家都难过 → 数值偏高,上调候选');
  for (final id in ceilWin.keys) {
    if (ceilWin[id]! < 0.50) {
      buf.writeln('  - $id:floor ${(floorWin[id]! * 100).toStringAsFixed(0)}% / '
          'ceiling ${(ceilWin[id]! * 100).toStringAsFixed(0)}%');
    }
  }
  buf.writeln('');
  buf.writeln('- **过易**(连 floor 欠配置玩家都 > 90%):欠配置玩家都碾压 → 数值偏低,下调候选(尤其 Boss)');
  for (final id in floorWin.keys) {
    if (floorWin[id]! > 0.90) {
      buf.writeln('  - $id:floor ${(floorWin[id]! * 100).toStringAsFixed(0)}% / '
          'ceiling ${(ceilWin[id]! * 100).toStringAsFixed(0)}%');
    }
  }
  buf.writeln('');
  buf.writeln('- **健康**:floor 偏低-中 + ceiling 中高-高 = 配装/投入有意义(欠配置有挑战、满配顺畅)。');
  buf.writeln('');
  buf.writeln('## 期望区间(参考)');
  buf.writeln('');
  buf.writeln('- 普通关:floor ∈ [40%, 75%] · ceiling ∈ [75%, 95%]');
  buf.writeln('- Boss 关:floor ∈ [20%, 55%] · ceiling ∈ [55%, 85%]');
  buf.writeln('');
  buf.writeln('## 数据局限');
  buf.writeln('');
  buf.writeln('- **玩家走真 build**(`BattleCharacter.fromCharacter` derived_stats '
      '生产路径)· **C 方案 floor+ceiling bracket**:floor 欠配置(0 强化/生疏共鸣/'
      '无 founder buff/zhongCheng/属性 20)— ceiling 活跃玩家(½ 强化/默契 ×1.20/'
      'founder buff/daCheng/属性 22),隔离配装/投入轴');
  buf.writeln('- **不含辅修 synergy**(心法相生):只主修单本,SynergyService 未注入');
  buf.writeln('- 流派固定刚猛 gangMeng · 不验阴柔/灵巧分布');
  buf.writeln('- **playerTier = requiredRealm**(on-level 诚实基线 · 2026-05-29 去 +1 '
      'confound):玩家恰在 required 阶 · 过度练级(挂机/grind)只会更易,这是「能否在'
      '达标阶通关」的下限读数');
  buf.writeln('- maxTicks=200 兜底(timeout = 不分胜负)');
  buf.writeln('');
  buf.writeln('**用途**:难度 bracket **方向性**诊断 · floor/ceiling 区间判断配装是否有意义、'
      '何处过易(连 floor 都碾压)/过难(连 ceiling 都难过)。');
  return buf.toString();
}
