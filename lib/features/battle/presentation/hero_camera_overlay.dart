import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 英雄镜头数据值对象（第七阶段 批一）。
/// 由 caller 从 TopDamageContributor 组装，纯数据无副作用。
class HeroCameraData {
  final String? portraitPath;
  final String heroName;
  final String realmLabel;
  final String bossName;
  final int topDamage;

  const HeroCameraData({
    required this.portraitPath,
    required this.heroName,
    required this.realmLabel,
    required this.bossName,
    required this.topDamage,
  });
}

/// Boss 首胜英雄镜头 overlay（第七阶段 批一）。
///
/// 本场最高输出角色立绘从右侧滑入+放大，配名号+「击破 {Boss名}」题字。
/// 自动在 [holdSeconds] 秒后消失，或点击任意处跳过。
/// 纯展示层：不读 BattleState，不修改数值。
class HeroCameraOverlay extends StatefulWidget {
  final HeroCameraData data;
  final VoidCallback onDone;

  const HeroCameraOverlay({
    super.key,
    required this.data,
    required this.onDone,
  });

  @override
  State<HeroCameraOverlay> createState() => _HeroCameraOverlayState();
}

class _HeroCameraOverlayState extends State<HeroCameraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _done = false;
  Timer? _autoTimer;

  double get _slidePx =>
      GameRepository.isLoaded
          ? GameRepository.instance.numbers.heroCamera.portraitSlidePx
          : 48.0;

  double get _scaleFrom =>
      GameRepository.isLoaded
          ? GameRepository.instance.numbers.heroCamera.portraitScaleFrom
          : 0.88;

  double get _holdSeconds =>
      GameRepository.isLoaded
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

    // 自动消失：到点调 _finish，守 _done 防重复
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
        // 径向 vignette 暗角（与 victory_overlay / VictorySealFlash 对齐）
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
                // 印章符（复用 ceremony 风格：48×48 + 「勝」题字，与 VictoryOverlay 一致）
                Transform.rotate(
                  angle: -0.08,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
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
                // 立绘（null 或 asset 缺失均 fallback SizedBox.shrink）
                if (widget.data.portraitPath != null)
                  Image.asset(
                    widget.data.portraitPath!,
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                const SizedBox(height: 10),
                // 「本场最强」badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: WuxiaColors.resultHighlight.withValues(alpha: 0.18),
                    border: Border.all(
                      color: WuxiaColors.resultHighlight.withValues(alpha: 0.55),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    UiStrings.heroCameraTopOutput,
                    style: TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 英雄名号（大，金色）
                Text(
                  widget.data.heroName,
                  style: const TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Color(0xCC000000),
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 境界副标（小，次要色）
                Text(
                  widget.data.realmLabel,
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                // 击破题字
                Text(
                  UiStrings.heroCameraDefeated(widget.data.bossName),
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 22,
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
