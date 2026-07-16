import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';

void main() {
  test('疗伤丹解析断魂庄内回血比例，行囊补给解析回气比例', () {
    final dan = ItemDef.fromYaml({
      'defId': 'item_liaoshangdan',
      'type': 'miscMaterial',
      'name': '疗伤丹',
      'gauntlet_hp_heal_pct': 0.30,
    });
    expect(dan.gauntletHpHealPct, 0.30);
    expect(dan.gauntletQiRestorePct, 0.0);

    final buji = ItemDef.fromYaml({
      'defId': 'item_xingnang_buji',
      'type': 'miscMaterial',
      'name': '行囊补给',
      'gauntlet_qi_restore_pct': 0.20,
    });
    expect(buji.gauntletQiRestorePct, 0.20);
  });
}
