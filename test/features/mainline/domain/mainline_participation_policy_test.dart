import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';

/// P2-M2-R01 纯合同（MAINLINE-REPLAY-PARTICIPANT-01 / G0=C）：
/// 仅 realtime 重打（真人或前台 bot）可选 eligible 空闲角色；
/// headless 重打、扫荡、首通恒固定当前掌门；记录/成长/伤势归实际参与者。
/// 不实现、不接线、不发明 eligibility 判定。
void main() {
  ActivityParticipationRequest request({
    ActivityContentKind contentKind = ActivityContentKind.mainline,
    int characterId = 42,
    ActivityParticipationMode participation = ActivityParticipationMode.direct,
    ActivityController controller = ActivityController.human,
    ActivityClock clock = ActivityClock.realtime,
    ActivityEntryKind entryKind = ActivityEntryKind.replay,
  }) {
    return ActivityParticipationRequest(
      contentId: 'mainline_1_1',
      contentKind: contentKind,
      characterId: characterId,
      loadoutPlanId: 'plan-42',
      participation: participation,
      controller: controller,
      clock: clock,
      entryKind: entryKind,
    );
  }

  group('realtime 重打：真人或前台 bot 可选合格空闲角色', () {
    test('真人可见重打选择请求的合格空闲角色', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(controller: ActivityController.human),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selection.participantId, 42);
      expect(selection.source, MainlineParticipantSource.requestedIdleEligible);
    });

    test('前台 bot 可见重打同样可选合格空闲角色', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(controller: ActivityController.playerBot),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selection.participantId, 42);
      expect(selection.source, MainlineParticipantSource.requestedIdleEligible);
    });

    test('真人请求角色不合格（不空闲/不合格）时拒绝，无掌门回退', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(controller: ActivityController.human),
          currentLeaderId: 7,
          requestedIdleEligible: false,
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    });

    test('前台 bot 请求角色不合格时同样拒绝，无掌门回退', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(controller: ActivityController.playerBot),
          currentLeaderId: 7,
          requestedIdleEligible: false,
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    });
  });

  group('headless 重打：恒固定当前掌门', () {
    test('真人挂起的 headless 重打固定掌门，不受 eligibility 判定影响', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(
          controller: ActivityController.human,
          clock: ActivityClock.headless,
        ),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });

    test('前台 bot 的 headless 重打固定掌门，忽略请求角色', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
        ),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });
  });

  group('扫荡与首通：恒固定当前掌门', () {
    test('扫荡固定掌门，不受时钟与 controller 影响', () {
      for (final clock in ActivityClock.values) {
        for (final controller in ActivityController.values) {
          final selection = MainlineParticipationPolicy.resolveParticipant(
            request: request(
              controller: controller,
              clock: clock,
              entryKind: ActivityEntryKind.sweep,
            ),
            currentLeaderId: 7,
            requestedIdleEligible: true,
          );
          expect(selection.participantId, 7, reason: '$clock/$controller');
          expect(
            selection.source,
            MainlineParticipantSource.currentLeader,
            reason: '$clock/$controller',
          );
        }
      }
    });

    test('首通不在选择范围，固定掌门', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(entryKind: ActivityEntryKind.firstClear),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });
  });

  group('requestedIdleEligible=false：仅 realtime 重打拒绝', () {
    test('headless 重打（真人）在不合格时仍恒固定掌门', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(
          controller: ActivityController.human,
          clock: ActivityClock.headless,
        ),
        currentLeaderId: 7,
        requestedIdleEligible: false,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });

    test('headless 重打（前台 bot）在不合格时仍恒固定掌门', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
        ),
        currentLeaderId: 7,
        requestedIdleEligible: false,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });

    test('扫荡在不合格时仍恒固定掌门（全时钟全 controller）', () {
      for (final clock in ActivityClock.values) {
        for (final controller in ActivityController.values) {
          final selection = MainlineParticipationPolicy.resolveParticipant(
            request: request(
              controller: controller,
              clock: clock,
              entryKind: ActivityEntryKind.sweep,
            ),
            currentLeaderId: 7,
            requestedIdleEligible: false,
          );
          expect(selection.participantId, 7, reason: '$clock/$controller');
          expect(
            selection.source,
            MainlineParticipantSource.currentLeader,
            reason: '$clock/$controller',
          );
        }
      }
    });

    test('首通在不合格时仍恒固定掌门', () {
      final selection = MainlineParticipationPolicy.resolveParticipant(
        request: request(entryKind: ActivityEntryKind.firstClear),
        currentLeaderId: 7,
        requestedIdleEligible: false,
      );
      expect(selection.participantId, 7);
      expect(selection.source, MainlineParticipantSource.currentLeader);
    });

    test('对照：只有 realtime 重打的 false 拒绝，无掌门回退', () {
      for (final controller in ActivityController.values) {
        expect(
          () => MainlineParticipationPolicy.resolveParticipant(
            request: request(
              controller: controller,
              clock: ActivityClock.realtime,
            ),
            currentLeaderId: 7,
            requestedIdleEligible: false,
          ),
          throwsA(isA<MainlineParticipationRefusedError>()),
          reason: '$controller',
        );
      }
    });
  });

  group('归属与合同边界', () {
    test('选择结果即实际参与者，成长与伤势归属恒等', () {
      final selected = MainlineParticipationPolicy.resolveParticipant(
        request: request(),
        currentLeaderId: 7,
        requestedIdleEligible: true,
      );
      expect(selected.actualParticipantId, selected.participantId);
      final leaderPicked = MainlineParticipationPolicy.resolveParticipant(
        request: request(clock: ActivityClock.headless),
        currentLeaderId: 7,
        requestedIdleEligible: false,
      );
      expect(leaderPicked.actualParticipantId, leaderPicked.participantId);
    });

    test('掌门指针必须为正数', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(),
          currentLeaderId: 0,
          requestedIdleEligible: true,
        ),
        throwsArgumentError,
      );
    });

    test('非主线内容拒绝', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(contentKind: ActivityContentKind.tower),
          currentLeaderId: 7,
          requestedIdleEligible: true,
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    });

    test('差遣参与不属于本合同', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(participation: ActivityParticipationMode.dispatch),
          currentLeaderId: 7,
          requestedIdleEligible: true,
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    });

    test('offlineResume 未被本决定覆盖，拒绝猜测', () {
      expect(
        () => MainlineParticipationPolicy.resolveParticipant(
          request: request(entryKind: ActivityEntryKind.offlineResume),
          currentLeaderId: 7,
          requestedIdleEligible: true,
        ),
        throwsA(isA<MainlineParticipationRefusedError>()),
      );
    });
  });
}
