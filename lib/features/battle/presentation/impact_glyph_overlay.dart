import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';

const String _kInkBlobAsset = 'assets/ui/mj/caption_ink_blob.png';

/// 批次 2.4 单字打击题字（「斩/震/断」）。与 [UltimateCaptionOverlay] 并列、
/// 独立 GlobalKey；短停留（870ms 总），区别于全名题字 1800ms。
/// 命令式 show(glyph, isEnemy)，latest-wins。纯表现层，不写 BattleState。
class ImpactGlyphOverlay extends StatefulWidget {
  const ImpactGlyphOverlay({super.key});

  @override
  State<ImpactGlyphOverlay> createState() => ImpactGlyphOverlayState();
}

class ImpactGlyphOverlayState extends State<ImpactGlyphOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _glyph;
  bool _isEnemy = false;

  // 120ms 淡入 + 500ms 停留 + 250ms 淡出 = 870ms 总时长
  static const _fadeInMs = 120;
  static const _holdMs = 500;
  static const _fadeOutMs = 250;
  static const _totalMs = _fadeInMs + _holdMs + _fadeOutMs;
  // 归一化时间断点，由上面 ms 派生（防注释/代码漂移）。
  static const _fadeInEnd = _fadeInMs / _totalMs;
  static const _fadeOutStart = (_fadeInMs + _holdMs) / _totalMs;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _glyph = null);
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 触发单字题字。覆盖语义：重置动画 + 换字符。
  void show(String glyph, {required bool isEnemy}) {
    setState(() {
      _glyph = glyph;
      _isEnemy = isEnemy;
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
    if (_glyph == null) return const SizedBox.shrink();
    final accent =
        _isEnemy ? WuxiaColors.gangMeng : WuxiaColors.resultHighlight;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: SizedBox(
              width: 200,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                      child: WuxiaImage(
                        _kInkBlobAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(_glyph!, style: _glyphStyle(stroke: true)),
                  Text(_glyph!, style: _glyphStyle(stroke: false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _glyphStyle({required bool stroke}) => TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: stroke ? null : WuxiaUi.paper,
        foreground: stroke
            ? (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = const Color(0xCC0A0A0A))
            : null,
      );
}
