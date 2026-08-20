import 'package:flutter_test/flutter_test.dart';
import 'phase0a_ch1_skill_profile.dart';

Phase0aCh1RunObservation r(String outcome, int ticks, {int damage = 10}) =>
    Phase0aCh1RunObservation(
      profileId: 'p',
      stageId: 's',
      seed: ticks,
      outcome: outcome,
      ticks: ticks,
      seconds: ticks * .1,
      hpStart: 100,
      hpEnd: 50,
      qiStart: 20,
      qiMax: 20,
      qiEnd: 10,
      basicCasts: 1,
      basicHits: 1,
      basicDamage: damage,
      gatherCasts: 0,
      gatherDamage: 0,
      clearCasts: 0,
      clearDamage: 0,
      numericCasts: const [1, 0, 0, 0, 0, 0],
      numericHits: const [1, 0, 0, 0, 0, 0],
      numericDamage: const [5, 0, 0, 0, 0, 0],
      totalPlayerDamage: damage + 5,
      criticalHits: 0,
      maxResolvedDamage: damage,
    );

void main() {
  test('aggregate uses nearest-rank percentiles and separates timeout', () {
    final a = Phase0aCh1ProfileAggregate([
      r('victory', 10),
      r('defeat', 20),
      r('timeout', 30),
    ]);
    expect(a.wins, 1);
    expect(a.defeats, 1);
    expect(a.timeouts, 1);
    expect(a.winRate, closeTo(1 / 3, .0001));
    expect(a.p50Ticks, 20);
    expect(a.p90Ticks, 30);
    expect(a.totalBasicCasts, 3);
    expect(a.totalNumericDamage(), [15, 0, 0, 0, 0, 0]);
  });

  test('observation equality is stable for identical fields', () {
    expect(r('victory', 7), r('victory', 7));
  });

  test('observation defensively copies six-slot metric lists', () {
    final casts = <int>[1, 0, 0, 0, 0, 0];
    final observation = Phase0aCh1RunObservation(
      profileId: 'p',
      stageId: 's',
      seed: 1,
      outcome: 'victory',
      ticks: 1,
      seconds: .1,
      hpStart: 100,
      hpEnd: 80,
      qiStart: 20,
      qiMax: 40,
      qiEnd: 10,
      basicCasts: 0,
      basicHits: 0,
      basicDamage: 0,
      gatherCasts: 0,
      gatherDamage: 0,
      clearCasts: 0,
      clearDamage: 0,
      numericCasts: casts,
      numericHits: const [0, 0, 0, 0, 0, 0],
      numericDamage: const [0, 0, 0, 0, 0, 0],
      totalPlayerDamage: 0,
      criticalHits: 0,
      maxResolvedDamage: 0,
    );
    casts[0] = 99;
    expect(observation.numericCasts, [1, 0, 0, 0, 0, 0]);
    expect(() => observation.numericCasts[0] = 2, throwsUnsupportedError);
    expect(observation.qiEndRatio, .25);
  });
}
