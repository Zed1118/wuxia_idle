import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/light_foot_strategy.dart';
import 'package:wuxia_idle/features/light_foot/domain/light_foot_def.dart';

/// LightFootStrategy 单测(1.0 P3.1 §12.3 Batch B.1):
///   - terrain bake water/rooftop/bamboo 3 terrain × {crit/evasion/defense} delta
///   - clamp ≤0.95 红线(critRate 0.90 + rooftop 0.10 = 1.00 → 0.95)
///   - 双方对等(地形中立 · left/right 都被烘焙)
///   - 不动 maxHp/maxInternalForce/totalEquipmentAttack(§5.4 红线)
///   - fixture 兼容(empty config → neutral modifier → 不动 stat)
///
/// 不测 runToEnd 主循环(沿 DefaultGroundStrategy e2e 测路径,本测只关 bake)。
void main() {
  group('LightFootStrategy.applyTerrainTo 烘焙 terrain modifier 到双方', () {
    test('water terrain:evasion +0.15 / defense -0.10 / crit 不变', () {
      final state = _makeState();
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.water,
        config: config,
      );

      final c = modified.leftTeam.first;
      expect(c.criticalRate, closeTo(0.15, 1e-9));
      expect(c.evasionRate, closeTo(0.20, 1e-9)); // 0.05 + 0.15
      expect(c.defenseRate, closeTo(0.25, 1e-9)); // 0.35 - 0.10
      // §5.4 红线不动
      expect(c.maxHp, 12000);
      expect(c.maxInternalForce, 10000);
      expect(c.totalEquipmentAttack, 1500);
    });

    test('rooftop terrain:crit +0.10 / defense -0.05 / evasion 不变', () {
      final state = _makeState();
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.rooftop,
        config: config,
      );

      final c = modified.leftTeam.first;
      expect(c.criticalRate, closeTo(0.25, 1e-9)); // 0.15 + 0.10
      expect(c.evasionRate, closeTo(0.05, 1e-9));
      expect(c.defenseRate, closeTo(0.30, 1e-9)); // 0.35 - 0.05
    });

    test('bamboo terrain:evasion +0.20 / crit/defense 不变', () {
      final state = _makeState();
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.bamboo,
        config: config,
      );

      final c = modified.leftTeam.first;
      expect(c.criticalRate, closeTo(0.15, 1e-9));
      expect(c.evasionRate, closeTo(0.25, 1e-9)); // 0.05 + 0.20
      expect(c.defenseRate, closeTo(0.35, 1e-9));
    });

    test('双方对等:left + right 都被烘焙(地形中立)', () {
      final state = _makeState(withRight: true);
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.water,
        config: config,
      );

      expect(modified.leftTeam.first.evasionRate, closeTo(0.20, 1e-9));
      expect(modified.rightTeam.first.evasionRate, closeTo(0.20, 1e-9));
    });

    test('clamp ≤0.95:critRate 0.90 + rooftop +0.10 → 0.95(不破)', () {
      final state = _makeState(criticalRate: 0.90);
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.rooftop,
        config: config,
      );

      expect(modified.leftTeam.first.criticalRate, closeTo(0.95, 1e-9));
    });

    test('clamp ≤0.95:evasionRate 0.85 + bamboo +0.20 → 0.95(不破)', () {
      final state = _makeState(evasionRate: 0.85);
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.bamboo,
        config: config,
      );

      expect(modified.leftTeam.first.evasionRate, closeTo(0.95, 1e-9));
    });

    test('clamp ≥0.0:defenseRate 0.05 + water -0.10 → 0.0(不为负)', () {
      final state = _makeState(defenseRate: 0.05);
      final config = _testConfig();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.water,
        config: config,
      );

      expect(modified.leftTeam.first.defenseRate, closeTo(0.0, 1e-9));
    });

    test('fixture 兼容:empty config → neutral modifier(0/0/0)→ 不动 stat', () {
      final state = _makeState();
      final emptyConfig = LightFootDef.empty();

      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.water,
        config: emptyConfig,
      );

      final c = modified.leftTeam.first;
      expect(c.criticalRate, closeTo(0.15, 1e-9));
      expect(c.evasionRate, closeTo(0.05, 1e-9));
      expect(c.defenseRate, closeTo(0.35, 1e-9));
      expect(c.attackPowerMultiplier, closeTo(1.0, 1e-9));
    });
  });

  // P3.1.B(2026-05-24):damage_multiplier 接入 attackPowerMultiplier 验证。
  // 沿 R5 红线测「写约束语义不写瞬时事实」体例:断言烘焙后字段值与 terrain
  // modifier 一致(语义),不写具体伤害值(瞬时)。damage_calculator 末乘
  // 由 default_ground_strategy 串通(已 R5.1 实测 bamboo draws 4→1 印证)。
  group('LightFootStrategy.applyTerrainTo 烘焙 damage_multiplier 到 attackPowerMultiplier (P3.1.B)',
      () {
    test('water terrain → attackPowerMultiplier 1.0(中性)', () {
      final state = _makeState();
      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.water,
        config: _testConfig(),
      );
      expect(modified.leftTeam.first.attackPowerMultiplier, closeTo(1.0, 1e-9));
    });

    test('rooftop terrain → attackPowerMultiplier 1.15(放大)', () {
      final state = _makeState();
      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.rooftop,
        config: _testConfig(),
      );
      expect(modified.leftTeam.first.attackPowerMultiplier, closeTo(1.15, 1e-9));
    });

    test('bamboo terrain → attackPowerMultiplier 0.90(削减)', () {
      final state = _makeState();
      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.bamboo,
        config: _testConfig(),
      );
      expect(modified.leftTeam.first.attackPowerMultiplier, closeTo(0.90, 1e-9));
    });

    test('双方对等:left + right 都被烘焙同一 multiplier', () {
      final state = _makeState(withRight: true);
      final modified = LightFootStrategy.applyTerrainTo(
        state,
        terrainBiome: TerrainBiome.rooftop,
        config: _testConfig(),
      );
      expect(modified.leftTeam.first.attackPowerMultiplier, closeTo(1.15, 1e-9));
      expect(modified.rightTeam.first.attackPowerMultiplier, closeTo(1.15, 1e-9));
    });
  });
}

/// 构造测试用 BattleState(skipping fromCharacter / IsarSetup 全 pipeline)。
BattleState _makeState({
  bool withRight = false,
  double criticalRate = 0.15,
  double evasionRate = 0.05,
  double defenseRate = 0.35,
}) {
  final left = _makeChar(
    characterId: 1,
    teamSide: 0,
    slotIndex: 0,
    criticalRate: criticalRate,
    evasionRate: evasionRate,
    defenseRate: defenseRate,
  );
  final right = withRight
      ? [
          _makeChar(
            characterId: -1,
            teamSide: 1,
            slotIndex: 0,
            criticalRate: criticalRate,
            evasionRate: evasionRate,
            defenseRate: defenseRate,
          ),
        ]
      : const <BattleCharacter>[];
  return BattleState.initial(leftTeam: [left], rightTeam: right);
}

BattleCharacter _makeChar({
  required int characterId,
  required int teamSide,
  required int slotIndex,
  required double criticalRate,
  required double evasionRate,
  required double defenseRate,
}) =>
    BattleCharacter(
      characterId: characterId,
      name: teamSide == 0 ? '玩家' : '敌',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 200,
      criticalRate: criticalRate,
      evasionRate: evasionRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const <SkillDef>[],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: teamSide,
      slotIndex: slotIndex,
    );

LightFootDef _testConfig() => const LightFootDef(
      terrainModifiers: {
        TerrainBiome.water: LightFootTerrainModifier(
          criticalRateDelta: 0.0,
          evasionRateDelta: 0.15,
          defenseRateDelta: -0.10,
          damageMultiplier: 1.0,
        ),
        TerrainBiome.rooftop: LightFootTerrainModifier(
          criticalRateDelta: 0.10,
          evasionRateDelta: 0.0,
          defenseRateDelta: -0.05,
          damageMultiplier: 1.15,
        ),
        TerrainBiome.bamboo: LightFootTerrainModifier(
          criticalRateDelta: 0.0,
          evasionRateDelta: 0.20,
          defenseRateDelta: 0.0,
          damageMultiplier: 0.90,
        ),
      },
      stageTerrain: {},
      unlockTriggers: {},
    );
