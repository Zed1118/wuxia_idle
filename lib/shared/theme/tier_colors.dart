import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import 'colors.dart';
import 'wuxia_tokens.dart';

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

/// 浅宣纸底（LightPaperPanel / PaperDialog）上可读的 tier 色。
/// [tierColorForEquipment] 的低阶灰(textMuted/textSecondary)与高阶金(resultHighlight
/// #E8C547)叠浅纸(panelFill ≈ #E9DCC0)对比 ~1.1–3:1 近隐形；此处把文字用 tier 色
/// 统一改为墨向混合的可读版：低阶直接取纸底墨色 token，高阶及其余向 [WuxiaUi.ink]
/// 混合 34% 变深。**仅用于浅底文字着色**；tier 金框/装饰/深底文字仍用
/// [tierColorForEquipment]。原私有实现出自 stage_victory_dialog，Tier2 收口抽共享。
Color paperTierColorForEquipment(EquipmentTier tier) {
  return switch (tier) {
    EquipmentTier.xunChang => WuxiaUi.ink2,
    EquipmentTier.xiangYang => WuxiaUi.muted,
    EquipmentTier.shenWu => paperReadableTierColor(WuxiaUi.gold),
    _ => paperReadableTierColor(tierColorForEquipment(tier)),
  };
}

/// 把任意 tier 色向纸底墨色 [WuxiaUi.ink] 混合 34%，压低亮度换取浅底可读。
Color paperReadableTierColor(Color color) {
  return Color.lerp(color, WuxiaUi.ink, 0.34)!;
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
