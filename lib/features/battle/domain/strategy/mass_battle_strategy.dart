import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../mass_battle/domain/mass_battle_def.dart';
import '../battle_state.dart';
import 'battle_strategy.dart';
import 'default_ground_strategy.dart';

/// 群战守城 strategy(1.0 P3.2 §12.3,GDD v1.13)。
///
/// **组合委派架构**(memory `feedback_avoid_over_engineer_abstraction`,沿
/// LightFootStrategy 体例):内部持 `const DefaultGroundStrategy _delegate`,
/// zero 代码重复;tick/requestUltimate 直接委派,runToEnd 入口先把 formation
/// modifier 烘焙到玩家 leftTeam,再 wave 循环交替 `enemyTeamsPerWave[w]` 进
/// rightTeam 委派 `_delegate.runToEnd`,wave 间走 [_intermission] 重置 actionPoint+cd
/// 但保留 HP/IF(守城压力跨 wave 累积)。
///
/// **真痛点 = formation 入口烘焙 + wave 循环 + intermission 三处**,
/// 不抽象多余 hook。BattleStrategy 接口粗粒度 3 method 已足,无需扩。
///
/// **与 LightFoot 关键差异**:
///   - Formation 烘焙**仅 leftTeam**(玩家战略选择,敌方不沾;LightFoot terrain
///     是地形中立双方对等)
///   - 多 wave 循环 + 中场 intermission(LightFoot 单场)
///   - 每 wave rightTeam 全新生成(从 ctor 注入的 `enemyTeamsPerWave`)
///
/// **immutable**:formation bake 在 runToEnd 入口一次(idempotent by ctor),
/// 后续 tick 由 _delegate 跑现有公式自动吸收(no mutable state)。
///
/// **clamp ≤0.95**:critRate / evasionRate / defenseRate 各 clamp(0.0, 0.95)
/// 防破 §5.4/§5.5 红线(沿 LightFoot bake 体例)。
///
/// **formation modifier 数值**(numbers.yaml mass_battle.formations):
///   - yanXing(雁行):crit +0.10 / defense -0.05 — 攻势启
///   - baGua(八卦):defense +0.10 / evasion +0.05 — 守势固
///   - fengShi(锋矢):damage ×1.10 / crit +0.05 — 突击强
class MassBattleStrategy implements BattleStrategy {
  /// 战前玩家选择的阵型(默认走 `config.stageFormations[stageId]` 或 yanXing)。
  final Formation formation;

  /// 每 wave 敌方队伍快照(`length == waveCount`,2.3 Batch service 层预生成
  /// 注入)。每 wave 用 `enemyTeamsPerWave[w]` 覆盖 rightTeam。
  final List<List<BattleCharacter>> enemyTeamsPerWave;

  /// MassBattleDef 配置(numbers.yaml mass_battle 段加载)。
  final MassBattleDef config;

  /// 内部委派 strategy(沿 DefaultGroundStrategy tick 主循环)。
  static const _delegate = DefaultGroundStrategy();

  const MassBattleStrategy({
    required this.formation,
    required this.enemyTeamsPerWave,
    required this.config,
  });

  /// wave 总数 = `enemyTeamsPerWave.length`(1-4 wave,wave=1 即单场群战)。
  int get waveCount => enemyTeamsPerWave.length;

  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) =>
      _delegate.tick(state, n, rng: rng);

  /// 跑完整守城战(多 wave 循环)。
  ///
  /// 流程:
  /// 1. 入口烘焙 formation modifier 到玩家 leftTeam(仅一次,idempotent)
  /// 2. for wave in 0..waveCount:
  ///    - 替换 rightTeam = `enemyTeamsPerWave[w]`
  ///    - 委派 `_delegate.runToEnd`(单 wave 内仍是 3v5/6/7 标准战斗)
  ///    - 若 leftWin → 继续下一 wave;若 rightWin/draw → 整场结束 return
  /// 3. 走完所有 wave → leftWin(守城成功)
  ///
  /// **wave 间 [_intermission]**:仅在 wave 之间(不在末尾)执行;按
  /// `config.waveIntermission` 4 字段控制 actionPoint reset / HP/IF preserve /
  /// cd reset / result 清空(否则下 wave _delegate.runToEnd 立即 short-circuit)。
  @override
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) {
    if (enemyTeamsPerWave.isEmpty) {
      return initial.copyWith(result: BattleResult.draw);
    }
    final r = rng ?? Random();
    var s = _applyFormation(initial);

    for (var w = 0; w < waveCount; w++) {
      // wave 入口:替换 rightTeam = 本 wave 敌方
      final waveEnemies = enemyTeamsPerWave[w];
      final rightEntryHp = waveEnemies.fold<int>(0, (a, c) => a + c.currentHp);
      s = s.copyWith(rightTeam: List.unmodifiable(waveEnemies));
      // 委派单 wave 战斗
      s = _delegate.runToEnd(s, n, maxTicks: maxTicks, rng: r);

      // P3.2.B 残血容差:draw 时若敌方剩余 HP ≤ 阈值比例 → 改判 leftWin
      // (守城清剿叙事 · 免「末尾 1 残血敌方 KO 不动 → maxTicks 触 draw」stalemate)。
      if (s.result == BattleResult.draw && rightEntryHp > 0) {
        final rightExitHp = s.rightTeam.fold<int>(0, (a, c) => a + c.currentHp);
        if (rightExitHp <= rightEntryHp * config.residualHpThresholdPct) {
          s = s.copyWith(result: BattleResult.leftWin);
        }
      }

      // wave 结算判定:rightWin 或 draw → 整场即终结(守城失败 / 兜底平局)
      if (s.result == BattleResult.rightWin || s.result == BattleResult.draw) {
        return s;
      }
      // leftWin → 本 wave 通过;若不是末 wave 走 intermission 准备下波
      if (w < waveCount - 1) {
        s = _intermission(s);
      }
    }
    // 全 wave 通过 → leftWin(守城成功;此时 s.result 仍是末 wave 的 leftWin,
    // 直接 return s 即可)
    return s;
  }

  @override
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate,
  ) =>
      _delegate.requestUltimate(state, characterId, ultimate);

  BattleState _applyFormation(BattleState s) => applyFormationTo(
        s,
        formation: formation,
        config: config,
      );

  /// 烘焙 formation modifier 到**仅 leftTeam** BattleCharacter 入口快照。
  ///
  /// 与 [LightFootStrategy.applyTerrainTo] 关键差异:阵型是玩家战略选择,
  /// 敌方 rightTeam **不沾**(地形中立双方对等的 LightFoot 不同)。
  ///
  /// idempotent:相同 (state, formation, config) 入参产同样 output;
  /// runToEnd 入口调一次即可(_delegate.runToEnd 内部 tick 循环不影响 bake)。
  ///
  /// **@visibleForTesting**:R6 直接断言 bake 后的 leftTeam stat,
  /// 不必跑完整 runToEnd 路径(沿 LightFootStrategy.applyTerrainTo 体例)。
  @visibleForTesting
  static BattleState applyFormationTo(
    BattleState s, {
    required Formation formation,
    required MassBattleDef config,
  }) {
    final m = config.formations[formation] ??
        MassBattleFormationModifier.neutral();
    final newLeft = s.leftTeam.map((c) => _bake(c, m)).toList(growable: false);
    return s.copyWith(
      leftTeam: List.unmodifiable(newLeft),
      // rightTeam 不动 — 阵型仅玩家战略,敌方不沾
    );
  }

  /// 单角色 stat bake(仅玩家用):critRate/evasionRate/defenseRate 加 delta +
  /// clamp(0.0, 0.95);attackPowerMultiplier 直接 set 为 formation.damageMultiplier
  /// (沿 LightFoot P3.1.B 体例)。
  ///
  /// 不动 maxHp/maxInternalForce/totalEquipmentAttack(§5.4 红线)。
  /// 不动 speed(阵型 modifier 不沾出手次数维度)。
  static BattleCharacter _bake(
    BattleCharacter c,
    MassBattleFormationModifier m,
  ) {
    return c.copyWith(
      criticalRate: (c.criticalRate + m.criticalRateDelta).clamp(0.0, 0.95),
      evasionRate: (c.evasionRate + m.evasionRateDelta).clamp(0.0, 0.95),
      defenseRate: (c.defenseRate + m.defenseRateDelta).clamp(0.0, 0.95),
      attackPowerMultiplier: m.damageMultiplier,
    );
  }

  /// wave 间过渡:按 `config.waveIntermission` 4 字段控制 leftTeam 状态。
  ///
  /// **必须清空 result**(否则下波 `_delegate.runToEnd` 进入 while !isFinished
  /// 立刻 short-circuit return)。`pendingUltimates` 也清空(上波未消费的
  /// 大招请求不带入下波)。
  ///
  /// **resetActionPoint=true**:wave 间 actionPoint 归 0,走 tick 不快进
  /// (契 §5.5 在线 = 离线)。
  /// **preserveHp=true**:HP 不回血,守城压力跨 wave 累积。
  /// **preserveInternalForce=true**:内力保留,限制大招使用频率。
  /// **preserveCooldowns=false**:cd 全清(map 空),给玩家下波大招机会。
  ///
  /// 死角色不复活(`isAlive=false` 保留 — 阵型烘焙后死了就死了,§5.1 反留存)。
  BattleState _intermission(BattleState s) {
    final wi = config.waveIntermission;
    final newLeft = s.leftTeam.map((c) {
      // 仅活角色调整 actionPoint/cd;死角色保持原状(isAlive=false)
      if (!c.isAlive) return c;
      return c.copyWith(
        actionPoint: wi.resetActionPoint ? 0 : c.actionPoint,
        currentHp: wi.preserveHp ? c.currentHp : c.maxHp,
        currentInternalForce: wi.preserveInternalForce
            ? c.currentInternalForce
            : c.maxInternalForce,
        skillCooldowns:
            wi.preserveCooldowns ? c.skillCooldowns : const <String, int>{},
      );
    }).toList(growable: false);

    return s.copyWith(
      leftTeam: List.unmodifiable(newLeft),
      result: null, // 清空 result 让下波继续
      pendingUltimates: const {}, // 不带入下波
    );
  }
}
