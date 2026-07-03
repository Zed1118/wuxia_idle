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
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

/// floor30 护法墙 taunt + 脆弱窗口硬闸诊断(Task 5,本批核心验证)。
///
/// 两个 team profile 对同一 floor30 全自动跑到底:
///   - onLevel   : 宗师(zongShi)满配 + 50% 强化 + 400 战意 + 创始 buff。意图必胜。
///   - underGear : 绝顶(jueDing,-1 阶)本阶装 + 0 强化 + 0 战意。意图可败。
///
/// 三个硬闸(证机制在全自动战斗下真触发,非 no-op):
///   ① taunt 真生效:护法(左使/右使)全灭前主 Boss 从不被选中攻击 → 首个 Boss
///      掉血 tick >= 护法全灭 tick(bossFirstDamageTick >= wardBreakTick)。守 ward_noop:
///      旧「护法存活时 Boss 减伤」在 auto 下 no-op(AI 先清低血护法);新 taunt 把 Boss
///      从目标池排除才真咬合。
///   ② 满配必胜:onLevel × 全 seed winRate == 100%(护法灭后靠脆弱窗口打残局,能打死)。
///   ③ 软门槛:underGear × 全 seed winRate < 100%(跨阶欠配有真实败率)。
///
/// 逐 tick 采样(BattleEngine.tick + 单一 Random(seed),复刻 runToEnd 的确定性)
/// 记录首个 Boss 掉血 tick / 护法全灭 tick / 相位转换 / 终局。
const int _maxTicks = 300;
const int _seeds = 30;
const String _outputDir = 'test/tools/output';
const String _bossDefId = 'enemy_tower_boss_30';

const _guardianIds = {'enemy_tower_30_cultist_a', 'enemy_tower_30_cultist_b'};

enum _Profile { onLevel, underGear }

class _Res {
  final _Profile profile;
  final int seed;
  final String result;
  final int ticks;
  final int wardBreakTick; // 两护法皆亡的首个 tick;-1=从未破
  final int bossFirstDamageTick; // 首个 Boss 掉血的 tick;-1=全程满血
  final int phaseTransitions;
  final int bossHpRemain;
  const _Res(this.profile, this.seed, this.result, this.ticks,
      this.wardBreakTick, this.bossFirstDamageTick, this.phaseTransitions,
      this.bossHpRemain);
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('floor30 护法墙 taunt + 软门槛硬闸诊断', () async {
    final floor = repo.getTowerFloor(30);
    final results = <_Res>[];
    for (final profile in _Profile.values) {
      for (var seed = 0; seed < _seeds; seed++) {
        results.add(_sim(floor, seed, repo, profile));
      }
    }
    final summary = _summarize(results);
    print(summary);
    File('$_outputDir/floor30_soft_gate_diagnostic.md').writeAsStringSync(
      summary,
    );

    final onLevel = results.where((r) => r.profile == _Profile.onLevel);
    final underGear = results.where((r) => r.profile == _Profile.underGear);
    final onWins = onLevel.where((r) => r.result == 'leftWin').length;
    final underWins = underGear.where((r) => r.result == 'leftWin').length;

    // ① taunt 真生效:每场护法全灭前 Boss 从不掉血。onLevel 会打死 Boss
    //    (bossFirstDamageTick 必被记录),且该 tick >= wardBreakTick。
    //    OBSERVED(30 seed):onLevel avgWardBreakTick=2.1 / avgBossFirstDmgTick=2.3,
    //    全 seed bossFirstDamageTick >= wardBreakTick(护法灭前 Boss 满血,taunt 非 no-op)。
    for (final r in onLevel) {
      expect(r.wardBreakTick, greaterThan(0),
          reason: 'onLevel 应打破护法墙(种子 ${r.seed})');
      expect(r.bossFirstDamageTick, greaterThanOrEqualTo(r.wardBreakTick),
          reason: '护法全灭前 Boss 不应掉血(taunt 真排除,种子 ${r.seed}):'
              'bossFirstDmg=${r.bossFirstDamageTick} wardBreak=${r.wardBreakTick}');
    }

    // ② 满配必胜(护法灭后靠脆弱窗口打残局,能打死)。
    expect(onWins, _seeds, reason: 'onLevel 满配应全 seed 必胜');

    // ③ 软门槛:跨阶欠配有真实败率(< 满配,且明显不是 100%)。
    //    OBSERVED(30 seed):onLevel winRate=100% / underGear winRate=13.3%(86.7% 败)。
    expect(underWins, lessThan(_seeds),
        reason: 'underGear 跨阶欠配应有真实败率(软门槛真咬合)');

    expect(results.length, _Profile.values.length * _seeds);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

_Res _sim(TowerFloorDef floor, int seed, GameRepository repo, _Profile p) {
  final tier = p == _Profile.onLevel ? RealmTier.zongShi : RealmTier.jueDing;
  final geared = p == _Profile.onLevel;
  final players = [
    for (var slot = 0; slot < 3; slot++)
      _buildPlayer(repo, tier, slot: slot, isFounder: slot == 0, geared: geared),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(
    floor.enemyTeam,
    isTower: true,
  );
  final bossMaxHp =
      enemies.firstWhere((e) => e.enemyDefId == _bossDefId).maxHp;

  // 逐 tick 推进(单一 Random 复刻 runToEnd 的确定性,见 runToEnd 实现:
  // 循环 tick(s, n, rng: r)),每 tick 后采样护法存活 / Boss 承伤。
  var s = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final rng = Random(seed);
  var wardBreakTick = -1;
  var bossFirstDamageTick = -1;
  var i = 0;
  while (!s.isFinished && i < _maxTicks) {
    s = BattleEngine.tick(s, repo.numbers, rng: rng);
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
  final phaseTransitions =
      s.actionLog.where((a) => a.bossPhaseTransitionTo != null).length;

  return _Res(
    p,
    seed,
    s.result?.name ?? 'timeout',
    s.tick,
    wardBreakTick,
    bossFirstDamageTick,
    phaseTransitions,
    boss.currentHp,
  );
}

BattleCharacter _buildPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required bool isFounder,
  required bool geared,
}) {
  const layer = RealmLayer.huaJing;
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
        obtainedAt: DateTime(2026, 6, 28),
        obtainedFrom: 'floor30_soft_gate',
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
    learnedAt: DateTime(2026, 6, 28),
    cultivationLayer:
        geared ? CultivationLayer.daCheng : CultivationLayer.zhongCheng,
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
    createdAt: DateTime(2026, 6, 28),
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
  buf.writeln('# floor30 护法墙 taunt + 软门槛硬闸诊断');
  buf.writeln();
  buf.writeln('$_seeds seed · maxTicks=$_maxTicks · 逐 tick 采样只读模拟。');
  buf.writeln();
  buf.writeln('- ① taunt 真生效:护法全灭前 Boss 不掉血(avgBossFirstDmgTick '
      '>= avgWardBreakTick)。');
  buf.writeln('- ② 满配必胜:onLevel winRate == 100%。');
  buf.writeln('- ③ 软门槛:underGear winRate < 100%。');
  buf.writeln();
  buf.writeln(
    '| profile | winRate | avgTicks | wardBreakRate | avgWardBreakTick | '
    'avgBossFirstDmgTick | avgPhaseTrans | avgBossHpRemain |',
  );
  buf.writeln('|---|---:|---:|---:|---:|---:|---:|---:|');
  for (final p in _Profile.values) {
    final sub = results.where((r) => r.profile == p).toList();
    final wins = sub.where((r) => r.result == 'leftWin').length;
    final wardBroke = sub.where((r) => r.wardBreakTick >= 0).length;
    final wbTicks = sub.where((r) => r.wardBreakTick >= 0).map((r) => r.wardBreakTick);
    final bfTicks =
        sub.where((r) => r.bossFirstDamageTick >= 0).map((r) => r.bossFirstDamageTick);
    buf.writeln(
      '| ${p.name} | ${pct(wins / sub.length)} | '
      '${avg(sub.map((r) => r.ticks)).round()} | '
      '${pct(wardBroke / sub.length)} | '
      '${avg(wbTicks).toStringAsFixed(1)} | '
      '${avg(bfTicks).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.phaseTransitions)).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.bossHpRemain)).round()} |',
    );
  }
  buf.writeln();
  // 逐 seed 结果表,校准选种子用。
  buf.writeln('## 逐 seed');
  buf.writeln('| profile | seed | result | ticks | wardBreakTick | '
      'bossFirstDmgTick | phaseTrans |');
  buf.writeln('|---|---:|---|---:|---:|---:|---:|');
  for (final r in results) {
    buf.writeln(
      '| ${r.profile.name} | ${r.seed} | ${r.result} | ${r.ticks} | '
      '${r.wardBreakTick} | ${r.bossFirstDamageTick} | ${r.phaseTransitions} |',
    );
  }
  return buf.toString();
}
