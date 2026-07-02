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

/// floor30 护法结界软门槛只读诊断(Task 5)。
///
/// 两个 team profile 对同一 floor30 全自动跑到底:
///   - onLevel   : 宗师(zongShi)满配 + 50% 强化 + 400 战意 + 创始 buff。意图必胜。
///   - underGear : 绝顶(jueDing,-1 阶)本阶装 + 0 强化 + 0 战意。意图可败。
/// 报告每档 winRate / avgTicks / 护法清除率(ward 破) / phase 触发次数。
const int _maxTicks = 300;
const int _seeds = 30;
const String _outputDir = 'test/tools/output';

const _guardianIds = {'enemy_tower_30_cultist_a', 'enemy_tower_30_cultist_b'};

enum _Profile { onLevel, underGear }

class _Res {
  final _Profile profile;
  final int seed;
  final String result;
  final int ticks;
  final int wardBreakTick; // 两护法皆亡的 tick;-1=从未破
  final int phaseTransitions;
  final int bossHpRemain;
  const _Res(this.profile, this.seed, this.result, this.ticks,
      this.wardBreakTick, this.phaseTransitions, this.bossHpRemain);
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('floor30 护法结界软门槛诊断', () async {
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
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = BattleEngine.runToEnd(
    initial,
    repo.numbers,
    maxTicks: _maxTicks,
    rng: Random(seed),
  );

  // ward 破:护法在 terminal 是否全灭(全自动打最低血,护法先死)。
  final guardiansAlive = terminal.rightTeam
      .where((e) => _guardianIds.contains(e.enemyDefId) && e.isAlive)
      .length;
  final wardBroken = guardiansAlive == 0;

  final boss = terminal.rightTeam.firstWhere(
    (e) => e.enemyDefId == 'enemy_tower_boss_30',
    orElse: () => terminal.rightTeam.first,
  );
  final phaseTransitions =
      terminal.actionLog.where((a) => a.bossPhaseTransitionTo != null).length;

  return _Res(
    p,
    seed,
    terminal.result?.name ?? 'timeout',
    terminal.tick,
    wardBroken ? terminal.tick : -1,
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
  buf.writeln('# floor30 护法结界软门槛诊断');
  buf.writeln();
  buf.writeln('$_seeds seed · maxTicks=$_maxTicks · 只读模拟。');
  buf.writeln();
  buf.writeln(
    '| profile | winRate | avgTicks | wardBreakRate | avgPhaseTrans | '
    'avgBossHpRemain |',
  );
  buf.writeln('|---|---:|---:|---:|---:|---:|');
  for (final p in _Profile.values) {
    final sub = results.where((r) => r.profile == p).toList();
    final wins = sub.where((r) => r.result == 'leftWin').length;
    final wardBroke = sub.where((r) => r.wardBreakTick >= 0).length;
    buf.writeln(
      '| ${p.name} | ${pct(wins / sub.length)} | '
      '${avg(sub.map((r) => r.ticks)).round()} | '
      '${pct(wardBroke / sub.length)} | '
      '${avg(sub.map((r) => r.phaseTransitions)).toStringAsFixed(1)} | '
      '${avg(sub.map((r) => r.bossHpRemain)).round()} |',
    );
  }
  buf.writeln();
  // 逐 seed 结果表,校准选种子用。
  buf.writeln('## 逐 seed');
  buf.writeln('| profile | seed | result | ticks | wardBroke | phaseTrans |');
  buf.writeln('|---|---:|---|---:|---|---:|');
  for (final r in results) {
    buf.writeln(
      '| ${r.profile.name} | ${r.seed} | ${r.result} | ${r.ticks} | '
      '${r.wardBreakTick >= 0} | ${r.phaseTransitions} |',
    );
  }
  return buf.toString();
}
