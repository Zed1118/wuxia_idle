import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';

/// 开始闭关题字过场:「闭关」淡入→停→淡出 ~1600ms 自动消失(点击可跳过)。
/// 镜像 battle/presentation/victory_ceremony.dart VictorySealFlash 体例。
class SeclusionEnterCaption extends StatefulWidget {
  final VoidCallback onDone;
  const SeclusionEnterCaption({super.key, required this.onDone});

  @override
  State<SeclusionEnterCaption> createState() => _SeclusionEnterCaptionState();
}

class _SeclusionEnterCaptionState extends State<SeclusionEnterCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
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
              child: const Text(
                UiStrings.seclusionEnterCaption,
                style: TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 88,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  shadows: [
                    Shadow(
                      blurRadius: 14,
                      color: Color(0xCC000000),
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 弹题字过场并 await 至消失(自动 ~1600ms 或点击跳过)。
Future<void> showSeclusionEnterCaption(BuildContext context) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, a, b) =>
        SeclusionEnterCaption(onDone: () => Navigator.of(ctx).pop()),
  );
}
