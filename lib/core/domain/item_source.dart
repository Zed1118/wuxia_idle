/// 背包资源的主要来源。
///
/// 只描述“哪里能获得该 item”；消费用途见 [ItemUsage]。
enum ItemSourceKind {
  mainline,
  stage,
  tower,
  seclusion,
  shop,
  equipmentDisassembly,
  enhancementFailure,
  islandSource,
  islandRecipe,
}

class ItemSource {
  final ItemSourceKind kind;
  final String? sourceId;
  final String? name;
  final int? chapterIndex;
  final int? floorIndex;
  final bool isBoss;

  const ItemSource._({
    required this.kind,
    this.sourceId,
    this.name,
    this.chapterIndex,
    this.floorIndex,
    this.isBoss = false,
  });

  const ItemSource.mainline({
    required String stageId,
    required String stageName,
    required int chapterIndex,
    required bool isBoss,
  }) : this._(
         kind: ItemSourceKind.mainline,
         sourceId: stageId,
         name: stageName,
         chapterIndex: chapterIndex,
         isBoss: isBoss,
       );

  const ItemSource.stage({
    required String stageId,
    required String stageName,
    required bool isBoss,
  }) : this._(
         kind: ItemSourceKind.stage,
         sourceId: stageId,
         name: stageName,
         isBoss: isBoss,
       );

  const ItemSource.tower({required int floorIndex, required bool isBoss})
    : this._(
        kind: ItemSourceKind.tower,
        floorIndex: floorIndex,
        isBoss: isBoss,
      );

  const ItemSource.seclusion({required String mapName})
    : this._(kind: ItemSourceKind.seclusion, name: mapName);

  const ItemSource.shop({String? shopId})
    : this._(kind: ItemSourceKind.shop, sourceId: shopId);

  const ItemSource.equipmentDisassembly()
    : this._(kind: ItemSourceKind.equipmentDisassembly);

  const ItemSource.enhancementFailure()
    : this._(kind: ItemSourceKind.enhancementFailure);

  const ItemSource.islandSource({required String buildingName})
    : this._(kind: ItemSourceKind.islandSource, name: buildingName);

  const ItemSource.islandRecipe({required String recipeId})
    : this._(kind: ItemSourceKind.islandRecipe, sourceId: recipeId);

  String get dedupeKey => switch (kind) {
    ItemSourceKind.mainline => 'mainline:$sourceId',
    ItemSourceKind.stage => 'stage:$sourceId',
    ItemSourceKind.tower => 'tower:$floorIndex',
    ItemSourceKind.seclusion => 'seclusion:$name',
    ItemSourceKind.shop => 'shop:${sourceId ?? ''}',
    ItemSourceKind.equipmentDisassembly => 'equipmentDisassembly',
    ItemSourceKind.enhancementFailure => 'enhancementFailure',
    ItemSourceKind.islandSource => 'islandSource:$name',
    ItemSourceKind.islandRecipe => 'islandRecipe:$sourceId',
  };
}
