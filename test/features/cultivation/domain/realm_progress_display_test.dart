import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/cultivation/domain/realm_progress_display.dart';

void main() {
  RealmProgressDisplay display({
    required int absoluteLevel,
    required int experience,
    required int experienceToNext,
    required bool hasNextRealmLayer,
  }) => RealmProgressDisplay.fromSnapshot(
    absoluteRealmLevel: absoluteLevel,
    experience: experience,
    experienceToNext: experienceToNext,
    hasNextRealmLayer: hasNextRealmLayer,
  );

  test('first realm starts at Lv1 and advances by ten segments', () {
    expect(
      display(
        absoluteLevel: 1,
        experience: 0,
        experienceToNext: 1000,
        hasNextRealmLayer: true,
      ).level,
      1,
    );
    expect(
      display(
        absoluteLevel: 1,
        experience: 500,
        experienceToNext: 1000,
        hasNextRealmLayer: true,
      ).level,
      6,
    );
    expect(
      display(
        absoluteLevel: 1,
        experience: 999,
        experienceToNext: 1000,
        hasNextRealmLayer: true,
      ).level,
      10,
    );
  });

  test('locked overflow stays at the tenth level and preserves real exp', () {
    final value = display(
      absoluteLevel: 42,
      experience: 1800,
      experienceToNext: 1200,
      hasNextRealmLayer: true,
    );

    expect(value.level, 420);
    expect(value.state, RealmProgressDisplayState.waitingForBreakthrough);
    expect(value.experience, 1800);
    expect(value.progress, 1.0);
  });

  test('final realm advances from Lv481 to Lv490 without Lv491', () {
    expect(
      display(
        absoluteLevel: 49,
        experience: 0,
        experienceToNext: 1250000,
        hasNextRealmLayer: false,
      ).level,
      481,
    );
    final peak = display(
      absoluteLevel: 49,
      experience: 1250000,
      experienceToNext: 1250000,
      hasNextRealmLayer: false,
    );
    expect(peak.level, 490);
    expect(peak.state, RealmProgressDisplayState.peak);

    final overflow = display(
      absoluteLevel: 49,
      experience: 9999999,
      experienceToNext: 1250000,
      hasNextRealmLayer: false,
    );
    expect(overflow.level, 490);
    expect(overflow.experience, 9999999);
  });

  test('defensive inputs never produce Lv0 or Lv491', () {
    expect(
      display(
        absoluteLevel: -1,
        experience: -5,
        experienceToNext: 0,
        hasNextRealmLayer: true,
      ).level,
      1,
    );
    expect(
      display(
        absoluteLevel: 99,
        experience: 999,
        experienceToNext: 0,
        hasNextRealmLayer: false,
      ).level,
      490,
    );
  });
}
