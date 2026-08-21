import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
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
    if (stage.winCondition != null) return 'unsupported_win_condition';
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
    if (enemies.any(
      (enemy) => enemy.guardianWard != null || enemy.guardInterceptsInterrupt,
    )) {
      return 'unsupported_guardian_ward';
    }
    if (enemies.any(
      (enemy) =>
          enemy.vulnerability != null || enemy.cycleVulnerability.isNotEmpty,
    )) {
      return 'unsupported_vulnerability_window';
    }
    if (enemies.any(
      (enemy) =>
          enemy.chargeSkillId != null ||
          (enemy.bossPhases?.isNotEmpty ?? false) ||
          enemy.cycleBossPhases.isNotEmpty,
    )) {
      return 'unsupported_boss_phase_or_charge_semantics';
    }
    return null;
  }
}
