import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/tier_colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

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

  group('isHighTreasureTier', () {
    test('宝物 / 神物 → true', () {
      expect(isHighTreasureTier(EquipmentTier.baoWu), isTrue);
      expect(isHighTreasureTier(EquipmentTier.shenWu), isTrue);
    });

    test('寻常货~重器 5 阶 → false', () {
      for (final t in const [
        EquipmentTier.xunChang,
        EquipmentTier.xiangYang,
        EquipmentTier.haoJiaHuo,
        EquipmentTier.liQi,
        EquipmentTier.zhongQi,
      ]) {
        expect(isHighTreasureTier(t), isFalse, reason: t.name);
      }
    });
  });

  test('神物浅纸文字色保留品阶色相且达到大标题对比门槛', () {
    final color = paperTierColorForEquipment(EquipmentTier.shenWu);
    expect(color, isNot(WuxiaColors.resultHighlight));
    expect(_contrastRatio(color, WuxiaUi.paper), greaterThanOrEqualTo(3));
  });

  group('treasureGlowColor & treasureSeedColor', () {
    test('爆品梯度色三档互异', () {
      final z = treasureSeedColor(EquipmentTier.zhongQi);
      final b = treasureSeedColor(EquipmentTier.baoWu);
      final s = treasureSeedColor(EquipmentTier.shenWu);
      expect({z, b, s}.length, 3);
    });

    test('glow 与 seed 各 tier 非空', () {
      for (final t in const [
        EquipmentTier.zhongQi,
        EquipmentTier.baoWu,
        EquipmentTier.shenWu,
      ]) {
        expect(treasureGlowColor(t), isNotNull);
        expect(treasureSeedColor(t), isNotNull);
      }
    });
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
