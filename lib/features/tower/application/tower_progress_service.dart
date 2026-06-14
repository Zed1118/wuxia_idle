import 'package:isar_community/isar.dart';

import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../domain/tower_floor_def.dart';
import '../domain/tower_progress.dart';

/// 单层 + 解锁状态（[TowerProgressService.floorList] 返回值）。
typedef TowerFloorEntry = ({TowerFloorDef def, TowerFloorStatus status});

/// recordClear 返回结果：[isFirstClear] 决定 UI 是否发奖（重打不发奖）。
typedef TowerClearResult = ({bool isFirstClear, int highestAfter});

/// 爬塔进度服务（Phase 3 T41）。
///
/// 与 [MainlineProgressService] 完全独立（不互相 import）：爬塔进度演化与
/// 主线解锁逻辑解耦，schema 演化也独立。
///
/// 关键不变量：
///   - [TowerProgress.highestClearedFloor] 单调递增（recordClear 仅在
///     `floorIndex == highest + 1` 时 ++）
///   - 跳层挑战由 UI 端 [canChallenge] 拦截；service 端 recordClear 收到
///     非法 floorIndex 时**不抛**，只是 `isFirstClear=false`，避免战斗
///     已结束才报错破坏 UX。totalAttempts++ 永远执行。
///   - recordDefeat 不影响 highestClearedFloor，只增统计。
class TowerProgressService {
  const TowerProgressService({required this.isar});

  final Isar isar;

  /// 拿不到对应 saveDataId 的行就建一行（默认 highestClearedFloor=0）。
  Future<TowerProgress> getOrCreate({
    required int saveDataId,
  }) async {
    final existing = await isar.towerProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (existing != null) return existing;

    final now = DateTime.now();
    final fresh = TowerProgress()
      ..saveDataId = saveDataId
      ..highestClearedFloor = 0
      ..highestClearedAt = null
      ..totalAttempts = 0
      ..totalDefeats = 0
      ..createdAt = now;
    await isar.writeTxn(() => isar.towerProgress.put(fresh));
    return fresh;
  }

  /// 当前可挑战的最高层号；30 已通则返回 30（封顶，UI 显示"已通关"）。
  static int availableFloor(TowerProgress progress) {
    if (progress.highestClearedFloor >= 30) return 30;
    return progress.highestClearedFloor + 1;
  }

  /// 是否可以挑战指定层（UI 端在 onTap 前拦截非法跳层）。
  ///
  /// 规则：`floorIndex ∈ [1, highestClearedFloor + 1]`，即可重打 + 下一关。
  static bool canChallenge({
    required TowerProgress progress,
    required int floorIndex,
  }) {
    if (floorIndex < 1 || floorIndex > 30) return false;
    return floorIndex <= progress.highestClearedFloor + 1;
  }

  /// 全 30 层 + 状态（cleared / available / locked），按 floorIndex 升序。
  ///
  /// [allFloors] 由调用方传入（通常是 `GameRepository.instance.towerFloors`）；
  /// 注入式参数便于测试/未来 fixture 替换。
  static List<TowerFloorEntry> floorList({
    required TowerProgress progress,
    required List<TowerFloorDef> allFloors,
  }) {
    final highest = progress.highestClearedFloor;
    return allFloors
        .map((f) => (
              def: f,
              status: f.floorIndex <= highest
                  ? TowerFloorStatus.cleared
                  : f.floorIndex == highest + 1
                      ? TowerFloorStatus.available
                      : TowerFloorStatus.locked,
            ))
        .toList(growable: false);
  }

  /// 通关一层。返回 [TowerClearResult]：
  ///   - `isFirstClear == true` 当且仅当 `floorIndex == highest + 1`，
  ///     此时 highest++ + highestClearedAt 更新；
  ///   - 否则（重打 / 跳层 / 越界）`isFirstClear == false`，highest 不变。
  ///   - 无论是否首通，`totalAttempts++` 永远执行。
  ///
  /// P0.2 #40 Phase 2 扩展:
  ///   - [elapsedMs] 本次通关耗时(从战斗 setup 完成到 onVictory 回调触发);
  ///   - 首通时写 perFloorClearTimes[floorIndex - 1] = elapsedMs(重打不覆盖);
  ///   - 重算 bestClearTime = min(perFloorClearTimes 中非 0 值);
  ///   - 任何通关(首通/重打)都更新 lastClearedAt;
  ///   - 跳层/越界时 perFloorClearTimes / bestClearTime 不动(对齐 highest 不变)。
  ///
  /// 调用方应根据 `isFirstClear` 决定是否走 [DropService.rollTowerRewards]
  /// 发奖（[CLAUDE.md §5.1] 反主流：重打不发奖防刷）。
  Future<TowerClearResult> recordClear({
    required int floorIndex,
    required DateTime now,
    required int elapsedMs,
  }) async {
    late TowerClearResult result;
    await isar.writeTxn(() async {
      final progress = await isar.towerProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'TowerProgress 未初始化：getOrCreate 未在 recordClear 前调用',
        );
      }
      progress.totalAttempts += 1;
      final isFirstClear = floorIndex == progress.highestClearedFloor + 1 &&
          floorIndex >= 1 &&
          floorIndex <= 30;
      if (isFirstClear) {
        progress.highestClearedFloor = floorIndex;
        progress.highestClearedAt = now;

        // P0.2 #40 Phase 2:首通锁耗时,重打不覆盖
        // List<int> @embedded findFirst 反序列化为 fixed-length,
        // 必须 List.from 转 growable 再写(memory feedback_isar_pitfalls §2)
        final times = List<int>.from(progress.perFloorClearTimes);
        while (times.length < floorIndex - 1) {
          times.add(0); // 跳层占位(canChallenge 已拦,理论不可达,守 invariant)
        }
        if (times.length == floorIndex - 1) {
          times.add(elapsedMs);
        } else if (times[floorIndex - 1] == 0) {
          times[floorIndex - 1] = elapsedMs; // 历史空位补首通
        }
        progress.perFloorClearTimes = times;

        // 重算 bestClearTime 派生(min over 非 0 值)
        final nonZero = times.where((t) => t > 0);
        progress.bestClearTime = nonZero.isEmpty
            ? null
            : nonZero.reduce((a, b) => a < b ? a : b);

        // P1 A2 问鼎轮回：30 层首通 → 标记当前周目已完成
        // 单调递增（max 防回退），不降级
        if (floorIndex == 30) {
          final completed = progress.currentCycleIndex;
          if (completed > progress.maxClearedCycle) {
            progress.maxClearedCycle = completed;
          }
        }
      }

      // P0.2 #40 Phase 2:任何通关(首通/重打/跳层)都更新 lastClearedAt
      progress.lastClearedAt = now;

      await isar.towerProgress.put(progress);
      result = (
        isFirstClear: isFirstClear,
        highestAfter: progress.highestClearedFloor,
      );
    });
    return result;
  }

  /// 战败：只增 totalAttempts + totalDefeats，不影响 highestClearedFloor。
  Future<void> recordDefeat({
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      final progress = await isar.towerProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'TowerProgress 未初始化：getOrCreate 未在 recordDefeat 前调用',
        );
      }
      progress.totalAttempts += 1;
      progress.totalDefeats += 1;
      await isar.towerProgress.put(progress);
    });
  }

  /// 推进到下一周目（问鼎轮回）。
  ///
  /// 守卫：仅当 `maxClearedCycle >= currentCycleIndex`（本周目 30 层已全通）
  /// 时才执行，否则 no-op，防止未通整塔提前推进。
  ///
  /// [maxCycleCap]：周目进化配置上限（来自 `numbers.yaml cycle_evolution.max_cycle_tower`）。
  /// 生产路径由调用方从 `GameRepository.instance.numbers.cycleEvolution.maxCycleTower`
  /// 传入；测试路径可直接传固定值，无需 GameRepository 已初始化（Isar-only 测试友好）。
  ///
  /// 执行后：
  ///   - `currentCycleIndex++`（进入下一周目）
  ///   - `highestClearedFloor = 0`（新周目从第 1 层重新开始爬）
  ///
  /// 保持累计：
  ///   - `totalAttempts` / `totalDefeats` 跨周目持续累加，不重置
  ///   - `perFloorClearTimes` 保留（首通耗时按 GDD §5.1 反主流锁首通，新周目
  ///     首通同层会按原逻辑写入，即 index 已有非 0 值时不覆盖；P1 A3+ 若需
  ///     按周目区分耗时可再扩展字段，目前 YAGNI）
  Future<void> advanceCycle({
    int saveDataId = 1,
    required int maxCycleCap,
  }) async {
    await isar.writeTxn(() async {
      final progress = await isar.towerProgress
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .findFirst();
      if (progress == null) return; // 未初始化 → no-op

      // 守卫：当前周目 30 层未全通，不推进
      if (progress.maxClearedCycle < progress.currentCycleIndex) return;

      // 守卫：已达配置上限，不推进（UI 已拦，service 端镜像 config cap）
      if (progress.currentCycleIndex >= maxCycleCap) return;

      progress.currentCycleIndex += 1;
      progress.highestClearedFloor = 0;
      await isar.towerProgress.put(progress);
    });
  }
}
