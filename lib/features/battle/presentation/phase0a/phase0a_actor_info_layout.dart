import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'phase0a_presentation_tokens.dart';

/// Screen geometry only. The actor's world position and hitbox never change.
final class Phase0aActorInfoAnchor {
  const Phase0aActorInfoAnchor({
    required this.id,
    required this.actorRect,
    required this.bodyRect,
    this.preferredOffsetX = 0,
    this.priority = false,
  });

  final String id;
  final Rect actorRect;
  final Rect bodyRect;
  final double preferredOffsetX;
  final bool priority;
}

/// Measures the actual information widgets, then keeps them clear of bodies,
/// prior information blocks and the reserved HUD area. No text measurement
/// approximation, asset decoding, domain mutation or frame callback is needed.
final class Phase0aActorInfoLayout extends MultiChildLayoutDelegate {
  Phase0aActorInfoLayout({
    required this.anchors,
    required this.bodyObstacles,
    required this.availableRect,
    required this.retainedOffsets,
  });

  final List<Phase0aActorInfoAnchor> anchors;
  final List<Rect> bodyObstacles;
  final Rect availableRect;

  /// Presentation cache owned by the screen; a valid placement follows its
  /// actor instead of oscillating back to the default lane every other frame.
  final Map<String, Offset> retainedOffsets;

  @override
  void performLayout(Size size) {
    final bounds = availableRect.intersect(Offset.zero & size);
    final blocked = <Rect>[...bodyObstacles];
    final ordered = anchors.toList()
      ..sort((a, b) {
        final priority = (b.priority ? 1 : 0).compareTo(a.priority ? 1 : 0);
        return priority != 0 ? priority : a.id.compareTo(b.id);
      });
    final ids = anchors.map((anchor) => anchor.id).toSet();
    retainedOffsets.removeWhere((id, _) => !ids.contains(id));
    for (final anchor in ordered) {
      final childSize = layoutChild(
        anchor.id,
        BoxConstraints.tightFor(width: anchor.actorRect.width),
      );
      final preferred =
          anchor.actorRect.topLeft + Offset(anchor.preferredOffsetX, 0);
      final gap = Phase0aPresentationTokens.actorInfoGap;
      Offset clamp(Offset position) => Offset(
        position.dx.clamp(
          bounds.left,
          math.max(bounds.left, bounds.right - childSize.width),
        ),
        position.dy.clamp(
          bounds.top,
          math.max(bounds.top, bounds.bottom - childSize.height),
        ),
      );
      bool isClear(Offset position) {
        final rect = position & childSize;
        return rect.left >= bounds.left &&
            rect.top >= bounds.top &&
            rect.right <= bounds.right &&
            rect.bottom <= bounds.bottom &&
            blocked.every((obstacle) => !rect.overlaps(obstacle.inflate(gap)));
      }

      // Side lanes stay level with their own body, so a displaced Boss label
      // cannot appear to belong to the adjacent enemy above it.
      final sideY = anchor.bodyRect.center.dy - childSize.height / 2;
      final left = Offset(anchor.bodyRect.left - gap - childSize.width, sideY);
      final right = Offset(anchor.bodyRect.right + gap, sideY);
      // A wider neighbor may block the owner's nearest side lane. Search the
      // next body edges at the same height before moving into another row.
      final leftXs = <double>{
        left.dx,
        for (final obstacle in blocked)
          if (obstacle.left - gap - childSize.width <= left.dx)
            obstacle.left - gap - childSize.width,
      }.toList()..sort((a, b) => b.compareTo(a));
      final rightXs = <double>{
        right.dx,
        for (final obstacle in blocked)
          if (obstacle.right + gap >= right.dx) obstacle.right + gap,
      }.toList()..sort();
      final inward = anchor.actorRect.center.dx > bounds.center.dx;
      final previous = retainedOffsets[anchor.id];
      final retainedCandidates = <Offset>[
        if (previous != null) anchor.actorRect.topLeft + previous,
        preferred,
      ].map(clamp);
      final candidates = <Offset>[
        for (final x in inward ? leftXs : rightXs) Offset(x, sideY),
        for (final x in inward ? rightXs : leftXs) Offset(x, sideY),
        Offset(preferred.dx, anchor.bodyRect.top - gap - childSize.height),
        Offset(preferred.dx, anchor.bodyRect.bottom + gap),
      ].map(clamp);
      Offset? selected;
      for (final candidate in retainedCandidates) {
        if (isClear(candidate)) {
          selected = candidate;
          break;
        }
      }
      double ownerDistance(Offset position) {
        final rect = position & childSize;
        final dx = math.max(
          0.0,
          math.max(
            anchor.bodyRect.left - rect.right,
            rect.left - anchor.bodyRect.right,
          ),
        );
        final dy = math.max(
          0.0,
          math.max(
            anchor.bodyRect.top - rect.bottom,
            rect.top - anchor.bodyRect.bottom,
          ),
        );
        return dx * dx + dy * dy;
      }

      if (selected == null) {
        // Prefer the closest clear lane across both sides and above/below.
        // Exhausting every inward edge first can place an enemy label beyond
        // the player even though a nearby vertical lane is available.
        var distance = double.infinity;
        for (final candidate in candidates) {
          final delta = ownerDistance(candidate);
          if (delta < distance - precisionErrorTolerance &&
              isClear(candidate)) {
            selected = candidate;
            distance = delta;
          }
        }
      }
      if (selected == null) {
        // Only dense/edge cases reach this bounded edge search. Axis-aligned
        // obstacles define the possible free-space boundaries, so we need no
        // per-pixel search or runtime alpha mask.
        final xs = <double>{
          bounds.left,
          bounds.right - childSize.width,
          clamp(preferred).dx,
        };
        final ys = <double>{
          bounds.top,
          bounds.bottom - childSize.height,
          clamp(preferred).dy,
          clamp(Offset(preferred.dx, sideY)).dy,
        };
        for (final obstacle in blocked) {
          xs.addAll([
            obstacle.left - gap - childSize.width,
            obstacle.right + gap,
          ]);
          ys.addAll([
            obstacle.top - gap - childSize.height,
            obstacle.bottom + gap,
          ]);
        }
        var distance = double.infinity;
        final orderedXs = xs.toList()..sort();
        final orderedYs = ys.toList()..sort();
        for (final x in orderedXs) {
          for (final y in orderedYs) {
            final candidate = Offset(x, y);
            final delta = ownerDistance(candidate);
            if (delta < distance - precisionErrorTolerance &&
                isClear(candidate)) {
              selected = candidate;
              distance = delta;
            }
          }
        }
      }
      // Keep critical information even if a viewport has no free region.
      // Such an overlap is not reported as successful avoidance.
      selected ??= clamp(preferred);
      positionChild(anchor.id, selected);
      retainedOffsets[anchor.id] = selected - anchor.actorRect.topLeft;
      blocked.add(selected & childSize);
    }
  }

  @override
  bool shouldRelayout(covariant Phase0aActorInfoLayout oldDelegate) => true;
}

/// Conservative envelope for the fixed-height Image and its slide/scale/
/// rotation, including interrupted easeOutBack transitions. A cubic stays
/// within its control-point range; the geometric bound also covers retargeting.
Rect phase0aActorBodyEnvelope(Rect actorRect) {
  const height = Phase0aPresentationTokens.actorImageHeight;
  final imageRect = Rect.fromLTWH(
    actorRect.left,
    actorRect.bottom - Phase0aPresentationTokens.actorImageBottomInset - height,
    actorRect.width,
    height,
  );
  final slide = math.max(
    Phase0aPresentationTokens.actorHitSlideFraction,
    Phase0aPresentationTokens.actorActionSlideFraction,
  );
  final lowScale = math.min(1.0, Phase0aPresentationTokens.actorHitScale);
  final highScale = math.max(1.0, Phase0aPresentationTokens.actorActionScale);
  final overshoot = Curves.easeOutBack.d - 1;
  final maxScale =
      highScale + overshoot * (highScale - lowScale) / (1 - overshoot);
  final angle =
      Phase0aPresentationTokens.postureUnbalancedTurns.abs() *
      2 *
      math.pi /
      (1 - overshoot);
  final centerRadius = imageRect.size.center(Offset.zero).distance;
  final rotationRadius = Offset(imageRect.width / 2, height).distance;
  final padding =
      math.max(imageRect.width, height) * slide +
      centerRadius * (maxScale - 1) +
      maxScale * 2 * rotationRadius * math.sin(angle / 2);
  return imageRect.inflate(padding);
}
