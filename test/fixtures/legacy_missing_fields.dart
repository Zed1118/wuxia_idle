import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

part 'legacy_missing_fields.g.dart';

/// Persisted older schemas deliberately omit the fields under examination.
@collection
@Name('Character')
class MissingCharacter {
  Id id = Isar.autoIncrement;
  String legacyMarker = 'legacy';
  MissingAttributes? attributes;
  double innerDemonResidueHoursRemaining = 6;
  int internalForceMax = 750;
}

@embedded
@Name('Attributes')
class MissingAttributes {
  String legacyMarker = 'legacy';
}

@collection
@Name('Equipment')
class MissingEquipment {
  Id id = Isar.autoIncrement;
  List<MissingLore> lores = [];
}

@embedded
@Name('Lore')
class MissingLore {
  String legacyMarker = 'legacy';
}

@collection
@Name('EncounterProgress')
class MissingEncounterProgress {
  Id id = Isar.autoIncrement;
  List<MissingBiomeMinutes> biomeMinutes = [];
}

@embedded
@Name('BiomeMinutes')
class MissingBiomeMinutes {
  String legacyMarker = 'legacy';
}

@collection
@Name('TowerProgress')
class MissingTowerCycle {
  Id id = 1;
  int saveDataId = 1;
  int highestClearedFloor = 2;
  int maxClearedCycle = 0;
  DateTime createdAt = DateTime.utc(2026, 9, 6);
}

@collection
@Name('Character')
class MissingCharacterMaxAndBirth {
  Id id = 1;
  int internalForce = 123;
  @Enumerated(EnumType.name)
  RarityTier rarity = RarityTier.jueShi;
  MissingAttributes attributes = MissingAttributes();
}

@collection
@Name('MainlineProgress')
class MissingMainlineLists {
  Id id = 1;
  String legacyMarker = 'legacy';
}

@collection
@Name('Character')
class AbsentCharacterProperties {
  Id id = 1;
  String legacyMarker = 'legacy';
}
