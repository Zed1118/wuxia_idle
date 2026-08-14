import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';

/// Style drafts for the Phase 0B playable draft.
///
/// Both styles reuse the existing greybox input mapping (WASD move, LMB
/// basic, SPACE dash, Q and R arts) and the same player model; only cadence
/// and shape parameters differ. Values are draft-local and never extend
/// production numeric configuration.
enum DraftStyleKind { surgeCurrent, sinisterDraft }

enum DraftClearShape { circle, line }

enum DraftGatherKind { pull, slowFog }

final class DraftStyleProfile {
  const DraftStyleProfile({
    required this.kind,
    required this.label,
    required this.basicInterval,
    required this.basicRange,
    required this.basicHalfArc,
    required this.basicDamage,
    required this.basicQiGain,
    required this.appliesInternalInjury,
    required this.internalInjuryDps,
    required this.internalInjuryDuration,
    required this.gatherKind,
    required this.gatherRadius,
    required this.gatherTargetRadius,
    required this.slowFieldDuration,
    required this.clearShape,
    required this.clearRadius,
    required this.clearLength,
    required this.clearWidth,
    required this.clearDamage,
  });

  /// Style A: the current greybox rhythm — fast short-arc basics into a
  /// gather-then-burst circle payoff.
  static const DraftStyleProfile surgeCurrent = DraftStyleProfile(
    kind: DraftStyleKind.surgeCurrent,
    label: 'SURGE · current greybox rhythm',
    basicInterval: 0.30,
    basicRange: 150,
    basicHalfArc: 0.655,
    basicDamage: 34,
    basicQiGain: 5,
    appliesInternalInjury: false,
    internalInjuryDps: 0,
    internalInjuryDuration: 0,
    gatherKind: DraftGatherKind.pull,
    gatherRadius: 300,
    gatherTargetRadius: 100,
    slowFieldDuration: 0,
    clearShape: DraftClearShape.circle,
    clearRadius: 340,
    clearLength: 0,
    clearWidth: 0,
    clearDamage: 65,
  );

  /// Style B draft: sinister-flavoured slow pressure — slow long narrow
  /// thrusts that leave internal injury, a slowing fog instead of a pull,
  /// and a piercing line instead of a burst circle.
  static const DraftStyleProfile sinisterDraft = DraftStyleProfile(
    kind: DraftStyleKind.sinisterDraft,
    label: 'SINISTER draft · slow pressure',
    basicInterval: 0.55,
    basicRange: 195,
    basicHalfArc: 0.30,
    basicDamage: 52,
    basicQiGain: 8,
    appliesInternalInjury: true,
    internalInjuryDps: 8,
    internalInjuryDuration: 2.5,
    gatherKind: DraftGatherKind.slowFog,
    gatherRadius: 230,
    gatherTargetRadius: 0,
    slowFieldDuration: 2.5,
    clearShape: DraftClearShape.line,
    clearRadius: 0,
    clearLength: 430,
    clearWidth: 96,
    clearDamage: 80,
  );

  static DraftStyleProfile of(DraftStyleKind kind) => switch (kind) {
    DraftStyleKind.surgeCurrent => surgeCurrent,
    DraftStyleKind.sinisterDraft => sinisterDraft,
  };

  final DraftStyleKind kind;
  final String label;
  final double basicInterval;
  final double basicRange;
  final double basicHalfArc;
  final double basicDamage;
  final double basicQiGain;
  final bool appliesInternalInjury;
  final double internalInjuryDps;
  final double internalInjuryDuration;
  final DraftGatherKind gatherKind;
  final double gatherRadius;
  final double gatherTargetRadius;
  final double slowFieldDuration;
  final DraftClearShape clearShape;
  final double clearRadius;
  final double clearLength;
  final double clearWidth;
  final double clearDamage;
}

bool draftInsideBasicArc({
  required DraftStyleProfile profile,
  required Vector2 origin,
  required Vector2 aim,
  required Vector2 target,
}) => isInsideAimArc(
  origin: origin,
  aimDirection: aim,
  target: target,
  range: profile.basicRange,
  halfArcRadians: profile.basicHalfArc,
);

bool draftInsideClearZone({
  required DraftStyleProfile profile,
  required Vector2 origin,
  required Vector2 aim,
  required Vector2 point,
}) {
  final delta = point - origin;
  switch (profile.clearShape) {
    case DraftClearShape.circle:
      return delta.length <= profile.clearRadius;
    case DraftClearShape.line:
      final direction = aim.length2 == 0 ? Vector2(1, 0) : aim.normalized();
      final along = delta.dot(direction);
      if (along < 0 || along > profile.clearLength) return false;
      final perpendicular = (delta - direction * along).length;
      return perpendicular <= profile.clearWidth / 2;
  }
}

/// Deterministic damage-per-second accumulation helper for internal injury:
/// refresh-on-hit stack with a bounded duration, no stacking multiplier.
double draftInternalInjuryTick({
  required double dps,
  required double remaining,
  required double dt,
}) {
  if (dps <= 0 || remaining <= 0) return 0;
  return dps * math.min(remaining, dt);
}
