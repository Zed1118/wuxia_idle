// ignore_for_file: avoid_print
//
// 早期难度特征化探针(2026-07-05 夜间批 · 一次性诊断,不入库)。
//
// 背景:技能成长门控批(6ce5e37e)让心法 3 招按修炼层解锁(初窥第1招/小成第2招/
// 大成大招),并配套下调 3 关敌 HP(01_04 2200→2050 / 04_04 8500→8000 /
// 06_04 22000→20000,~7%)。本探针量化:
//   1. 门控真实生效面:floor 档(中成=2招)与 ungated(3招·balance_simulator 现状,
//      fromCharacter fallback 不过门控)的 winRate/ticks 差;
//   2. HP 下调补偿是否到位:同门控态下 current vs old HP 的 A/B;
//   3. 章末关(01_05/04_05/06_05·未调)在门控下是否出现新失败悬崖;
//   4. 真萌新弧(01_04 · floor × 初窥=1招)的极端下限。
//
// 跑法:flutter test test/tools/early_difficulty_gate_probe_test.dart
// 体例镜像 balance_simulator_test.dart(_buildRealPlayer floor/ceiling 剖面)。

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/features/cultivation/application/technique_skill_growth_gate.dart';

const int _seeds = 25;
const int _maxTicks = 200;

late GameRepository _repo;

enum _P { floor, ceiling }

class _Cell {
  final String stage;
  final String hpArm;
  final String buildArm;
  final int wins;
  final int runs;
  final double avgWinTicks;
  _Cell(this.stage, this.hpArm, this.buildArm, this.wins, this.runs,
      this.avgWinTicks);

  @override
  String toString() {
    final pct = (wins / runs * 100).round();
    final t = avgWinTicks.isNaN ? '—' : avgWinTicks.toStringAsFixed(1);
    return '| $stage | $hpArm | $buildArm | $pct% ($wins/$runs) | $t |';
  }
}

BattleCharacter _buildPlayer(
  RealmTier tier, {
  required int slot,
  required bool isFounder,
  required _P profile,
  CultivationLayer? layerOverride,
  bool gated = false,
}) {
  final ceiling = profile == _P.ceiling;
  const layer = RealmLayer.huaJing;
  const school = TechniqueSchool.gangMeng;
  final numbers = _repo.numbers;
  final realmDef = _repo.getRealm(tier, layer);
  final enhanceLevel = ceiling ? (realmDef.absoluteLevel * 0.5).round() : 0;
  final battleCount = ceiling ? 400 : 0;

  final eqTierCap = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final wantSlot in [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final defs = _repo.equipmentDefs.values;
    final EquipmentDef def = defs.firstWhere(
      (d) => d.tier == eqTierCap && d.slot == wantSlot,
      orElse: () => defs.firstWhere((d) => d.slot == wantSlot),
    );
    equipped.add(Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 7, 5),
      obtainedFrom: 'early_gate_probe',
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
  final TechniqueDef techDef = _repo.techniqueDefs.values
      .firstWhere((d) => d.tier == techTierCap);
  final cultLayer = layerOverride ??
      (ceiling ? CultivationLayer.daCheng : CultivationLayer.zhongCheng);
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 7, 5),
    cultivationLayer: cultLayer,
  );

  final attributes = Attributes()
    ..constitution = ceiling ? 6 : 5
    ..agility = ceiling ? 6 : 5
    ..enlightenment = 5
    ..fortune = 5;

  final character = Character.create(
    name: 'P$slot',
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 7, 5),
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = 999 + slot;

  var bc = BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: ceiling,
  );
  if (gated) {
    final kept = bc.availableSkills
        .where((s) => isTechniqueSkillUnlockedByGrowth(
              technique: mainTech,
              techniqueDef: techDef,
              skill: s,
            ))
        .toList();
    bc = bc.copyWith(availableSkills: kept);
  }
  return bc;
}

({String result, int ticks}) _run(
  StageDef stage,
  int seed,
  _P profile, {
  bool gated = false,
  CultivationLayer? layerOverride,
  int? bossHpOverride,
  bool solo = false,
}) {
  final tier = stage.requiredRealm;
  final players = [
    _buildPlayer(tier,
        slot: 0,
        isFounder: true,
        profile: profile,
        gated: gated,
        layerOverride: layerOverride),
    if (!solo) ...[
      _buildPlayer(tier,
          slot: 1,
          isFounder: false,
          profile: profile,
          gated: gated,
          layerOverride: layerOverride),
      _buildPlayer(tier,
          slot: 2,
          isFounder: false,
          profile: profile,
          gated: gated,
          layerOverride: layerOverride),
    ],
  ];
  var enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
  if (bossHpOverride != null) {
    enemies = [
      for (final e in enemies)
        e.isBoss
            ? e.copyWith(maxHp: bossHpOverride, currentHp: bossHpOverride)
            : e,
    ];
  }
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = BattleEngine.runToEnd(initial, _repo.numbers,
      maxTicks: _maxTicks, rng: Random(seed));
  return (
    result: terminal.result == null ? 'timeout' : terminal.result!.name,
    ticks: terminal.tick,
  );
}

_Cell _cell(
  StageDef stage,
  String hpArm,
  String buildArm,
  _P profile, {
  bool gated = false,
  CultivationLayer? layerOverride,
  int? bossHpOverride,
  bool solo = false,
}) {
  var wins = 0;
  var tickSum = 0;
  for (var seed = 0; seed < _seeds; seed++) {
    final r = _run(stage, seed, profile,
        gated: gated,
        layerOverride: layerOverride,
        bossHpOverride: bossHpOverride,
        solo: solo);
    if (r.result == 'leftWin') {
      wins++;
      tickSum += r.ticks;
    }
  }
  return _Cell(stage.id, hpArm, buildArm, wins, _seeds,
      wins == 0 ? double.nan : tickSum / wins);
}

void main() {
  setUpAll(() async {
    _repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('早期难度门控特征化:3 调值关 A/B + 3 章末控制关', () {
    // {stageId: 旧 baseHp(null=未调·控制组)}
    const stages = <String, int?>{
      'stage_01_04': 2200,
      'stage_01_05': null,
      'stage_04_04': 8500,
      'stage_04_05': null,
      'stage_06_04': 22000,
      'stage_06_05': null,
    };

    final cells = <_Cell>[];
    stages.forEach((sid, oldHp) {
      final stage = _repo.stageDefs[sid]!;
      // sanity:cycle-1 buildEnemyTeam 直通 yaml baseHp
      final built = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
      final boss = built.firstWhere((e) => e.isBoss);
      final yamlHp = stage.enemyTeam.firstWhere((e) => e.isBoss).baseHp;
      expect(boss.maxHp, yamlHp,
          reason: '$sid boss maxHp 应直通 yaml baseHp(cycle-1)');

      for (final hpArm in [
        ('cur', null),
        if (oldHp != null) ('old', oldHp),
      ]) {
        cells.add(_cell(stage, hpArm.$1, 'floor·gated(2招)', _P.floor,
            gated: true, bossHpOverride: hpArm.$2));
        cells.add(_cell(stage, hpArm.$1, 'floor·ungated(3招)', _P.floor,
            bossHpOverride: hpArm.$2));
        cells.add(_cell(stage, hpArm.$1, 'ceiling(3招)', _P.ceiling,
            bossHpOverride: hpArm.$2));
        if (sid == 'stage_01_04') {
          cells.add(_cell(stage, hpArm.$1, 'floor·gated·初窥(1招)', _P.floor,
              gated: true,
              layerOverride: CultivationLayer.chuKui,
              bossHpOverride: hpArm.$2));
        }
        // 真实早期弧=祖师单人线(收徒前),solo 维度是主读数
        if (sid.startsWith('stage_01') || sid.startsWith('stage_04')) {
          cells.add(_cell(stage, hpArm.$1, 'SOLO·floor·gated(2招)', _P.floor,
              gated: true, solo: true, bossHpOverride: hpArm.$2));
          cells.add(_cell(stage, hpArm.$1, 'SOLO·floor·ungated(3招)',
              _P.floor,
              solo: true, bossHpOverride: hpArm.$2));
          cells.add(_cell(stage, hpArm.$1, 'SOLO·ceiling(3招)', _P.ceiling,
              solo: true, bossHpOverride: hpArm.$2));
          if (sid == 'stage_01_04' || sid == 'stage_01_05') {
            cells.add(_cell(
                stage, hpArm.$1, 'SOLO·floor·gated·初窥(1招)', _P.floor,
                gated: true,
                solo: true,
                layerOverride: CultivationLayer.chuKui,
                bossHpOverride: hpArm.$2));
            cells.add(_cell(
                stage, hpArm.$1, 'SOLO·floor·gated·小成(2招)', _P.floor,
                gated: true,
                solo: true,
                layerOverride: CultivationLayer.xiaoCheng,
                bossHpOverride: hpArm.$2));
          }
        }
      }
    });

    print('=== 早期难度门控特征化($_seeds seed/cell · on-level 3v1) ===');
    print('| stage | hp | build | win% | avgWinTicks |');
    print('|---|---|---|---|---|');
    for (final c in cells) {
      print(c);
    }
    expect(cells, isNotEmpty);
  });
}
