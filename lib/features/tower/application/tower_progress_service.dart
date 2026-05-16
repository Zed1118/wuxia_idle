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
  /// 调用方应根据 `isFirstClear` 决定是否走 [DropService.rollTowerRewards]
  /// 发奖（[CLAUDE.md §5.1] 反主流：重打不发奖防刷）。
  Future<TowerClearResult> recordClear({
    required int floorIndex,
    required DateTime now,
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
      }
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
}
