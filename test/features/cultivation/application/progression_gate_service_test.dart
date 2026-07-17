import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/realm_def.dart';
import 'package:wuxia_idle/features/cultivation/application/progression_gate_service.dart';
import 'package:wuxia_idle/data/defs/progression_release_cap.dart';
import 'package:wuxia_idle/data/defs/inner_demon_def.dart';

RealmDef _realmLookup(RealmTier tier, RealmLayer layer) => RealmDef(
  tier: tier,
  layer: layer,
  absoluteLevel: tier.index * RealmLayer.values.length + layer.index + 1,
  internalForceMax: 500,
  experienceToNext: 100,
  equipmentTierCap: EquipmentTier.xunChang,
  techniqueTierCap: TechniqueTier.ruMenGong,
);

bool _isLocked({required RealmTier nextTier, required RealmLayer nextLayer}) =>
    ProgressionGateService.isLayerLocked(
      nextTier: nextTier,
      nextLayer: nextLayer,
      releaseCap: const ProgressionReleaseCap(maxAbsoluteRealmLevel: 10),
      realmLookup: _realmLookup,
      innerDemonDef: InnerDemonDef.empty(),
      clearedStageIds: const {},
    );

void main() {
  group('ProgressionGateService.isLayerLocked', () {
    test('allows entering the configured final release layer', () {
      expect(
        _isLocked(nextTier: RealmTier.sanLiu, nextLayer: RealmLayer.shuLian),
        isFalse,
      );
    });

    test('locks the first layer above the release cap', () {
      expect(
        _isLocked(nextTier: RealmTier.sanLiu, nextLayer: RealmLayer.jingTong),
        isTrue,
      );
    });

    test('grandfathered characters cannot advance farther above the cap', () {
      expect(
        _isLocked(nextTier: RealmTier.sanLiu, nextLayer: RealmLayer.yuanShu),
        isTrue,
      );
    });
  });
}
