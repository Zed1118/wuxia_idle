import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
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
