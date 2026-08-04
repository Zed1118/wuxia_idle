import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import "../../support/isar_test_support.dart";

/// P1 周目进化 Task A2：TowerProgress 周目字段 + advanceCycle 方法。
///
/// 验证「问鼎轮回」全塔周目规则：
///   - 全塔通关 → maxClearedCycle = currentCycleIndex
///   - advanceCycle → currentCycleIndex++ + highestClearedFloor 归零(从头爬)
///   - 未全通时 advanceCycle 是 no-op(防提前推进)
///
/// **本文件刻意用非 30 的层数**（[_towerMax]）：周目完成判定必须跟随
/// `recordClear` 的 `maxFloor` 入参，而非代码里写死的层数。若实现回退成
/// 硬编码 30，本文件断言全红——这是 A0「解层数硬编码」的永久守卫
/// （破坏证红的常驻化，见 spec 2026-08-01 §8 批 A）。
///
/// 本文件是 Isar-only 测（不加载 GameRepository），故直接传常量而非
/// 从 `towerMaxFloor` 派生——正好证明判定只依赖入参。
const _towerMax = 12;

void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_cycle_');
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

  // 纯静态函数，不碰 Isar：专钉 availableFloor / canChallenge 的上界确实
  // 来自 maxFloor 入参。`tower_progress_service_test` 那边跑在真 towers.yaml
  // （当前 30 层）上，实现若写死 30 与派生值恰好相等、抓不到回退；本组用
  // 非 30 的 [_towerMax] 才能证伪。
  group('availableFloor / canChallenge 上界跟随 maxFloor 入参', () {
    test('顶层已通 → availableFloor 封顶在 maxFloor', () {
      final p = TowerProgress()
        ..saveDataId = 1
        ..highestClearedFloor = _towerMax;
      expect(
        TowerProgressService.availableFloor(p, maxFloor: _towerMax),
        _towerMax,
        reason: '封顶值须是入参 maxFloor，写死 30 时会返回 ${_towerMax + 1}',
      );
    });

    test('未到顶层 → availableFloor = highest + 1', () {
      final p = TowerProgress()
        ..saveDataId = 1
        ..highestClearedFloor = _towerMax - 2;
      expect(
        TowerProgressService.availableFloor(p, maxFloor: _towerMax),
        _towerMax - 1,
      );
    });

    test('超出 maxFloor 的层号不可挑战', () {
      final p = TowerProgress()
        ..saveDataId = 1
        ..highestClearedFloor = _towerMax;
      expect(
        TowerProgressService.canChallenge(
          progress: p,
          floorIndex: _towerMax + 1,
          maxFloor: _towerMax,
        ),
        isFalse,
        reason: '上界须是入参 maxFloor，写死 30 时第 ${_towerMax + 1} 层会被放行',
      );
      expect(
        TowerProgressService.canChallenge(
          progress: p,
          floorIndex: _towerMax,
          maxFloor: _towerMax,
        ),
        isTrue,
        reason: '顶层本身可重打',
      );
    });
  });

  group('TowerProgress 周目字段默认值', () {
    test('新建行 → currentCycleIndex=1 / maxClearedCycle=0', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.currentCycleIndex, 1, reason: '初始从第 1 周目开始爬');
      expect(p.maxClearedCycle, 0, reason: '0 = 从未全塔通关');
    });
  });

  group('全塔通关 → maxClearedCycle 更新', () {
    test(
      '通关全塔 → maxClearedCycle=1；advanceCycle 后 currentCycleIndex=2 从头爬',
      () async {
        final svc = TowerProgressService(isar: IsarSetup.instance);
        await svc.getOrCreate(saveDataId: 1);
        final now = DateTime(2026, 6, 14);
        for (var f = 1; f <= _towerMax; f++) {
          await svc.recordClear(
            floorIndex: f,
            now: now,
            elapsedMs: 1000,
            maxFloor: _towerMax,
          );
        }
        var p = await svc.getOrCreate(saveDataId: 1);
        expect(p.maxClearedCycle, 1, reason: '全塔通关首次 → 当前周目(1)已完成');
        expect(
          p.currentCycleIndex,
          1,
          reason: 'advanceCycle 前 currentCycleIndex 不变',
        );

        await svc.advanceCycle(
          saveDataId: 1,
          maxCycleCap: 99,
        ); // 测试不限 cap，专注通关守卫
        p = await svc.getOrCreate(saveDataId: 1);
        expect(p.currentCycleIndex, 2, reason: '进入第 2 周目');
        expect(p.highestClearedFloor, 0, reason: '新周目从第 1 层重新爬');
      },
    );

    test('通到顶层前一层（未满全塔）→ maxClearedCycle 仍 0', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= _towerMax - 1; f++) {
        await svc.recordClear(
          floorIndex: f,
          now: now,
          elapsedMs: 1000,
          maxFloor: _towerMax,
        );
      }
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.maxClearedCycle, 0, reason: '未通到顶层，周目未完成');
    });

    test('超出顶层的层号不算首通（isFirstClear 上界跟随 maxFloor）', () async {
      // 这条专钉 recordClear 的 `floorIndex <= maxFloor` 上界。若实现回退成
      // 硬编码 30，本用例的第 _towerMax+1 层（13 <= 30 成立）会被误判成首通，
      // highestClearedFloor 越过塔顶且照常发奖 —— 扩层时最严重的静默失效形态。
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= _towerMax; f++) {
        await svc.recordClear(
          floorIndex: f,
          now: now,
          elapsedMs: 1000,
          maxFloor: _towerMax,
        );
      }
      final result = await svc.recordClear(
        floorIndex: _towerMax + 1,
        now: now,
        elapsedMs: 1000,
        maxFloor: _towerMax,
      );
      expect(
        result.isFirstClear,
        isFalse,
        reason: '第 ${_towerMax + 1} 层超出塔顶，不得算首通',
      );
      expect(
        result.highestAfter,
        _towerMax,
        reason: 'highestClearedFloor 不得越过塔顶',
      );
      final p = await svc.getOrCreate(saveDataId: 1);
      expect(p.highestClearedFloor, _towerMax);
    });
  });

  group('advanceCycle 守卫：未全通时 no-op', () {
    test(
      'maxClearedCycle=0（未通整塔）→ advanceCycle no-op，currentCycleIndex 不变',
      () async {
        final svc = TowerProgressService(isar: IsarSetup.instance);
        await svc.getOrCreate(saveDataId: 1);
        // 通 10 层但未满全塔
        final now = DateTime(2026, 6, 14);
        for (var f = 1; f <= 10; f++) {
          await svc.recordClear(
            floorIndex: f,
            now: now,
            elapsedMs: 1000,
            maxFloor: _towerMax,
          );
        }

        await svc.advanceCycle(saveDataId: 1, maxCycleCap: 99); // 测试通关守卫，不限 cap

        final p = await svc.getOrCreate(saveDataId: 1);
        expect(p.currentCycleIndex, 1, reason: '未全通不应推进周目');
        expect(p.highestClearedFloor, 10, reason: 'highestClearedFloor 不应被重置');
      },
    );
  });

  group('累计统计在 advanceCycle 后保留', () {
    test('totalAttempts/totalDefeats 跨周目累计，不被 advanceCycle 重置', () async {
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: 1);
      final now = DateTime(2026, 6, 14);
      for (var f = 1; f <= _towerMax; f++) {
        await svc.recordClear(
          floorIndex: f,
          now: now,
          elapsedMs: 1000,
          maxFloor: _towerMax,
        );
      }
      final beforeAdvance = await svc.getOrCreate(saveDataId: 1);
      final attemptsBeforeAdvance = beforeAdvance.totalAttempts;

      await svc.advanceCycle(saveDataId: 1, maxCycleCap: 99); // 测试累计统计，不限 cap

      final p = await svc.getOrCreate(saveDataId: 1);
      expect(
        p.totalAttempts,
        attemptsBeforeAdvance,
        reason: 'advanceCycle 本身不改变 totalAttempts 累计值',
      );
    });
  });
}
