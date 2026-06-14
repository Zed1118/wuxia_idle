import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

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
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.saveDataId, 1);
      expect(p.highestClearedFloor, 0);
      expect(p.highestClearedAt, isNull);
      expect(p.totalAttempts, 0);
      expect(p.totalDefeats, 0);
      expect(p.createdAt, isNotNull);
      expect(p.id, isNot(Isar.autoIncrement),
          reason: 'put 后应分配真实 id');
    });

    test('P0.2 #40 Phase 1 新加 3 字段默认值', () async {
      // 约束语义:新存档 3 字段默认值符合 schema 设计,排行榜 UI 空态可读
      // (memory feedback_red_line_test_semantics 实践:测约束不测瞬时具体值)
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.perFloorClearTimes, isEmpty,
          reason: 'List<int> 默认空,recordClear 时按 floorIndex 写入');
      expect(p.bestClearTime, isNull,
          reason: 'null 语义 = 无通关数据,UI 显「—」');
      expect(p.lastClearedAt, isNull,
          reason: 'null 语义 = 无任何通关,UI 不显最近活跃时间');
    });

    test('二次调用同 saveDataId → 复用同一行（不重复建）', () async {
      final p1 = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final p2 = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
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
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
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
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 10; i++) {
        await TowerProgressService(isar: IsarSetup.instance).recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11, i),
        elapsedMs: 1000,
        );
      }
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
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
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 30; i++) {
        await TowerProgressService(isar: IsarSetup.instance).recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
        );
      }
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 30);
      expect(TowerProgressService.availableFloor(p), 30);
    });
  });

  group('recordClear', () {
    test('首通下一层 → isFirstClear=true + highest++ + highestClearedAt 更新',
        () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final t = DateTime(2026, 5, 11, 14, 30);
      final result = await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: t,
        elapsedMs: 1000,
      );
      expect(result.isFirstClear, isTrue);
      expect(result.highestAfter, 1);

      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1);
      expect(p.highestClearedAt, t);
      expect(p.totalAttempts, 1);
    });

    test('重打已通层 → isFirstClear=false + highest 不变 + totalAttempts++', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
      );
      final firstAt = DateTime(2026, 5, 11);
      // 重打 1 层
      final result = await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 12),
        elapsedMs: 1000,
      );
      expect(result.isFirstClear, isFalse);
      expect(result.highestAfter, 1);

      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1);
      expect(p.highestClearedAt, firstAt,
          reason: '重打不更新 highestClearedAt');
      expect(p.totalAttempts, 2);
    });

    test('跳层挑战（floorIndex 非 highest+1）→ service 不抛但 isFirstClear=false',
        () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      // highest=0，尝试跳到 5 层（违反 canChallenge）
      final result = await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 5,
        now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
      );
      expect(result.isFirstClear, isFalse);
      expect(result.highestAfter, 0);

      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 0);
      expect(p.totalAttempts, 1, reason: 'totalAttempts 仍 ++');
    });

    test('未先 getOrCreate 直接 recordClear → StateError', () async {
      expect(
        () => TowerProgressService(isar: IsarSetup.instance).recordClear(
          floorIndex: 1,
          now: DateTime(2026, 5, 11),
          elapsedMs: 1000,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('TowerProgress 未初始化'),
        )),
      );
    });

    // ─── P0.2 #40 Phase 2:elapsedMs 写入 / bestClearTime 派生 / lastClearedAt ───

    test('Phase 2:首通写 perFloorClearTimes[floorIndex-1] = elapsedMs', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
        elapsedMs: 5000,
      );
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 2,
        now: DateTime(2026, 5, 11),
        elapsedMs: 8000,
      );
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.perFloorClearTimes.length, 2,
          reason: '每层首通 push 一项,index = floorIndex - 1');
      expect(p.perFloorClearTimes[0], 5000);
      expect(p.perFloorClearTimes[1], 8000);
    });

    test('Phase 2:重打不覆盖 perFloorClearTimes(GDD §5.1 反主流防刷)', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
        elapsedMs: 5000,
      );
      // 重打 1 层用更快耗时 → 不覆盖首通(玩家强化后刷数据被防住)
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 12),
        elapsedMs: 2000,
      );
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.perFloorClearTimes, [5000],
          reason: '重打 elapsedMs 2000 不覆盖首通 5000');
      expect(p.bestClearTime, 5000,
          reason: 'bestClearTime 派生自首通,不受重打影响');
    });

    test('Phase 2:bestClearTime 派生 = min over 非 0 值', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      // 顺序通 3 层,耗时各不同
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1, now: DateTime(2026, 5, 11), elapsedMs: 7000,
      );
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 2, now: DateTime(2026, 5, 11), elapsedMs: 3000, // 最快
      );
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 3, now: DateTime(2026, 5, 11), elapsedMs: 9000,
      );
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.bestClearTime, 3000,
          reason: 'min over [7000, 3000, 9000] = 3000');
    });

    test('Phase 2:lastClearedAt 任何通关(首通/重打/跳层)都更新', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final t1 = DateTime(2026, 5, 11, 14, 0);
      final t2 = DateTime(2026, 5, 11, 15, 0);
      final t3 = DateTime(2026, 5, 11, 16, 0);

      // 首通 1 层
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1, now: t1, elapsedMs: 5000,
      );
      var p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.lastClearedAt, t1, reason: '首通更新 lastClearedAt');

      // 重打 1 层
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1, now: t2, elapsedMs: 4000,
      );
      p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.lastClearedAt, t2, reason: '重打也更新 lastClearedAt(与 highestClearedAt 区分)');

      // 跳层挑战(违反 canChallenge)— lastClearedAt 也更新(任何 recordClear 调用都更)
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 10, now: t3, elapsedMs: 6000,
      );
      p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.lastClearedAt, t3,
          reason: '跳层也更新 lastClearedAt(highest 不变但 totalAttempts++)');
      expect(p.highestClearedFloor, 1, reason: '跳层不解锁 highest');
      expect(p.perFloorClearTimes, [5000],
          reason: '跳层不写 perFloorClearTimes(对齐 highest 不变)');
    });
  });

  group('recordDefeat', () {
    test('战败 → totalAttempts++ + totalDefeats++ + highest 不变', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
      );
      // 挑战 2 层失败
      await TowerProgressService(isar: IsarSetup.instance).recordDefeat(now: DateTime(2026, 5, 12));
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, 1, reason: '不退层');
      expect(p.totalAttempts, 2);
      expect(p.totalDefeats, 1);
    });

    test('多次战败累加', () async {
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordDefeat(now: DateTime(2026, 5, 11));
      await TowerProgressService(isar: IsarSetup.instance).recordDefeat(now: DateTime(2026, 5, 12));
      await TowerProgressService(isar: IsarSetup.instance).recordDefeat(now: DateTime(2026, 5, 13));
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      expect(p.totalAttempts, 3);
      expect(p.totalDefeats, 3);
      expect(p.highestClearedFloor, 0);
    });
  });

  group('floorList', () {
    test('全新进度 → floor 1 available，2-30 全 locked', () async {
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
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
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 5; i++) {
        await TowerProgressService(isar: IsarSetup.instance).recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
        );
      }
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
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
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 30; i++) {
        await TowerProgressService(isar: IsarSetup.instance).recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
        );
      }
      final p = await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      final floors = GameRepository.instance.towerFloors;
      final entries = TowerProgressService.floorList(
        progress: p,
        allFloors: floors,
      );
      expect(entries.every((e) => e.status == TowerFloorStatus.cleared),
          isTrue);
    });
  });

  group('advanceCycle', () {
    test('当前周目 30 层未全通 → advanceCycle no-op（maxClearedCycle < currentCycleIndex）',
        () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 默认 currentCycleIndex=1, maxClearedCycle=0 → 守卫触发 no-op
      await svc.advanceCycle(saveDataId: 1, maxCycleCap: 99);
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 1,
          reason: '未 30 层全通时 advanceCycle 应 no-op');
    });

    test('30 层全通后 advanceCycle → currentCycleIndex++ + highestClearedFloor=0',
        () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      for (var i = 1; i <= 30; i++) {
        await svc.recordClear(
          floorIndex: i,
          now: DateTime(2026, 5, 11),
          elapsedMs: 1000,
        );
      }
      await svc.advanceCycle(saveDataId: 1, maxCycleCap: 99); // cap 不限，专注通关守卫
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 2,
          reason: '30 层全通后 advanceCycle 应 currentCycleIndex=2');
      expect(p.highestClearedFloor, 0,
          reason: '新周目 highestClearedFloor 重置为 0');
    });

    test('advanceCycle：currentCycleIndex >= maxCycleCap 时 no-op（config cap 防越线）',
        () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      // 从 GameRepository 读取真实配置值（maxCycleTower=2，service 端 cap 守卫语义锁）
      final maxCycleTower =
          GameRepository.instance.numbers.cycleEvolution.maxCycleTower;
      // 直接在 Isar 里把 progress 设到 maxCycleTower（=2）且 maxClearedCycle>=current
      // 模拟玩家已在最高周目且已全通塔
      await IsarSetup.instance.writeTxn(() async {
        final progress = await IsarSetup.instance.towerProgress
            .filter()
            .saveDataIdEqualTo(1)
            .findFirst();
        if (progress == null) return;
        progress.currentCycleIndex = maxCycleTower;
        progress.maxClearedCycle = maxCycleTower; // 本周目已全通
        await IsarSetup.instance.towerProgress.put(progress);
      });

      // advanceCycle 应 no-op（不能超 config cap）
      await svc.advanceCycle(saveDataId: 1, maxCycleCap: maxCycleTower);
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, maxCycleTower,
          reason: 'currentCycleIndex 已达 maxCycleCap=$maxCycleTower，'
              'advanceCycle 应 no-op（service 端 config cap 守卫生效）');
    });
  });

  group('与 MainlineProgressService 独立', () {
    test('TowerProgress 状态不影响 MainlineProgress（独立 collection）', () async {
      // 仅初始化 TowerProgress；MainlineProgress collection 应保持空
      await TowerProgressService(isar: IsarSetup.instance).getOrCreate(saveDataId: 1);
      await TowerProgressService(isar: IsarSetup.instance).recordClear(
        floorIndex: 1,
        now: DateTime(2026, 5, 11),
        elapsedMs: 1000,
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
