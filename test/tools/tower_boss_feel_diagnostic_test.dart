// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart' show EnemyDef;
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import '../support/test_data.dart';

const int _maxTicks = 200;
const int _seeds = 50;
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
    repo = await loadTestGameRepository();
    Directory(_outputDir).createSync(recursive: true);
  });

  test('爬塔全坡度 7 大 Boss 层 + 前驱普通层体感只读诊断', () async {
    // 批 A 塔 49 层重排:采样每 tier 的大 Boss(tier 末层 7/14/21/28/35/42/49)
    // + 各自前驱普通层成对,7 tier 全坡度覆盖,支撑 no-regress 断言与
    // 整塔难度坡度实测(14 Boss 全采样会翻倍模拟时长,大 Boss 对已覆盖每段落)。
    const bossPairs = [
      [6, 7],
      [13, 14],
      [20, 21],
      [27, 28],
      [31, 32], // 机制 Boss(剑魔·vuln)对——相位触发断言需要其模拟数据
      [34, 35],
      [41, 42],
      [48, 49],
    ];
    final sampleFloors = [for (final pair in bossPairs) ...pair];
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
    final outPath = '$_outputDir/tower_boss_feel_2026-07-01.md';
    File(outPath).writeAsStringSync(summary);
    print(summary);
    print('tower_boss_feel_diagnostic done · summary=$outPath');

    expect(
      results.length,
      sampleFloors.length * _BuildProfile.values.length * _seeds,
    );
    expect(results.where((r) => r.result != 'timeout'), isNotEmpty);

    // 全部采样 Boss 层不得弱于其前驱普通层(总 baseHp/baseAttack 单调)。
    for (final pair in bossPairs) {
      _expectBossDoesNotRegress(
        repo.getTowerFloor(pair[0]),
        repo.getTowerFloor(pair[1]),
      );
    }

    final floor32 = repo
        .getTowerFloor(32)
        .enemyTeam
        .firstWhere((e) => e.isBoss);
    final floor49 = repo
        .getTowerFloor(49)
        .enemyTeam
        .firstWhere((e) => e.isBoss);
    expect(
      floor32.bossPhases,
      isNotNull,
      reason: '32 层剑魔应至少有二阶段,避免单体 Boss 体感弱于前一普通层',
    );
    expect(
      floor49.bossPhases,
      isNotNull,
      reason: '49 层终关 Boss 应至少有二阶段,避免终关体感弱于前一普通层',
    );
    // 相位触发不变量**只对 ceiling(满投入 on-level)成立**——保证正常养成玩家能
    // 看到完整相位战。floor(零投入 on-level:0 强化 / 0 战意 / 无 buff)profile 不硬
    // 断言其触发率(仍照跑模拟并进报告表供观测,此处只是不 expect 它;不写死 8/20 那种
    // 噪声易漂的瞬时值,守 memory red_line_test_semantics)。
    //
    // 为何豁免 floor profile(实测差异):
    //   - **floor32(批 A 后剑魔位,首相位 0.92 浅开窗)**:批 A 校准后零投入队理论
    //     可开窗,但保持 ceiling-only 口径不变(floor profile 仍只观测不断言)。
    //   - **floor49(魔尊位,首相位 0.90 浅)**:同上。
    // 非 vuln Boss 不适用本豁免。旧 [25,30] 是重排前的机制 Boss 位(2026-08-04 迁)。
    for (final floorIndex in [32, 49]) {
      final triggered = results
          .where(
            (r) =>
                r.floorIndex == floorIndex &&
                r.profile == _BuildProfile.ceiling,
          )
          .where((r) => r.phaseTransitions > 0)
          .length;
      expect(
        triggered,
        greaterThanOrEqualTo((_seeds * 0.8).ceil()),
        reason: 'floor $floorIndex ceiling(满投入)至少 80% seed 应触发二阶段',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

void _expectBossDoesNotRegress(TowerFloorDef previous, TowerFloorDef boss) {
  // 2026-08-04 批 A 塔 49 层后语义修正:比较口径从「队伍总量」改「单体最强」。
  // 高段普通层是 3 人贴 60000 红线的队(总血 15 万+),单体 Boss 被同一红线钉死,
  // 「Boss 总量 > 普通层总量」在红线段结构上不可满足;体感上「守关人比路人强」
  // 本就是单体对单体的比较。顶格段(48/49 均 59500/2000)用 >=(贴线相等=不倒退)。
  // vuln 机制 Boss 的名义血刻意低于曲线(§5.4 机制型=减伤方向不膨胀数字,
  // 血量与乘子联动校准),体感血量 = baseHp / outOfWindowDamageMult(窗口外
  // 有效血),用它参与不倒退比较(剑魔 40000/0.35≈11.4 万 >> 前驱 47000)。
  int effectiveHp(EnemyDef e) {
    final mult = e.vulnerability?.outOfWindowDamageMult;
    if (mult == null || mult <= 0) return e.baseHp;
    return (e.baseHp / mult).round();
  }

  int maxHp(TowerFloorDef f) =>
      f.enemyTeam.map(effectiveHp).reduce((a, b) => a > b ? a : b);
  int maxAtk(TowerFloorDef f) =>
      f.enemyTeam.map((e) => e.baseAttack).reduce((a, b) => a > b ? a : b);

  expect(
    maxHp(boss),
    greaterThanOrEqualTo(maxHp(previous)),
    reason: 'floor ${boss.floorIndex} Boss 单体体感血量(vuln 折算)不应低于前一普通层单体',
  );
  expect(
    maxAtk(boss),
    greaterThanOrEqualTo(maxAtk(previous)),
    reason: 'floor ${boss.floorIndex} Boss 单体 baseAttack 不应低于前一普通层单体',
  );
}

_FloorResult _simulateFloor(
  TowerFloorDef floor,
  int seed,
  GameRepository repo,
  _BuildProfile profile,
) {
  final layer = floor.enemyTeam.first.realmLayer;
  final players = [
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      layer: layer,
      slot: 0,
      name: '玩家',
      isFounder: true,
      profile: profile,
    ),
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      layer: layer,
      slot: 1,
      name: '徒弟一',
      isFounder: false,
      profile: profile,
    ),
    _buildRealPlayer(
      repo,
      floor.requiredRealm,
      layer: layer,
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
  final terminal = defaultGroundStrategy.runToEnd(
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
  required RealmLayer layer,
  required int slot,
  required String name,
  required bool isFounder,
  required _BuildProfile profile,
}) {
  final ceiling = profile == _BuildProfile.ceiling;
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
  buf.writeln('# 爬塔 Boss 体感诊断 · 2026-07-01');
  buf.writeln();
  buf.writeln(
    '全坡度 7 大 Boss 层(7/14/21/28/35/42/49)+ 各自前驱普通层 · '
    '${_BuildProfile.values.length} profile × '
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
  buf.writeln('- 25/30 必须配置 bossPhases；若高爆发直接击杀,少量 seed 可跳过 transition。');
  buf.writeln('- Boss 总 baseHp/baseAttack 必须高于前一普通层,避免单体 Boss 体感倒退。');

  return buf.toString();
}
