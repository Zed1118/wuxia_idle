import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('既有精确 case 不回归', () {
    expect(ItemType.fromDefId('item_mojianshi'), ItemType.moJianShi);
    expect(ItemType.fromDefId('item_xinxuejiejing'), ItemType.xinXueJieJing);
    expect(ItemType.fromDefId('item_silver'), ItemType.silver);
  });

  test('经验丹前缀 → jingYanDan', () {
    expect(ItemType.fromDefId('item_jingyandan_small'), ItemType.jingYanDan);
    expect(ItemType.fromDefId('item_jingyandan_mid'), ItemType.jingYanDan);
    expect(ItemType.fromDefId('item_jingyandan_large'), ItemType.jingYanDan);
  });

  test('秘籍前缀 → techniqueScroll', () {
    expect(ItemType.fromDefId('item_scroll_kai_bei_shou'), ItemType.techniqueScroll);
    expect(ItemType.fromDefId('item_scroll_ye_yu_shi_nian_deng'), ItemType.techniqueScroll);
  });

  test('未知 id → miscMaterial 兜底', () {
    expect(ItemType.fromDefId('item_unknown_xyz'), ItemType.miscMaterial);
  });
}
