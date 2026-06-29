import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 第七阶段批三 · 最小拜入立绘题字 overlay。
///
/// 新弟子立绘从右侧滑入 + 放大,下方配「XX 拜入门下」题字。
/// **用户拍板:不显伤害 / 不显 Boss 名 / 不显境界** —— 纯拜入仪式感,与英雄镜头
/// (HeroCameraOverlay)分流,不复用其 [HeroCameraData]。
///
/// 自动在 numbers heroCamera.hold_seconds 秒后消失(复用同一节奏配置),或点击任意
/// 处跳过。纯展示层:不读 BattleState,不修改数值。
class DiscipleJoinOverlay extends StatefulWidget {
  /// 弟子立绘路径(可能指向缺失资源 / 空串 → errorBuilder 兜底)。
  final String portraitPath;

  /// 题字:UiStrings.discipleJoinCaption(name)「XX 拜入门下」。
  final String caption;

  final VoidCallback onDone;

  const DiscipleJoinOverlay({
    super.key,
    required this.portraitPath,
    required this.caption,
    required this.onDone,
  });

  @override
  State<DiscipleJoinOverlay> createState() => _DiscipleJoinOverlayState();
}

class _DiscipleJoinOverlayState extends State<DiscipleJoinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _done = false;
  Timer? _autoTimer;

  double get _slidePx => GameRepository.isLoaded
      ? GameRepository.instance.numbers.heroCamera.portraitSlidePx
      : 48.0;

  double get _scaleFrom => GameRepository.isLoaded
      ? GameRepository.instance.numbers.heroCamera.portraitScaleFrom
      : 0.88;

  double get _holdSeconds => GameRepository.isLoaded
      ? GameRepository.instance.numbers.heroCamera.holdSeconds
      : 3.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _scale = Tween<double>(begin: _scaleFrom, end: 1.0).animate(curve);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();

    // 自动消失:到点调 _finish,守 _done 防重复(对称 once-guard,同 HeroCameraOverlay)。
    _autoTimer = Timer(
      Duration(milliseconds: (_holdSeconds * 1000).round()),
      _finish,
    );
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 径向 vignette 暗角(与 HeroCameraOverlay / victory_overlay 对齐)。
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Color(0x33000000), Color(0xCC000000)],
            stops: [0.45, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(_slide.value * _slidePx, 0),
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: child,
                ),
              ),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 印章符(48×48 + sealGlyph「武」题字,与 HeroCameraOverlay 一致水墨调)。
                Transform.rotate(
                  angle: -0.08,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        WuxiaImage(
                          WuxiaUi.ceremonyRedSeal,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: WuxiaColors.gangMeng,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const Text(
                          UiStrings.sealGlyph,
                          style: TextStyle(
                            color: WuxiaColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 立绘:空串 / asset 缺失 → 纸调兜底方框(survive widget test + 缺图)。
                _Portrait(portraitPath: widget.portraitPath),
                const SizedBox(height: 18),
                // 拜入题字(题字主体,无伤害 / 无 Boss 名 / 无境界)。
                Text(
                  widget.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Color(0xAA000000),
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 立绘渲染:空 portraitPath 直接走纸调兜底;非空时 Image.asset + errorBuilder
/// 兜底(缺图不破布局,守 widget test)。
class _Portrait extends StatelessWidget {
  const _Portrait({required this.portraitPath});

  final String portraitPath;

  static const double _height = 280;

  @override
  Widget build(BuildContext context) {
    if (portraitPath.isEmpty) return _fallback();
    return WuxiaImage(
      portraitPath,
      height: _height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        height: _height,
        width: _height * 0.62,
        decoration: BoxDecoration(
          color: WuxiaColors.paperUnderlay.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: WuxiaColors.inkPanelEdge.withValues(alpha: 0.7),
          ),
        ),
      );
}

/// 弹拜入立绘题字 overlay 并 await 至消失(numbers hold_seconds 或点击跳过)。
/// 拜师 hook 在叙事之后调用。barrier 透明 + 不可点穿,对齐 presentHeroCamera。
Future<void> presentDiscipleJoin(
  BuildContext context, {
  required String portraitPath,
  required String caption,
}) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => DiscipleJoinOverlay(
      portraitPath: portraitPath,
      caption: caption,
      onDone: () => Navigator.of(ctx).maybePop(),
    ),
  );
}
