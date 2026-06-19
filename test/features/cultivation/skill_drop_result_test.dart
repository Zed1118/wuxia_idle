import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_drop_result.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/cultivation/presentation/stage_skill_drop_hook.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

/// 第七阶段批二 ④：SkillDropResult + service/hook 回传掉落结果 测族。
void main() {
  // ── Isar 初始化(镜同 skill_unlock_service_test.dart) ──
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wuxia_skill_drop_result_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ── SkillDropResult getters ──────────────────────────────────────────────
  group('SkillDropResult getters', () {
    test('none: isMajor false, isMinorFragment false', () {
      const r = SkillDropResult.none;
      expect(r.isMajor, false);
      expect(r.isMinorFragment, false);
      expect(r.manualGranted, null);
      expect(r.fragmentSkillId, null);
    });

    test('manualGranted set → isMajor true', () {
      const r = SkillDropResult(manualGranted: 'skill_x');
      expect(r.isMajor, true);
      expect(r.isMinorFragment, false);
    });

    test('fragmentJustUnlocked → isMajor true', () {
      const r = SkillDropResult(
        fragmentSkillId: 'skill_x',
        fragmentCount: 5,
        fragmentThreshold: 5,
        fragmentJustUnlocked: true,
      );
      expect(r.isMajor, true);
      expect(r.isMinorFragment, false);
    });

    test('fragment dropped but not yet unlocked → isMinorFragment true', () {
      const r = SkillDropResult(
        fragmentSkillId: 'skill_x',
        fragmentCount: 3,
        fragmentThreshold: 5,
        fragmentJustUnlocked: false,
      );
      expect(r.isMajor, false);
      expect(r.isMinorFragment, true);
    });
  });

  // ── SkillDropResult ==, hashCode ─────────────────────────────────────────
  group('SkillDropResult == / hashCode', () {
    test('none == const SkillDropResult()', () {
      expect(SkillDropResult.none, equals(const SkillDropResult()));
      expect(SkillDropResult.none.hashCode,
          equals(const SkillDropResult().hashCode));
    });

    test('identical fields → equal', () {
      const a = SkillDropResult(
        fragmentSkillId: 'skill_x',
        fragmentCount: 3,
        fragmentThreshold: 5,
        fragmentJustUnlocked: false,
      );
      const b = SkillDropResult(
        fragmentSkillId: 'skill_x',
        fragmentCount: 3,
        fragmentThreshold: 5,
        fragmentJustUnlocked: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing fragmentCount → not equal', () {
      const a = SkillDropResult(fragmentSkillId: 'skill_x', fragmentCount: 3);
      const b = SkillDropResult(fragmentSkillId: 'skill_x', fragmentCount: 4);
      expect(a, isNot(equals(b)));
    });

    test('differing fragmentSkillId → not equal', () {
      const a = SkillDropResult(fragmentSkillId: 'skill_x');
      const b = SkillDropResult(fragmentSkillId: 'skill_y');
      expect(a, isNot(equals(b)));
    });

    test('differing manualGranted → not equal', () {
      const a = SkillDropResult(manualGranted: 'skill_m');
      const b = SkillDropResult(manualGranted: 'skill_n');
      expect(a, isNot(equals(b)));
    });

    test('differing fragmentJustUnlocked → not equal', () {
      const a = SkillDropResult(
          fragmentSkillId: 'skill_x', fragmentJustUnlocked: true);
      const b = SkillDropResult(
          fragmentSkillId: 'skill_x', fragmentJustUnlocked: false);
      expect(a, isNot(equals(b)));
    });
  });

  // ── SkillUnlockService.grantManual 返回 bool ──────────────────────────────
  group('SkillUnlockService.grantManual → Future<bool>', () {
    test('first call returns true (newly granted)', () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final granted = await svc.grantManual('skill_qingshan_qingfeng');
      expect(granted, true);
      expect(await svc.isUnlocked('skill_qingshan_qingfeng'), true);
    });

    test('second call (same id) returns false (already unlocked, idempotent)',
        () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      await svc.grantManual('skill_qingshan_qingfeng');
      final secondGrant = await svc.grantManual('skill_qingshan_qingfeng');
      expect(secondGrant, false);
      // 状态不变
      expect(await svc.isUnlocked('skill_qingshan_qingfeng'), true);
    });
  });

  // ── SkillUnlockService.addFragment 返回 SkillDropResult ──────────────────
  group('SkillUnlockService.addFragment → Future<SkillDropResult>', () {
    test('below threshold → fragmentJustUnlocked false, count correct',
        () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      final r = await svc.addFragment('skill_x', 3);
      expect(r.fragmentSkillId, 'skill_x');
      expect(r.fragmentCount, 3);
      expect(r.fragmentThreshold, 5);
      expect(r.fragmentJustUnlocked, false);
      expect(await svc.isUnlocked('skill_x'), false);
    });

    test('reaches threshold → fragmentJustUnlocked true', () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      await svc.addFragment('skill_x', 4); // 4 残页,未集齐
      final r = await svc.addFragment('skill_x', 1); // 第 5 片 → 集齐
      expect(r.fragmentJustUnlocked, true);
      expect(r.fragmentCount, 5);
      expect(r.fragmentSkillId, 'skill_x');
      expect(await svc.isUnlocked('skill_x'), true);
    });

    test('already unlocked → returns SkillDropResult.none (no fragment signal)',
        () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      await svc.grantManual('skill_y'); // 真解直接解锁
      final r = await svc.addFragment('skill_y', 3); // 已解锁短路
      // 短路应回 none：无残页信号，防止下游误报"得残页"通知
      expect(r.fragmentSkillId, null);
      expect(r.isMinorFragment, false);
      expect(r.isMajor, false);
      expect(r, SkillDropResult.none);
      // 残页计数不变
      final (cur, _) = await svc.fragmentProgress('skill_y');
      expect(cur, 0);
    });

    test('overshoot: single call adds n >= threshold → unlocks in one shot',
        () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      final r = await svc.addFragment('skill_z', 9); // 一次超过阈值
      expect(r.fragmentJustUnlocked, true);
      expect(r.fragmentCount, 9);
      expect(await svc.isUnlocked('skill_z'), true);
    });
  });

  // ── hook: _applySkillDrop 返回 SkillDropResult ────────────────────────────
  group('stage hook → SkillDropResult', () {
    StageDef bossStage({String? manual, String? fragment}) => StageDef(
          id: 'stage_test_boss',
          name: '测试Boss关',
          stageType: StageType.mainline,
          chapterIndex: 1,
          requiredRealm: RealmTier.xueTu,
          enemyTeam: const [],
          isBossStage: true,
          dropEquipmentDefIds: const [],
          dropItemDefIds: const [],
          baseExpReward: 0,
          difficultyMultiplier: 1.0,
          dropSkillManualId: manual,
          dropSkillFragmentId: fragment,
        );

    test('first-clear manual stage → manualGranted set, isMajor true',
        () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final stage = bossStage(manual: 'skill_real');
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {}, // 首通
        towerFragmentDropProb: 0.0, // 无残页
        rng: Random(0),
      );
      expect(r.manualGranted, 'skill_real');
      expect(r.isMajor, true);
      expect(r.fragmentSkillId, null);
    });

    test('second-clear manual stage → manualGranted null (already unlocked)',
        () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final stage = bossStage(manual: 'skill_real');
      // 首通先解锁
      await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 0.0,
        rng: Random(0),
      );
      // 重通:快照已含本关
      final r2 = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {'stage_test_boss'},
        towerFragmentDropProb: 0.0,
        rng: Random(1),
      );
      expect(r2.manualGranted, null);
      expect(r2.isMajor, false);
    });

    test('fragment prob=1.0 → fragmentSkillId set, count 1, isMinorFragment',
        () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      final stage = bossStage(fragment: 'skill_frag');
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 1.0,
        rng: Random(0),
      );
      expect(r.fragmentSkillId, 'skill_frag');
      expect(r.fragmentCount, 1);
      expect(r.isMinorFragment, true);
      expect(r.isMajor, false);
    });

    test('fragment prob=0.0 → SkillDropResult.none', () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final stage = bossStage(fragment: 'skill_frag2');
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 0.0,
        rng: Random(0),
      );
      expect(r.manualGranted, null);
      expect(r.fragmentSkillId, null);
    });

    test('fragment 5th drop → fragmentJustUnlocked, isMajor', () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      final stage = bossStage(fragment: 'skill_frag3');
      for (var i = 0; i < 4; i++) {
        await runStageSkillDropHookAfterVictory(
          stage: stage,
          svc: svc,
          clearedStageIds: const {},
          towerFragmentDropProb: 1.0,
          rng: Random(i),
        );
      }
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 1.0,
        rng: Random(99),
      );
      expect(r.fragmentJustUnlocked, true);
      expect(r.isMajor, true);
    });

    test('both manual (first-clear) AND fragment drop → merge both fields',
        () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      // 关卡同时挂了 manualId 和 fragmentId
      final stage = bossStage(manual: 'skill_m', fragment: 'skill_f');
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {}, // 首通
        towerFragmentDropProb: 1.0, // 必掉残页
        rng: Random(0),
      );
      expect(r.manualGranted, 'skill_m');
      expect(r.fragmentSkillId, 'skill_f');
      expect(r.isMajor, true); // manualGranted != null → major
    });

    test('no dropSkillManualId/fragmentId → SkillDropResult.none', () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final stage = bossStage(manual: null, fragment: null);
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 1.0,
        rng: Random(0),
      );
      expect(r.manualGranted, null);
      expect(r.fragmentSkillId, null);
    });

    test(
        'fragment prob=1.0 on already-unlocked skill → hook returns SkillDropResult.none',
        () async {
      // 验证 M1 修复：已解锁的招,hook 调 addFragment 后不应产出 isMinorFragment=true
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      // 先真解解锁技能
      await svc.grantManual('skill_frag_unlocked');
      final stage = bossStage(fragment: 'skill_frag_unlocked');
      final r = await runStageSkillDropHookAfterVictory(
        stage: stage,
        svc: svc,
        clearedStageIds: const {},
        towerFragmentDropProb: 1.0, // 必走 addFragment
        rng: Random(0),
      );
      // 已解锁短路 → none，不得出现 isMinorFragment=true 的误报
      expect(r, SkillDropResult.none);
      expect(r.fragmentSkillId, null);
      expect(r.isMinorFragment, false);
      expect(r.isMajor, false);
    });
  });

  // ── tower hook → SkillDropResult ─────────────────────────────────────────
  group('tower hook → SkillDropResult', () {
    TowerFloorDef bossFloor({String? fragment}) => TowerFloorDef(
          floorIndex: 10,
          requiredRealm: RealmTier.sanLiu,
          enemyTeam: const [],
          bossKind: TowerBossKind.major,
          dropSkillFragmentId: fragment,
        );

    test('prob=1.0 → fragmentSkillId set', () async {
      final svc =
          SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
      final floor = bossFloor(fragment: 'skill_tower_frag');
      final r = await runTowerSkillDropHookAfterVictory(
        floor: floor,
        svc: svc,
        towerFragmentDropProb: 1.0,
        rng: Random(0),
      );
      expect(r.fragmentSkillId, 'skill_tower_frag');
      expect(r.fragmentCount, 1);
    });

    test('prob=0.0 → SkillDropResult.none', () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final floor = bossFloor(fragment: 'skill_tower_frag2');
      final r = await runTowerSkillDropHookAfterVictory(
        floor: floor,
        svc: svc,
        towerFragmentDropProb: 0.0,
        rng: Random(0),
      );
      expect(r.fragmentSkillId, null);
    });

    test('null fragmentId floor → SkillDropResult.none', () async {
      final svc = SkillUnlockService(IsarSetup.instance);
      final floor = bossFloor(fragment: null);
      final r = await runTowerSkillDropHookAfterVictory(
        floor: floor,
        svc: svc,
        towerFragmentDropProb: 1.0,
        rng: Random(0),
      );
      expect(r.fragmentSkillId, null);
      expect(r.manualGranted, null);
    });
  });
}
