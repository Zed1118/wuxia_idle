import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/attack_token_director.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_presentation_tokens.dart';
import 'phase0a_stage.dart';
import 'phase0a_visual_roster.dart';

enum Phase0aOffscreenThreatKind { charge, rangedWindup, support, boss }

enum Phase0aOffscreenProximity { near, medium, far }

final class Phase0aOffscreenIndicator {
  Phase0aOffscreenIndicator({
    required Iterable<String> actorIds,
    required this.kind,
    required this.proximity,
    required this.direction,
    required this.priority,
  }) : actorIds = List<String>.unmodifiable(actorIds);

  final List<String> actorIds;
  final Phase0aOffscreenThreatKind kind;
  final Phase0aOffscreenProximity proximity;
  final ArenaVector direction;
  final int priority;
}

final class _Candidate {
  const _Candidate({
    required this.actorId,
    required this.kind,
    required this.proximity,
    required this.direction,
    required this.priority,
    required this.sector,
  });

  final String actorId;
  final Phase0aOffscreenThreatKind kind;
  final Phase0aOffscreenProximity proximity;
  final ArenaVector direction;
  final int priority;
  final int sector;
}

List<Phase0aOffscreenIndicator> selectPhase0aOffscreenIndicators({
  required Phase0aArenaState state,
  required Phase0aStage stage,
  required Phase0aVisualRoster roster,
  ArenaVector Function(Phase0aActor actor)? positionOf,
}) {
  final playerPosition =
      positionOf?.call(state.player) ?? state.player.position;
  final candidates = <_Candidate>[];
  for (final actor in state.enemies) {
    if (!actor.isAlive) continue;
    final position = positionOf?.call(actor) ?? actor.position;
    if (stage.isWorldPointVisible(position)) continue;
    final visualThreat = roster.visualFor(actor.id).threat;
    final kind = _kindFor(actor, visualThreat);
    if (kind == null) continue;
    final delta = position - playerPosition;
    if (delta.lengthSquared == 0) continue;
    final direction = delta.normalized();
    final distanceRatio = delta.length / stage.cameraWorldDiagonal;
    final proximity =
        distanceRatio <= Phase0aPresentationTokens.offscreenIndicatorNearRatio
        ? Phase0aOffscreenProximity.near
        : distanceRatio <=
              Phase0aPresentationTokens.offscreenIndicatorMediumRatio
        ? Phase0aOffscreenProximity.medium
        : Phase0aOffscreenProximity.far;
    final sectorRadians =
        2 * math.pi / Phase0aPresentationTokens.offscreenDirectionSectors;
    final angle = math.atan2(direction.y, direction.x);
    final sector =
        ((angle + math.pi + sectorRadians / 2) / sectorRadians).floor() %
        Phase0aPresentationTokens.offscreenDirectionSectors;
    candidates.add(
      _Candidate(
        actorId: actor.id,
        kind: kind,
        proximity: proximity,
        direction: direction,
        priority: _priorityFor(actor, visualThreat, kind),
        sector: sector,
      ),
    );
  }
  candidates.sort(_compareCandidates);

  final grouped = <int, List<_Candidate>>{};
  for (final candidate in candidates) {
    grouped.putIfAbsent(candidate.sector, () => <_Candidate>[]).add(candidate);
  }
  final indicators =
      <Phase0aOffscreenIndicator>[
        for (final group in grouped.values)
          Phase0aOffscreenIndicator(
            actorIds: group.map((item) => item.actorId),
            kind: group.first.kind,
            proximity: group.first.proximity,
            direction: group.first.direction,
            priority: group.first.priority,
          ),
      ]..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        final byProximity = a.proximity.index.compareTo(b.proximity.index);
        if (byProximity != 0) return byProximity;
        return a.actorIds.first.compareTo(b.actorIds.first);
      });
  return List<Phase0aOffscreenIndicator>.unmodifiable(
    indicators.take(Phase0aPresentationTokens.maxOffscreenIndicatorDirections),
  );
}

Phase0aOffscreenThreatKind? _kindFor(
  Phase0aActor actor,
  Phase0aActorThreatVisual? threat,
) {
  if (actor.isBoss) return Phase0aOffscreenThreatKind.boss;
  return switch (threat?.kind) {
    AttackTokenKind.charge => Phase0aOffscreenThreatKind.charge,
    AttackTokenKind.support => Phase0aOffscreenThreatKind.support,
    AttackTokenKind.ranged when actor.chargingCast != null =>
      Phase0aOffscreenThreatKind.rangedWindup,
    _ => null,
  };
}

int _priorityFor(
  Phase0aActor actor,
  Phase0aActorThreatVisual? threat,
  Phase0aOffscreenThreatKind kind,
) {
  if (actor.isBoss) return 4;
  if (threat?.isHighImpact == true) return 3;
  if (kind == Phase0aOffscreenThreatKind.support) return 2;
  return 1;
}

int _compareCandidates(_Candidate a, _Candidate b) {
  final byPriority = b.priority.compareTo(a.priority);
  if (byPriority != 0) return byPriority;
  final byProximity = a.proximity.index.compareTo(b.proximity.index);
  if (byProximity != 0) return byProximity;
  return a.actorId.compareTo(b.actorId);
}

final class Phase0aOffscreenIndicatorPainter extends CustomPainter {
  Phase0aOffscreenIndicatorPainter({
    required this.indicators,
    ValueListenable<int>? frame,
  }) : _frame = frame,
       super(repaint: frame);

  final List<Phase0aOffscreenIndicator> indicators;
  final ValueListenable<int>? _frame;

  List<Offset> markerCenters(Size size) {
    final edge = Rect.fromLTWH(
      Phase0aPresentationTokens.offscreenIndicatorEdgeInset,
      Phase0aPresentationTokens.offscreenIndicatorEdgeInset,
      math.max(
        0,
        size.width - 2 * Phase0aPresentationTokens.offscreenIndicatorEdgeInset,
      ),
      math.max(
        0,
        // Keep the lower threat marker above the same reserved HUD band.
        size.height -
            Phase0aPresentationTokens.battleHudReservedHeight -
            2 * Phase0aPresentationTokens.offscreenIndicatorEdgeInset,
      ),
    );
    final origin = edge.center;
    return <Offset>[
      for (final indicator in indicators)
        _edgeIntersection(origin, edge, indicator.direction),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centers = markerCenters(size);
    final frame = _frame?.value ?? 0;
    final pulse =
        (math.sin(
              frame *
                  Phase0aPresentationTokens
                      .offscreenIndicatorPulseRadiansPerFrame,
            ) +
            1) /
        2;
    for (var index = 0; index < indicators.length; index++) {
      final indicator = indicators[index];
      final baseOpacity = switch (indicator.proximity) {
        Phase0aOffscreenProximity.near =>
          Phase0aPresentationTokens.offscreenIndicatorNearOpacity,
        Phase0aOffscreenProximity.medium =>
          Phase0aPresentationTokens.offscreenIndicatorMediumOpacity,
        Phase0aOffscreenProximity.far =>
          Phase0aPresentationTokens.offscreenIndicatorFarOpacity,
      };
      final opacity =
          (baseOpacity +
                  pulse *
                      Phase0aPresentationTokens.offscreenIndicatorPulseOpacity)
              .clamp(0.0, 1.0);
      final accent = indicator.kind == Phase0aOffscreenThreatKind.boss
          ? WuxiaUi.jiang
          : WuxiaUi.qingOnDark;
      final direction = indicator.direction;
      canvas.save();
      canvas.translate(centers[index].dx, centers[index].dy);
      canvas.rotate(math.atan2(direction.y, direction.x));
      _paintMarker(canvas, indicator.kind, accent, opacity);
      canvas.restore();
    }
  }

  static Offset _edgeIntersection(
    Offset origin,
    Rect edge,
    ArenaVector direction,
  ) {
    final dx = direction.x;
    final dy = direction.y;
    final horizontal = dx.abs() < 0.000001
        ? double.infinity
        : (dx > 0 ? edge.right - origin.dx : origin.dx - edge.left) / dx.abs();
    final vertical = dy.abs() < 0.000001
        ? double.infinity
        : (dy > 0 ? edge.bottom - origin.dy : origin.dy - edge.top) / dy.abs();
    final distance = math.min(horizontal, vertical);
    return Offset(origin.dx + dx * distance, origin.dy + dy * distance);
  }

  static void _paintMarker(
    Canvas canvas,
    Phase0aOffscreenThreatKind kind,
    Color accent,
    double opacity,
  ) {
    final length = Phase0aPresentationTokens.offscreenIndicatorLength;
    final halfWidth = Phase0aPresentationTokens.offscreenIndicatorHalfWidth;
    final path = Path()
      ..moveTo(length / 2, 0)
      ..quadraticBezierTo(0, -halfWidth, -length / 2, -halfWidth * 0.45)
      ..quadraticBezierTo(-length * 0.18, 0, -length / 2, halfWidth * 0.45)
      ..quadraticBezierTo(0, halfWidth, length / 2, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.ink.withValues(alpha: opacity * 0.58)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Phase0aPresentationTokens.offscreenIndicatorStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final glyph = Paint()
      ..color = WuxiaUi.paper.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          Phase0aPresentationTokens.offscreenIndicatorInnerStrokeWidth
      ..strokeCap = StrokeCap.round;
    switch (kind) {
      case Phase0aOffscreenThreatKind.charge:
        canvas.drawLine(const Offset(-9, -7), const Offset(1, 0), glyph);
        canvas.drawLine(const Offset(-9, 7), const Offset(1, 0), glyph);
        canvas.drawLine(const Offset(-1, -7), const Offset(9, 0), glyph);
        canvas.drawLine(const Offset(-1, 7), const Offset(9, 0), glyph);
      case Phase0aOffscreenThreatKind.rangedWindup:
        canvas.drawCircle(Offset.zero, 7, glyph);
        canvas.drawLine(const Offset(-10, 0), const Offset(10, 0), glyph);
      case Phase0aOffscreenThreatKind.support:
        canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), glyph);
        canvas.drawLine(const Offset(0, -8), const Offset(0, 8), glyph);
      case Phase0aOffscreenThreatKind.boss:
        final diamond = Path()
          ..moveTo(9, 0)
          ..lineTo(0, -9)
          ..lineTo(-9, 0)
          ..lineTo(0, 9)
          ..close();
        canvas.drawPath(diamond, glyph);
    }
  }

  @override
  bool shouldRepaint(covariant Phase0aOffscreenIndicatorPainter oldDelegate) {
    if (oldDelegate.indicators.length != indicators.length) return true;
    for (var index = 0; index < indicators.length; index++) {
      final old = oldDelegate.indicators[index];
      final current = indicators[index];
      if (old.kind != current.kind ||
          old.proximity != current.proximity ||
          old.direction != current.direction ||
          !listEquals(old.actorIds, current.actorIds)) {
        return true;
      }
    }
    return false;
  }
}
