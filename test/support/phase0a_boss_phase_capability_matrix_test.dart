import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

import 'phase0a_production_preflight_manifest.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  test('production boss phase capability matrix is derived from manifest', () {
    final stages = repo.stageDefs.values
        .where(
          (stage) =>
              stage.stageType == StageType.mainline &&
              (stage.chapterIndex ?? 0) >= 2,
        )
        .toList();
    final towers = repo.towerFloors;
    expect(stages, hasLength(100));
    expect(towers, hasLength(49));

    final entries = [
      ...stages.map(Phase0aProductionPreflightManifest.classifyStage),
      ...towers.map(Phase0aProductionPreflightManifest.classifyTower),
    ];
    expect(entries, hasLength(149));
    expect(entries.map((entry) => entry.key).toSet(), hasLength(149));

    // charge/破招纵切(2026-08-22):phase/charge 语义已由 reducer/AI 消费,
    // 任何条目不得再以该原因跳过。
    expect(
      entries.where(
        (entry) =>
            entry.skipReason == 'unsupported_boss_phase_or_charge_semantics',
      ),
      isEmpty,
    );

    // 真实 phase/charge 内容组(内容侧推导,不读 manifest 原因):
    // 敌队含 bossPhases 或顶层 chargeSkillId 且无更高优先级未迁机制的条目,
    // 共 35 = 原 32 + guardian 塔 2 + surviveTicks 主线 1，
    // 全部转 eligible——语义已迁移,不得伪报 skipped。
    List<EnemyDef> enemyTeamOf(Phase0aPreflightManifestEntry entry) =>
        switch (entry.kind) {
          Phase0aPreflightContentKind.stage =>
            repo.stageDefs[entry.id]!.enemyTeam,
          Phase0aPreflightContentKind.tower =>
            repo.towerFloors
                .firstWhere((floor) => 'tower_${floor.floorIndex}' == entry.id)
                .enemyTeam,
        };
    bool hasPhaseOrChargeContent(Phase0aPreflightManifestEntry entry) =>
        enemyTeamOf(entry).any(
          (enemy) =>
              enemy.chargeSkillId != null ||
              (enemy.bossPhases?.isNotEmpty ?? false) ||
              enemy.cycleBossPhases.isNotEmpty,
        );
    final bossPhaseEntries = entries
        .where((entry) => entry.status == Phase0aPreflightStatus.eligible)
        .where(hasPhaseOrChargeContent)
        .toList();
    expect(bossPhaseEntries, hasLength(35));

    // 脆弱窗口纵切(2026-08-22):基础 vulnerability 语义已迁移,8 条内容
    // 基础窗口与 cycleVulnerability 高周目覆盖均已接通。
    const vulnerabilityKeys = {
      'stage/stage_17_05',
      'stage/stage_18_04',
      'stage/stage_18_05',
      'stage/stage_19_05',
      'stage/stage_20_04',
      'stage/stage_20_05',
      'stage/stage_21_04',
      'stage/stage_21_05',
      'tower/tower_32',
      'tower/tower_49',
    };
    for (final key in vulnerabilityKeys) {
      expect(
        entries.singleWhere((entry) => entry.key == key).status,
        Phase0aPreflightStatus.eligible,
        reason: '$key 脆弱窗口语义已迁移,必须 eligible',
      );
    }

    // 迁移后不得再有「被其它机制优先跳过」的 phase/charge 内容。
    final latentPhaseSkipped = entries
        .where((entry) => entry.status == Phase0aPreflightStatus.skipped)
        .where(hasPhaseOrChargeContent)
        .toList();
    expect(latentPhaseSkipped, isEmpty);
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'stage'),
      hasLength(27),
    );
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'tower'),
      hasLength(8),
    );
    for (final entry in bossPhaseEntries) {
      expect(
        entry.status,
        Phase0aPreflightStatus.eligible,
        reason: '${entry.key} phase/charge 语义已迁移,必须 eligible',
      );
    }

    for (final entry in bossPhaseEntries) {
      final phases = enemyTeamOf(
        entry,
      ).expand((enemy) => enemy.bossPhases ?? const <BossPhaseDef>[]);
      expect(
        phases,
        contains(
          predicate<BossPhaseDef>(
            (phase) => phase.onEnterMechanic == BossPhaseMechanic.chargeCounter,
          ),
        ),
        reason: '${entry.key} must expose a chargeCounter phase',
      );
    }

    final stageBossPhaseEntries = bossPhaseEntries.where(
      (entry) => entry.kind == Phase0aPreflightContentKind.stage,
    );
    for (final entry in stageBossPhaseEntries) {
      final hasTopLevelCharge = repo.stageDefs[entry.id]!.enemyTeam.any(
        (enemy) => enemy.chargeSkillId != null,
      );
      expect(hasTopLevelCharge, isTrue, reason: entry.key);
    }
    final towerBossPhaseEntries = bossPhaseEntries.where(
      (entry) => entry.kind == Phase0aPreflightContentKind.tower,
    );
    bool towerHasTopLevelCharge(Phase0aPreflightManifestEntry entry) => repo
        .towerFloors
        .firstWhere((floor) => 'tower_${floor.floorIndex}' == entry.id)
        .enemyTeam
        .any((enemy) => enemy.chargeSkillId != null);
    expect(
      towerHasTopLevelCharge(
        towerBossPhaseEntries.singleWhere(
          (entry) => entry.key == 'tower/tower_42',
        ),
      ),
      isTrue,
      reason: 'tower_42 护法合击相位依赖顶层蓄力',
    );
    expect(
      towerBossPhaseEntries.any((entry) => !towerHasTopLevelCharge(entry)),
      isTrue,
      reason: '塔内阶段 chargeCounter 仍覆盖无顶层蓄力的内容',
    );

    // guardian ward / intercept / coop 与 surviveTicks 均已迁移。
    final guardianEntries = entries
        .where((entry) => entry.skipReason == 'unsupported_guardian_ward')
        .toList();
    final winConditionEntries = entries
        .where((entry) => entry.skipReason == 'unsupported_win_condition')
        .toList();
    expect(guardianEntries, isEmpty);
    expect(winConditionEntries, isEmpty);
    expect(
      entries.where(
        (entry) => entry.skipReason == 'unsupported_vulnerability_window',
      ),
      isEmpty,
      reason: '脆弱窗口语义已迁移,任何条目不得再以该原因跳过',
    );
    // 149 条已全覆盖；任何新增未迁机制必须显式更新本矩阵。
    final skippedEntries = entries
        .where((entry) => entry.status == Phase0aPreflightStatus.skipped)
        .toList();
    expect(skippedEntries, isEmpty);
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_32').status,
      Phase0aPreflightStatus.eligible,
    );
    for (final key in const {
      'tower/tower_42',
      'tower/tower_49',
      'stage/stage_21_05',
    }) {
      expect(
        entries.singleWhere((entry) => entry.key == key).status,
        Phase0aPreflightStatus.eligible,
        reason: '$key 新语义已迁移',
      );
    }
  });
}
