// test/features/loot_preview/drop_name_resolver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_name_resolver.dart';

void main() {
  test('repo 未加载 → 装备名降级 raw defId、阶为 null', () {
    // GameRepository 未 load（轻量测无 Isar）。
    expect(DropNameResolver.equipmentName('weapon_x'), 'weapon_x');
    expect(DropNameResolver.equipmentTier('weapon_x'), isNull);
  });

  test('物品名走 EnumL10n（known→磨剑石 / unknown→杂项材料）', () {
    expect(DropNameResolver.itemName('item_mojianshi'), '磨剑石');
    expect(DropNameResolver.itemName('item_unknown_xyz'), '杂项材料');
  });

  test('isAboveRealm：tier.index > currentRealm.index', () {
    // shenWu(6) > sanLiu(1) → true
    expect(DropNameResolver.isAboveRealm(EquipmentTier.shenWu, RealmTier.sanLiu), true);
    // xunChang(0) <= wuSheng(6) → false
    expect(DropNameResolver.isAboveRealm(EquipmentTier.xunChang, RealmTier.wuSheng), false);
  });

  test('EquipmentTier 与 RealmTier 阶数对齐（isAboveRealm 依赖 index 同尺度）', () {
    expect(EquipmentTier.values.length, RealmTier.values.length);
  });
}
