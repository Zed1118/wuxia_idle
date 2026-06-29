import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

/// P0-5(2026-06-29 审查修复):_migrateSaveData 段1(0.18.0 encounter unlock 池
/// 并入)与段3(0.22.0 章周目 key 重建)补版本门——不再每次升级重跑、不再依赖
/// 段3 的隐式启动顺序契约(GameRepository.isLoaded)。两段本幂等,版本门是防御
/// 加固:已过对应版本的存档不再进入该段。
void main() {
  group('P0-5 迁移版本门(Isar + GameRepository)', () {
    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
      }
    });

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_mig_gate_');
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

    // --- 段 3(0.22.0)版本门 ---

    test('0.22+ 存档不重跑段3:isLoaded 也不重建 chapter cycle key', () async {
      final repo = GameRepository.instance;
      final ch1Boss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType.name == 'mainline' &&
          s.chapterIndex == 1 &&
          s.isBossStage);
      final svc = MainlineProgressService(isar: IsarSetup.instance);
      final mp = await svc.getOrCreate(saveDataId: 1);
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.saveVersion = '0.22.0'; // == 0.22.0 → 段3 门 <0.22.0 为 false
        mp.clearedStageCycleKeys = ['${ch1Boss.id}#1', '${ch1Boss.id}#2'];
        mp.clearedChapterCycleKeys = [];
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.mainlineProgress.put(mp);
      });

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);

      final mp2 =
          await MainlineProgressService(isar: IsarSetup.instance)
              .getOrCreate(saveDataId: 1);
      expect(mp2.clearedChapterCycleKeys, isEmpty,
          reason: '0.22+ 存档段3 被版本门跳过,不重建 chapter cycle key');
    });

    test('0.21 旧档仍迁段3:chapter cycle key 正常重建(门不过度跳过)', () async {
      final repo = GameRepository.instance;
      final ch1Boss = repo.stageDefs.values.firstWhere((s) =>
          s.stageType.name == 'mainline' &&
          s.chapterIndex == 1 &&
          s.isBossStage);
      final svc = MainlineProgressService(isar: IsarSetup.instance);
      final mp = await svc.getOrCreate(saveDataId: 1);
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.saveVersion = '0.21.0'; // < 0.22.0 → 段3 仍跑
        mp.clearedStageCycleKeys = ['${ch1Boss.id}#1', '${ch1Boss.id}#2'];
        mp.clearedChapterCycleKeys = [];
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.mainlineProgress.put(mp);
      });

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);

      final mp2 =
          await MainlineProgressService(isar: IsarSetup.instance)
              .getOrCreate(saveDataId: 1);
      expect(mp2.clearedChapterCycleKeys, contains('ch1#2'),
          reason: '0.21 旧档段3 仍执行,重建 ch1#2');
    });

    // --- 段 1(0.18.0)版本门 ---

    const probeSkillId = 'skill_p05_gate_probe';

    Future<void> seedEncounterUnlock(String saveVersion) async {
      await IsarSetup.instance.writeTxn(() async {
        final save = await IsarSetup.instance.saveDatas.get(0);
        save!.saveVersion = saveVersion;
        save.skillUnlockProgress = <SkillUnlockEntry>[]; // 不含 probe
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.encounterProgress.put(
          EncounterProgress()
            ..saveDataId = 1
            ..createdAt = DateTime(2026, 1, 1)
            ..unlockedSkillIds = [probeSkillId],
        );
      });
    }

    test('0.18+ 存档不重跑段1:encounter 旧 unlock 池不再并入', () async {
      await seedEncounterUnlock('0.18.0'); // == 0.18.0 → 段1 门 <0.18.0 为 false

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);

      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.skillUnlockProgress.isUnlocked(probeSkillId), isFalse,
          reason: '0.18+ 存档段1 被版本门跳过,不并入旧池');
    });

    test('0.17 旧档仍迁段1:encounter 旧 unlock 池并入(门不过度跳过)', () async {
      await seedEncounterUnlock('0.17.0'); // < 0.18.0 → 段1 仍跑

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);

      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.skillUnlockProgress.isUnlocked(probeSkillId), isTrue,
          reason: '0.17 旧档段1 仍执行,并入旧池');
    });
  });
}
