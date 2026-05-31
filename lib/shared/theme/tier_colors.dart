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
