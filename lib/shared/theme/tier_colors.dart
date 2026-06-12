import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import 'colors.dart';

/// Shared tier color mapping for equipment UI.
Color tierColorForEquipment(EquipmentTier tier) {
  return switch (tier) {
    EquipmentTier.xunChang => WuxiaColors.textMuted,
    EquipmentTier.xiangYang => WuxiaColors.textSecondary,
    EquipmentTier.haoJiaHuo => WuxiaColors.internalForce,
    EquipmentTier.liQi => WuxiaColors.lingQiao,
    EquipmentTier.zhongQi => WuxiaColors.gangMeng,
    EquipmentTier.baoWu => WuxiaColors.yinRou,
    EquipmentTier.shenWu => WuxiaColors.resultHighlight,
  };
}

/// 高阶珍品(宝物 / 神物)。详情页给更强边框 + 题字(出版美术 §5.4
/// 「神物、宝物拥有更强边框和题字」),区别寻常货的朴素 tier 色底边。
bool isHighTreasureTier(EquipmentTier tier) =>
    tier == EquipmentTier.baoWu || tier == EquipmentTier.shenWu;

/// 爆品动画墨团光晕色(半透明,radial gradient 中心)。重器青铜→宝物紫→神物金。
Color treasureGlowColor(EquipmentTier tier) => switch (tier) {
      EquipmentTier.shenWu => const Color(0x77F0D878),
      EquipmentTier.baoWu => const Color(0x559A63C8),
      _ => const Color(0x55C89B3C), // 重器及兜底:青铜赭金
    };

/// 爆品动画墨点/图标光色(不透明实色)。
Color treasureSeedColor(EquipmentTier tier) => switch (tier) {
      EquipmentTier.shenWu => const Color(0xFFF0D878),
      EquipmentTier.baoWu => const Color(0xFFB886E6),
      _ => const Color(0xFFC89B3C),
    };
