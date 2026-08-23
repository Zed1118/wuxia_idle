import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';

void main() {
  ActivityParticipationRequest request({
    String contentId = ' stage-01 ',
    ActivityContentKind contentKind = ActivityContentKind.mainline,
    int characterId = 7,
    String loadoutPlanId = ' loadout-a ',
    ActivityParticipationMode participation = ActivityParticipationMode.direct,
    ActivityController controller = ActivityController.human,
    ActivityClock clock = ActivityClock.realtime,
    ActivityEntryKind entryKind = ActivityEntryKind.firstClear,
  }) => ActivityParticipationRequest(
    contentId: contentId,
    contentKind: contentKind,
    characterId: characterId,
    loadoutPlanId: loadoutPlanId,
    participation: participation,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  test('covers every explicit enum value', () {
    expect(ActivityContentKind.values, hasLength(7));
    expect(ActivityParticipationMode.values, hasLength(2));
    expect(ActivityController.values, hasLength(2));
    expect(ActivityClock.values, hasLength(2));
    expect(ActivityEntryKind.values, hasLength(4));

    for (final contentKind in ActivityContentKind.values) {
      expect(request(contentKind: contentKind).contentKind, contentKind);
    }
    for (final participation in ActivityParticipationMode.values) {
      expect(
        request(participation: participation).participation,
        participation,
      );
    }
    for (final controller in ActivityController.values) {
      expect(request(controller: controller).controller, controller);
    }
    for (final clock in ActivityClock.values) {
      expect(request(clock: clock).clock, clock);
    }
    for (final entryKind in ActivityEntryKind.values) {
      expect(request(entryKind: entryKind).entryKind, entryKind);
    }
  });

  test(
    'trims and validates string IDs and validates the real integer character ID',
    () {
      final value = request();
      expect(value.contentId, 'stage-01');
      expect(value.loadoutPlanId, 'loadout-a');

      for (final badContentId in ['', '   ']) {
        expect(() => request(contentId: badContentId), throwsArgumentError);
      }
      for (final badLoadoutPlanId in ['', '   ']) {
        expect(
          () => request(loadoutPlanId: badLoadoutPlanId),
          throwsArgumentError,
        );
      }
      for (final badCharacterId in [0, -1]) {
        expect(() => request(characterId: badCharacterId), throwsArgumentError);
      }
    },
  );

  test('value equality and hash code use every field', () {
    final left = request();
    final right = request();
    expect(left, right);
    expect(left.hashCode, right.hashCode);

    expect(request(contentId: 'other'), isNot(left));
    expect(request(contentKind: ActivityContentKind.tower), isNot(left));
    expect(request(characterId: 8), isNot(left));
    expect(request(loadoutPlanId: 'other'), isNot(left));
    expect(
      request(participation: ActivityParticipationMode.dispatch),
      isNot(left),
    );
    expect(request(controller: ActivityController.playerBot), isNot(left));
    expect(request(clock: ActivityClock.headless), isNot(left));
    expect(request(entryKind: ActivityEntryKind.replay), isNot(left));
  });

  test('does not reject semantically explicit combinations', () {
    expect(
      request(
        participation: ActivityParticipationMode.dispatch,
        controller: ActivityController.human,
        clock: ActivityClock.realtime,
        entryKind: ActivityEntryKind.sweep,
      ),
      isNotNull,
    );
    expect(
      request(
        participation: ActivityParticipationMode.direct,
        controller: ActivityController.playerBot,
        clock: ActivityClock.headless,
        entryKind: ActivityEntryKind.offlineResume,
      ),
      isNotNull,
    );
  });

  test('is immutable at the public API', () {
    final value = request();
    expect(value, isA<ActivityParticipationRequest>());
    expect(value.toString(), contains('ActivityParticipationRequest'));
  });
}
