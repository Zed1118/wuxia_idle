import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/equipment/application/forging_service.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/derived_stats.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';

import 'phase0a_full_build_profile.dart';

/// Settlement/migration fixture, not a natural-growth or economy simulation.
/// Reuse production onboarding/advancement/learning/equipping, then replace the
/// extreme damage oracle's duplicate attack slots before any combat can run.
/// Enhancement/resonance and the forging material budget are explicit fixtures;
/// Every supported slot passes production validation and debits storage. Armor
/// and accessories without authored skill candidates keep their third slot empty.
Future<CombatantSnapshot> seedPhase0aTowerEndgameProfile({
  required Isar isar,
}) async {
  await seedPhase0aFullBuildProfile(
    isar: isar,
    school: TechniqueSchool.gangMeng,
  );
  final repo = GameRepository.instance;
  final config = repo.numbers.forging;
  final character = (await isar.characters.get(1))!;
  final equipmentIds = [
    character.equippedWeaponId!,
    character.equippedArmorId!,
    character.equippedAccessoryId!,
  ];
  var totalMaterialCost = 0;
  for (final id in equipmentIds) {
    final equipment = (await isar.equipments.get(id))!;
    final hasSpecial = repo
        .getEquipment(equipment.defId)
        .specialSkillCandidates
        .isNotEmpty;
    totalMaterialCost +=
        config.slotByIndex(1).fucaiCost + config.slotByIndex(2).fucaiCost;
    if (hasSpecial) totalMaterialCost += config.slotByIndex(3).fucaiCost;
  }
  const materialId = 'item_kaifeng_fucai';
  final existingMaterial = await isar.inventoryItems.getByDefId(materialId);
  final originalQuantity = existingMaterial?.quantity ?? 0;
  final at = DateTime.now();
  await isar.writeTxn(() async {
    final material =
        existingMaterial ??
        (InventoryItem()
          ..defId = materialId
          ..itemType = ItemType.fromDefId(materialId)
          ..firstObtainedAt = at);
    material
      ..quantity = originalQuantity + totalMaterialCost
      ..lastObtainedAt = at;
    await isar.inventoryItems.put(material);
  });

  final service = ForgingService(isar: isar);
  for (final id in equipmentIds) {
    var equipment = (await isar.equipments.get(id))!;
    final definition = repo.getEquipment(equipment.defId);
    equipment.forgingSlots = [
      for (var slot = 1; slot <= 3; slot++) ForgingSlot()..slotIndex = slot,
    ];
    await isar.writeTxn(() => isar.equipments.put(equipment));
    for (final (index, type) in [
      (1, ForgingSlotType.attack),
      (2, ForgingSlotType.pierce),
      if (definition.specialSkillCandidates.isNotEmpty)
        (3, ForgingSlotType.specialSkill),
    ]) {
      final before = (await isar.inventoryItems.getByDefId(
        materialId,
      ))!.quantity;
      final result = ForgingService.forge(
        eq: equipment,
        def: definition,
        slotIndex: index,
        type: type,
        specialSkillId: type == ForgingSlotType.specialSkill
            ? definition.specialSkillCandidates.first
            : null,
        config: config,
      );
      if (result != ForgeResult.success) {
        throw StateError('Endgame forging rejected $id/$index: $result');
      }
      await service.persistResult(
        eq: equipment,
        slotIndex: index,
        config: config,
      );
      final after =
          (await isar.inventoryItems.getByDefId(materialId))?.quantity ?? 0;
      if (before - after != config.slotByIndex(index).fucaiCost) {
        throw StateError(
          'Endgame forging did not debit materials for $id/$index',
        );
      }
      equipment = (await isar.equipments.get(id))!;
    }
    if (!equipment.isEquippableAtRealm(character.realmTier) ||
        (definition.schoolBias != null &&
            definition.schoolBias != character.school) ||
        equipment.enhanceLevel > RealmUtils.maxEnhanceLevelOf(character) ||
        equipment.forgingSlots[0].type == equipment.forgingSlots[1].type ||
        equipment.forgingSlots.take(2).any((slot) => !slot.unlocked) ||
        equipment.forgingSlots[2].unlocked !=
            definition.specialSkillCandidates.isNotEmpty ||
        (definition.specialSkillCandidates.isEmpty &&
            (equipment.forgingSlots[2].type != null ||
                equipment.forgingSlots[2].specialSkillId != null))) {
      throw StateError(
        'Endgame equipment violates realm or forging constraints',
      );
    }
  }
  if (((await isar.inventoryItems.getByDefId(materialId))?.quantity ?? 0) !=
      originalQuantity) {
    throw StateError('Endgame forging material budget was not fully consumed');
  }
  final techniques = await isar.techniques
      .filter()
      .ownerCharacterIdEqualTo(character.id)
      .findAll();
  if (character.school != TechniqueSchool.gangMeng ||
      character.realmTier != RealmTier.wuSheng ||
      character.realmLayer != RealmLayer.dengFeng ||
      techniques.any(
        (technique) =>
            technique.school != character.school ||
            technique.tier.index >
                RealmUtils.techniqueTierCapOf(character.realmTier).index,
      )) {
    throw StateError('Endgame character/technique realm constraints failed');
  }
  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([character.id]);
  if (snapshots.length != 1 || snapshots.single.forgingLifestealPct != 0) {
    throw StateError('Endgame fixture must produce one legal Phase0A snapshot');
  }
  return snapshots.single;
}
