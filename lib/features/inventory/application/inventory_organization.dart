import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';

enum InventorySlotFilter { all, weapon, armor, accessory }

enum InventoryTierFilter {
  all,
  xunChang,
  xiangYang,
  haoJiaHuo,
  liQi,
  zhongQi,
  baoWu,
  shenWu,
}

enum InventoryOwnershipFilter {
  all,
  free,
  equipped,
  heritage,
  equippable,
  forgeable,
  realmLocked,
}

enum InventoryEquipmentSort {
  tierDesc,
  tierAsc,
  enhanceDesc,
  obtainedDesc,
  obtainedAsc,
}

class InventoryEquipmentQuery {
  final InventorySlotFilter slot;
  final InventoryTierFilter tier;
  final InventoryOwnershipFilter ownership;
  final InventoryEquipmentSort sort;

  const InventoryEquipmentQuery({
    this.slot = InventorySlotFilter.all,
    this.tier = InventoryTierFilter.all,
    this.ownership = InventoryOwnershipFilter.all,
    this.sort = InventoryEquipmentSort.tierDesc,
  });
}

typedef EquipmentLockPredicate = bool Function(Equipment equipment);

bool _neverLocked(Equipment _) => false;

List<Equipment> organizeInventoryEquipments(
  Iterable<Equipment> equipments,
  InventoryEquipmentQuery query, {
  RealmTier? realm,
}) {
  final result = equipments.where((eq) {
    return _matchesSlot(eq, query.slot) &&
        _matchesTier(eq, query.tier) &&
        _matchesOwnership(eq, query.ownership, realm);
  }).toList();
  result.sort((a, b) => _compareEquipment(a, b, query.sort));
  return result;
}

bool isBulkDisposalCandidate(
  Equipment equipment, {
  EquipmentLockPredicate isLocked = _neverLocked,
}) {
  return equipment.ownerCharacterId == null &&
      !equipment.isLineageHeritage &&
      !isLocked(equipment);
}

BulkDisposalPlan buildBulkDisposalPlan(
  Iterable<Equipment> equipments, {
  EquipmentLockPredicate isLocked = _neverLocked,
}) {
  final byTier = <EquipmentTier, List<Equipment>>{};
  for (final eq in equipments) {
    if (!isBulkDisposalCandidate(eq, isLocked: isLocked)) continue;
    byTier.putIfAbsent(eq.tier, () => []).add(eq);
  }
  for (final items in byTier.values) {
    items.sort(
      (a, b) => _compareEquipment(a, b, InventoryEquipmentSort.tierDesc),
    );
  }
  final tiers = byTier.keys.toList()
    ..sort((a, b) => b.index.compareTo(a.index));
  return BulkDisposalPlan._(byTier, tiers);
}

class BulkDisposalPlan {
  final Map<EquipmentTier, List<Equipment>> _byTier;
  final List<EquipmentTier> tiers;

  const BulkDisposalPlan._(this._byTier, this.tiers);

  List<Equipment> itemsFor(EquipmentTier tier) =>
      List.unmodifiable(_byTier[tier] ?? const []);

  bool get isEmpty => tiers.isEmpty;
}

bool _matchesSlot(Equipment eq, InventorySlotFilter filter) {
  return switch (filter) {
    InventorySlotFilter.all => true,
    InventorySlotFilter.weapon => eq.slot == EquipmentSlot.weapon,
    InventorySlotFilter.armor => eq.slot == EquipmentSlot.armor,
    InventorySlotFilter.accessory => eq.slot == EquipmentSlot.accessory,
  };
}

bool _matchesTier(Equipment eq, InventoryTierFilter filter) {
  final tier = switch (filter) {
    InventoryTierFilter.all => null,
    InventoryTierFilter.xunChang => EquipmentTier.xunChang,
    InventoryTierFilter.xiangYang => EquipmentTier.xiangYang,
    InventoryTierFilter.haoJiaHuo => EquipmentTier.haoJiaHuo,
    InventoryTierFilter.liQi => EquipmentTier.liQi,
    InventoryTierFilter.zhongQi => EquipmentTier.zhongQi,
    InventoryTierFilter.baoWu => EquipmentTier.baoWu,
    InventoryTierFilter.shenWu => EquipmentTier.shenWu,
  };
  return tier == null || eq.tier == tier;
}

bool _matchesOwnership(
  Equipment eq,
  InventoryOwnershipFilter filter,
  RealmTier? realm,
) {
  return switch (filter) {
    InventoryOwnershipFilter.all => true,
    InventoryOwnershipFilter.free => eq.ownerCharacterId == null,
    InventoryOwnershipFilter.equipped => eq.ownerCharacterId != null,
    InventoryOwnershipFilter.heritage => eq.isLineageHeritage,
    InventoryOwnershipFilter.equippable =>
      eq.ownerCharacterId == null &&
          (realm == null || eq.isEquippableAtRealm(realm)),
    InventoryOwnershipFilter.forgeable => eq.forgingSlots.any(
      (s) => !s.unlocked,
    ),
    InventoryOwnershipFilter.realmLocked =>
      realm != null && !eq.isEquippableAtRealm(realm),
  };
}

int _compareEquipment(Equipment a, Equipment b, InventoryEquipmentSort sort) {
  final primary = switch (sort) {
    InventoryEquipmentSort.tierDesc => b.tier.index.compareTo(a.tier.index),
    InventoryEquipmentSort.tierAsc => a.tier.index.compareTo(b.tier.index),
    InventoryEquipmentSort.enhanceDesc => b.enhanceLevel.compareTo(
      a.enhanceLevel,
    ),
    InventoryEquipmentSort.obtainedDesc => b.obtainedAt.compareTo(a.obtainedAt),
    InventoryEquipmentSort.obtainedAsc => a.obtainedAt.compareTo(b.obtainedAt),
  };
  if (primary != 0) return primary;

  final tier = b.tier.index.compareTo(a.tier.index);
  if (tier != 0) return tier;
  final enhance = b.enhanceLevel.compareTo(a.enhanceLevel);
  if (enhance != 0) return enhance;
  final obtained = b.obtainedAt.compareTo(a.obtainedAt);
  if (obtained != 0) return obtained;
  return b.id.compareTo(a.id);
}
