import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/stage_skill_drop_hook.dart';

StageDef _bossStage({String? manual, String? fragment}) => StageDef(
      id: 'stage_test_boss',
      name: '测试Boss关',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: const [],
      isBossStage: true,
      baseExpReward: 0,
      difficultyMultiplier: 1.0,
      dropSkillManualId: manual,
      dropSkillFragmentId: fragment,
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_skill_drop_hook_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真解:首通(快照不含本关)→ 解锁;重复(快照含本关)→ 不依赖重复给', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    final stage = _bossStage(manual: 'skill_real');

    await runStageSkillDropHookAfterVictory(
      stage: stage,
      svc: svc,
      clearedStageIds: const {}, // 首通快照
      towerFragmentDropProb: 0.20,
      rng: Random(1),
    );
    expect(await svc.isUnlocked('skill_real'), true);

    // 重复通关:快照已含本关 → manual 分支不触发,但已解锁状态不变
    await runStageSkillDropHookAfterVictory(
      stage: stage,
      svc: svc,
      clearedStageIds: const {'stage_test_boss'},
      towerFragmentDropProb: 0.20,
      rng: Random(2),
    );
    expect(await svc.isUnlocked('skill_real'), true);
  });

  test('残页:prob=1.0 必掉,集齐 5 次自动解锁', () async {
    final svc = SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
    final stage = _bossStage(fragment: 'skill_frag');
    for (var i = 0; i < 4; i++) {
      await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 1.0,
        rng: Random(i),
      );
    }
    expect(await svc.isUnlocked('skill_frag'), false);
    final (cur, total) = await svc.fragmentProgress('skill_frag');
    expect(cur, 4);
    expect(total, 5);
    // 第 5 次 → 达阈值解锁
    await runStageSkillDropHookAfterVictory(
      stage: stage,
      svc: svc,
      clearedStageIds: const {},
      towerFragmentDropProb: 1.0,
      rng: Random(9),
    );
    expect(await svc.isUnlocked('skill_frag'), true);
  });

  test('残页:prob=0.0 不掉', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    final stage = _bossStage(fragment: 'skill_frag2');
    await runStageSkillDropHookAfterVictory(
      stage: stage,
      svc: svc,
      clearedStageIds: const {},
      towerFragmentDropProb: 0.0,
      rng: Random(0),
    );
    final (cur, _) = await svc.fragmentProgress('skill_frag2');
    expect(cur, 0);
  });
}
