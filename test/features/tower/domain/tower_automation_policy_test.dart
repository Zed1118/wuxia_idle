import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';

void main() {
  ActivityParticipationRequest request({
    ActivityContentKind contentKind = ActivityContentKind.tower,
    String contentId = 'tower_7',
    int characterId = 42,
    String? loadoutPlanId,
    ActivityParticipationMode participation = ActivityParticipationMode.direct,
    ActivityController controller = ActivityController.playerBot,
    ActivityClock clock = ActivityClock.headless,
    ActivityEntryKind entryKind = ActivityEntryKind.sweep,
  }) => ActivityParticipationRequest(
    contentId: contentId,
    contentKind: contentKind,
    characterId: characterId,
    loadoutPlanId:
        loadoutPlanId ??
        towerAutomationLoadoutPlanId(floorIndex: 7, characterId: characterId),
    participation: participation,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  test(
    'only direct playerBot headless sweep of an already-cleared floor passes',
    () {
      final decision = TowerAutomationPolicy.evaluate(
        request: request(),
        floorIndex: 7,
        highestClearedFloor: 7,
      );

      expect(decision.allowed, isTrue);
      expect(decision.rejectionReason, isNull);
    },
  );

  test('first-clear, visible bot, dispatch, and wrong content fail closed', () {
    final cases =
        <
          ({
            ActivityParticipationRequest request,
            TowerAutomationRejectionReason reason,
          })
        >[
          (
            request: request(entryKind: ActivityEntryKind.firstClear),
            reason: TowerAutomationRejectionReason.unsupportedEntryKind,
          ),
          (
            request: request(clock: ActivityClock.realtime),
            reason: TowerAutomationRejectionReason.visibleRealtimePlayerBot,
          ),
          (
            request: request(participation: ActivityParticipationMode.dispatch),
            reason: TowerAutomationRejectionReason.unsupportedParticipation,
          ),
          (
            request: request(contentKind: ActivityContentKind.mainline),
            reason: TowerAutomationRejectionReason.wrongContentKind,
          ),
          (
            request: request(contentId: 'tower_8'),
            reason: TowerAutomationRejectionReason.wrongContentId,
          ),
          (
            request: request(loadoutPlanId: 'tower:7:character:999'),
            reason: TowerAutomationRejectionReason.wrongLoadoutPlan,
          ),
        ];

    for (final item in cases) {
      final decision = TowerAutomationPolicy.evaluate(
        request: item.request,
        floorIndex: 7,
        highestClearedFloor: 7,
      );
      expect(decision.allowed, isFalse, reason: item.reason.name);
      expect(decision.rejectionReason, item.reason);
    }
  });

  test('已通层精确允许 durable dispatch tuple', () {
    final dispatch = towerDurableDispatchRequest(
      floorIndex: 7,
      characterId: 42,
    );
    final decision = TowerAutomationPolicy.evaluate(
      request: dispatch,
      floorIndex: 7,
      highestClearedFloor: 7,
    );

    expect(decision.allowed, isTrue);
    expect(decision.rejectionReason, isNull);
    expect(dispatch.participation, ActivityParticipationMode.dispatch);
    expect(dispatch.controller, ActivityController.playerBot);
    expect(dispatch.clock, ActivityClock.headless);
    expect(dispatch.entryKind, ActivityEntryKind.offlineResume);
  });

  test('durable dispatch 混合 tuple fail closed', () {
    final cases = [
      request(entryKind: ActivityEntryKind.offlineResume),
      request(
        participation: ActivityParticipationMode.dispatch,
        entryKind: ActivityEntryKind.sweep,
      ),
    ];

    for (final value in cases) {
      final decision = TowerAutomationPolicy.evaluate(
        request: value,
        floorIndex: 7,
        highestClearedFloor: 7,
      );
      expect(decision.allowed, isFalse);
      expect(decision.rejectionReason, isNotNull);
    }
  });

  test('uncleared floor cannot be admitted as automation replay', () {
    final decision = TowerAutomationPolicy.evaluate(
      request: request(),
      floorIndex: 7,
      highestClearedFloor: 6,
    );

    expect(decision.allowed, isFalse);
    expect(
      decision.rejectionReason,
      TowerAutomationRejectionReason.firstClearRequired,
    );
  });
}
