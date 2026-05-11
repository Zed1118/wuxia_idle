import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/mainline_progress.dart';
import 'package:wuxia_idle/data/models/tower_progress.dart';
import 'package:wuxia_idle/services/tower_progress_service.dart';

/// Phase 3 T41 · TowerProgressService 真 Isar 落地测试。
///
/// 沿用 mainline_progress_service_test 的 setUp：临时目录 + IsarSetup.init +
/// GameRepository.loadAllDefs（从文件系统加载 30 层 fixture）。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_test_');
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
    test('首次调用 → 建一行 + 默认 highest=0 + totalAttempts/Defeats=0', () async {
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.saveDataId, 1);
      expect(p.highestClearedFloor, 0);
      expect(p.highestClearedAt, isNull);
      expect(p.totalAttempts, 0);
      expect(p.totalDefeats, 0);
      expect(p.createdAt, isNotNull);
      expect(p.id, isNot(Isar.autoIncrement),
          reason: 'put 后应分配真实 id');
    });

    test('二次调用同 saveDataId → 复用同一行（不重复建）', () async {
      final p1 = await TowerProgressService.getOrCreate(saveDataId: 1);
      final p2 = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p2.id, p1.id);
      expect(
        await IsarSetup.instance.towerProgress.count(),
        1,
        reason: '不重复建行',
      );
    });
  });

  group('availableFloor / canChallenge', () {
    test('全新进度 → availableFloor=1，canChallenge(1) true / (2) false', () async {
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(TowerProgressService.availableFloor(p), 1);
      expect(
        TowerProgressService.canChallenge(progress: p, floorIndex: 1),
        isTrue,
      );
      expect(
        TowerProgressService.canChallenge(progress: p, floorIndex: 2),
        isFalse,
      );
      expect(
        TowerProgressService.canChallenge(progress: p, floorIndex: 0),
        isFalse,
      );
      expect(
        TowerProgressService.canChallenge(progress: p, floorIndex: 31),
        isFalse,
      );
    });

    test('通到 10 层 → availableFloor=11，canChallenge(1..11) 全 true / (12) false',
        () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 10; i++) {
        await TowerProgressService.recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11, i),
        );
      }
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(TowerProgressService.availableFloor(p), 11);
      for (var i = 1; i <= 11; i++) {
        expect(
          TowerProgressService.canChallenge(progress: p, floorIndex: i),
          isTrue,
          reason: 'floor $i 应可挑战（重打或下一关）',
        );
      }
      expect(
        TowerProgressService.canChallenge(progress: p, floorIndex: 12),
        isFalse,
      );
    });

    test('30 层全通 → availableFloor 封顶 30', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 30; i++) {
        await TowerProgressService.recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        );
      }
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 30);
      expect(TowerProgressService.availableFloor(p), 30);
    });
  });

  group('recordClear', () {
    test('首通下一层 → isFirstClear=true + highest++ + highestClearedAt 更新',
        () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      final t = DateTime(2026, 5, 11, 14, 30);
      final result = await TowerProgressService.recordClear(
        floorIndex: 1,
        now: t,
      );
      expect(result.isFirstClear, isTrue);
      expect(result.highestAfter, 1);

      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1);
      expect(p.highestClearedAt, t);
      expect(p.totalAttempts, 1);
    });

    test('重打已通层 → isFirstClear=false + highest 不变 + totalAttempts++', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      await TowerProgressService.recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
      );
      final firstAt = DateTime(2026, 5, 11);
      // 重打 1 层
      final result = await TowerProgressService.recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 12),
      );
      expect(result.isFirstClear, isFalse);
      expect(result.highestAfter, 1);

      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1);
      expect(p.highestClearedAt, firstAt,
          reason: '重打不更新 highestClearedAt');
      expect(p.totalAttempts, 2);
    });

    test('跳层挑战（floorIndex 非 highest+1）→ service 不抛但 isFirstClear=false',
        () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      // highest=0，尝试跳到 5 层（违反 canChallenge）
      final result = await TowerProgressService.recordClear(
        floorIndex: 5,
        now: DateTime(2026, 5, 11),
      );
      expect(result.isFirstClear, isFalse);
      expect(result.highestAfter, 0);

      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 0);
      expect(p.totalAttempts, 1, reason: 'totalAttempts 仍 ++');
    });

    test('未先 getOrCreate 直接 recordClear → StateError', () async {
      expect(
        () => TowerProgressService.recordClear(
          floorIndex: 1,
          now: DateTime(2026, 5, 11),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('TowerProgress 未初始化'),
        )),
      );
    });
  });

  group('recordDefeat', () {
    test('战败 → totalAttempts++ + totalDefeats++ + highest 不变', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      await TowerProgressService.recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
      );
      // 挑战 2 层失败
      await TowerProgressService.recordDefeat(now: DateTime(2026, 5, 12));
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1, reason: '不退层');
      expect(p.totalAttempts, 2);
      expect(p.totalDefeats, 1);
    });

    test('多次战败累加', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      await TowerProgressService.recordDefeat(now: DateTime(2026, 5, 11));
      await TowerProgressService.recordDefeat(now: DateTime(2026, 5, 12));
      await TowerProgressService.recordDefeat(now: DateTime(2026, 5, 13));
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      expect(p.totalAttempts, 3);
      expect(p.totalDefeats, 3);
      expect(p.highestClearedFloor, 0);
    });
  });

  group('floorList', () {
    test('全新进度 → floor 1 available，2-30 全 locked', () async {
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      final floors = GameRepository.instance.towerFloors;
      final entries = TowerProgressService.floorList(
        progress: p,
        allFloors: floors,
      );
      expect(entries.length, 30);
      expect(entries[0].def.floorIndex, 1);
      expect(entries[0].status, TowerFloorStatus.available);
      for (var i = 1; i < 30; i++) {
        expect(entries[i].status, TowerFloorStatus.locked,
            reason: 'floor ${i + 1} 应锁');
      }
    });

    test('通到 5 层 → 1-5 cleared、6 available、7-30 locked', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 5; i++) {
        await TowerProgressService.recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        );
      }
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      final floors = GameRepository.instance.towerFloors;
      final entries = TowerProgressService.floorList(
        progress: p,
        allFloors: floors,
      );
      for (var i = 0; i < 5; i++) {
        expect(entries[i].status, TowerFloorStatus.cleared,
            reason: 'floor ${i + 1} 应通');
      }
      expect(entries[5].status, TowerFloorStatus.available,
          reason: 'floor 6 应可挑战');
      for (var i = 6; i < 30; i++) {
        expect(entries[i].status, TowerFloorStatus.locked,
            reason: 'floor ${i + 1} 应锁');
      }
    });

    test('全 30 通 → 全 cleared（无 available）', () async {
      await TowerProgressService.getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 30; i++) {
        await TowerProgressService.recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        );
      }
      final p = await TowerProgressService.getOrCreate(saveDataId: 1);
      final floors = GameRepository.instance.towerFloors;
      final entries = TowerProgressService.floorList(
        progress: p,
        allFloors: floors,
      );
      expect(entries.every((e) => e.status == TowerFloorStatus.cleared),
          isTrue);
    });
  });

  group('与 MainlineProgressService 独立', () {
    test('TowerProgress 状态不影响 MainlineProgress（独立 collection）', () async {
      // 仅初始化 TowerProgress；MainlineProgress collection 应保持空
      await TowerProgressService.getOrCreate(saveDataId: 1);
      await TowerProgressService.recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
      );
      expect(
        await IsarSetup.instance.mainlineProgress.count(),
        0,
        reason: 'TowerProgressService 不应隐式创建 MainlineProgress',
      );
      expect(
        await IsarSetup.instance.towerProgress.count(),
        1,
      );
    });
  });
}
