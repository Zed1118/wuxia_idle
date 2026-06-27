import 'package:flutter/material.dart';

import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';

const String _kInkBlobAsset = 'assets/ui/mj/caption_ink_blob.png';

/// 出版美术 B2:出招是否该弹大招题字(ultimate 或人剑合一)。纯函数便于单测。
bool isUltimateCaptionSkill(SkillDef? skill) =>
    skill != null &&
    (skill.type == SkillType.ultimate || skill.type == SkillType.jointSkill);

/// 大招题字视觉(纯展示,无动画)。供动画 overlay 与视觉验收路由复用。
/// 玩家方暖金、敌方绛红，水墨大字 + 墨色描边。
/// [fontSize] 默认 56；暴击峰值时传 captionPeakSize(68)。
/// [glowBlur] 默认 0(无辉光)；暴击时传 captionGlowBlur。
class UltimateCaptionContent extends StatelessWidget {
  final String name;
  final bool isEnemy;
  final double fontSize;
  final double glowBlur;

  const UltimateCaptionContent({
    super.key,
    required this.name,
    required this.isEnemy,
    this.fontSize = 56,
    this.glowBlur = 0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isEnemy ? WuxiaColors.gangMeng : WuxiaColors.resultHighlight;
    final glowShadows = glowBlur > 0
        ? [Shadow(color: accent, blurRadius: glowBlur)]
        : null;
    return Align(
      alignment: const Alignment(0, -0.45),
      child: SizedBox(
        width: 340,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                child: Image.asset(
                  _kInkBlobAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            Text(name, style: _captionStyle(stroke: true)),
            Text(name, style: _captionStyle(stroke: false, shadows: glowShadows)),
          ],
        ),
      ),
    );
  }

  TextStyle _captionStyle({required bool stroke, List<Shadow>? shadows}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
        color: stroke ? null : WuxiaUi.paper,
        foreground: stroke
            ? (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = const Color(0xCC0A0A0A))
            : null,
        shadows: shadows,
      );
}

/// 非阻塞大招题字 overlay:Stack 顶层,[show] 触发淡入→停留→淡出,自管生命周期。
/// 1.2s 内再 show 覆盖前者(单实例,latest wins)。idle 时渲染 SizedBox.shrink。
class UltimateCaptionOverlay extends StatefulWidget {
  const UltimateCaptionOverlay({super.key});

  @override
  State<UltimateCaptionOverlay> createState() => UltimateCaptionOverlayState();
}

class UltimateCaptionOverlayState extends State<UltimateCaptionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _name;
  bool _isEnemy = false;
  double _fontSize = 56;
  double _glowBlur = 0;

  // 250ms 淡入 + 1200ms 停留 + 350ms 淡出 = 1800ms 总时长
  static const _fadeInMs = 250;
  static const _holdMs = 1200;
  static const _fadeOutMs = 350;
  static const _totalMs = _fadeInMs + _holdMs + _fadeOutMs;
  static const _total = Duration(milliseconds: _totalMs);
  // 归一化时间断点,由上面 ms 派生(防注释/代码漂移)。
  static const _fadeInEnd = _fadeInMs / _totalMs;
  static const _fadeOutStart = (_fadeInMs + _holdMs) / _totalMs;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _name = null);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 触发题字。覆盖语义:重置动画 + 换文字。
  /// [fontSize] 默认 56；暴击峰值时传 captionPeakSize。
  /// [glowBlur] 默认 0；暴击时传 captionGlowBlur 产生辉光效果。
  void show(String name,
      {required bool isEnemy, double fontSize = 56, double glowBlur = 0}) {
    setState(() {
      _name = name;
      _isEnemy = isEnemy;
      _fontSize = fontSize;
      _glowBlur = glowBlur;
    });
    _ctrl.forward(from: 0.0);
  }

  // 淡入(0→_fadeInEnd:opacity 0→1) / 停留(_fadeInEnd→_fadeOutStart:1) /
  // 淡出(_fadeOutStart→1:1→0)。断点全由 ms 派生。
  double get _opacity {
    final t = _ctrl.value;
    if (t < _fadeInEnd) return t / _fadeInEnd;
    if (t > _fadeOutStart) return (1.0 - t) / (1.0 - _fadeOutStart);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: UltimateCaptionContent(
            name: _name!,
            isEnemy: _isEnemy,
            fontSize: _fontSize,
            glowBlur: _glowBlur,
          ),
        ),
      ),
    );
  }
}
