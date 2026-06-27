import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../domain/equipment_slot_occupancy.dart';

/// 玩家手动装备穿戴结果(H1 批2 · 核心循环修复)。
enum EquipOutcome {
  success,

  /// §5.3 三系锁死:角色境界未达 eq.tier 对应阶,拒绝上身。
  lockedByRealm,

  /// 角色或装备不存在(防御性,UI 正常不触发)。
  notFound,
}

/// 玩家手动装备 service(H1 批2 · 修「掉落装备无穿戴入口」核心循环断裂)。
///
/// 数据模型双轨:`Character.equipped{Slot}Id` 是「装备中」真相源；
/// `Equipment.ownerCharacterId` 仅同步当前槽位装备者,换装/卸装会回收为 null。
/// 「自由池」= 不在任何角色槽位的同 slot 装备(picker 可选)。
///
/// §5.3 三系锁死守卫:`isEquippableAtRealm`(沿 `ascend_service` auto_swap 体例 —
/// 境界不达不上身)。**师承遗物 / 奇遇高阶装备也不例外**(GDD §5.3 无网开一面)。
class EquipmentService {
  EquipmentService({required this.isar});

  final Isar isar;

  /// 装备 [equipmentId] 到 [characterId] 的对应 slot(由 `eq.slot` 决定)。
  ///
  /// - 境界不达 `eq.tier` → 不改任何状态,返回 [EquipOutcome.lockedByRealm]。
  /// - 该装备若原在他角色槽位 → 一并解钩(移装语义,防双持)。
  /// - 目标角色该 slot 旧装由覆盖自动回自由池(`equipped{Slot}Id` 不再指向它)。
  Future<EquipOutcome> equip({
    required int characterId,
    required int equipmentId,
  }) async {
    return isar.writeTxn(() async {
      final character = await isar.characters.get(characterId);
      final eq = await isar.equipments.get(equipmentId);
      if (character == null || eq == null) return EquipOutcome.notFound;
      // §5.3 三系锁死:境界不达不上身。
      if (!eq.isEquippableAtRealm(character.realmTier)) {
        return EquipOutcome.lockedByRealm;
      }

      final previousEquipmentId = equippedEquipmentIdForSlot(
        character,
        eq.slot,
      );

      // 移装解钩:清掉任何「其他角色」当前指向 eq 的槽位(防双持)。
      final all = await isar.characters.where().findAll();
      for (final h in all) {
        if (h.id == characterId) continue;
        var changed = false;
        if (h.equippedWeaponId == equipmentId) {
          h.equippedWeaponId = null;
          changed = true;
        }
        if (h.equippedArmorId == equipmentId) {
          h.equippedArmorId = null;
          changed = true;
        }
        if (h.equippedAccessoryId == equipmentId) {
          h.equippedAccessoryId = null;
          changed = true;
        }
        if (changed) await isar.characters.put(h);
      }

      // 目标角色:占 eq.slot 槽位；旧装回自由池并清 owner。
      setEquippedEquipmentIdForSlot(character, eq.slot, eq.id);
      if (previousEquipmentId != null && previousEquipmentId != eq.id) {
        final previous = await isar.equipments.get(previousEquipmentId);
        if (previous != null) {
          previous.ownerCharacterId = null;
          await isar.equipments.put(previous);
        }
      }
      eq.ownerCharacterId = characterId;
      await isar.equipments.put(eq);
      await isar.characters.put(character);
      return EquipOutcome.success;
    });
  }

  /// 卸下 [characterId] 的 [slot] 槽位装备(回自由池;装备实例 owner 清空)。
  Future<void> unequip({
    required int characterId,
    required EquipmentSlot slot,
  }) async {
    await isar.writeTxn(() async {
      final character = await isar.characters.get(characterId);
      if (character == null) return;
      final equipmentId = equippedEquipmentIdForSlot(character, slot);
      setEquippedEquipmentIdForSlot(character, slot, null);
      if (equipmentId != null) {
        final eq = await isar.equipments.get(equipmentId);
        if (eq != null) {
          eq.ownerCharacterId = null;
          await isar.equipments.put(eq);
        }
      }
      await isar.characters.put(character);
    });
  }
}
