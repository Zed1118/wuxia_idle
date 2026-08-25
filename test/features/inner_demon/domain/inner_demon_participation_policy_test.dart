import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_participation_policy.dart';

void main() {
  const stageId = 'stage_inner_demon_01';
  const characterId = 7;

  ActivityParticipationRequest request({
    ActivityContentKind contentKind = ActivityContentKind.innerDemon,
    ActivityParticipationMode participation = ActivityParticipationMode.direct,
    ActivityController controller = ActivityController.human,
    ActivityClock clock = ActivityClock.realtime,
    ActivityEntryKind entryKind = ActivityEntryKind.firstClear,
    String contentId = stageId,
    int participantId = characterId,
    String? loadoutPlanId,
  }) => ActivityParticipationRequest(
    contentId: contentId,
    contentKind: contentKind,
    characterId: participantId,
    loadoutPlanId:
        loadoutPlanId ??
        innerDemonLoadoutPlanId(stageId: stageId, characterId: characterId),
    participation: participation,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  test('只允许本人 direct + human + realtime 的首通或重打', () {
    for (final contentKind in ActivityContentKind.values) {
      for (final participation in ActivityParticipationMode.values) {
        for (final controller in ActivityController.values) {
          for (final clock in ActivityClock.values) {
            for (final entryKind in ActivityEntryKind.values) {
              final decision = InnerDemonParticipationPolicy.evaluate(
                request: request(
                  contentKind: contentKind,
                  participation: participation,
                  controller: controller,
                  clock: clock,
                  entryKind: entryKind,
                ),
                expectedStageId: stageId,
                expectedCharacterId: characterId,
              );
              final shouldAllow =
                  contentKind == ActivityContentKind.innerDemon &&
                  participation == ActivityParticipationMode.direct &&
                  controller == ActivityController.human &&
                  clock == ActivityClock.realtime &&
                  (entryKind == ActivityEntryKind.firstClear ||
                      entryKind == ActivityEntryKind.replay);
              expect(
                decision.allowed,
                shouldAllow,
                reason:
                    '$contentKind/$participation/$controller/$clock/$entryKind',
              );
              expect(
                decision.rejectionReason,
                shouldAllow ? isNull : isNotNull,
              );
            }
          }
        }
      }
    }
  });

  test('错关、替代角色与伪造装配方案全部 fail closed', () {
    expect(
      InnerDemonParticipationPolicy.evaluate(
        request: request(contentId: 'stage_inner_demon_02'),
        expectedStageId: stageId,
        expectedCharacterId: characterId,
      ).allowed,
      isFalse,
    );
    expect(
      InnerDemonParticipationPolicy.evaluate(
        request: request(participantId: 8),
        expectedStageId: stageId,
        expectedCharacterId: characterId,
      ).allowed,
      isFalse,
    );
    expect(
      InnerDemonParticipationPolicy.evaluate(
        request: request(loadoutPlanId: 'forged'),
        expectedStageId: stageId,
        expectedCharacterId: characterId,
      ).allowed,
      isFalse,
    );
  });
}
