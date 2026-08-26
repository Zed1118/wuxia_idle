import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

({int hits, double directDamage, double injuryDamage, List<double> hitTimes})
_runBasicScript(DraftStyleProfile profile, {double seconds = 12}) {
  final origin = Vector2(0, 0);
  final aim = Vector2(1, 0);
  final dummy = Vector2(120, 0);
  var remaining = 0.0;
  var injuryRemaining = 0.0;
  var injuryDamage = 0.0;
  var directDamage = 0.0;
  var hits = 0;
  final hitTimes = <double>[];
  const dt = 1 / 60;
  for (var t = 0.0; t < seconds; t += dt) {
    if (injuryRemaining > 0) {
      injuryDamage += draftInternalInjuryTick(
        dps: profile.internalInjuryDps,
        remaining: injuryRemaining,
        dt: dt,
      );
      injuryRemaining -= dt;
    }
    remaining -= dt;
    if (remaining > 0) continue;
    // Primary held from t=0: every swing resolves against the dummy.
    if (draftInsideBasicArc(
      profile: profile,
      origin: origin,
      aim: aim,
      target: dummy,
    )) {
      hits++;
      hitTimes.add(t);
      directDamage += profile.basicDamage;
      if (profile.appliesInternalInjury) {
        injuryRemaining = profile.internalInjuryDuration;
      }
    }
    remaining = profile.basicInterval;
  }
  return (
    hits: hits,
    directDamage: directDamage,
    injuryDamage: injuryDamage,
    hitTimes: hitTimes,
  );
}

void main() {
  test('both styles reuse the same inputs but differ in cadence', () {
    final surge = _runBasicScript(DraftStyleProfile.surgeCurrent);
    final sinister = _runBasicScript(DraftStyleProfile.sinisterDraft);

    expect(surge.hits, greaterThan(sinister.hits));
    final surgeGap = surge.hitTimes[1] - surge.hitTimes[0];
    final sinisterGap = sinister.hitTimes[1] - sinister.hitTimes[0];
    expect(surgeGap, closeTo(0.30, 0.02));
    expect(sinisterGap, closeTo(0.55, 0.02));

    // Total output stays in the same magnitude band: rhythm changes, not
    // numeric inflation.
    final surgeTotal = surge.directDamage + surge.injuryDamage;
    final sinisterTotal = sinister.directDamage + sinister.injuryDamage;
    expect(sinisterTotal / surgeTotal, inInclusiveRange(0.5, 2.0));
  });

  test('only the sinister draft applies internal injury pressure', () {
    final surge = _runBasicScript(DraftStyleProfile.surgeCurrent);
    final sinister = _runBasicScript(DraftStyleProfile.sinisterDraft);
    expect(surge.injuryDamage, 0);
    expect(sinister.injuryDamage, greaterThan(50));
  });

  test('basic arcs differ in shape: wide chop vs narrow thrust', () {
    final origin = Vector2(0, 0);
    final aim = Vector2(1, 0);
    final angledTarget = Vector2(120 * 0.9, 120 * 0.45); // ~0.46 rad off-aim
    expect(
      draftInsideBasicArc(
        profile: DraftStyleProfile.surgeCurrent,
        origin: origin,
        aim: aim,
        target: angledTarget,
      ),
      isTrue,
    );
    expect(
      draftInsideBasicArc(
        profile: DraftStyleProfile.sinisterDraft,
        origin: origin,
        aim: aim,
        target: angledTarget,
      ),
      isFalse,
    );
    expect(
      DraftStyleProfile.surgeCurrent.basicRange,
      lessThan(DraftStyleProfile.sinisterDraft.basicRange),
    );
  });

  test('clear shapes differ: burst circle vs piercing line', () {
    final origin = Vector2(0, 0);
    final aim = Vector2(1, 0);
    final surge = DraftStyleProfile.surgeCurrent;
    final sinister = DraftStyleProfile.sinisterDraft;
    expect(surge.clearShape, DraftClearShape.circle);
    expect(sinister.clearShape, DraftClearShape.line);

    // Lateral point: inside the burst circle, outside the pierce line.
    final lateral = Vector2(0, 250);
    expect(
      draftInsideClearZone(
        profile: surge,
        origin: origin,
        aim: aim,
        point: lateral,
      ),
      isTrue,
    );
    expect(
      draftInsideClearZone(
        profile: sinister,
        origin: origin,
        aim: aim,
        point: lateral,
      ),
      isFalse,
    );

    // Far down the aim axis: beyond the circle, inside the pierce.
    final farAhead = Vector2(400, 0);
    expect(
      draftInsideClearZone(
        profile: surge,
        origin: origin,
        aim: aim,
        point: farAhead,
      ),
      isFalse,
    );
    expect(
      draftInsideClearZone(
        profile: sinister,
        origin: origin,
        aim: aim,
        point: farAhead,
      ),
      isTrue,
    );

    // Behind the caster: circle reaches, pierce does not.
    final behind = Vector2(-300, 0);
    expect(
      draftInsideClearZone(
        profile: surge,
        origin: origin,
        aim: aim,
        point: behind,
      ),
      isTrue,
    );
    expect(
      draftInsideClearZone(
        profile: sinister,
        origin: origin,
        aim: aim,
        point: behind,
      ),
      isFalse,
    );
  });

  test('gather arts differ: pull vs slowing fog', () {
    expect(DraftStyleProfile.surgeCurrent.gatherKind, DraftGatherKind.pull);
    expect(DraftStyleProfile.sinisterDraft.gatherKind, DraftGatherKind.slowFog);
    expect(DraftStyleProfile.sinisterDraft.slowFieldDuration, greaterThan(0));
  });
}
