import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';

int? equippedEquipmentIdForSlot(Character character, EquipmentSlot slot) {
  return switch (slot) {
    EquipmentSlot.weapon => character.equippedWeaponId,
    EquipmentSlot.armor => character.equippedArmorId,
    EquipmentSlot.accessory => character.equippedAccessoryId,
  };
}

void setEquippedEquipmentIdForSlot(
  Character character,
  EquipmentSlot slot,
  int? equipmentId,
) {
  switch (slot) {
    case EquipmentSlot.weapon:
      character.equippedWeaponId = equipmentId;
    case EquipmentSlot.armor:
      character.equippedArmorId = equipmentId;
    case EquipmentSlot.accessory:
      character.equippedAccessoryId = equipmentId;
  }
}

bool characterHasEquipmentEquipped(Character character, int equipmentId) {
  return character.equippedWeaponId == equipmentId ||
      character.equippedArmorId == equipmentId ||
      character.equippedAccessoryId == equipmentId;
}

Set<int> equippedEquipmentIdsForCharacters(Iterable<Character> characters) {
  return {
    for (final character in characters) ...[
      if (character.equippedWeaponId != null) character.equippedWeaponId!,
      if (character.equippedArmorId != null) character.equippedArmorId!,
      if (character.equippedAccessoryId != null) character.equippedAccessoryId!,
    ],
  };
}

bool isEquipmentEquippedBySlot(
  Equipment equipment,
  Set<int> equippedEquipmentIds,
) => equippedEquipmentIds.contains(equipment.id);
