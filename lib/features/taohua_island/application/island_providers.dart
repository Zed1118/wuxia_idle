import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/inventory_item.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../domain/island_building_state.dart';
import '../domain/island_building_type.dart';
import 'island_settle_service.dart';

/// 进屏 settle 后的桃花岛视图契约（供 Task 11 主屏 watch）。
///
/// 字段均为快照值；config（不可变）由 UI 直接读
/// `GameRepository.instance.numbers.taohuaIsland`，不放入此 view。
class IslandView {
  /// 各建筑状态（已 settle 至 now）。
  final List<IslandBuildingState> buildings;

  /// 祖师境界 index（0=学徒…6=武圣），供升级/配方境界门槛判断。
  final int founderRealmIndex;

  /// 当前银两数量（item_silver inventory quantity）。
  final int silver;

  /// `defId → 当前数量`，仅含各建筑 upgradeMaterialItem 的库存，
  /// 供升级可负担判断。
  final Map<String, int> materials;

  const IslandView({
    required this.buildings,
    required this.founderRealmIndex,
    required this.silver,
    required this.materials,
  });
}

/// 桃花岛进屏 settle gate provider。
///
/// plain [FutureProvider.autoDispose]（无 @riverpod codegen，免 build_runner）。
///
/// 行为：
/// - Isar 未初始化 / 无存档 → 返回 null（进屏前 guard 判断）。
/// - 有存档：[IslandSettleService.ensureInitialized] + [IslandSettleService.settle]
///   → 读 silver / materials → 组装 [IslandView] 返回。
/// - settle 使用真实 [DateTime.now()]（与 §5.5 离线=在线语义一致；进屏 settle 不加速）。
///
/// Task 11 主屏调用：`ref.watch(taohuaIslandViewProvider)`；
/// 操作（升级/配方切换）完成后：`ref.invalidate(taohuaIslandViewProvider)`。
final taohuaIslandViewProvider =
    FutureProvider.autoDispose<IslandView?>((ref) async {
  // Isar 未初始化时 instanceOrNull == null → 返回 null
  if (IsarSetup.instanceOrNull == null) return null;

  final save = await IsarSetup.currentSaveData();
  if (save == null) return null;

  final now = DateTime.now();

  // 进屏首次：首开初始化（幂等；已初始化则 no-op）
  await IslandSettleService.ensureInitialized(save, now);

  // ensureInitialized 可能写了新建筑状态，重取最新 save 再 settle
  final freshSave = await IsarSetup.currentSaveData();
  if (freshSave == null) return null;

  await IslandSettleService.settle(freshSave, now);

  // settle 完成后取最终状态
  final settledSave = await IsarSetup.currentSaveData();
  if (settledSave == null) return null;

  // 取祖师境界 index（公开 helper，供 view 与后续 action 复用）
  final realmIdx = await IslandSettleService.founderRealmIndex(settledSave);

  // 取银两库存
  final isarInst = IsarSetup.instance;
  final silverItem =
      await isarInst.inventoryItems.getByDefId('item_silver');
  final silverQty = silverItem?.quantity ?? 0;

  // 收集各建筑升级材料 defId（去重后批量查）
  final cfg = GameRepository.instance.numbers.taohuaIsland;
  final materialDefIds = BuildingType.values
      .map((t) => cfg.buildings[t]?.upgradeMaterialItem)
      .whereType<String>()
      .toSet();

  final materials = <String, int>{};
  for (final defId in materialDefIds) {
    final item = await isarInst.inventoryItems.getByDefId(defId);
    materials[defId] = item?.quantity ?? 0;
  }

  return IslandView(
    buildings: settledSave.islandBuildings,
    founderRealmIndex: realmIdx,
    silver: silverQty,
    materials: materials,
  );
});
