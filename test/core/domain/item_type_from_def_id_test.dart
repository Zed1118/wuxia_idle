import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

/// W15 #30 P3 后续 F1 · ItemType.fromDefId 静态工厂单测。
///
/// 入库(tower/mainline 写背包)与展示(victory dialog drop banner)共用,
/// 未知 id 兜底 miscMaterial(victory dialog 展示「杂项材料 ×N」语义弱化但不失真)。
void main() {
  group('ItemType.fromDefId', () {
    test('item_mojianshi → moJianShi', () {
      expect(ItemType.fromDefId('item_mojianshi'), ItemType.moJianShi);
    });

    test('item_xinxuejiejing → xinXueJieJing', () {
      expect(
        ItemType.fromDefId('item_xinxuejiejing'),
        ItemType.xinXueJieJing,
      );
    });

    test('未知 id → miscMaterial(兜底)', () {
      expect(ItemType.fromDefId('item_unknown'), ItemType.miscMaterial);
      expect(ItemType.fromDefId(''), ItemType.miscMaterial);
    });
  });
}
