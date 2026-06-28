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

const int _maxTicks = 200;
const int _seeds = 20;
const String _outputDir = 'test/tools/output';

enum _BuildProfile { floor, ceiling }

class _FloorResult {
  final int floorIndex;
  final TowerBossKind? bossKind;
  final _BuildProfile profile;
  final int seed;
  final String result;
  final int ticks;
  final int initialPlayerHp;
  final int playerHpEnd;
  final int enemyHpRemain;
  final int phaseTransitions;

  const _FloorResult({
    required this.floorIndex,
    required this.bossKind,
    required this.profile,
    required this.seed,
    required this.result,
    required this.ticks,
    required this.initialPlayerHp,
    required this.playerHpEnd,
    required this.enemyHpRemain,
    required this.phaseTransitions,
  });

  double get playerHpPct =>
      initialPlayerHp == 0 ? 0 : playerHpEnd / initialPlayerHp;
}

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    Directory(_outputDir).createSync(recursive: true);
  });

  test('爬塔 24→25、29→30 Boss 体感只读诊断', () async {
    const sampleFloors = [24, 25, 29, 30];
    final floors = sampleFloors.map(repo.getTowerFloor).toList();
    final results = <_FloorResult>[];

    for (final floor in floors) {
      for (final profile in _BuildProfile.values) {
        for (var seed = 0; seed < _seeds; seed++) {
          results.add(_simulateFloor(floor, seed, repo, profile));
        }
      }
    }

    final summary = _summarize(results, floors);
    final outPath = '$_outputDir/tower_boss_feel_2026-06-28.md';
    File(outPath).writeAsStringSync(summary);
    print(summary);
    print('tower_boss_feel_diagnostic done · summary=$outPath');

    expect(
      results.length,
      sampleFloors.length * _BuildProfile.values.length * _seeds,
    );
    expect(results.where((r) => r.result != 'timeout'), isNotEmpty);

    final floor25 = repo.getTowerFloor(25).enemyTeam.single;
    final floor30 = repo.getTowerFloor(30).enemyTeam.single;
    expect(
      floor25.bossPhases,
      isNull,
      reason: '当前 25 层 Boss 未配置 phase,诊断需显式记录此事实',
    );
    expect(
      floor30.bossPhases,
      isNull,
      reason: '当前 30 层 Boss 未配置 phase,诊断需显式记录此事实',
    );
    expect(
      results
          .where((r) => r.floorIndex == 25 || r.floorIndex == 30)
          .every((r) => r.phaseTransitions == 0),
      isTrue,
      reason: '25/30 未配置 phase 时,战斗日志不应出现 phase transition',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}

_FloorResult _simulateFloor(
  TowerFloorDef floor,
  int seed,
  GameRepository repo,
  _BuildProfile profile,
) {
  final players = [
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      slot: 0,
      name: '玩家',
      isFounder: true,
      profile: profile,
    ),
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      slot: 1,
      name: '徒弟一',
      isFounder: false,
      profile: profile,
    ),
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      slot: 2,
      name: '徒弟二',
      isFounder: false,
      profile: profile,
    ),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(
    floor.enemyTeam,
    isTower: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final initialPlayerHp = initial.leftTeam.fold<int>(
    0,
    (sum, p) => sum + p.maxHp,
  );
  final terminal = BattleEngine.runToEnd(
    initial,
    repo.numbers,
    maxTicks: _maxTicks,
    rng: Random(seed),
  );

  final playerHpEnd = terminal.leftTeam
      .where((p) => p.isAlive)
      .fold<int>(0, (sum, p) => sum + p.currentHp);
  final enemyHpRemain = terminal.rightTeam
      .where((e) => e.isAlive)
      .fold<int>(0, (sum, e) => sum + e.currentHp);
  final phaseTransitions = terminal.actionLog
      .where((a) => a.bossPhaseTransitionTo != null)
      .length;

  return _FloorResult(
    floorIndex: floor.floorIndex,
    bossKind: floor.bossKind,
    profile: profile,
    seed: seed,
    result: terminal.result?.name ?? 'timeout',
    ticks: terminal.tick,
    initialPlayerHp: initialPlayerHp,
    playerHpEnd: playerHpEnd,
    enemyHpRemain: enemyHpRemain,
    phaseTransitions: phaseTransitions,
  );
}

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
  const school = TechniqueSchool.gangMeng;
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
            throw StateError('tower_boss_feel: 无 ${wantSlot.name} 装备'),
      ),
    );
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 6, 28),
        obtainedFrom: 'tower_boss_feel',
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
  final TechniqueDef techDef = defsT.firstWhere(
    (d) => d.tier == techTierCap,
    orElse: () => throw StateError('tower_boss_feel: 无 ${techTierCap.name} 心法'),
  );
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 6, 28),
    cultivationLayer: ceiling
        ? CultivationLayer.daCheng
        : CultivationLayer.zhongCheng,
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
    founderBuffActive: ceiling,
  );
}

String _summarize(List<_FloorResult> results, List<TowerFloorDef> floors) {
  final byFloor = <int, List<_FloorResult>>{};
  for (final result in results) {
    byFloor.putIfAbsent(result.floorIndex, () => []).add(result);
  }

  String pct(num value) => '${(value * 100).toStringAsFixed(1)}%';
  double avg(Iterable<num> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, v) => sum + v) / list.length;
  }

  final buf = StringBuffer();
  buf.writeln('# 爬塔 Boss 体感诊断 · 2026-06-28');
  buf.writeln();
  buf.writeln(
    '24→25 与 29→30 · ${_BuildProfile.values.length} profile × '
    '$_seeds seed · maxTicks=$_maxTicks · 只读模拟,不改数值。',
  );
  buf.writeln();
  buf.writeln('## 汇总');
  buf.writeln();
  buf.writeln(
    '| floor | type | enemies | profile | winRate | avgTicks | '
    'avgPlayerHpEnd | phaseTransitions |',
  );
  buf.writeln('|---|---|---:|---|---:|---:|---:|---:|');

  for (final floor in floors) {
    final list = byFloor[floor.floorIndex] ?? const <_FloorResult>[];
    for (final profile in _BuildProfile.values) {
      final sub = list.where((r) => r.profile == profile).toList();
      final wins = sub.where((r) => r.result == 'leftWin').length;
      final phaseTransitions = sub.fold<int>(
        0,
        (sum, r) => sum + r.phaseTransitions,
      );
      buf.writeln(
        '| ${floor.floorIndex} | ${floor.bossKind?.name ?? "normal"} | '
        '${floor.enemyTeam.length} | ${profile.name} | '
        '${pct(wins / sub.length)} | ${avg(sub.map((r) => r.ticks)).round()} | '
        '${pct(avg(sub.map((r) => r.playerHpPct)))} | '
        '$phaseTransitions |',
      );
    }
  }

  buf.writeln();
  buf.writeln('## 静态对照');
  buf.writeln();
  buf.writeln('| floor | totalBaseHp | totalBaseAttack | hasBossPhases |');
  buf.writeln('|---|---:|---:|---|');
  for (final floor in floors) {
    final hp = floor.enemyTeam.fold<int>(0, (sum, e) => sum + e.baseHp);
    final attack = floor.enemyTeam.fold<int>(0, (sum, e) => sum + e.baseAttack);
    final hasPhases = floor.enemyTeam.any((e) => e.bossPhases != null);
    buf.writeln('| ${floor.floorIndex} | $hp | $attack | $hasPhases |');
  }

  buf.writeln();
  buf.writeln('## 解读边界');
  buf.writeln();
  buf.writeln('- 玩家 build 使用 on-level 三人队,固定刚猛,两档投入(floor/ceiling)。');
  buf.writeln('- 25/30 当前没有 bossPhases,phaseTransitions 为 0 是配置事实,不是调优结论。');
  buf.writeln('- 本诊断只给方向:若 Boss 胜率/耗时/剩余血低于前一普通层,再进入数值调整计划。');

  return buf.toString();
}
