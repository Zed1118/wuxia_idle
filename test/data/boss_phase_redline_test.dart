/// 批二①：BossPhase unlockSkillIds 红线校验单元测试。
///
/// 直接调 [GameRepository.enforceBossPhaseSkillIds]（纯 static 方法，接受
/// stageDefs Map + skillIdSet），无需走完整 loadAllDefs，与 _enforceBossChargeRedLines
/// 同实现模式。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

// ── fixture helpers ─────────────────────────────────────────────────────────

EnemyDef _enemy({
  String id = 'boss_x',
  bool isBoss = true,
  List<BossPhaseDef>? bossPhases,
}) =>
    EnemyDef(
      id: id,
      name: '测试Boss',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 5000,
      baseAttack: 200,
      baseSpeed: 50,
      skillIds: const ['skill_normal'],
      iconPath: 'x.png',
      isBoss: isBoss,
      bossPhases: bossPhases,
    );

TowerFloorDef _towerFloor(int floorIndex, List<EnemyDef> team) => TowerFloorDef(
      floorIndex: floorIndex,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: team,
    );

StageDef _stage(String id, List<EnemyDef> team) => StageDef(
      id: id,
      name: '测试关',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.erLiu,
      enemyTeam: team,
      isBossStage: false,
      baseExpReward: 100,
      difficultyMultiplier: 1.0,
    );

// ── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('GameRepository.enforceBossPhaseSkillIds(批二①)', () {
    test('有效 unlockSkillIds 全在 skillIdSet → 不抛', () {
      final enemy = _enemy(
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          const BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: ['skill_rage'],
          ),
        ],
      );
      final stages = {'s1': _stage('s1', [enemy])};
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(
          stages,
          {'skill_normal', 'skill_rage'},
        ),
        returnsNormally,
      );
    });

    test('unlockSkillIds 引用不存在 id → 抛 StateError 含该 id', () {
      final enemy = _enemy(
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          const BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: ['skill_ghost_not_in_yaml'],
          ),
        ],
      );
      final stages = {'s1': _stage('s1', [enemy])};
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(
          stages,
          {'skill_normal'},
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('skill_ghost_not_in_yaml'),
          ),
        ),
      );
    });

    test('bossPhases==null 的敌人跳过，不抛', () {
      final mob = _enemy(id: 'mob', isBoss: false, bossPhases: null);
      final stages = {'s1': _stage('s1', [mob])};
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(stages, {}),
        returnsNormally,
      );
    });

    test('unlockSkillIds 为空列表的阶段 → 不抛', () {
      final enemy = _enemy(
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          const BossPhaseDef(hpThresholdPct: 0.5),
        ],
      );
      final stages = {'s1': _stage('s1', [enemy])};
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(stages, {}),
        returnsNormally,
      );
    });
  });

  group('GameRepository.enforceBossPhaseSkillIds — tower floors(批二①)', () {
    test('塔层 boss unlockSkillIds 全在 skillIdSet → 不抛', () {
      final enemy = _enemy(
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          const BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: ['skill_tower_rage'],
          ),
        ],
      );
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(
          {},
          {'skill_tower_rage'},
          towerFloors: [_towerFloor(10, [enemy])],
        ),
        returnsNormally,
      );
    });

    test('塔层 boss unlockSkillIds 引用不存在 id → 抛 StateError 含 floor 标识', () {
      final enemy = _enemy(
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          const BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: ['skill_ghost_tower'],
          ),
        ],
      );
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(
          {},
          {'skill_normal'},
          towerFloors: [_towerFloor(10, [enemy])],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('skill_ghost_tower'), contains('10')),
          ),
        ),
      );
    });

    test('塔层 bossPhases==null 的敌人跳过 → 不抛', () {
      final mob = _enemy(id: 'mob', isBoss: false, bossPhases: null);
      expect(
        () => GameRepository.enforceBossPhaseSkillIds(
          {},
          {},
          towerFloors: [_towerFloor(3, [mob])],
        ),
        returnsNormally,
      );
    });
  });
}
