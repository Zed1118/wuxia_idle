import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/ui/theme/colors.dart';
import 'package:wuxia_idle/ui/theme/tier_colors.dart';

void main() {
  group('tierColorForEquipment', () {
    test('xunChang maps to textMuted', () {
      expect(
        tierColorForEquipment(EquipmentTier.xunChang),
        WuxiaColors.textMuted,
      );
    });

    test('xiangYang maps to textSecondary', () {
      expect(
        tierColorForEquipment(EquipmentTier.xiangYang),
        WuxiaColors.textSecondary,
      );
    });

    test('haoJiaHuo maps to internalForce', () {
      expect(
        tierColorForEquipment(EquipmentTier.haoJiaHuo),
        WuxiaColors.internalForce,
      );
    });

    test('liQi maps to lingQiao', () {
      expect(tierColorForEquipment(EquipmentTier.liQi), WuxiaColors.lingQiao);
    });

    test('zhongQi maps to gangMeng', () {
      expect(
        tierColorForEquipment(EquipmentTier.zhongQi),
        WuxiaColors.gangMeng,
      );
    });

    test('baoWu maps to yinRou', () {
      expect(tierColorForEquipment(EquipmentTier.baoWu), WuxiaColors.yinRou);
    });

    test('shenWu maps to resultHighlight', () {
      expect(
        tierColorForEquipment(EquipmentTier.shenWu),
        WuxiaColors.resultHighlight,
      );
    });
  });
}
