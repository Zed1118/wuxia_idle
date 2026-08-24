import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';

/// Debug-only water-ink VFX vertical slices. Nothing in this file participates
/// in combat resolution or production routing.
enum InkVfxSlice { light, interrupt, domain }

abstract final class InkVfxDemoTokens {
  static const Duration lightDuration = Duration(milliseconds: 720);
  static const Duration interruptDuration = Duration(milliseconds: 980);
  static const Duration domainDuration = Duration(milliseconds: 1420);
  static const double stageCornerRadius = 10;
  static const double stageBorderWidth = 1.4;
  static const double controlsMaxWidth = 760;
  static const double headerMaxWidth = 450;
  static const double actorHeightFraction = 0.58;
  static const double actorMaxHeight = 430;
  static const double enemyHeightFraction = 0.52;
  static const double enemyMaxHeight = 382;
  static const double stageBottomInset = 70;

  static Duration durationFor(InkVfxSlice slice) => switch (slice) {
    InkVfxSlice.light => lightDuration,
    InkVfxSlice.interrupt => interruptDuration,
    InkVfxSlice.domain => domainDuration,
  };
}

class InkVfxVerticalSliceDemo extends StatefulWidget {
  const InkVfxVerticalSliceDemo({
    super.key,
    required this.initialSlice,
    this.autoReplay = true,
  });

  final InkVfxSlice initialSlice;
  final bool autoReplay;

  @override
  State<InkVfxVerticalSliceDemo> createState() =>
      _InkVfxVerticalSliceDemoState();
}

class _InkVfxVerticalSliceDemoState extends State<InkVfxVerticalSliceDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late InkVfxSlice _slice;

  @override
  void initState() {
    super.initState();
    _slice = widget.initialSlice;
    _controller = AnimationController(
      vsync: this,
      duration: InkVfxDemoTokens.durationFor(_slice),
    );
    _play();
  }

  @override
  void didUpdateWidget(covariant InkVfxVerticalSliceDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlice != widget.initialSlice) {
      _slice = widget.initialSlice;
      _play();
    }
  }

  void _play() {
    _controller.duration = InkVfxDemoTokens.durationFor(_slice);
    if (widget.autoReplay) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _select(InkVfxSlice slice) {
    if (_slice != slice) setState(() => _slice = slice);
    _play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('ink_vfx_vertical_slice_demo'),
      backgroundColor: const Color(0xFF171A1C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                _buildStage(_timelineProgress(_controller.value)),
          ),
        ),
      ),
    );
  }

  double _timelineProgress(double raw) {
    final peak = switch (_slice) {
      InkVfxSlice.light => 0.42,
      InkVfxSlice.interrupt => 0.50,
      InkVfxSlice.domain => 0.56,
    };
    if (raw <= 0.48) {
      return peak * Curves.easeOutCubic.transform(raw / 0.48);
    }
    if (raw <= 0.84) return peak;
    return peak + (1 - peak) * ((raw - 0.84) / 0.16);
  }

  Widget _buildStage(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            InkVfxDemoTokens.stageCornerRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: WuxiaUi.gold.withValues(alpha: 0.42),
                width: InkVfxDemoTokens.stageBorderWidth,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _InkRealmBackdrop(slice: _slice, progress: progress),
                _combatants(constraints.biggest, progress),
                IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: ValueKey('ink_vfx_effect_${_slice.name}'),
                      painter: InkVfxEffectPainter(
                        slice: _slice,
                        progress: progress,
                      ),
                    ),
                  ),
                ),
                _calligraphy(progress),
                _header(),
                _controls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _combatants(Size size, double progress) {
    final actorHeight = math.min(
      size.height * InkVfxDemoTokens.actorHeightFraction,
      InkVfxDemoTokens.actorMaxHeight,
    );
    final enemyHeight = math.min(
      size.height * InkVfxDemoTokens.enemyHeightFraction,
      InkVfxDemoTokens.enemyMaxHeight,
    );
    final impact = _segment(progress, 0.20, 0.48);
    final settle = 1 - _segment(progress, 0.55, 0.92);
    final actorLunge = switch (_slice) {
      InkVfxSlice.light => 38 * Curves.easeOutCubic.transform(impact) * settle,
      InkVfxSlice.interrupt => 22 * Curves.easeOut.transform(impact) * settle,
      InkVfxSlice.domain => 12 * Curves.easeOut.transform(impact) * settle,
    };
    final targetHit = switch (_slice) {
      InkVfxSlice.light => 14 * impact * settle,
      InkVfxSlice.interrupt => 22 * impact * settle,
      InkVfxSlice.domain => 30 * impact * settle,
    };
    final domainFade = _slice == InkVfxSlice.domain
        ? 1 - 0.34 * _segment(progress, 0.0, 0.28)
        : 1.0;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            key: const ValueKey('ink_vfx_actor'),
            left: size.width * 0.17 + actorLunge,
            bottom: InkVfxDemoTokens.stageBottomInset,
            height: actorHeight,
            child: _standee(
              'assets/characters/battle_founder_v2.png',
              opacity: domainFade,
            ),
          ),
          Positioned(
            key: const ValueKey('ink_vfx_enemy_primary'),
            right: size.width * 0.19 - targetHit,
            bottom: InkVfxDemoTokens.stageBottomInset - 4,
            height: enemyHeight,
            child: Transform.scale(
              scaleX: -1,
              child: _standee(
                'assets/enemies/battle_bandit_blade.png',
                opacity: domainFade,
              ),
            ),
          ),
          if (_slice == InkVfxSlice.domain)
            Positioned(
              key: const ValueKey('ink_vfx_enemy_secondary'),
              right: size.width * 0.06 - targetHit * 0.65,
              bottom: InkVfxDemoTokens.stageBottomInset + 14,
              height: enemyHeight * 0.88,
              child: Transform.scale(
                scaleX: -1,
                child: _standee(
                  'assets/enemies/battle_bandit_archer.png',
                  opacity: domainFade * 0.88,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _standee(String asset, {required double opacity}) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: WuxiaImage(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _calligraphy(double progress) {
    final visible = switch (_slice) {
      InkVfxSlice.light => 0.0,
      InkVfxSlice.interrupt =>
        _segment(progress, 0.28, 0.42) * (1 - _segment(progress, 0.70, 1.0)),
      InkVfxSlice.domain =>
        _segment(progress, 0.12, 0.28) * (1 - _segment(progress, 0.72, 1.0)),
    };
    if (visible <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: _slice == InkVfxSlice.interrupt
            ? const Alignment(0.38, -0.08)
            : const Alignment(-0.02, -0.22),
        child: Opacity(
          opacity: (visible * (_slice == InkVfxSlice.interrupt ? 0.78 : 0.48))
              .clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: _slice == InkVfxSlice.interrupt ? -0.08 : 0.03,
            child: Text(
              _slice == InkVfxSlice.interrupt
                  ? UiStrings.inkVfxBreakGlyph
                  : UiStrings.inkVfxDomainGlyph,
              style: TextStyle(
                color: _slice == InkVfxSlice.interrupt
                    ? WuxiaUi.jiang
                    : WuxiaUi.ink,
                fontSize: _slice == InkVfxSlice.interrupt ? 82 : 104,
                height: 1,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: WuxiaUi.paper, blurRadius: 6),
                  Shadow(color: Color(0x66000000), blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final (title, hint, rank) = switch (_slice) {
      InkVfxSlice.light => (
        UiStrings.inkVfxLightTitle,
        UiStrings.inkVfxLightHint,
        UiStrings.inkVfxLightRank,
      ),
      InkVfxSlice.interrupt => (
        UiStrings.inkVfxInterruptTitle,
        UiStrings.inkVfxInterruptHint,
        UiStrings.inkVfxInterruptRank,
      ),
      InkVfxSlice.domain => (
        UiStrings.inkVfxDomainTitle,
        UiStrings.inkVfxDomainHint,
        UiStrings.inkVfxDomainRank,
      ),
    };
    return Positioned(
      left: 22,
      top: 18,
      width: InkVfxDemoTokens.headerMaxWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: 0.86),
          border: Border(
            left: const BorderSide(color: WuxiaUi.jiang, width: 4),
            bottom: BorderSide(color: WuxiaUi.ink.withValues(alpha: 0.22)),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x42000000), blurRadius: 14),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                UiStrings.inkVfxDemoTitle,
                style: TextStyle(
                  color: WuxiaUi.ink2,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: WuxiaUi.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    rank,
                    style: const TextStyle(
                      color: WuxiaUi.jiang,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaUi.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 18,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: InkVfxDemoTokens.controlsMaxWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD91B1E20),
              border: Border.all(color: WuxiaUi.paper.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _selector(
                    key: const ValueKey('ink_vfx_selector_light'),
                    slice: InkVfxSlice.light,
                    label: UiStrings.inkVfxLightTitle,
                  ),
                  const SizedBox(width: 8),
                  _selector(
                    key: const ValueKey('ink_vfx_selector_interrupt'),
                    slice: InkVfxSlice.interrupt,
                    label: UiStrings.inkVfxInterruptTitle,
                  ),
                  const SizedBox(width: 8),
                  _selector(
                    key: const ValueKey('ink_vfx_selector_domain'),
                    slice: InkVfxSlice.domain,
                    label: UiStrings.inkVfxDomainTitle,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    key: const ValueKey('ink_vfx_replay'),
                    width: 92,
                    child: PlaqueButton(
                      label: UiStrings.inkVfxReplay,
                      onTap: _play,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selector({
    required Key key,
    required InkVfxSlice slice,
    required String label,
  }) {
    return Expanded(
      key: key,
      child: PlaqueButton(
        label: label,
        primary: _slice == slice,
        onTap: () => _select(slice),
      ),
    );
  }
}

class _InkRealmBackdrop extends StatelessWidget {
  const _InkRealmBackdrop({required this.slice, required this.progress});

  final InkVfxSlice slice;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final domain = slice == InkVfxSlice.domain
        ? _segment(progress, 0.0, 0.28)
        : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color.lerp(
              const Color(0xFFD6D0C2),
              const Color(0xFFF0EEE8),
              domain,
            )!,
            BlendMode.modulate,
          ),
          child: WuxiaImage(
            'assets/scenes/battle_innerrealm_cool_v2.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFFD8D3C6)),
          ),
        ),
        ColoredBox(
          color: Color.lerp(
            const Color(0x1612181B),
            const Color(0x24F5F1E6),
            domain,
          )!,
        ),
        CustomPaint(painter: _PaperGrainPainter(domain: domain)),
      ],
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({required this.domain});

  final double domain;

  @override
  void paint(Canvas canvas, Size size) {
    final fiber = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.022 + domain * 0.025)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 54; i++) {
      final x = ((i * 97) % 541) / 541 * size.width;
      final y = ((i * 53) % 337) / 337 * size.height;
      final length = 8.0 + (i % 7) * 4.0;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + length, y + ((i % 3) - 1) * 1.8),
        fiber,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) =>
      oldDelegate.domain != domain;
}

/// Public only so widget tests can verify that replay resets the real animation
/// frame rather than merely swapping a decorative child.
class InkVfxEffectPainter extends CustomPainter {
  const InkVfxEffectPainter({required this.slice, required this.progress});

  final InkVfxSlice slice;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (slice) {
      case InkVfxSlice.light:
        _paintLight(canvas, size);
      case InkVfxSlice.interrupt:
        _paintInterrupt(canvas, size);
      case InkVfxSlice.domain:
        _paintDomain(canvas, size);
    }
  }

  void _paintLight(Canvas canvas, Size size) {
    final reveal = _segment(progress, 0.10, 0.42);
    final fade = 1 - _segment(progress, 0.58, 1.0);
    final source = Offset(size.width * 0.34, size.height * 0.62);
    final target = Offset(size.width * 0.69, size.height * 0.56);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = WuxiaUi.ink.withValues(alpha: 0.86 * fade);

    for (var i = 0; i < 7; i++) {
      final lane = (i - 3) * 7.0;
      final path = Path()
        ..moveTo(source.dx - 34 - i * 6, source.dy + lane)
        ..quadraticBezierTo(
          size.width * 0.50,
          source.dy - 22 + lane * 0.35,
          target.dx + 18,
          target.dy + lane * 0.18,
        );
      ink.strokeWidth = i == 3 ? 5.5 : 1.2 + (i % 3) * 0.7;
      ink.color = WuxiaUi.ink.withValues(alpha: (i == 3 ? 0.62 : 0.22) * fade);
      canvas.drawPath(_revealed(path, reveal), ink);
    }

    final slash = Path()
      ..moveTo(target.dx - 100, target.dy + 92)
      ..cubicTo(
        target.dx - 70,
        target.dy + 24,
        target.dx + 18,
        target.dy - 70,
        target.dx + 78,
        target.dy - 96,
      );
    _drawDryBrush(
      canvas,
      _revealed(slash, reveal),
      color: WuxiaUi.ink,
      width: 15,
      alpha: 0.90 * fade,
    );

    _drawSplats(
      canvas,
      target,
      count: 10,
      travel: 52 * reveal,
      alpha: fade,
      color: WuxiaUi.ink,
    );
    canvas.drawCircle(
      target,
      5 + 10 * reveal,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.76 * fade),
    );
  }

  void _paintInterrupt(Canvas canvas, Size size) {
    final charge = _segment(progress, 0.0, 0.30);
    final breakReveal = _segment(progress, 0.24, 0.50);
    final fade = 1 - _segment(progress, 0.72, 1.0);
    final target = Offset(size.width * 0.69, size.height * 0.53);

    final chargePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = WuxiaUi.jiang.withValues(alpha: 0.48 * (1 - breakReveal));
    for (var i = 0; i < 3; i++) {
      final radius = 46.0 + i * 20 + charge * 12;
      canvas.drawArc(
        Rect.fromCircle(center: target, radius: radius),
        -math.pi * 0.84 + i * 0.3,
        math.pi * (1.18 + charge * 0.28),
        false,
        chargePaint..strokeWidth = 3.5 - i * 0.7,
      );
    }

    final vertical = Path()
      ..moveTo(target.dx + 16, size.height * 0.22)
      ..cubicTo(
        target.dx - 8,
        size.height * 0.38,
        target.dx + 8,
        size.height * 0.64,
        target.dx - 24,
        size.height * 0.78,
      );
    _drawDryBrush(
      canvas,
      _revealed(vertical, breakReveal),
      color: WuxiaUi.ink,
      width: 20,
      alpha: 0.94 * fade,
    );

    for (var i = 0; i < 3; i++) {
      final fracture = Path()
        ..moveTo(target.dx - 9 + i * 12, target.dy - 72 + i * 8)
        ..quadraticBezierTo(
          target.dx - 42 + i * 18,
          target.dy - 12,
          target.dx - 54 + i * 46,
          target.dy + 72 - i * 10,
        );
      canvas.drawPath(
        _revealed(fracture, breakReveal),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2 + i
          ..color = WuxiaUi.ink.withValues(alpha: (0.34 + i * 0.12) * fade),
      );
    }

    final cross = Path()
      ..moveTo(target.dx - 118, target.dy + 16)
      ..quadraticBezierTo(
        target.dx,
        target.dy - 28,
        target.dx + 112,
        target.dy + 8,
      );
    _drawDryBrush(
      canvas,
      _revealed(cross, breakReveal),
      color: WuxiaUi.jiang,
      width: 8,
      alpha: 0.78 * fade,
    );

    final shock = Curves.easeOut.transform(breakReveal);
    canvas.drawCircle(
      target,
      22 + 116 * shock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = WuxiaUi.gold.withValues(alpha: 0.54 * fade * (1 - shock)),
    );
    _drawSplats(
      canvas,
      target,
      count: 18,
      travel: 86 * shock,
      alpha: fade,
      color: WuxiaUi.ink,
    );
  }

  void _paintDomain(Canvas canvas, Size size) {
    final enter = _segment(progress, 0.0, 0.26);
    final strike = _segment(progress, 0.22, 0.56);
    final release = _segment(progress, 0.56, 1.0);
    final fade = 1 - release;
    final source = Offset(size.width * 0.31, size.height * 0.61);
    final target = Offset(size.width * 0.71, size.height * 0.54);

    final veil = Paint()
      ..color = WuxiaUi.paper.withValues(alpha: 0.12 * enter * fade);
    canvas.drawRect(Offset.zero & size, veil);

    final wash = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 9; i++) {
      final angle = i * 2.399963;
      final radius = size.shortestSide * (0.22 + (i % 4) * 0.05) * enter;
      final center = Offset(
        size.width * (i.isEven ? 0.08 : 0.92) + math.cos(angle) * 42,
        size.height * (0.18 + (i % 5) * 0.16),
      );
      wash.color = WuxiaUi.ink.withValues(
        alpha: (0.045 + (i % 3) * 0.018) * enter * fade,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 1.9,
          height: radius * 0.78,
        ),
        wash,
      );
    }

    final horizon = Path()
      ..moveTo(source.dx - 80, source.dy + 34)
      ..cubicTo(
        size.width * 0.43,
        source.dy - 82,
        size.width * 0.62,
        target.dy + 58,
        size.width * 0.91,
        target.dy - 22,
      );
    _drawDryBrush(
      canvas,
      _revealed(horizon, strike),
      color: WuxiaUi.ink,
      width: 36,
      alpha: 0.92 * fade,
    );

    for (var i = 0; i < 13; i++) {
      final lane = (i - 6) * 9.0;
      final path = Path()
        ..moveTo(source.dx - 110 - i * 5, source.dy + lane)
        ..quadraticBezierTo(
          size.width * 0.53,
          target.dy + lane * 0.4,
          size.width * 0.94,
          target.dy + lane * 0.18,
        );
      canvas.drawPath(
        _revealed(path, strike),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.2 + (i % 4) * 0.9
          ..color = WuxiaUi.ink.withValues(
            alpha: (0.12 + (i % 3) * 0.055) * fade,
          ),
      );
    }

    final shock = Curves.easeOutCubic.transform(strike);
    canvas.drawCircle(
      target,
      20 + 118 * shock,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = WuxiaUi.ink.withValues(alpha: 0.42 * fade * (1 - shock)),
    );
    canvas.drawCircle(
      target,
      8 + 24 * strike,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.78 * fade),
    );
    canvas.drawCircle(
      target,
      3 + 9 * strike,
      Paint()..color = WuxiaUi.gold.withValues(alpha: 0.86 * fade),
    );
    _drawSplats(
      canvas,
      target,
      count: 28,
      travel: 150 * shock,
      alpha: fade,
      color: WuxiaUi.ink,
    );
  }

  static void _drawDryBrush(
    Canvas canvas,
    Path path, {
    required Color color,
    required double width,
    required double alpha,
  }) {
    if (alpha <= 0) return;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color.withValues(alpha: alpha * 0.76);
    canvas.drawPath(path, base);

    for (var i = 0; i < 7; i++) {
      canvas.save();
      canvas.translate(
        (i - 3) * width * 0.045,
        (((i * 5) % 7) - 3) * width * 0.028,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = i.isEven ? StrokeCap.square : StrokeCap.round
          ..strokeWidth = math.max(0.8, width * (0.055 + i * 0.018))
          ..color = color.withValues(alpha: alpha * (0.14 + i * 0.035)),
      );
      canvas.restore();
    }

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      for (var i = 0; i < 4; i++) {
        final start = length * (0.16 + i * 0.19);
        final end = math.min(length, start + length * (0.035 + i * 0.008));
        canvas.drawPath(
          metric.extractPath(start, end),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.square
            ..strokeWidth = width * (0.34 + i * 0.06)
            ..color = WuxiaUi.paper.withValues(alpha: alpha * 0.26),
        );
      }
    }
  }

  static void _drawSplats(
    Canvas canvas,
    Offset center, {
    required int count,
    required double travel,
    required double alpha,
    required Color color,
  }) {
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final angle = i * 2.399963;
      final distance = travel * (0.28 + (i % 7) / 8);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final radius = 1.8 + (i % 5) * 1.15;
      paint.color = color.withValues(alpha: alpha * (0.34 + (i % 4) * 0.10));
      canvas.drawOval(
        Rect.fromCenter(
          center: point,
          width: radius * (1.1 + (i % 3) * 0.35),
          height: radius,
        ),
        paint,
      );
    }
  }

  static Path _revealed(Path source, double progress) {
    final result = Path();
    final safe = progress.clamp(0.0, 1.0);
    for (final metric in source.computeMetrics()) {
      result.addPath(metric.extractPath(0, metric.length * safe), Offset.zero);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant InkVfxEffectPainter oldDelegate) =>
      oldDelegate.slice != slice || oldDelegate.progress != progress;
}

double _segment(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return (value - start) / (end - start);
}
