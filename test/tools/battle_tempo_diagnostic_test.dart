// ignore_for_file: avoid_print
//
// 第五阶段·主线二 批次 2.1 战斗节奏诊断探针 · 2026-06-17
//
// 目标:量化「普攻 vs 技能」在战斗里的伤害/击杀占比,证伪/证实
// 「普攻伤害过高、小怪几下被普攻打死」这一假设。
//
// **纯诊断,不下硬数值断言**(现阶段不知道阈值);只加一条极松自洽断言
// (普攻+技能伤害占比 ≈ 100%)防测试空跑。
//
// 复用 balance_simulator_test.dart 既有战斗装配:
//   - GameRepository.loadAllDefs(loader: File) 接 production yaml
//   - StageBattleSetup.buildEnemyTeam 静态构造敌方
//   - BattleCharacter.fromCharacter derived_stats 生产路径(floor/ceiling 两档 build profile)
//   - BattleEngine.runToEnd 推到终态,读 terminal.actionLog
//
// 样本:前/中/后期代表性主线关(各章首关 + 一个 Boss 关)× floor/ceiling × 20 seed。
//
// 统计口径(只统计玩家方 actorId>0 且有 attackResult 的动作):
//   - 伤害分桶:普攻(SkillType.normalAttack)finalDamage 合计 vs 技能(其余三类)合计。
//   - 击杀归因:按 actionLog 时序重放,逐敌跟踪 currentHp(从 maxHp 开始递减),
//     某次玩家攻击把目标 HP 从 >0 打到 ≤0 = 该次为致死击,按 skill.type 计入
//     普攻击杀 or 技能击杀。
//     · 单次攻击只命中单一 targetId(见 default_ground_strategy §382-503 _resolveAction:
//       每动作 target = _findById(targetId),applyDamage 仅作用该一目标),故重放精确。
//     · 敌人若死于内伤 DoT(无 attackResult 的自伤动作)不计入任一桶——本 sim 玩家全
//       gangMeng 不施 yinRou 内伤,该路径不触发,记为 0 即可。

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

const int _maxTicks = 200;
const int _seeds = 20;
const String _outputDir = 'test/tools/output';

/// build 剖面(镜像 balance_simulator 的 floor/ceiling,隔离配装/投入轴)。
enum _BuildProfile { floor, ceiling }

/// 单场战斗的节奏统计。
class _TempoStat {
  int normalDamage = 0; // 玩家普攻 finalDamage 合计
  int skillDamage = 0; // 玩家技能(power/ultimate/joint)finalDamage 合计
  int normalKills = 0; // 普攻致死击次数
  int skillKills = 0; // 技能致死击次数
  int dotOrOtherKills = 0; // 敌死于非玩家攻击(内伤 DoT 等),不归普攻/技能
  int ticks = 0;
  String result = '';

  void add(_TempoStat o) {
    normalDamage += o.normalDamage;
    skillDamage += o.skillDamage;
    normalKills += o.normalKills;
    skillKills += o.skillKills;
    dotOrOtherKills += o.dotOrOtherKills;
    ticks += o.ticks;
  }
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('战斗节奏诊断:普攻 vs 技能 伤害/击杀占比(前中后期代表关 × floor/ceiling × $_seeds seed)',
      () async {
    // 代表性样本:各章首关覆盖前/中/后期 + 一个章末 Boss 关。
    // 用既有关卡 id 体例(stage_0X_0Y),缺失的关跳过(防 drift)。
    const sampleIds = [
      'stage_01_01', // 前期 学武出山 首关
      'stage_02_01', // 武林初识 首关
      'stage_03_01', // 名扬江湖 首关
      'stage_04_01', // 中后期 Ch4 首关
      'stage_05_01', // Ch5 首关
      'stage_06_01', // 后期 Ch6 首关
      'stage_03_05', // 中期 Boss 关(章末)
      'stage_06_05', // 后期 Boss 关(章末)
    ];

    final stages = <StageDef>[];
    for (final id in sampleIds) {
      final s = repo.stageDefs[id];
      if (s != null && s.enemyTeam.isNotEmpty) stages.add(s);
    }
    expect(stages, isNotEmpty, reason: '至少要有一个有敌方编队的样本关');

    // 全样本累计 + 分关累计。
    final overall = _TempoStat();
    final perStage = <String, _TempoStat>{}; // key = stageId(两档合并)
    final perStageRuns = <String, int>{};

    for (final stage in stages) {
      final agg = perStage.putIfAbsent(stage.id, () => _TempoStat());
      for (final profile in _BuildProfile.values) {
        for (var seed = 0; seed < _seeds; seed++) {
          final one = _simulateAndTally(stage, seed, repo, profile);
          agg.add(one);
          overall.add(one);
          perStageRuns[stage.id] = (perStageRuns[stage.id] ?? 0) + 1;
        }
      }
    }

    // ── 汇总输出 ──
    final buf = StringBuffer();
    String pct(num part, num whole) =>
        whole == 0 ? '—' : '${(part / whole * 100).toStringAsFixed(1)}%';

    final totalDmg = overall.normalDamage + overall.skillDamage;
    final totalKills =
        overall.normalKills + overall.skillKills + overall.dotOrOtherKills;
    final attributedKills = overall.normalKills + overall.skillKills;

    buf.writeln('# 战斗节奏诊断 · 2026-06-17');
    buf.writeln();
    buf.writeln('${stages.length} 关 × ${_BuildProfile.values.length} profile '
        '× $_seeds seed · maxTicks=$_maxTicks · 仅统计玩家方(actorId>0)有 '
        'attackResult 的动作');
    buf.writeln();
    buf.writeln('## 全样本');
    buf.writeln();
    buf.writeln('- 普攻伤害合计 = ${overall.normalDamage} · 技能伤害合计 = '
        '${overall.skillDamage}');
    buf.writeln('- **普攻伤害占比 = ${pct(overall.normalDamage, totalDmg)}** · '
        '技能伤害占比 = ${pct(overall.skillDamage, totalDmg)}');
    buf.writeln('- 普攻击杀 = ${overall.normalKills} · 技能击杀 = '
        '${overall.skillKills} · 其他(DoT等) = ${overall.dotOrOtherKills}');
    buf.writeln('- **普攻击杀占比(占已归因击杀)= '
        '${pct(overall.normalKills, attributedKills)}** · '
        '技能击杀占比 = ${pct(overall.skillKills, attributedKills)}');
    buf.writeln('- 普攻击杀占比(占全部击杀)= '
        '${pct(overall.normalKills, totalKills)}');
    buf.writeln();
    buf.writeln('## 分关卡');
    buf.writeln();
    buf.writeln('| stage_id | Boss | 普攻伤害% | 普攻击杀% | 均回合数 |');
    buf.writeln('|---|---|---|---|---|');
    for (final stage in stages) {
      final s = perStage[stage.id]!;
      final runs = perStageRuns[stage.id] ?? 1;
      final dmg = s.normalDamage + s.skillDamage;
      final atkKills = s.normalKills + s.skillKills;
      buf.writeln('| ${stage.id} | ${stage.isBossStage ? "Boss" : "—"} | '
          '${pct(s.normalDamage, dmg)} | ${pct(s.normalKills, atkKills)} | '
          '${(s.ticks / runs).round()} |');
    }

    final summary = buf.toString();
    print(summary);
    final outPath = '$_outputDir/battle_tempo_diagnostic_2026-06-17.md';
    File(outPath).writeAsStringSync(summary);
    print('battle_tempo_diagnostic done · summary=$outPath');

    // 极松自洽断言:防测试空跑。普攻+技能伤害占比应 ≈ 100%(允许浮点容差)。
    expect(totalDmg, greaterThan(0), reason: '玩家应至少打出伤害,否则 sim 空跑');
    final sumPct = (overall.normalDamage / totalDmg) +
        (overall.skillDamage / totalDmg);
    expect(sumPct, closeTo(1.0, 1e-9),
        reason: '普攻 + 技能伤害占比应自洽求和为 1');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// 跑一场战斗 + 统计节奏。
_TempoStat _simulateAndTally(
    StageDef stage, int seed, GameRepository repo, _BuildProfile profile) {
  final tier = stage.requiredRealm; // on-level 诚实基线(沿 balance_simulator 体例)
  final players = [
    _buildRealPlayer(repo, tier, slot: 0, name: '玩家', isFounder: true, profile: profile),
    _buildRealPlayer(repo, tier, slot: 1, name: '徒弟一', isFounder: false, profile: profile),
    _buildRealPlayer(repo, tier, slot: 2, name: '徒弟二', isFounder: false, profile: profile),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final rng = Random(seed);
  final terminal =
      BattleEngine.runToEnd(initial, repo.numbers, maxTicks: _maxTicks, rng: rng);

  final stat = _TempoStat()
    ..ticks = terminal.tick
    ..result = terminal.result?.name ?? 'timeout';

  // 击杀归因:按 actionLog 时序重放,逐敌跟踪 HP。敌人初始 HP = 进战 maxHp。
  // 敌人 id 为负(actorId<0);玩家攻击的 targetId 即被攻击敌人 id。
  final enemyHp = <int, int>{
    for (final e in initial.rightTeam) e.characterId: e.maxHp,
  };

  for (final a in terminal.actionLog) {
    final isPlayerAttack = a.actorId > 0 && a.attackResult != null;
    if (isPlayerAttack) {
      final dmg = a.attackResult!.finalDamage;
      final isNormal = a.skill?.type == SkillType.normalAttack;
      if (isNormal) {
        stat.normalDamage += dmg;
      } else {
        stat.skillDamage += dmg;
      }
      // 击杀归因:目标 HP 从 >0 跌到 ≤0 = 致死击。
      final tid = a.targetId;
      if (tid != null && enemyHp.containsKey(tid)) {
        final before = enemyHp[tid]!;
        if (before > 0) {
          final after = before - dmg;
          enemyHp[tid] = after;
          if (after <= 0) {
            if (isNormal) {
              stat.normalKills++;
            } else {
              stat.skillKills++;
            }
          }
        }
      }
    } else if (a.actorId < 0 && a.attackResult == null) {
      // 敌方自伤动作(内伤 DoT 致死等):若该敌从活变死,记为「其他击杀」。
      // 本 sim 玩家全 gangMeng,不施 yinRou 内伤,正常不触发;兜底计数。
      final aid = a.actorId;
      if (enemyHp.containsKey(aid) && enemyHp[aid]! > 0) {
        // 无法从 description 精确知扣血量;以「终局该敌已死且此前未被攻击致死」近似。
        // 仅当终局该敌 isAlive=false 且当前 sim 内未记录其攻击致死时,归其他。
        final terminalEnemy = terminal.rightTeam
            .where((e) => e.characterId == aid)
            .cast<BattleCharacter?>()
            .firstWhere((e) => e != null, orElse: () => null);
        if (terminalEnemy != null && !terminalEnemy.isAlive) {
          enemyHp[aid] = 0;
          stat.dotOrOtherKills++;
        }
      }
    }
  }

  return stat;
}

/// 玩家代表 build(floor/ceiling 两档,镜像 balance_simulator_test 的
/// _buildRealPlayer · 仅保留本诊断用到的 floor/ceiling 路径)。
BattleCharacter _buildRealPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required String name,
  required bool isFounder,
  required _BuildProfile profile,
}) {
  final ceiling = profile == _BuildProfile.ceiling;
  const layer = RealmLayer.huaJing;
  const school = TechniqueSchool.gangMeng; // 固定刚猛(流派分布留局限)
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = ceiling ? (realmDef.absoluteLevel * 0.5).round() : 0;
  final battleCount = ceiling ? 400 : 0;

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
            throw StateError('battle_tempo: 无 ${wantSlot.name} 装备 def'),
      ),
    );
    equipped.add(Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 6, 17),
      obtainedFrom: 'battle_tempo',
      school: school,
      baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
      baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
      baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
      forgingSlots: const [],
    ));
  }

  final techTierCap = RealmUtils.techniqueTierCapOf(tier);
  final defsT = repo.techniqueDefs.values;
  final TechniqueDef techDef = defsT.firstWhere(
    (d) => d.tier == techTierCap,
    orElse: () =>
        throw StateError('battle_tempo: 无 ${techTierCap.name} 心法 def'),
  );
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 6, 17),
    cultivationLayer:
        ceiling ? CultivationLayer.daCheng : CultivationLayer.zhongCheng,
  );

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
    createdAt: DateTime(2026, 6, 17),
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = 999 + slot;

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
