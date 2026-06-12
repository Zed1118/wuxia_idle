import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';

/// 简版「勝」淡入淡出(时序重排 spec 2026-06-12)。
///
/// 普通/无掉落档的胜利仪式:印章符 + 「勝」题字,淡入→停→淡出 ~800ms 自动消失
/// (不拦点击 / 无统计 / 无按钮)。爆品档不走此 widget,走 TreasureDropOverlay。
/// 点击可提前跳过。
class VictorySealFlash extends StatefulWidget {
  final VoidCallback onDone;
  const VictorySealFlash({super.key, required this.onDone});

  @override
  State<VictorySealFlash> createState() => _VictorySealFlashState();
}

class _VictorySealFlashState extends State<VictorySealFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _opacity(double t) {
    if (t < 0.3) return (t / 0.3).clamp(0.0, 1.0);
    if (t > 0.7) return (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Opacity(
            opacity: _opacity(_ctrl.value),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Color(0x33000000), Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            errorBuilder: (_, e, s) => DecoratedBox(
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
                  const SizedBox(height: 16),
                  const Text(
                    UiStrings.victoryTitle,
                    style: TextStyle(
                      color: WuxiaColors.resultHighlight,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Color(0xCC000000),
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 弹简版勝 overlay 并 await 至消失(自动 ~800ms 或点击跳过)。
Future<void> showVictorySealFlash(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, a, b) =>
        VictorySealFlash(onDone: () => Navigator.of(ctx).pop()),
  );
}
