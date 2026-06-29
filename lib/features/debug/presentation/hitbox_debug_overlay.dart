import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';

/// Debug-only hitbox visualizer for visual acceptance routes.
///
/// Enable with `--dart-define=HITBOX_DEBUG=true`. The overlay walks the render
/// tree after layout and paints translucent rectangles over likely interactive
/// render boxes. Release/profile builds ignore the overlay even if the define is
/// present, so this cannot leak into the shipped desktop build.
class HitboxDebugOverlay extends StatefulWidget {
  const HitboxDebugOverlay({super.key, required this.child});

  final Widget child;

  static const bool enabledFromEnv = bool.fromEnvironment('HITBOX_DEBUG');

  static Widget maybeWrap(Widget child) {
    if (!kDebugMode || !enabledFromEnv) return child;
    return HitboxDebugOverlay(child: child);
  }

  @override
  State<HitboxDebugOverlay> createState() => _HitboxDebugOverlayState();
}

class _HitboxDebugOverlayState extends State<HitboxDebugOverlay> {
  List<_HitboxMark> _marks = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMarks());
  }

  @override
  void didUpdateWidget(covariant HitboxDebugOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMarks());
  }

  void _refreshMarks() {
    if (!mounted) return;
    final root = context.findRenderObject();
    if (root == null) return;

    final marks = <_HitboxMark>[];
    void visit(RenderObject object) {
      if (object is RenderBox && object.attached && _isInteractive(object)) {
        final rect = MatrixUtils.transformRect(
          object.getTransformTo(null),
          object.paintBounds,
        );
        if (_isUsefulRect(rect)) {
          marks.add(_HitboxMark(rect, object.runtimeType.toString()));
        }
      }
      object.visitChildren(visit);
    }

    visit(root);
    if (listEquals(_marks, marks)) return;
    setState(() => _marks = marks);
  }

  bool _isInteractive(RenderBox box) {
    final type = box.runtimeType.toString();
    return type.contains('RenderSemanticsGestureHandler') ||
        type.contains('RenderPointerListener') ||
        type.contains('RenderMouseRegion') ||
        type.contains('RenderTapRegion');
  }

  bool _isUsefulRect(Rect rect) {
    if (rect.isEmpty || rect.width < 8 || rect.height < 8) return false;
    if (!rect.left.isFinite || !rect.top.isFinite) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(
            painter: _HitboxPainter(_marks),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

@immutable
class _HitboxMark {
  const _HitboxMark(this.rect, this.kind);

  final Rect rect;
  final String kind;

  @override
  bool operator ==(Object other) {
    return other is _HitboxMark && other.rect == rect && other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(rect, kind);
}

class _HitboxPainter extends CustomPainter {
  const _HitboxPainter(this.marks);

  final List<_HitboxMark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = WuxiaUi.gold.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = WuxiaUi.jiang.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final labelStyle = TextStyle(
      color: WuxiaUi.ink,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      backgroundColor: WuxiaUi.paper.withValues(alpha: 0.78),
    );

    for (final mark in marks) {
      final rect = mark.rect.intersect(Offset.zero & size);
      if (rect.isEmpty) continue;
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }

    final summary = TextPainter(
      text: TextSpan(
        text: UiStrings.hitboxDebugSummary(marks.length),
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    summary.paint(canvas, const Offset(12, 12));
  }

  @override
  bool shouldRepaint(covariant _HitboxPainter oldDelegate) {
    return oldDelegate.marks != marks;
  }
}
