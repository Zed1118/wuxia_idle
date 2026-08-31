import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/gauntlet_automation_policy.dart';

ActivityParticipationRequest _request({
  String contentId = GauntletAutomationPolicy.gauntletId,
  ActivityContentKind contentKind = ActivityContentKind.gauntlet,
  ActivityParticipationMode participation = ActivityParticipationMode.direct,
  ActivityController controller = ActivityController.playerBot,
  ActivityClock clock = ActivityClock.headless,
  ActivityEntryKind entryKind = ActivityEntryKind.replay,
  String loadoutPlanId = 'gauntlet-plan-42',
}) => ActivityParticipationRequest(
  contentId: contentId,
  contentKind: contentKind,
  characterId: 42,
  loadoutPlanId: loadoutPlanId,
  participation: participation,
  controller: controller,
  clock: clock,
  entryKind: entryKind,
);

void main() {
  const cleared = {GauntletAutomationPolicy.gauntletId};

  test('only direct playerBot headless replay is admitted among 32 shapes', () {
    var allowed = 0;
    for (final participation in ActivityParticipationMode.values) {
      for (final controller in ActivityController.values) {
        for (final clock in ActivityClock.values) {
          for (final entryKind in ActivityEntryKind.values) {
            final decision = GauntletAutomationPolicy.evaluate(
              request: _request(
                participation: participation,
                controller: controller,
                clock: clock,
                entryKind: entryKind,
              ),
              clearedGauntletIds: cleared,
            );
            final exactTuple =
                participation == ActivityParticipationMode.direct &&
                controller == ActivityController.playerBot &&
                clock == ActivityClock.headless &&
                entryKind == ActivityEntryKind.replay;
            expect(
              decision.allowed,
              exactTuple,
              reason: _request(
                participation: participation,
                controller: controller,
                clock: clock,
                entryKind: entryKind,
              ).toString(),
            );
            if (decision.allowed) allowed += 1;
          }
        }
      }
    }
    expect(allowed, 1);
  });

  test('wrong content kinds are all rejected', () {
    for (final kind in ActivityContentKind.values) {
      if (kind == ActivityContentKind.gauntlet) continue;
      final decision = GauntletAutomationPolicy.evaluate(
        request: _request(contentKind: kind),
        clearedGauntletIds: cleared,
      );
      expect(decision.allowed, isFalse, reason: kind.name);
      expect(
        decision.rejectionReason,
        GauntletAutomationRejectionReason.wrongContentKind,
      );
    }
  });

  test('content ID comparison is exact and case-sensitive', () {
    for (final id in const [
      'duanhunzhuang_v2',
      'DuanHunZhuang',
      'gauntlet_1',
    ]) {
      final decision = GauntletAutomationPolicy.evaluate(
        request: _request(contentId: id),
        clearedGauntletIds: cleared,
      );
      expect(decision.allowed, isFalse, reason: id);
      expect(
        decision.rejectionReason,
        GauntletAutomationRejectionReason.wrongContentId,
      );
    }
  });

  test(
    'production request builder freezes the exact headless replay tuple',
    () {
      final request = gauntletHeadlessReplayRequest(characterId: 42);
      expect(request.contentKind, ActivityContentKind.gauntlet);
      expect(request.contentId, GauntletAutomationPolicy.gauntletId);
      expect(request.characterId, 42);
      expect(request.loadoutPlanId, 'gauntlet-plan-42');
      expect(request.participation, ActivityParticipationMode.direct);
      expect(request.controller, ActivityController.playerBot);
      expect(request.clock, ActivityClock.headless);
      expect(request.entryKind, ActivityEntryKind.replay);
    },
  );

  test('loadout plan must bind the exact participant', () {
    final decision = GauntletAutomationPolicy.evaluate(
      request: _request(loadoutPlanId: 'gauntlet-plan-7'),
      clearedGauntletIds: cleared,
    );
    expect(decision.allowed, isFalse);
    expect(
      decision.rejectionReason,
      GauntletAutomationRejectionReason.wrongLoadoutPlan,
    );
  });

  test('visible realtime playerBot has an explicit rejection reason', () {
    final decision = GauntletAutomationPolicy.evaluate(
      request: _request(clock: ActivityClock.realtime),
      clearedGauntletIds: cleared,
    );
    expect(decision.allowed, isFalse);
    expect(
      decision.rejectionReason,
      GauntletAutomationRejectionReason.visibleRealtimePlayerBot,
    );
  });

  test('headless first clear is rejected even if exact ID was cleared', () {
    final decision = GauntletAutomationPolicy.evaluate(
      request: _request(entryKind: ActivityEntryKind.firstClear),
      clearedGauntletIds: cleared,
    );
    expect(decision.allowed, isFalse);
    expect(
      decision.rejectionReason,
      GauntletAutomationRejectionReason.unsupportedEntryKind,
    );
  });

  test('replay requires exact clearedGauntletIds membership', () {
    for (final ids in const [
      <String>{},
      {'another_gauntlet'},
    ]) {
      final decision = GauntletAutomationPolicy.evaluate(
        request: _request(),
        clearedGauntletIds: ids,
      );
      expect(decision.allowed, isFalse, reason: ids.toString());
      expect(
        decision.rejectionReason,
        GauntletAutomationRejectionReason.fullClearRequired,
      );
    }
  });

  test('exact tuple and exact clear are admitted', () {
    final decision = GauntletAutomationPolicy.evaluate(
      request: _request(),
      clearedGauntletIds: cleared,
    );
    expect(decision.allowed, isTrue);
    expect(decision.rejectionReason, isNull);
  });
}
