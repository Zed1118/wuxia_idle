import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/enums.dart';

/// 道具使用后统一失效的 provider 集合。
///
/// 使用经验丹/秘籍/疗伤物品会扣对应背包数量；部分道具还会改角色经验、
/// 境界或伤势。集中失效避免仓库、材料来源弹层、角色页和战后疗伤面板
/// 在当前会话继续显示旧数据。
void invalidateAfterItemUse(
  void Function(ProviderOrFamily) invalidate, {
  required String defId,
  required ItemType itemType,
}) {
  invalidate(allInventoryItemsProvider);
  invalidate(inventoryQuantityByDefIdProvider(defId));
  invalidate(inventoryQuantityByTypeProvider(itemType));
  invalidate(characterByIdProvider);
  invalidate(activeCharacterIdsProvider);
}
