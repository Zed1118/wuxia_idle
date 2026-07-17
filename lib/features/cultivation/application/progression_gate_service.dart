import '../../../core/domain/enums.dart';
import '../../../data/defs/realm_def.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../../data/defs/inner_demon_def.dart';
import '../../../data/defs/progression_release_cap.dart';

final class ProgressionGateService {
  ProgressionGateService._();

  static bool isLayerLocked({
    required RealmTier nextTier,
    required RealmLayer nextLayer,
    required ProgressionReleaseCap releaseCap,
    required RealmDef Function(RealmTier tier, RealmLayer layer) realmLookup,
    required InnerDemonDef innerDemonDef,
    required Set<String> clearedStageIds,
  }) {
    final nextRealm = realmLookup(nextTier, nextLayer);
    if (nextRealm.absoluteLevel > releaseCap.maxAbsoluteRealmLevel) {
      return true;
    }
    return InnerDemonService.isLayerLocked(
      nextTier: nextTier,
      nextLayer: nextLayer,
      innerDemonDef: innerDemonDef,
      clearedStageIds: clearedStageIds,
    );
  }
}
