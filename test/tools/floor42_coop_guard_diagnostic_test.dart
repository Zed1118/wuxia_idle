// ignore_for_file: avoid_print

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
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import '../support/test_data.dart';

/// floor42 敌方协同(掩护重定向 + 护法合击)实例校准诊断(第八阶段切片 4-5)。
///
/// 三画像对同一 floor42 全自动跑到底(spec 2026-08-05 §4:画像×20 组):
///   - onLevel   : 推荐阶(宗师)满配 + 50% 强化 + 400 战意 + 创始 buff。意图必胜。
///   - onLevelBare: 推荐阶(宗师)本阶装 + 0 强化 + 0 战意。软门槛档。
///   - underTier : 低一阶(绝顶)本阶装 + 0 强化 + 0 战意。意图可败。
///
/// 断言:
///   ① 机制负载自证(feedback_probe_must_prove_its_load:先证明「量的是协同机制」
///      而非 0 负载):全画像聚合 interceptCount > 0(掩护重定向真发生)且
///      coopStrikeCount > 0(合击真发生);onLevel 组 Boss 蓄力相位真进入
///      (phaseTransitions ≥ 1)。若为 0 = 配置死/机制未触发,校准无意义。
///   ② 集成不变量:掩护体系下护法全灭前 Boss 不掉血(taunt 拦常规目标 +
///      guardInterceptsInterrupt 把破招也代吃 → Boss 承伤路径在护法存活期全封;
///      比 floor49 的同名断言更强——那里破招仍可直击 Boss)。只测 onLevel
///      (underTier 常破不了墙,wardBreakTick=-1 特判排除)。
///   ③ 满配必胜:onLevel × 全 seed winRate == 100%。
///   ④ 软门槛梯度(沿 floor32 2026-08-04 高段位修正语义,见
///      vulnerability_window_diagnostic_test.dart「梯度语义」注:zongShi 段敌方
///      伤害由境界内力主导,「同阶 0 强化偶胜」结构上不可达):
///      onLevelBare < onLevel(门槛存在)、onLevelBare >= underTier(排序自洽)、
///      underTier ≤ 50%(跨阶真咬合)。
///
/// 逐 tick 采样(defaultGroundStrategy.tick + 单一 Random(seed),复刻 runToEnd
/// 确定性)记录护法全灭 / Boss 首承伤 / 重定向次数 / 合击次数 / 相位转换。
const int _maxTicks = 300;
const int _seeds = 20;
const String _outputDir = 'test/tools/output';
const String _bossDefId = 'enemy_tower_boss_42';

const _guardianIds = {'enemy_tower_42_guard_a', 'enemy_tower_42_guard_b'};

enum _Profile { onLevel, onLevelBare, underTier }

class _Res {
  final _Profile profile;
  final int seed;
  final String result;
  final int ticks;
  final int wardBreakTick; // 两护法皆亡的首个 tick;-1=从未破
  final int bossFirstDamageTick; // 首个 Boss 掉血的 tick;-1=全程满血
  final int interceptCount; // 掩护重定向(破招被代吃)次数
  final int coopStrikeCount; // 护法合击次数
  final int phaseTransitions;
  final int bossHpRemain;
  const _Res(
    this.profile,
    this.seed,
    this.result,
    this.ticks,
    this.wardBreakTick,
    this.bossFirstDamageTick,
    this.interceptCount,
    this.coopStrikeCount,
    this.phaseTransitions,
    this.bossHpRemain,
  );
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    Directory(_outputDir).createSync(recursive: true);
  });

  test('floor42 敌方协同实例校准诊断(三画像×20 seed)', () async {
    final floor = repo.getTowerFloor(42);
    final results = <_Res>[];
    for (final profile in _Profile.values) {
      for (var seed = 0; seed < _seeds; seed++) {
        results.add(_sim(floor, seed, repo, profile));
      }
    }
    final summary = _summarize(results);
    print(summary);
    File(
      '$_outputDir/floor42_coop_guard_diagnostic.md',
    ).writeAsStringSync(summary);

    final onLevel = results.where((r) => r.profile == _Profile.onLevel);
    final bare = results.where((r) => r.profile == _Profile.onLevelBare);
    final under = results.where((r) => r.profile == _Profile.underTier);
    final onWins = onLevel.where((r) => r.result == 'leftWin').length;
    final bareWins = bare.where((r) => r.result == 'leftWin').length;
    final underWins = under.where((r) => r.result == 'leftWin').length;

    // ① 机制负载自证:重定向/合击/蓄力相位都真的发生过,不在量 0 负载。
    final totalIntercepts = results.fold<int>(
      0,
      (s, r) => s + r.interceptCount,
    );
    final totalCoops = results.fold<int>(0, (s, r) => s + r.coopStrikeCount);
    expect(
      totalIntercepts,
      greaterThan(0),
      reason: '掩护重定向应在真实 floor42 配置下真触发(0=机制死配置或速杀盲区)',
    );
    expect(
      totalCoops,
      greaterThan(0),
      reason: '护法合击应在真实 floor42 配置下真触发(0=机制死配置)',
    );
    for (final r in onLevel) {
      expect(
        r.phaseTransitions,
        greaterThanOrEqualTo(1),
        reason: 'onLevel 应至少进一次蓄力相位(种子 ${r.seed}),否则掩护窗从未打开',
      );
    }

    // ② 集成不变量:护法全灭前 Boss 不掉血(taunt + 掩护代吃双封)。
    for (final r in onLevel) {
      expect(
        r.wardBreakTick,
        greaterThan(0),
        reason: 'onLevel 应打破护法墙(种子 ${r.seed})',
      );
      expect(
        r.bossFirstDamageTick,
        greaterThanOrEqualTo(r.wardBreakTick),
        reason:
            '护法全灭前 Boss 不应掉血(掩护体系双封,种子 ${r.seed}):'
            'bossFirstDmg=${r.bossFirstDamageTick} wardBreak=${r.wardBreakTick}',
      );
    }

    // ③ 满配必胜(软门槛非硬墙)。
    expect(onWins, _seeds, reason: 'onLevel 满配应全 seed 必胜');

    // ④ 软门槛梯度(floor32 高段位修正语义)。
    expect(
      bareWins,
      lessThan(onWins),
      reason: '同阶 0 强化不应达到满配胜率(门槛真存在)',
    );
    expect(
      bareWins,
      greaterThanOrEqualTo(underWins),
      reason: '同阶 0 强化不应比跨阶欠配更差(梯度排序自洽)',
    );
    expect(
      underWins,
      lessThanOrEqualTo((_seeds * 0.5).floor()),
      reason: '跨 1 阶欠配应有实质败率(门槛真咬合)',
    );

    expect(results.length, _Profile.values.length * _seeds);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

_Res _sim(TowerFloorDef floor, int seed, GameRepository repo, _Profile p) {
  final tier = p == _Profile.underTier
      ? RealmTier.values[floor.requiredRealm.index - 1]
      : floor.requiredRealm;
  final layer = floor.enemyTeam.first.realmLayer;
  final geared = p == _Profile.onLevel;
  final players = [
    for (var slot = 0; slot < 3; slot++)
      _buildPlayer(
        repo,
        tier,
        layer: layer,
        slot: slot,
        isFounder: slot == 0,
        geared: geared,
      ),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(
    floor.enemyTeam,
    isTower: true,
  );
  final bossMaxHp = enemies.firstWhere((e) => e.enemyDefId == _bossDefId).maxHp;

  var s = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final rng = Random(seed);
  var wardBreakTick = -1;
  var bossFirstDamageTick = -1;
  var i = 0;
  while (!s.isFinished && i < _maxTicks) {
    s = defaultGroundStrategy.tick(s, repo.numbers, rng: rng);
    i++;
    if (wardBreakTick < 0) {
      final aliveGuardians = s.rightTeam
          .where((e) => _guardianIds.contains(e.enemyDefId) && e.isAlive)
          .length;
      if (aliveGuardians == 0) wardBreakTick = s.tick;
    }
    if (bossFirstDamageTick < 0) {
      final boss = s.rightTeam.firstWhere(
        (e) => e.enemyDefId == _bossDefId,
        orElse: () => s.rightTeam.first,
      );
      if (boss.currentHp < bossMaxHp) bossFirstDamageTick = s.tick;
    }
  }
  if (!s.isFinished) {
    s = s.copyWith(result: BattleResult.draw);
  }

  final boss = s.rightTeam.firstWhere(
    (e) => e.enemyDefId == _bossDefId,
    orElse: () => s.rightTeam.first,
  );
  final interceptCount = s.actionLog.where((a) => a.guardIntercepted).length;
  final coopStrikeCount = s.actionLog
      .where((a) => a.coopStrikeTotalDamage != null)
      .length;
  final phaseTransitions = s.actionLog
      .where((a) => a.bossPhaseTransitionTo != null)
      .length;

  return _Res(
    p,
    seed,
    s.result?.name ?? 'timeout',
    s.tick,
    wardBreakTick,
    bossFirstDamageTick,
    interceptCount,
    coopStrikeCount,
    phaseTransitions,
    boss.currentHp,
  );
}

BattleCharacter _buildPlayer(
  GameRepository repo,
  RealmTier tier, {
  required RealmLayer layer,
  required int slot,
  required bool isFounder,
  required bool geared,
}) {
  const school = TechniqueSchool.gangMeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = geared ? (realmDef.absoluteLevel * 0.5).round() : 0;
  final battleCount = geared ? 400 : 0;

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
      orElse: () => defs.firstWhere((d) => d.slot == wantSlot),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 8, 6),
        obtainedFrom: 'floor42_coop_guard',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
        forgingSlots: const [],
      ),
    );
  }

  final techTierCap = RealmUtils.techniqueTierCapOf(tier);
  final defsT = repo.techniqueDefs.values;
  final TechniqueDef techDef = defsT.firstWhere((d) => d.tier == techTierCap);
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 8, 6),
    cultivationLayer: geared
        ? CultivationLayer.daCheng
        : CultivationLayer.zhongCheng,
  );

  final attributes = Attributes()
    ..constitution = geared ? 6 : 5
    ..agility = geared ? 6 : 5
    ..enlightenment = 5
    ..fortune = 5;

  final character = Character.create(
    name: '玩家$slot',
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 8, 6),
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
    founderBuffActive: geared,
  );
}

String _summarize(List<_Res> results) {
  String pct(num v) => '${(v * 100).toStringAsFixed(1)}%';
  double avg(Iterable<num> xs) {
    final l = xs.toList();
    return l.isEmpty ? 0 : l.fold<double>(0, (s, v) => s + v) / l.length;
  }

  final buf = StringBuffer();
  buf.writeln('# floor42 敌方协同(掩护重定向+护法合击)实例校准诊断');
  buf.writeln();
  buf.writeln('$_seeds seed × 3 画像 · maxTicks=$_maxTicks · 逐 tick 采样只读模拟。');
  buf.writeln();
  buf.writeln('- ① 机制负载自证:intercept/coopStrike 聚合 > 0(不在量 0 负载)。');
  buf.writeln('- ② 集成不变量:护法全灭前 Boss 不掉血(taunt+掩护代吃双封)。');
  buf.writeln('- ③ 满配必胜:onLevel winRate == 100%。');
  buf.writeln('- ④ 梯度:bare < onLevel、bare >= under、under ≤ 50%。');
  buf.writeln();
  buf.writeln(
    '| profile | winRate | avgTicks | wardBreakRate | avgWardBreakTick | '
    'avgBossFirstDmgTick | avgIntercept | avgCoopStrike | avgPhaseTrans | '
    'avgBossHpRemain |',
  );
  buf.writeln('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (final p in _Profile.values) {
    final sub = results.where((r) => r.profile == p).toList();
    final wins = sub.where((r) => r.result == 'leftWin').length;
    final wardBroke = sub.where((r) => r.wardBreakTick >= 0).length;
    final wbTicks = sub
        .where((r) => r.wardBreakTick >= 0)
        .map((r) => r.wardBreakTick);
    final bfTicks = sub
        .where((r) => r.bossFirstDamageTick >= 0)
        .map((r) => r.bossFirstDamageTick);
    buf.writeln(
      '| ${p.name} | ${pct(wins / sub.length)} | '
      '${avg(sub.map((r) => r.ticks)).round()} | '
      '${pct(wardBroke / sub.length)} | '
      '${avg(wbTicks).toStringAsFixed(1)} | '
      '${avg(bfTicks).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.interceptCount)).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.coopStrikeCount)).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.phaseTransitions)).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.bossHpRemain)).round()} |',
    );
  }
  buf.writeln();
  buf.writeln('## 逐 seed');
  buf.writeln(
    '| profile | seed | result | ticks | wardBreakTick | bossFirstDmgTick | '
    'intercept | coopStrike | phaseTrans |',
  );
  buf.writeln('|---|---:|---|---:|---:|---:|---:|---:|---:|');
  for (final r in results) {
    buf.writeln(
      '| ${r.profile.name} | ${r.seed} | ${r.result} | ${r.ticks} | '
      '${r.wardBreakTick} | ${r.bossFirstDamageTick} | ${r.interceptCount} | '
      '${r.coopStrikeCount} | ${r.phaseTransitions} |',
    );
  }
  return buf.toString();
}
