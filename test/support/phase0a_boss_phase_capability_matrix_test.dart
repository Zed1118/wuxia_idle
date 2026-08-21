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
    // 共 32 = 主线 26(19 phase/charge + 7 脆弱窗口) + 塔 6(5 phase/charge
    // + tower_32 脆弱窗口),全部转 eligible——语义已迁移,不得伪报 skipped。
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
    expect(bossPhaseEntries, hasLength(32));

    // 脆弱窗口纵切(2026-08-22):基础 vulnerability 语义已迁移,8 条内容
    // (主线 7 + tower_32)必须 eligible;cycleVulnerability 高周目覆盖在恒
    // cycle-1 装配下惰性未迁,不构成跳过(与 cycleBossPhases 同口径)。
    const vulnerabilityKeys = {
      'stage/stage_17_05',
      'stage/stage_18_04',
      'stage/stage_18_05',
      'stage/stage_19_05',
      'stage/stage_20_04',
      'stage/stage_20_05',
      'stage/stage_21_04',
      'tower/tower_32',
    };
    for (final key in vulnerabilityKeys) {
      expect(
        entries.singleWhere((entry) => entry.key == key).status,
        Phase0aPreflightStatus.eligible,
        reason: '$key 脆弱窗口语义已迁移,必须 eligible',
      );
    }

    // 潜在重叠:guardian 条目按 EnemyDef 联结校验必带蓄招途径,
    // 它们保持 skipped 且原因必须是更高优先级机制,不得回落 phase/charge 原因。
    final latentPhaseSkipped = entries
        .where((entry) => entry.status == Phase0aPreflightStatus.skipped)
        .where(hasPhaseOrChargeContent)
        .toList();
    expect(latentPhaseSkipped, isNotEmpty);
    for (final entry in latentPhaseSkipped) {
      expect(
        entry.skipReason,
        isNot('unsupported_boss_phase_or_charge_semantics'),
        reason: '${entry.key} 被更高优先级机制跳过',
      );
    }
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'stage'),
      hasLength(26),
    );
    expect(
      bossPhaseEntries.where((entry) => entry.kind.name == 'tower'),
      hasLength(6),
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
    for (final entry in towerBossPhaseEntries) {
      final hasTopLevelCharge = repo.towerFloors
          .firstWhere((floor) => 'tower_${floor.floorIndex}' == entry.id)
          .enemyTeam
          .any((enemy) => enemy.chargeSkillId != null);
      expect(hasTopLevelCharge, isFalse, reason: entry.key);
    }

    // 其他未迁机制守恒:guardian ward / survive 胜负仍按各自原因跳过,
    // 数量与优先级口径不回退;脆弱窗口语义已迁,不再构成跳过原因。
    final guardianEntries = entries
        .where((entry) => entry.skipReason == 'unsupported_guardian_ward')
        .toList();
    final winConditionEntries = entries
        .where((entry) => entry.skipReason == 'unsupported_win_condition')
        .toList();
    expect(guardianEntries, hasLength(2));
    expect(winConditionEntries, hasLength(1));
    expect(
      entries.where(
        (entry) => entry.skipReason == 'unsupported_vulnerability_window',
      ),
      isEmpty,
      reason: '脆弱窗口语义已迁移,任何条目不得再以该原因跳过',
    );
    // 硬断言:剩余 skip 精确为以上两类共 3 条,不得出现第三种原因
    // (任何新增未迁机制必须显式更新本矩阵,不得静默跳过)。
    final skippedEntries = entries
        .where((entry) => entry.status == Phase0aPreflightStatus.skipped)
        .toList();
    expect(skippedEntries, hasLength(3));
    expect(skippedEntries.map((entry) => entry.skipReason).toSet(), {
      'unsupported_guardian_ward',
      'unsupported_win_condition',
    });
    expect(
      entries
          .singleWhere((entry) => entry.key == 'tower/tower_32')
          .status,
      Phase0aPreflightStatus.eligible,
    );
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_42').skipReason,
      'unsupported_guardian_ward',
    );
    expect(
      entries.singleWhere((entry) => entry.key == 'tower/tower_49').skipReason,
      'unsupported_guardian_ward',
    );
    expect(
      entries
          .singleWhere((entry) => entry.key == 'stage/stage_21_05')
          .skipReason,
      'unsupported_win_condition',
    );
    expect(
      guardianEntries
          .map((entry) => entry.key)
          .toSet()
          .intersection(bossPhaseEntries.map((entry) => entry.key).toSet()),
      isEmpty,
      reason: 'guardian 优先级必须先于 phase/charge 分组',
    );
  });
}
