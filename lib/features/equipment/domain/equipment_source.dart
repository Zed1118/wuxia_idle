enum EquipmentSourceKind { mainline, stage, tower, seclusion, shop, tag }

class EquipmentSource {
  final EquipmentSourceKind kind;
  final String? sourceId;
  final String? name;
  final int? chapterIndex;
  final int? floorIndex;
  final bool isBoss;
  final String? tag;

  const EquipmentSource._({
    required this.kind,
    this.sourceId,
    this.name,
    this.chapterIndex,
    this.floorIndex,
    this.isBoss = false,
    this.tag,
  });

  const EquipmentSource.mainline({
    required String stageId,
    required String stageName,
    required int chapterIndex,
    required bool isBoss,
  }) : this._(
         kind: EquipmentSourceKind.mainline,
         sourceId: stageId,
         name: stageName,
         chapterIndex: chapterIndex,
         isBoss: isBoss,
       );

  const EquipmentSource.stage({
    required String stageId,
    required String stageName,
    required bool isBoss,
  }) : this._(
         kind: EquipmentSourceKind.stage,
         sourceId: stageId,
         name: stageName,
         isBoss: isBoss,
       );

  const EquipmentSource.tower({required int floorIndex, required bool isBoss})
    : this._(
        kind: EquipmentSourceKind.tower,
        floorIndex: floorIndex,
        isBoss: isBoss,
      );

  const EquipmentSource.seclusion({required String mapName})
    : this._(kind: EquipmentSourceKind.seclusion, name: mapName);

  const EquipmentSource.shop({String? shopId})
    : this._(kind: EquipmentSourceKind.shop, sourceId: shopId);

  const EquipmentSource.tag(String tag)
    : this._(kind: EquipmentSourceKind.tag, tag: tag);

  String get dedupeKey => switch (kind) {
    EquipmentSourceKind.mainline => 'mainline:$sourceId',
    EquipmentSourceKind.stage => 'stage:$sourceId',
    EquipmentSourceKind.tower => 'tower:$floorIndex',
    EquipmentSourceKind.seclusion => 'seclusion:$name',
    EquipmentSourceKind.shop => 'shop:${sourceId ?? tag ?? ''}',
    EquipmentSourceKind.tag => 'tag:$tag',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentSource &&
          other.kind == kind &&
          other.sourceId == sourceId &&
          other.name == name &&
          other.chapterIndex == chapterIndex &&
          other.floorIndex == floorIndex &&
          other.isBoss == isBoss &&
          other.tag == tag;

  @override
  int get hashCode =>
      Object.hash(kind, sourceId, name, chapterIndex, floorIndex, isBoss, tag);
}
