import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// Phase 3 T34 · MainlineProgressService 真 Isar 落地测试。
///
/// 沿用 phase2_seed_service_test 的 setUp：临时目录 + IsarSetup.init +
/// GameRepository.loadAllDefs（从文件系统加载）。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_mainline_test_');
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

  group('getOrCreate', () {
    test('首次调用 → 建一行 + 默认 currentChapterIndex=1 + 空 cleared 列表',
        () async {
      final p = await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.saveDataId, 1);
      expect(p.currentChapterIndex, 1);
      expect(p.clearedStageIds, isEmpty);
      expect(p.clearedAt, isEmpty);
      expect(p.id, isNot(Isar.autoIncrement),
          reason: 'put 后应分配真实 id');
    });

    test('二次调用同 saveDataId → 复用同一行（id 不变 + 字段一致）', () async {
      final p1 = await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final p2 = await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p2.id, p1.id);
      expect(
        await IsarSetup.instance.mainlineProgress.count(),
        1,
        reason: '不重复建行',
      );
    });
  });

  group('availableStages', () {
    test('Ch1 全新进度 → 首关 available + 后续全 locked', () async {
      final p = await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final entries = MainlineProgressService.availableStages(
        progress: p,
        chapterIndex: 1,
      );
      expect(entries.length, 5, reason: 'Phase 3 Week 5 扩到每章 5 关');
      expect(entries[0].def.id, 'stage_01_01');
      expect(entries[0].status, StageStatus.available);
      expect(entries[1].def.id, 'stage_01_02');
      expect(entries[1].status, StageStatus.locked);
      for (var i = 2; i < entries.length; i++) {
        expect(entries[i].status, StageStatus.locked);
      }
    });

    test('Ch1 首关已通 → 01 cleared + 02 available', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: DateTime(2026, 5, 11),
      );
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final entries = MainlineProgressService.availableStages(
        progress: p,
        chapterIndex: 1,
      );
      expect(entries[0].status, StageStatus.cleared);
      expect(entries[1].status, StageStatus.available);
    });

    test('Ch1 全通（5 关）→ 全部 cleared', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 5; i++) {
        await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
          stageId: 'stage_01_0$i',
          now: DateTime(2026, 5, 10 + i),
        );
      }
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final entries = MainlineProgressService.availableStages(
        progress: p,
        chapterIndex: 1,
      );
      expect(entries.length, 5);
      expect(entries.every((e) => e.status == StageStatus.cleared), isTrue);
    });

    test('Ch2 / Ch3 各自独立解锁链（不会串到 Ch1 的 cleared 集）', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: DateTime(2026, 5, 11),
      );
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);

      // Ch2 首关仍 available（与 Ch1 无关）
      final ch2 = MainlineProgressService.availableStages(
        progress: p,
        chapterIndex: 2,
      );
      expect(ch2[0].def.id, 'stage_02_01');
      expect(ch2[0].status, StageStatus.available);
      expect(ch2[1].status, StageStatus.locked);

      // Ch3 同理
      final ch3 = MainlineProgressService.availableStages(
        progress: p,
        chapterIndex: 3,
      );
      expect(ch3[0].def.id, 'stage_03_01');
      expect(ch3[0].status, StageStatus.available);
    });
  });

  group('recordVictory', () {
    test('首通 → append clearedStageIds + clearedAt 同序', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final t = DateTime(2026, 5, 11, 14, 30);
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: t,
      );
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.clearedStageIds, ['stage_01_01']);
      expect(p.clearedAt, [t]);
    });

    test('重复通关同一 stage → 不重复 append（保留首通时间）', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final t1 = DateTime(2026, 5, 11);
      final t2 = DateTime(2026, 5, 12);
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: t1,
      );
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: t2,
      );
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.clearedStageIds.length, 1);
      expect(p.clearedAt, [t1], reason: '保留首通时间');
    });

    test('未先 getOrCreate 直接 recordVictory → StateError', () async {
      expect(
        () => MainlineProgressService(isar: IsarSetup.instance).recordVictory(
          stageId: 'stage_01_01',
          now: DateTime(2026, 5, 11),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('MainlineProgress 未初始化'),
        )),
      );
    });
  });

  group('chapterCompleted', () {
    test('Ch1 全通（5 关）→ true', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 5; i++) {
        await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
          stageId: 'stage_01_0$i',
          now: DateTime(2026, 5, 10 + i),
        );
      }
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(
        MainlineProgressService.chapterCompleted(
          progress: p,
          chapterIndex: 1,
        ),
        isTrue,
      );
    });

    test('Ch1 仅通首关 → false', () async {
      await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await MainlineProgressService(isar: IsarSetup.instance).recordVictory(
        stageId: 'stage_01_01',
        now: DateTime(2026, 5, 11),
      );
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(
        MainlineProgressService.chapterCompleted(
          progress: p,
          chapterIndex: 1,
        ),
        isFalse,
      );
    });

    test('全新进度 → 任意章节 false', () async {
      final p =
          await MainlineProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(
        MainlineProgressService.chapterCompleted(
          progress: p,
          chapterIndex: 1,
        ),
        isFalse,
      );
      expect(
        MainlineProgressService.chapterCompleted(
          progress: p,
          chapterIndex: 3,
        ),
        isFalse,
      );
    });
  });
}
