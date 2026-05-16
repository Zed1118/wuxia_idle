import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';

/// W16 GDD §12.4 节日活动：[EnumL10n.festival] 8 映射单测（W17 扩 chuXi/qingMingJie）。
///
/// 对齐 enum_localizations_item_type_test 体例：8 节日各 1 case + 1 红线
/// (所有 Festival enum 值都有非空映射)。
void main() {
  group('EnumL10n.festival 8 映射', () {
    test('chuXi → 除夕', () {
      expect(EnumL10n.festival(Festival.chuXi), '除夕');
    });

    test('chunJie → 春节', () {
      expect(EnumL10n.festival(Festival.chunJie), '春节');
    });

    test('yuanXiao → 元宵', () {
      expect(EnumL10n.festival(Festival.yuanXiao), '元宵');
    });

    test('qingMingJie → 清明', () {
      expect(EnumL10n.festival(Festival.qingMingJie), '清明');
    });

    test('duanWu → 端午', () {
      expect(EnumL10n.festival(Festival.duanWu), '端午');
    });

    test('qiXi → 七夕', () {
      expect(EnumL10n.festival(Festival.qiXi), '七夕');
    });

    test('zhongQiu → 中秋', () {
      expect(EnumL10n.festival(Festival.zhongQiu), '中秋');
    });

    test('chongYang → 重阳', () {
      expect(EnumL10n.festival(Festival.chongYang), '重阳');
    });

    test('所有 Festival enum 值都有非空映射(全覆盖红线)', () {
      for (final f in Festival.values) {
        expect(
          EnumL10n.festival(f),
          isNotEmpty,
          reason: '$f 缺少中文映射',
        );
      }
    });
  });
}
