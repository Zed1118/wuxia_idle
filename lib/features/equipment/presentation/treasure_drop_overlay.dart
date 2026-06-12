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
/// t 时间轴:0-0.16 墨团炸开 / 0.16-0.30 印章盖落 / 0.30 震屏峰 / 0.34+ 属性+典故渐入。
/// 布局(2026-06-12 内容化重设计):墨团氛围 + 图标名居中 + **印章右下角落款**(不遮主体)
///   + 属性行 + 典故金句。拆出便于 widget test + 视觉验收路由。
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
    // 印章: t<0.16 隐藏在上方,0.16→0.30 落下,之后定住(落定后微倾如真盖章)
    final sealT = ((t - 0.16) / 0.14).clamp(0.0, 1.0);
    final sealDy = (1 - sealT) * -90.0;
    final sealRot = (1 - sealT) * -0.4 + 0.10;
    // 震屏: 0.30 附近左右抖
    final shake = (t > 0.28 && t < 0.36)
        ? ((t * 120).floor().isEven ? -5.0 : 5.0)
        : 0.0;
    // 内容(属性+典故)在印章盖定后渐入
    final contentT = ((t - 0.34) / 0.2).clamp(0.0, 1.0);
    final tagline = highlight.tagline;
    return Align(
      alignment: const Alignment(0, -0.12),
      child: Transform.translate(
        offset: Offset(shake, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── crest: 墨团氛围 + 图标名居中 + 印章右下落款 ──
          SizedBox(
            width: 320,
            height: 226,
            child: Stack(children: [
              // 墨团背景(染 tier glow)
              Center(
                child: Transform.scale(
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
              ),
              // 装备图标 + 名(居中清晰)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      width: 64,
                      height: 64,
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
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
                ]),
              ),
              // 印章盖落(绛红 + tier 题字,右下角落款 78px)
              Positioned(
                right: 16,
                bottom: 18,
                child: Transform.translate(
                  offset: Offset(0, sealDy),
                  child: Transform.rotate(
                    angle: sealRot,
                    child: Opacity(
                      opacity: sealT,
                      child: Container(
                        width: 78,
                        height: 78,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: WuxiaColors.sealCrimson,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF7A1F1A), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x80000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2))
                            ]),
                        child: Text(EnumL10n.equipmentTier(highlight.tier),
                            style: const TextStyle(
                                color: Color(0xFFF3E6D0),
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // ── extra: 属性行 + 典故金句(印章定后渐入) ──
          Opacity(
            opacity: contentT,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _AttrChip(label: '攻击', value: highlight.attack, color: seed),
                const SizedBox(width: 14),
                _AttrChip(label: '血量', value: highlight.health, color: seed),
                const SizedBox(width: 14),
                _AttrChip(label: '速度', value: highlight.speed, color: seed),
              ]),
              if (tagline != null && tagline.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFD8C79A),
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          shadows: [Shadow(color: Colors.black, blurRadius: 3)])),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// 爆品属性单项(标签 + 数值)。
class _AttrChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttrChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: '$label ',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
        TextSpan(
            text: '$value',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 3)])),
      ]),
    );
  }
}

/// 爆品动画 overlay(showGeneralDialog 调起,自管 AnimationController)。
/// 动画跑完或点击跳过 → onDone。总时长 1.3s。
class TreasureDropOverlay extends StatefulWidget {
  final TreasureHighlight highlight;
  final VoidCallback onDone;
  const TreasureDropOverlay(
      {super.key, required this.highlight, required this.onDone});

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
    // 动画播完停留在末态(属性+典故全显),不自动消失——等用户轻触才继续,
    // 让"得宝"瞬间能停下来看够典故与属性。
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
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
          builder: (_, _) {
            final t = _ctrl.value;
            return Stack(children: [
              Positioned.fill(
                  child: TreasureDropContent(
                      highlight: widget.highlight, t: t)),
              // 「轻触继续」提示(动画末期淡入,引导停留后手动继续)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: ((t - 0.5) / 0.3).clamp(0.0, 1.0),
                  child: const Text('轻触继续',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                          letterSpacing: 2,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

/// 公共触发:有 ≥门槛爆品且 [gate] 时,播动画(+reward 音)并 await 至结束。
/// 返回 true=播了爆品镜头;false=无爆品(gate false / 未加载 / 无重器)。
/// 主线传 gate=true;塔传 gate=isFirstClear(沿现有 reward gate)。
Future<bool> playTreasureDropIfAny(
    BuildContext context, DropResult drops,
    {required bool gate}) async {
  if (!gate || !GameRepository.isLoaded) return false;
  final minTier = GameRepository.instance.numbers.treasureDrop.minTier;
  final candidates = drops.equipments.map((e) {
    final def = GameRepository.instance.getEquipment(e.defId);
    return TreasureHighlight(
        defId: e.defId,
        name: def.name,
        tier: def.tier,
        slot: def.slot,
        iconPath: def.iconPath,
        attack: e.baseAttack,
        health: e.baseHealth,
        speed: e.baseSpeed,
        tagline: def.tagline);
  }).toList();
  final hl = pickTreasureHighlight(candidates, minTier);
  if (hl == null || !context.mounted) return false;
  SoundManager.instance.playSfx(SfxId.reward);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => TreasureDropOverlay(
        highlight: hl, onDone: () => Navigator.of(ctx).pop()),
  );
  return true;
}
