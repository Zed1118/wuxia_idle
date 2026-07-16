import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('断魂帖 defId 映射到 ItemType.ticket（不落 miscMaterial）', () {
    expect(ItemType.fromDefId('item_duanhuntie'), ItemType.ticket);
  });
  test('既有映射不回归', () {
    expect(ItemType.fromDefId('item_silver'), ItemType.silver);
    expect(ItemType.fromDefId('item_mojianshi'), ItemType.moJianShi);
    expect(ItemType.fromDefId('item_unknown_xyz'), ItemType.miscMaterial);
  });
}
