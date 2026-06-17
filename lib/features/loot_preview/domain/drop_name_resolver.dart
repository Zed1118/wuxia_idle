// lib/features/loot_preview/domain/drop_name_resolver.dart
import '../../../core/domain/enums.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';

/// 薄封装 defId → 显示名 / 阶 / 越阶判定。复用 victory dialog 同源解析，
/// `GameRepository` 未加载时降级 raw defId（护轻量 widget 测）。
abstract final class DropNameResolver {
  static String equipmentName(String defId) {
    if (!GameRepository.isLoaded) return defId;
    return GameRepository.instance.getEquipment(defId).name;
  }

  static EquipmentTier? equipmentTier(String defId) {
    if (!GameRepository.isLoaded) return null;
    return GameRepository.instance.getEquipment(defId).tier;
  }

  static String itemName(String defId) =>
      EnumL10n.itemType(ItemType.fromDefId(defId));

  static bool isAboveRealm(EquipmentTier tier, RealmTier currentRealm) =>
      tier.index > currentRealm.index;
}
