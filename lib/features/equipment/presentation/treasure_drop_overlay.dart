import 'package:flutter/material.dart';
import '../../../data/game_repository.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/widgets/equipment_glyph.dart';
import '../../battle/domain/enum_localizations.dart';
import '../application/drop_service.dart';
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

/// 爆品动画 overlay(showGeneralDialog 调起,自管 AnimationController)。
/// 动画跑完或点击跳过 → onDone。总时长 1.3s。
class TreasureDropOverlay extends StatefulWidget {
  final TreasureHighlight highlight;
  final VoidCallback onDone;
  const TreasureDropOverlay({super.key, required this.highlight, required this.onDone});

  @override
  State<TreasureDropOverlay> createState() => _TreasureDropOverlayState();
}

class _TreasureDropOverlayState extends State<TreasureDropOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish, // 点击跳过
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xB3000000), // 半透明暗幕
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => TreasureDropContent(highlight: widget.highlight, t: _ctrl.value),
        ),
      ),
    );
  }
}

/// 公共触发:有 ≥门槛爆品且 [gate] 时,播动画(+reward 音)并 await 至结束。
/// 主线传 gate=true;塔传 gate=isFirstClear(沿现有 reward gate)。
Future<void> playTreasureDropIfAny(
    BuildContext context, DropResult drops, {required bool gate}) async {
  if (!gate || !GameRepository.isLoaded) return;
  final minTier = GameRepository.instance.numbers.treasureDrop.minTier;
  final candidates = drops.equipments.map((e) {
    final def = GameRepository.instance.getEquipment(e.defId);
    return TreasureHighlight(
        defId: e.defId, name: def.name, tier: def.tier,
        slot: def.slot, iconPath: def.iconPath);
  }).toList();
  final hl = pickTreasureHighlight(candidates, minTier);
  if (hl == null || !context.mounted) return;
  SoundManager.instance.playSfx(SfxId.reward);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => TreasureDropOverlay(
        highlight: hl, onDone: () => Navigator.of(ctx).pop()),
  );
}
