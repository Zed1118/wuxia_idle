import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../light_foot/domain/light_foot_def.dart';
import '../battle_state.dart';
import 'battle_strategy.dart';
import 'default_ground_strategy.dart';

/// 轻功对决 strategy(1.0 P3.1 §12.3,GDD v1.11)。
///
/// **组合委派架构**(memory `feedback_avoid_over_engineer_abstraction`):
/// 内部持 `const DefaultGroundStrategy _delegate`,zero 代码重复;tick/
/// requestUltimate 直接委派,runToEnd 入口先把 terrain modifier 烘焙到双方
/// BattleCharacter critRate/evasionRate/defenseRate,再委派给 _delegate.runToEnd。
///
/// **真痛点 = terrain modifier 入口**,不抽象多余 hook。BattleStrategy 接口
/// 粗粒度 3 method 已足,无需扩。
///
/// **immutable**:terrain bake 在 runToEnd 入口一次(idempotent by ctor),
/// 后续 tick 由 _delegate 跑现有公式自动吸收(no mutable state)。
///
/// **clamp ≤0.95**:critRate / evasionRate / defenseRate 各 clamp(0.0, 0.95)防破
/// §5.4/§5.5 红线(玩家 / 镜像 / lightfoot 三 strategy 红线对齐)。
///
/// **terrain modifier 数值**(numbers.yaml light_foot.terrain_modifiers,
/// 双方对等地形中立):
///   - water(水面):evasion +0.15 / defense -0.10
///   - rooftop(屋脊):crit +0.10 / damage ×1.15 / defense -0.05
///   - bamboo(竹林):evasion +0.20 / damage ×0.90
///
/// **damage_multiplier 接入**(P3.1.B 子批 · 2026-05-24):terrain.damageMultiplier
/// 烘焙到双方 BattleCharacter.attackPowerMultiplier,damage_calculator base 公式
/// 末乘读用。沿 crit/evasion/defense delta 体例,双方对等 → 双方 attacker 出招时
/// 同步放大/缩小(rooftop ×1.15 / bamboo ×0.90 / water 1.0)。
class LightFootStrategy extends BattleStrategy {
  /// 当前关 terrain(从 stages.yaml `terrainBiome` 字段读 + ctor 注入)。
  final TerrainBiome terrainBiome;

  /// LightFootDef 配置(numbers.yaml light_foot 段加载)。
  final LightFootDef config;

  /// 内部委派 strategy(沿 DefaultGroundStrategy tick 主循环)。
  static const _delegate = DefaultGroundStrategy();

  const LightFootStrategy({
    required this.terrainBiome,
    required this.config,
  });

  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) =>
      _delegate.tick(state, n, rng: rng);

  /// 跑完整场战斗。入口烘焙 terrain modifier 到双方 BattleCharacter stat,
  /// 然后委派 _delegate.runToEnd。
  @override
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) {
    final modified = _applyTerrain(initial);
    return _delegate.runToEnd(modified, n, maxTicks: maxTicks, rng: rng);
  }

  @override
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate, {
    int? targetId,
  }) =>
      _delegate.requestUltimate(state, characterId, ultimate,
          targetId: targetId);

  BattleState _applyTerrain(BattleState s) =>
      applyTerrainTo(s, terrainBiome: terrainBiome, config: config);

  /// 烘焙 terrain modifier 到双方 BattleCharacter 入口快照。
  ///
  /// idempotent:相同 (state, terrainBiome, config) 入参产同样 output;
  /// runToEnd 入口调一次即可(_delegate.runToEnd 内部 tick 循环不影响 bake)。
  ///
  /// **@visibleForTesting**:R5 / unit test 直接断言 bake 后的 stat,
  /// 不必跑完整 runToEnd 路径(沿 StageBattleSetup.applySynergy 静态方法
  /// `@visibleForTesting` 体例)。
  @visibleForTesting
  static BattleState applyTerrainTo(
    BattleState s, {
    required TerrainBiome terrainBiome,
    required LightFootDef config,
  }) {
    final m = config.terrainModifiers[terrainBiome] ??
        LightFootTerrainModifier.neutral();
    final newLeft = s.leftTeam.map((c) => _bake(c, m)).toList(growable: false);
    final newRight = s.rightTeam.map((c) => _bake(c, m)).toList(growable: false);
    return s.copyWith(
      leftTeam: List.unmodifiable(newLeft),
      rightTeam: List.unmodifiable(newRight),
    );
  }

  /// 单角色 stat bake:critRate/evasionRate/defenseRate 加 delta + clamp(0.0, 0.95);
  /// attackPowerMultiplier 直接 set 为 terrain.damageMultiplier(P3.1.B · 双方对等)。
  ///
  /// 不动 maxHp/maxInternalForce/totalEquipmentAttack(§5.4 红线);
  /// 不动 speed(轻功对决用 terrain modifier 影响出手次数留 P3.2 群战)。
  static BattleCharacter _bake(BattleCharacter c, LightFootTerrainModifier m) {
    return c.copyWith(
      criticalRate: (c.criticalRate + m.criticalRateDelta).clamp(0.0, 0.95),
      evasionRate: (c.evasionRate + m.evasionRateDelta).clamp(0.0, 0.95),
      defenseRate: (c.defenseRate + m.defenseRateDelta).clamp(0.0, 0.95),
      attackPowerMultiplier: m.damageMultiplier,
    );
  }
}
