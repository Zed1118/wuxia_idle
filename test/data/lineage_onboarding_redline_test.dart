import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/master_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// 第七阶段批三 P2 红线：lineage_onboarding 配置漂移 fail-fast。
void main() {
  MasterDef master(int slot, LineageRole role) => MasterDef(
        id: 'm$slot',
        lineageRole: role,
        slotIndex: slot,
        defaultRealm: RealmTier.erLiu,
        defaultLayer: RealmLayer.qiMeng,
        attributeProfile: const AttributeProfile(
          constitution: 5,
          enlightenment: 5,
          agility: 5,
          fortune: 5,
        ),
        startingTechniqueIds: const [],
        startingEquipmentIds: const [],
        enabledInDemo: true,
        portraitPath: 'p.png',
      );

  final masters = [
    master(0, LineageRole.founder),
    master(1, LineageRole.senior),
    master(2, LineageRole.junior),
  ];

  DiscipleJoinDef join(
    String stage,
    int slot,
    LineageRole role, {
    String narrative = 'narr',
  }) =>
      DiscipleJoinDef(
        stageId: stage,
        masterSlotIndex: slot,
        role: role,
        narrativeId: narrative,
      );

  final stageIds = {'stage_01_02', 'stage_01_04'};

  test('合法配置 → 不抛', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [
          join('stage_01_02', 1, LineageRole.senior),
          join('stage_01_04', 2, LineageRole.junior),
        ],
        existingStageIds: stageIds,
        masters: masters,
      ),
      returnsNormally,
    );
  });

  test('stage 不存在 → 抛（拼错永不触发被拦）', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [join('stage_typo', 1, LineageRole.senior)],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });

  test('stage 重复 → 抛', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [
          join('stage_01_02', 1, LineageRole.senior),
          join('stage_01_02', 2, LineageRole.junior),
        ],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });

  test('role 非 senior/junior → 抛', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [join('stage_01_02', 0, LineageRole.founder)],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });

  test('slot 越界 → 抛（防 service 静默 return null）', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [join('stage_01_02', 9, LineageRole.senior)],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });

  test('join.role 与 masters[slot].lineageRole 不一致 → 抛（核心：双源漂移）', () {
    // join 说 senior，但指向 slot 2（masters 里是 junior）。
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [join('stage_01_02', 2, LineageRole.senior)],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });

  test('narrative_id 为空 → 抛', () {
    expect(
      () => enforceLineageOnboardingRedLines(
        joins: [join('stage_01_02', 1, LineageRole.senior, narrative: '')],
        existingStageIds: stageIds,
        masters: masters,
      ),
      throwsStateError,
    );
  });
}
