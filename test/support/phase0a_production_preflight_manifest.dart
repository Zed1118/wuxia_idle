import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';

enum Phase0aPreflightContentKind { stage, tower }

enum Phase0aPreflightStatus { eligible, skipped }

final class Phase0aPreflightManifestEntry {
  const Phase0aPreflightManifestEntry({
    required this.kind,
    required this.id,
    required this.status,
    this.skipReason,
  });

  final Phase0aPreflightContentKind kind;
  final String id;
  final Phase0aPreflightStatus status;
  final String? skipReason;

  String get key => '${kind.name}/$id';
}

/// Phase 0A 当前能力 manifest。分类只描述语义是否已被 reducer/AI 消费，
/// 不以“能够构造并跑完”替代迁移完成。
final class Phase0aProductionPreflightManifest {
  const Phase0aProductionPreflightManifest._();

  static Phase0aPreflightManifestEntry classifyStage(StageDef stage) {
    final reason = _stageSkipReason(stage);
    return Phase0aPreflightManifestEntry(
      kind: Phase0aPreflightContentKind.stage,
      id: stage.id,
      status: reason == null
          ? Phase0aPreflightStatus.eligible
          : Phase0aPreflightStatus.skipped,
      skipReason: reason,
    );
  }

  static Phase0aPreflightManifestEntry classifyTower(TowerFloorDef floor) {
    final reason = _enemyTeamSkipReason(floor.enemyTeam);
    return Phase0aPreflightManifestEntry(
      kind: Phase0aPreflightContentKind.tower,
      id: 'tower_${floor.floorIndex}',
      status: reason == null
          ? Phase0aPreflightStatus.eligible
          : Phase0aPreflightStatus.skipped,
      skipReason: reason,
    );
  }

  static String? _stageSkipReason(StageDef stage) {
    if (stage.enemyTeam.isEmpty) return 'empty_enemy_team';
    if (!_winConditionSupported(stage.winCondition)) {
      return 'unsupported_win_condition';
    }
    if (stage.massBattleWaveCount != null ||
        stage.massBattleEnemyCounts != null) {
      return 'unsupported_waves';
    }
    if (stage.stageType != StageType.mainline) {
      return 'unsupported_stage_type_${stage.stageType.name}';
    }
    return _enemyTeamSkipReason(stage.enemyTeam);
  }

  static String? _enemyTeamSkipReason(List<EnemyDef> enemies) {
    if (enemies.isEmpty) return 'empty_enemy_team';
    if (enemies.any(_hasUnsupportedBossPhaseOrChargeSemantics)) {
      return 'unsupported_boss_phase_or_charge_semantics';
    }
    return null;
  }

  /// 穷尽生产胜负条件：两类均已由 Phase 0A flow 消费。
  /// 未来扩枚举时 switch 编译失败，强制重新决策而非默认放行。
  static bool _winConditionSupported(StageWinCondition? condition) =>
      switch (condition?.type) {
        null => true,
        StageWinConditionType.defeatAll => true,
        StageWinConditionType.surviveTicks => true,
      };

  /// 阶段/蓄力语义支持性(charge/破招纵切后):顶层 chargeSkillId 与
  /// chargeCounter 阶段机制已由 reducer/AI 消费;周目覆盖在 0A 装配恒为
  /// cycle-1 默认值下惰性,但其机制
  /// 同样过支持性检查。穷尽 switch 表达式:未来新增 BossPhaseMechanic
  /// 枚举值 = 编译错误 = 强制 fail-closed 决策,不得静默放行。
  ///
  /// 脆弱窗口(2026-08-22 纵切):`EnemyDef.vulnerability` 基础值已经
  /// mapper→快照→actor→reducer 运行态事实(蓄招/踉跄)折入唯一
  /// DamageCalculator 消费,不再构成跳过原因。mapper 已支持显式
  /// cycleIndex；默认仍为 cycle-1 零回归，高周目取对应覆盖。
  /// 注意与 `cycleBossPhases` 口径不同:后者的周目覆盖
  /// 仍逐一过机制支持性检查(见 [_hasUnsupportedBossPhaseOrChargeSemantics]
  /// 对 cycleBossPhases 的遍历),而 cycleVulnerability 无独立机制可查;
  /// 两者均不单独构成跳过原因,但校验路径不一样,不是「同口径」。
  static bool _hasUnsupportedBossPhaseOrChargeSemantics(EnemyDef enemy) {
    for (final phase in enemy.bossPhases ?? const <BossPhaseDef>[]) {
      if (!_phaseMechanicSupported(phase.onEnterMechanic)) return true;
    }
    for (final phases in enemy.cycleBossPhases.values) {
      for (final phase in phases) {
        if (!_phaseMechanicSupported(phase.onEnterMechanic)) return true;
      }
    }
    return false;
  }

  static bool _phaseMechanicSupported(BossPhaseMechanic? mechanic) =>
      switch (mechanic) {
        null => true,
        BossPhaseMechanic.chargeCounter => true,
      };
}
