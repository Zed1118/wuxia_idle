import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// 周目按章(2026-06-14)· 章级周目派生 + recordVictory 章末 Boss 记账。
///
/// 校验:
///   - highestClearedCycleForChapter / currentChallengeCycleForChapter 纯派生
///   - chapterKeyForStage:主线 ch{N} / 副本 stageType.name
///   - recordVictory:章末 Boss 关(isBoss)记 chapter cycle key;非 Boss 关不记
void main() {
  group('章级周目纯派生(无 Isar)', () {
    test('highestClearedCycleForChapter 取该章最大 cycle,未通返 0', () {
      final p = MainlineProgress()
        ..clearedChapterCycleKeys = ['ch1#1', 'ch1#2', 'ch2#1', 'innerDemon#1'];
      expect(MainlineProgressService.highestClearedCycleForChapter(p, 'ch1'), 2);
      expect(MainlineProgressService.highestClearedCycleForChapter(p, 'ch2'), 1);
      expect(
          MainlineProgressService.highestClearedCycleForChapter(p, 'ch3'), 0);
      expect(
          MainlineProgressService.highestClearedCycleForChapter(
              p, 'innerDemon'),
          1);
    });

    test('currentChallengeCycleForChapter = 最高+1,clamp maxCycle', () {
      final p = MainlineProgress()..clearedChapterCycleKeys = ['ch1#2'];
      expect(
        MainlineProgressService.currentChallengeCycleForChapter(p, 'ch1',
            maxCycle: 3),
        3,
      );
      expect(
        MainlineProgressService.currentChallengeCycleForChapter(p, 'ch1',
            maxCycle: 2),
        2, // next=3 clamp 到 2
      );
      expect(
        MainlineProgressService.currentChallengeCycleForChapter(p, 'ch9',
            maxCycle: 3),
        1, // 未通 → next=1
      );
    });
  });

  group('chapterKeyForStage + recordVictory 章末 Boss(Isar + GameRepository)',
      () {
    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (p) => File(p).readAsString(),
        );
      }
    });

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_chapter_cycle_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('chapterKeyForStage:主线 ch{N} / 副本 stageType.name', () {
      final repo = GameRepository.instance;
      final ch1Boss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType == StageType.mainline &&
          s.chapterIndex == 1 &&
          s.isBossStage);
      expect(MainlineProgressService.chapterKeyForStage(ch1Boss), 'ch1');

      final innerDemon = repo.stageDefs.values
          .firstWhere((s) => s.stageType == StageType.innerDemon);
      expect(MainlineProgressService.chapterKeyForStage(innerDemon),
          'innerDemon');
    });

    test('章末 Boss 关通关记 chapter cycle key,非 Boss 关不记', () async {
      final repo = GameRepository.instance;
      final svc = MainlineProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);

      final ch1Boss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType == StageType.mainline &&
          s.chapterIndex == 1 &&
          s.isBossStage);
      final ch1NonBoss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType == StageType.mainline &&
          s.chapterIndex == 1 &&
          !s.isBossStage);

      // 非 Boss 关通关 → 不记 chapter key
      await svc.recordVictory(stageId: ch1NonBoss.id, now: DateTime(2026, 6, 14));
      var p = await svc.getOrCreate(saveDataId: 1);
      expect(
        MainlineProgressService.highestClearedCycleForChapter(p, 'ch1'),
        0,
        reason: '非 Boss 关不解锁章周目',
      );

      // 章末 Boss 关通关 → 记 ch1#1
      await svc.recordVictory(stageId: ch1Boss.id, now: DateTime(2026, 6, 14));
      p = await svc.getOrCreate(saveDataId: 1);
      expect(p.clearedChapterCycleKeys, contains('ch1#1'));
      expect(
        MainlineProgressService.highestClearedCycleForChapter(p, 'ch1'),
        1,
      );

      // 二周目 Boss 通关 → ch1#2,解锁三周目挑战
      await svc.recordVictory(
          stageId: ch1Boss.id, now: DateTime(2026, 6, 15), cycle: 2);
      p = await svc.getOrCreate(saveDataId: 1);
      expect(
        MainlineProgressService.highestClearedCycleForChapter(p, 'ch1'),
        2,
      );
      expect(
        MainlineProgressService.currentChallengeCycleForChapter(p, 'ch1',
            maxCycle: 3),
        3,
      );
    });

    test('0.21→0.22 迁移:旧 Boss 关 stage cycle key → chapter cycle key', () async {
      final repo = GameRepository.instance;
      final ch1Boss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType == StageType.mainline &&
          s.chapterIndex == 1 &&
          s.isBossStage);

      // 构造 0.21 旧档:Boss 关有 per-stage cycle key,无 chapter cycle key。
      final svc = MainlineProgressService(isar: IsarSetup.instance);
      final mp = await svc.getOrCreate(saveDataId: 1);
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.saveVersion = '0.21.0';
        mp.clearedStageCycleKeys = ['${ch1Boss.id}#1', '${ch1Boss.id}#2'];
        mp.clearedChapterCycleKeys = [];
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.mainlineProgress.put(mp);
      });

      // 重 init → 触发 _migrateSaveData 段 3(0.22 章 key 转换)。
      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);

      final mp2 = await MainlineProgressService(isar: IsarSetup.instance)
          .getOrCreate(saveDataId: 1);
      expect(mp2.clearedChapterCycleKeys, contains('ch1#2'),
          reason: 'Boss 关二周目 → ch1#2');
      expect(
        MainlineProgressService.highestClearedCycleForChapter(mp2, 'ch1'),
        2,
      );
    });
  });
}
