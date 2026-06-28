import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/item_source.dart';
import '../../../core/domain/item_usage.dart';
import '../../../data/defs/shop_item_def.dart';
import '../../../data/game_repository.dart';
import '../../inventory/application/item_usage_lookup_service.dart';
import '../../inventory/application/material_source_lookup_service.dart';

/// 商店货架需求提示的只读派生服务。
///
/// 只聚合现有 item/use/source 配置和当前角色状态，不写存档、不改价格、不新增消费路径。
class ShopNeedHintService {
  const ShopNeedHintService(this.repo);

  final GameRepository repo;

  ShopNeedHint hintFor({
    required ShopItemDef def,
    required List<Character> activeCharacters,
  }) {
    final itemDef = repo.itemDefs[def.itemDefId];
    final type = itemDef?.type ?? def.itemType;
    final usages = ItemUsageLookupService(repo).usagesFor(def.itemDefId);
    final sources = MaterialSourceLookupService(repo)
        .sourcesFor(def.itemDefId)
        .where((source) => source.kind != ItemSourceKind.shop)
        .toList(growable: false);

    final hasRecoveryEffect = itemDef?.hasRecoveryEffect ?? false;

    return ShopNeedHint(
      displayName: itemDef?.name,
      showCurrentUsers: _shouldShowCurrentUsers(type, hasRecoveryEffect),
      currentUserNames: _currentUserNames(
        type,
        hasRecoveryEffect,
        activeCharacters,
      ),
      usages: usages,
      alternateSources: sources,
    );
  }

  bool _shouldShowCurrentUsers(ItemType type, bool hasRecoveryEffect) {
    return type == ItemType.jingYanDan || hasRecoveryEffect;
  }

  List<String> _currentUserNames(
    ItemType type,
    bool hasRecoveryEffect,
    List<Character> activeCharacters,
  ) {
    if (type == ItemType.jingYanDan) {
      return activeCharacters
          .where((character) => character.isFounder)
          .map((character) => character.name)
          .toList(growable: false);
    }

    if (hasRecoveryEffect) {
      final wounded =
          activeCharacters.where((character) {
            return character.injuryHoursRemaining > 0 ||
                character.innerDemonResidueHoursRemaining > 0 ||
                character.lightInjuryStacks > 0;
          }).toList()..sort(
            (a, b) => _recoveryNeedScore(b).compareTo(_recoveryNeedScore(a)),
          );
      return wounded.map((character) => character.name).toList(growable: false);
    }

    return const [];
  }

  double _recoveryNeedScore(Character character) {
    return character.injuryHoursRemaining +
        character.innerDemonResidueHoursRemaining +
        character.lightInjuryStacks;
  }
}

class ShopNeedHint {
  const ShopNeedHint({
    required this.displayName,
    required this.showCurrentUsers,
    required this.currentUserNames,
    required this.usages,
    required this.alternateSources,
  });

  final String? displayName;
  final bool showCurrentUsers;
  final List<String> currentUserNames;
  final List<ItemUsage> usages;
  final List<ItemSource> alternateSources;

  bool get hasAnyHint =>
      showCurrentUsers || usages.isNotEmpty || alternateSources.isNotEmpty;
}
