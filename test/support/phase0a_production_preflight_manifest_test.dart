import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';

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
      // charge/破招纵切(2026-08-22):19 条 phase/charge 主线转 eligible。
      hasLength(92),
    );
    expect(towers, hasLength(49));
    expect(
      towers.where((entry) => entry.status == Phase0aPreflightStatus.eligible),
      // charge/破招纵切(2026-08-22):5 条 phase/charge 塔层转 eligible。
      hasLength(46),
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
