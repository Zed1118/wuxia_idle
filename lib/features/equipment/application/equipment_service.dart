import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../domain/equipment_disposal.dart';
import '../domain/equipment_slot_occupancy.dart';
import 'equipment_disposal_service.dart';

/// 玩家手动装备穿戴结果(H1 批2 · 核心循环修复)。
enum EquipOutcome {
  success,

  /// §5.3 三系锁死:角色境界未达 eq.tier 对应阶,拒绝上身。
  lockedByRealm,

  /// 角色或装备不存在(防御性,UI 正常不触发)。
  notFound,

  /// 旧槽装备为传承遗物，或目标装备仍在出战角色身上，拒绝静默替换。
  protectedCurrentEquipment,

  /// 角色或装备被远征/断魂庄在途会话保留(出发快照为准),拒绝穿/卸/移
  /// (活动占用契约,07-21 审查 P1-5.1)。
  reservedByActivity,
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
  EquipmentService({
    required this.isar,
    EquipmentProtectionPolicy? protectionPolicy,
  }) : protectionPolicy =
           protectionPolicy ?? defaultEquipmentProtectionPolicy();

  final Isar isar;
  final EquipmentProtectionPolicy protectionPolicy;

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

      // 活动占用契约(P1-5.1):在途会话成员及其出发快照保留装备不可穿/移
      // (穿上在途成员会顶掉其保留装备;移走保留装备会令快照漂移)。
      final occupancy = await CharacterOccupancyService(isar).snapshot();
      if (occupancy.isCharacterOccupied(characterId) ||
          occupancy.reservedEquipmentIds.contains(eq.id)) {
        return EquipOutcome.reservedByActivity;
      }

      final activeEquippedIds = await _activeFormationEquipmentIds();
      if (activeEquippedIds.contains(eq.id) &&
          eq.ownerCharacterId != characterId) {
        return EquipOutcome.protectedCurrentEquipment;
      }

      final previousEquipmentId = equippedEquipmentIdForSlot(
        character,
        eq.slot,
      );
      if (previousEquipmentId != null && previousEquipmentId != eq.id) {
        final previous = await isar.equipments.get(previousEquipmentId);
        if (previous != null && _isProtectedForDirectReplacement(previous)) {
          return EquipOutcome.protectedCurrentEquipment;
        }
      }

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

  bool _isProtectedForDirectReplacement(Equipment equipment) =>
      equipment.isLineageHeritage;

  Future<Set<int>> _activeFormationEquipmentIds() async {
    final save = await isar.saveDatas.get(0);
    final activeIds = save?.activeCharacterIds.toSet() ?? const <int>{};
    if (activeIds.isEmpty) return const {};
    final characters = await isar.characters.where().findAll();
    return equippedEquipmentIdsForCharacters(
      characters.where((c) => activeIds.contains(c.id)),
    );
  }

  /// 卸下 [characterId] 的 [slot] 槽位装备(回自由池;装备实例 owner 清空)。
  /// 在途会话成员/保留装备拒绝卸装(P1-5.1),返回 [EquipOutcome.reservedByActivity]。
  Future<EquipOutcome> unequip({
    required int characterId,
    required EquipmentSlot slot,
  }) async {
    return isar.writeTxn(() async {
      final character = await isar.characters.get(characterId);
      if (character == null) return EquipOutcome.notFound;
      final occupancy = await CharacterOccupancyService(isar).snapshot();
      if (occupancy.isCharacterOccupied(characterId)) {
        return EquipOutcome.reservedByActivity;
      }
      final equipmentId = equippedEquipmentIdForSlot(character, slot);
      if (equipmentId != null &&
          occupancy.reservedEquipmentIds.contains(equipmentId)) {
        return EquipOutcome.reservedByActivity;
      }
      setEquippedEquipmentIdForSlot(character, slot, null);
      if (equipmentId != null) {
        final eq = await isar.equipments.get(equipmentId);
        if (eq != null) {
          eq.ownerCharacterId = null;
          await isar.equipments.put(eq);
        }
      }
      await isar.characters.put(character);
      return EquipOutcome.success;
    });
  }

  /// 设置装备锁定状态。锁定只影响出售/分解/批量整理，不改变穿戴与养成状态。
  Future<EquipOutcome> setLocked({
    required int equipmentId,
    required bool locked,
  }) async {
    return isar.writeTxn(() async {
      final eq = await isar.equipments.get(equipmentId);
      if (eq == null) return EquipOutcome.notFound;
      eq.isLocked = locked;
      await isar.equipments.put(eq);
      return EquipOutcome.success;
    });
  }
}
