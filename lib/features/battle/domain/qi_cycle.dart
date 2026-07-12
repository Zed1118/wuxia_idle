import '../../../core/domain/enums.dart';

/// One resolved action's qi-relevant facts.
///
/// Multiple true flags still yield at most one school bonus for one character.
class QiActionEvent {
  const QiActionEvent({
    this.landedHit = false,
    this.receivedHit = false,
    this.appliedControlOrDot = false,
    this.critical = false,
    this.dodged = false,
    this.chained = false,
  });

  final bool landedHit;
  final bool receivedHit;
  final bool appliedControlOrDot;
  final bool critical;
  final bool dodged;
  final bool chained;
}

/// Pure combat-resource arithmetic shared by setup, AI and battle strategies.
abstract final class QiCycle {
  static int openingQi({
    required int maxQi,
    required int openingQi,
    required int openingCap,
  }) => openingQi.clamp(0, maxQi < openingCap ? maxQi : openingCap);

  static int applyDelta({
    required int currentQi,
    required int maxQi,
    required int delta,
  }) => (currentQi + delta).clamp(0, maxQi);

  static int effectiveCost({
    required int baseCost,
    required double reductionPct,
    required double reductionCap,
  }) {
    if (baseCost <= 0) return 0;
    final safeReduction = reductionPct.clamp(0.0, reductionCap);
    return (baseCost * (1 - safeReduction)).round().clamp(0, baseCost);
  }

  static int effectiveSkillDelta({
    required int baseDelta,
    required double gainMultiplier,
    required double gainMultiplierCap,
    required double costReductionPct,
    required double costReductionCap,
  }) {
    if (baseDelta >= 0) {
      final multiplier = gainMultiplier.clamp(1.0, gainMultiplierCap);
      return (baseDelta * multiplier).round();
    }
    return -effectiveCost(
      baseCost: -baseDelta,
      reductionPct: costReductionPct,
      reductionCap: costReductionCap,
    );
  }

  static int schoolBonus({
    required TechniqueSchool school,
    required QiActionEvent event,
    required int bonus,
  }) {
    final triggered = switch (school) {
      TechniqueSchool.gangMeng => event.landedHit || event.receivedHit,
      TechniqueSchool.yinRou => event.appliedControlOrDot,
      TechniqueSchool.lingQiao =>
        event.critical || event.dodged || event.chained,
    };
    return triggered ? bonus : 0;
  }

  static int recoverBetweenWaves({
    required int currentQi,
    required int maxQi,
    required double recoveryPct,
  }) {
    final recovered = (maxQi * recoveryPct.clamp(0.0, 1.0)).floor();
    return applyDelta(currentQi: currentQi, maxQi: maxQi, delta: recovered);
  }

  static int effectiveInnerForce({
    required int actualInnerForce,
    required double disorderHours,
    required double disorderMaxHours,
    required double maxPenaltyPct,
  }) {
    if (actualInnerForce <= 0 || disorderHours <= 0 || disorderMaxHours <= 0) {
      return actualInnerForce < 0 ? 0 : actualInnerForce;
    }
    final severity = (disorderHours / disorderMaxHours).clamp(0.0, 1.0);
    final penalty = maxPenaltyPct.clamp(0.0, 1.0) * severity;
    return (actualInnerForce * (1 - penalty)).round().clamp(
      0,
      actualInnerForce,
    );
  }

  static int disorderOpeningQiPenalty({
    required double disorderHours,
    required double disorderMaxHours,
    required int maxPenalty,
  }) {
    if (disorderHours <= 0 || disorderMaxHours <= 0 || maxPenalty <= 0)
      return 0;
    final severity = (disorderHours / disorderMaxHours).clamp(0.0, 1.0);
    return (maxPenalty * severity).round().clamp(0, maxPenalty);
  }
}
