import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/equipment_glyph.dart';
import '../../battle/domain/enum_localizations.dart';
import '../domain/treasure_highlight.dart';

const String _kInkBlobAsset = 'assets/ui/mj/caption_ink_blob.png';

/// 爆品展示静态内容(无动画;动画值 [t] 0→1 由 [TreasureDropOverlay] 驱动)。
/// t 时间轴:0-0.16 墨团炸开 / 0.16-0.30 印章盖落 / 0.30 震屏峰 / 0.30+ 保持。
/// 拆出便于 widget test + 视觉验收路由。
class TreasureDropContent extends StatelessWidget {
  final TreasureHighlight highlight;
  final double t;
  const TreasureDropContent({super.key, required this.highlight, this.t = 1.0});

  @override
  Widget build(BuildContext context) {
    final glow = treasureGlowColor(highlight.tier);
    final seed = treasureSeedColor(highlight.tier);
    // 墨团 scale: 0.2→1.15→1(炸开回弹)
    final blobScale = t < 0.16
        ? (0.2 + (t / 0.16) * 0.95)
        : (1.15 - ((t - 0.16).clamp(0.0, 0.14) / 0.14) * 0.15);
    // 印章: t<0.16 隐藏在上方,0.16→0.30 落下,之后定住
    final sealT = ((t - 0.16) / 0.14).clamp(0.0, 1.0);
    final sealDy = (1 - sealT) * -90.0;
    final sealRot = (1 - sealT) * -0.4;
    // 震屏: 0.30 附近左右抖
    final shake = (t > 0.28 && t < 0.36)
        ? ((t * 120).floor().isEven ? -5.0 : 5.0)
        : 0.0;
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Transform.translate(
        offset: Offset(shake, 0),
        child: SizedBox(
          width: 320,
          height: 240,
          child: Stack(alignment: Alignment.center, children: [
            // 墨团背景(染 tier glow)
            Transform.scale(
              scale: blobScale.clamp(0.0, 1.2),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(glow, BlendMode.srcIn),
                child: Image.asset(
                  _kInkBlobAsset,
                  width: 260,
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                      width: 240,
                      height: 170,
                      decoration: BoxDecoration(
                          color: glow,
                          borderRadius: BorderRadius.circular(120))),
                ),
              ),
            ),
            // 装备图标 + 名
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.asset(
                    highlight.iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        EquipGlyph(tierColor: seed, slot: highlight.slot),
                  )),
              const SizedBox(height: 4),
              Text(highlight.name,
                  style: const TextStyle(
                      color: WuxiaColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 6)
                      ])),
            ]),
            // 印章盖落(绛红 + tier 题字)
            Transform.translate(
              offset: Offset(0, sealDy),
              child: Transform.rotate(
                angle: sealRot,
                child: Opacity(
                  opacity: sealT,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: WuxiaColors.sealCrimson,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: const Color(0xFF7A1F1A), width: 2)),
                    child: Text(EnumL10n.equipmentTier(highlight.tier),
                        style: const TextStyle(
                            color: Color(0xFFF3E6D0),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
