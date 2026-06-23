import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

/// W15 #30 P3 后续 F1 · ItemType.fromDefId 静态工厂单测。
///
/// 入库(tower/mainline 写背包)与展示(victory dialog drop banner)共用,
/// 未知 id 兜底 miscMaterial(victory dialog 展示「杂项材料 ×N」语义弱化但不失真)。
///
/// 材料经济P1 bug fix: item_silver 首次入库必须返回 ItemType.silver，
/// 否则泄漏进背包材料网格显示「杂项材料 ×N」。
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

    test('item_silver → silver（首次入库类型正确，不泄漏进材料网格）', () {
      expect(ItemType.fromDefId('item_silver'), ItemType.silver);
    });

    test('未知 id → miscMaterial(兜底)', () {
      expect(ItemType.fromDefId('item_unknown'), ItemType.miscMaterial);
      expect(ItemType.fromDefId(''), ItemType.miscMaterial);
    });
  });

  /// F2(2026-06-23 续48)·秘籍首通门控 canonical 谓词。
  /// 此前 item_scroll_ 前缀散写 3 处(enums.fromDefId / shouldSkipScrollDrop / preview);
  /// 抽成单一谓词消除 drift,runtime/preview 共用同一真相。
  group('isTechniqueScrollDefId', () {
    test('item_scroll_* 前缀 → true', () {
      expect(isTechniqueScrollDefId('item_scroll_guan_shan_ba_ji'), true);
      expect(isTechniqueScrollDefId('item_scroll_'), true);
    });

    test('非秘籍 defId → false', () {
      expect(isTechniqueScrollDefId('item_mojianshi'), false);
      expect(isTechniqueScrollDefId('item_silver'), false);
      expect(isTechniqueScrollDefId('weapon_a'), false);
      expect(isTechniqueScrollDefId(''), false);
    });

    test('与 ItemType.fromDefId 一致：scroll 前缀即 techniqueScroll', () {
      const id = 'item_scroll_ye_yu_shi_nian_deng';
      expect(isTechniqueScrollDefId(id), true);
      expect(ItemType.fromDefId(id), ItemType.techniqueScroll);
    });
  });
}
