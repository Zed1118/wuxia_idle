import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../battle_record/application/boss_memory_providers.dart';
import '../../shop/application/shop_providers.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';

/// 战斗 / 扫荡结算后统一失效的 provider 集合（体检批3 P0-5 单一事实源）。
///
/// 此前主线（stage_entry_flow）、爬塔（tower_entry_flow）各自复制粘贴一份
/// 「角色 family 失效」（W13-v3 fix），扫荡（sweep_settlement）只失效进度，
/// 且**三路径都漏了主菜单隐藏入口门控 + 银两**——导致首次获银两 / 装备 / 杀 Boss
/// 后主菜单商店 / 兵器谱 / 战绩册入口当次会话永不解锁（重启才见）。
/// 集中一处后各结算路径共享，消灭「复制粘贴 + 各自遗漏」。
///
/// 参数是 `void Function(ProviderOrFamily)`：生产传 `ref.invalidate`（WidgetRef），
/// 测试传 `container.invalidate`（ProviderContainer），无 WidgetRef 耦合、可单测。
///
/// 失效两类：
/// 1. **角色 / 装备 / 心法 family**：结算改 battleCount / cultivationProgress /
///    internalForce（Boss 战败 ×0.5）/ 关卡 drop 入背包，缓存旧 Character/Equipment/
///    Technique 会让角色面板 / 心法面板 / 仓库读到旧值（W13-v3 实测根因）。
/// 2. **主菜单隐藏入口门控 + 银两余额**：首次获得对应资源后 §5.7 隐藏入口需解锁。
void invalidateAfterCombatSettlement(
  void Function(ProviderOrFamily) invalidate,
) {
  // 1. 角色 / 装备 / 心法 family。
  invalidate(characterByIdProvider);
  invalidate(activeCharacterIdsProvider);
  invalidate(equipmentByIdProvider);
  invalidate(techniqueByIdProvider);
  invalidate(characterAllTechniquesProvider);
  invalidate(allEquipmentsProvider);
  // 2. 主菜单隐藏入口门控 + 银两余额。
  invalidate(silverBalanceProvider);
  invalidate(shopUnlockedProvider);
  invalidate(equipmentCatalogCountProvider);
  invalidate(bossMemoryCountProvider);
}
