import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/application/enemy_combatant_snapshot_assembler.dart';

import 'phase0a_production_preflight_manifest.dart';
import 'test_data.dart';

void main() {
  test('生产定义分类数量稳定且 manifest key 唯一', () async {
    final repo = await loadTestGameRepository();
    final stages = repo.stageDefs.values
        .where(
          (stage) =>
              stage.stageType == StageType.mainline &&
              (stage.chapterIndex ?? 0) >= 2,
        )
        .map(Phase0aProductionPreflightManifest.classifyStage)
        .toList();
    final towers = repo.towerFloors
        .map(Phase0aProductionPreflightManifest.classifyTower)
        .toList();

    expect(stages, hasLength(100));
    expect(
      stages.where((entry) => entry.status == Phase0aPreflightStatus.eligible),
      // charge/破招纵切(2026-08-22):19 条 phase/charge 主线转 eligible;
      // vulnerability 纵切(2026-08-22):7 条脆弱窗口主线再转 eligible。
      hasLength(99),
    );
    expect(towers, hasLength(49));
    expect(
      towers.where((entry) => entry.status == Phase0aPreflightStatus.eligible),
      // charge/破招纵切(2026-08-22):5 条 phase/charge 塔层转 eligible;
      // vulnerability 纵切(2026-08-22):tower_32 再转 eligible。
      hasLength(47),
    );
    final all = [...stages, ...towers];
    expect(all.map((entry) => entry.key).toSet(), hasLength(all.length));
    expect(
      all.where((entry) => entry.status == Phase0aPreflightStatus.skipped),
      everyElement(
        isA<Phase0aPreflightManifestEntry>().having(
          (entry) => entry.skipReason,
          'skipReason',
          isNotEmpty,
        ),
      ),
    );

    // 硬断言:剩余 skip 精确为 3 条 = guardian 2 + unsupported_win_condition 1,
    // 不得出现第三种原因。
    final skipCounts = <String, int>{};
    for (final entry in all.where(
      (entry) => entry.status == Phase0aPreflightStatus.skipped,
    )) {
      skipCounts.update(
        entry.skipReason!,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    expect(skipCounts, {
      'unsupported_guardian_ward': 2,
      'unsupported_win_condition': 1,
    });
  });

  test('cycleVulnerability 守卫:base 必有且装配恒取 cycle-1 基础值', () async {
    // 本批只验证 cycle-1 装配(mapper/preflight 无 cycle 参数)。此守卫钉:
    // ① 所有带非空 cycleVulnerability 的生产 EnemyDef 必须同时带 base
    //    vulnerability(加载期 fromYaml 已校,此处对生产内容显式双保险,
    //    防未来放宽后 cycle 覆盖失去基础锚);
    // ② 生产装配默认口径(不传 cycle 参数)解析出的承伤乘子恒等于
    //    cycle-1 base 值、绝不解析成周目覆盖值——不声称 cycle2 已迁。
    final repo = await loadTestGameRepository();
    var cycleOverrideEnemies = 0;
    void checkTeam(List<EnemyDef> team, {required bool isTower}) {
      for (final enemy in team) {
        if (enemy.cycleVulnerability.isEmpty) continue;
        cycleOverrideEnemies++;
        expect(
          enemy.vulnerability,
          isNotNull,
          reason: '${enemy.id} 配 cycleVulnerability 必须带 base vulnerability',
        );
        final baseMult = enemy.vulnerability!.outOfWindowDamageMult;
        // 生产装配默认口径 = 恒 cycle-1:乘子解析成 base,不得解析成周目覆盖。
        final snapshot = EnemyCombatantSnapshotAssembler.assembleAll(
          [enemy],
          isTower: isTower,
        ).single;
        expect(
          snapshot.vulnerabilityMult,
          baseMult,
          reason: '${enemy.id} 装配必须恒取 cycle-1 base 值',
        );
        final cycle2 = enemy.cycleVulnerability[2]?.outOfWindowDamageMult;
        if (cycle2 != null && cycle2 != baseMult) {
          expect(
            snapshot.vulnerabilityMult,
            isNot(cycle2),
            reason: '${enemy.id} 不得被误读成已迁 cycle2 覆盖',
          );
        }
      }
    }

    for (final stage in repo.stageDefs.values.where(
      (stage) =>
          stage.stageType == StageType.mainline &&
          (stage.chapterIndex ?? 0) >= 2,
    )) {
      checkTeam(stage.enemyTeam, isTower: false);
    }
    for (final floor in repo.towerFloors) {
      checkTeam(floor.enemyTeam, isTower: true);
    }
    expect(
      cycleOverrideEnemies,
      greaterThan(0),
      reason: '守卫必须覆盖真实生产内容,不得空转',
    );
  });

  test('clean 主线被列为 eligible', () {
    const base = EnemyDef(
      id: 'enemy',
      name: 'enemy',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 1,
      baseAttack: 1,
      baseSpeed: 1,
      skillIds: [],
      iconPath: '',
    );
    const stage = StageDef(
      id: 'stage',
      name: 'stage',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [base],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );
    expect(
      Phase0aProductionPreflightManifest.classifyStage(stage).status,
      Phase0aPreflightStatus.eligible,
    );
  });
}
