import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

/// A3 saveVersion 0.20.0 → 0.22.0 迁移测试。
///
/// 验证：
/// 1. MainlineProgress.clearedStageCycleKeys 补入 "stageId#1" 条目（来自旧 clearedStageIds）。
/// 2. TowerProgress.currentCycleIndex == 1（显式落档）。
/// 3. TowerProgress.maxClearedCycle == 1（highestClearedFloor >= 30）或 0（< 30）。
/// 4. SaveData.saveVersion 升为 '0.22.0'。
/// 5. 迁移幂等：再次 close/init 不重复 append。
void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_migration_021_');
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    '0.20.0 旧档迁移：clearedStageCycleKeys 补 cycle1 键 + TowerProgress 塔 30 层 → maxClearedCycle=1',
    () async {
      // 构造 0.20.0 旧档：init 得到一份新档，再降版为 0.20.0 并写入旧数据。
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        // 1) 把版本降回 0.20.0（模拟旧档）
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.saveVersion = '0.20.0';
        await IsarSetup.instance.saveDatas.put(save);

        // 2) 写入 MainlineProgress（旧档没有 clearedStageCycleKeys）
        final mp = MainlineProgress()
          ..saveDataId = 1
          ..clearedStageIds = ['stage_01_01', 'stage_01_02']
          ..clearedAt = [DateTime(2026, 1, 1), DateTime(2026, 1, 2)]
          ..clearedStageCycleKeys = []; // 旧档默认空
        await IsarSetup.instance.mainlineProgress.put(mp);

        // 3) 写入 TowerProgress（旧档没有 currentCycleIndex/maxClearedCycle）
        final tp = TowerProgress()
          ..saveDataId = 1
          ..highestClearedFloor = 30
          ..createdAt = DateTime(2026, 1, 1)
          ..currentCycleIndex = 1 // 旧档默认值（Isar 会用字段默认值）
          ..maxClearedCycle = 0; // 旧档未设置
        await IsarSetup.instance.towerProgress.put(tp);
      });
      await IsarSetup.close();

      // 重新 init → 触发 _migrateSaveData（旧 0.20.0 一路迁到当前 0.25.0）。
      await IsarSetup.init(directory: tempDir, inspector: false);

      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      expect(save.saveVersion, '0.26.0', reason: '迁移后升版到当前 0.26.0');

      final mp =
          await IsarSetup.instance.mainlineProgress.where().findFirst();
      expect(mp, isNotNull);
      expect(
        mp!.clearedStageCycleKeys,
        containsAll(['stage_01_01#1', 'stage_01_02#1']),
        reason: 'clearedStageIds 各条目应有对应 #1 周目键',
      );

      final tp = await IsarSetup.instance.towerProgress.where().findFirst();
      expect(tp, isNotNull);
      expect(tp!.currentCycleIndex, 1, reason: '迁移后 currentCycleIndex 显式为 1');
      expect(
        tp.maxClearedCycle,
        1,
        reason: 'highestClearedFloor=30 → maxClearedCycle=1',
      );

      // 幂等：再 close/init 一次，cycleKeys 不重复 append。
      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final mp2 =
          await IsarSetup.instance.mainlineProgress.where().findFirst();
      expect(
        mp2!.clearedStageCycleKeys
            .where((k) => k == 'stage_01_01#1')
            .length,
        1,
        reason: '幂等：stage_01_01#1 只出现一次',
      );
    },
  );

  test(
    '0.20.0 旧档迁移：TowerProgress highestClearedFloor=10 → maxClearedCycle=0',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.saveVersion = '0.20.0';
        await IsarSetup.instance.saveDatas.put(save);

        final tp = TowerProgress()
          ..saveDataId = 1
          ..highestClearedFloor = 10
          ..createdAt = DateTime(2026, 1, 1)
          ..currentCycleIndex = 1
          ..maxClearedCycle = 0;
        await IsarSetup.instance.towerProgress.put(tp);
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      final tp = await IsarSetup.instance.towerProgress.where().findFirst();
      expect(tp, isNotNull);
      expect(tp!.currentCycleIndex, 1);
      expect(
        tp.maxClearedCycle,
        0,
        reason: 'highestClearedFloor=10 < 30 → maxClearedCycle 保持 0',
      );

      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      expect(save.saveVersion, '0.26.0');
    },
  );

  test(
    'H1 回归：0.22.0 已推进周目存档迁移到 0.25.0，currentCycleIndex/maxClearedCycle 不被重置',
    () async {
      // 构造 0.22.0 存档（周目字段已引入），玩家已推进到周目 2。
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.saveVersion = '0.22.0';
        await IsarSetup.instance.saveDatas.put(save);

        // advanceCycle 进周目 2 后 highestClearedFloor 重置为 0，已打到 5 层。
        final tp = TowerProgress()
          ..saveDataId = 1
          ..highestClearedFloor = 5
          ..createdAt = DateTime(2026, 1, 1)
          ..currentCycleIndex = 2
          ..maxClearedCycle = 1; // 周目 1 已通关
        await IsarSetup.instance.towerProgress.put(tp);
      });
      await IsarSetup.close();

      // 迁移到 0.25.0：tower 块版本门应跳过 0.21+ 存档，不碰已有周目数据。
      await IsarSetup.init(directory: tempDir, inspector: false);
      final tp = await IsarSetup.instance.towerProgress.where().findFirst();
      expect(tp, isNotNull);
      expect(
        tp!.currentCycleIndex,
        2,
        reason: 'H1: 已推进的周目不得被迁移重置为 1（数据丢失）',
      );
      expect(
        tp.maxClearedCycle,
        1,
        reason: 'H1: 周目 1 通关成就不得被迁移清掉',
      );

      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      expect(save.saveVersion, '0.26.0');
    },
  );
}
