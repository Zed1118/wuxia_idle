import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';
import 'package:wuxia_idle/features/cultivation/domain/advancement_entry.dart';
import 'package:wuxia_idle/features/equipment/domain/resonance_upgrade_notice.dart';

void main() {
  test('advancement entry keeps stable character id', () {
    const entry = AdvancementEntry(
      characterId: 7,
      chName: '同名',
      result: AdvancementResult(
        layersGained: 0,
        tierBefore: RealmTier.xueTu,
        layerBefore: RealmLayer.qiMeng,
        tierAfter: RealmTier.xueTu,
        layerAfter: RealmLayer.qiMeng,
        internalForceMaxBefore: 500,
        internalForceMaxAfter: 500,
      ),
    );
    expect(entry.characterId, 7);
  });

  test('resonance notice is independent from victory presentation', () {
    const notice = ResonanceUpgradeNotice(
      equipmentName: '试剑',
      newStage: ResonanceStage.moQi,
    );
    expect(notice.equipmentName, '试剑');
    expect(notice.newStage, ResonanceStage.moQi);
  });
}
