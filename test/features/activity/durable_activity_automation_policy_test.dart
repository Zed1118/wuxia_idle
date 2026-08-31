import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_automation_policy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';

import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  ActivityParticipationRequest request({
    required DurableActivityKind kind,
    required String stageId,
    ActivityParticipationMode participation =
        ActivityParticipationMode.dispatch,
    ActivityController controller = ActivityController.playerBot,
    ActivityClock clock = ActivityClock.headless,
    ActivityEntryKind entryKind = ActivityEntryKind.offlineResume,
  }) => ActivityParticipationRequest(
    contentId: stageId,
    contentKind: kind == DurableActivityKind.lightFoot
        ? ActivityContentKind.lightFoot
        : ActivityContentKind.massBattle,
    characterId: 7,
    loadoutPlanId: durableActivityLoadoutPlanId(
      kind: kind,
      stageId: stageId,
      characterId: 7,
    ),
    participation: participation,
    controller: controller,
    clock: clock,
    entryKind: entryKind,
  );

  ActivityParticipationRequest replayRequest({
    required DurableActivityKind kind,
    required String stageId,
    required ActivityClock clock,
  }) => request(
    kind: kind,
    stageId: stageId,
    participation: ActivityParticipationMode.direct,
    clock: clock,
    entryKind: ActivityEntryKind.replay,
  );

  test('构造器固定产出前台重打、快速推演与差遣的精确三元组', () {
    const kind = DurableActivityKind.lightFoot;
    const stageId = 'stage_light_foot_01';

    final visible = durableActivityAutomationRequest(
      kind: kind,
      stageId: stageId,
      characterId: 7,
      mode: DurableActivityAutomationMode.visibleReplay,
    );
    final headless = durableActivityAutomationRequest(
      kind: kind,
      stageId: stageId,
      characterId: 7,
      mode: DurableActivityAutomationMode.headlessReplay,
    );
    final dispatch = durableActivityAutomationRequest(
      kind: kind,
      stageId: stageId,
      characterId: 7,
      mode: DurableActivityAutomationMode.dispatch,
    );

    expect(
      (
        visible.participation,
        visible.controller,
        visible.clock,
        visible.entryKind,
      ),
      (
        ActivityParticipationMode.direct,
        ActivityController.playerBot,
        ActivityClock.realtime,
        ActivityEntryKind.replay,
      ),
    );
    expect(
      (
        headless.participation,
        headless.controller,
        headless.clock,
        headless.entryKind,
      ),
      (
        ActivityParticipationMode.direct,
        ActivityController.playerBot,
        ActivityClock.headless,
        ActivityEntryKind.replay,
      ),
    );
    expect(
      (
        dispatch.participation,
        dispatch.controller,
        dispatch.clock,
        dispatch.entryKind,
      ),
      (
        ActivityParticipationMode.dispatch,
        ActivityController.playerBot,
        ActivityClock.headless,
        ActivityEntryKind.offlineResume,
      ),
    );
    expect(visible.contentId, stageId);
    expect(visible.characterId, 7);
    expect(visible.loadoutPlanId, 'lightFoot:$stageId:character:7');
  });

  test('轻功已首通后精确允许前台 bot、快速推演与 durable 差遣三通道', () {
    const kind = DurableActivityKind.lightFoot;
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final allowedRequests = [
      replayRequest(
        kind: kind,
        stageId: stage.id,
        clock: ActivityClock.realtime,
      ),
      replayRequest(
        kind: kind,
        stageId: stage.id,
        clock: ActivityClock.headless,
      ),
      request(kind: kind, stageId: stage.id),
    ];
    for (final allowedRequest in allowedRequests) {
      expect(
        DurableActivityAutomationPolicy.evaluate(
          kind: kind,
          stage: stage,
          request: allowedRequest,
          alreadyCleared: true,
          formation: null,
        ).allowed,
        isTrue,
      );
      expect(
        DurableActivityAutomationPolicy.evaluate(
          kind: kind,
          stage: stage,
          request: allowedRequest,
          alreadyCleared: false,
          formation: null,
        ).rejectionReason,
        DurableActivityAutomationRejectionReason.firstClearRequired,
      );
    }

    final rejected = <DurableActivityAutomationDecision>[
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(
          kind: kind,
          stageId: stage.id,
          participation: ActivityParticipationMode.direct,
        ),
        alreadyCleared: true,
        formation: null,
      ),
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(
          kind: kind,
          stageId: stage.id,
          controller: ActivityController.human,
        ),
        alreadyCleared: true,
        formation: null,
      ),
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(
          kind: kind,
          stageId: stage.id,
          clock: ActivityClock.realtime,
        ),
        alreadyCleared: true,
        formation: null,
      ),
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(
          kind: kind,
          stageId: stage.id,
          entryKind: ActivityEntryKind.sweep,
        ),
        alreadyCleared: true,
        formation: null,
      ),
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(kind: kind, stageId: stage.id),
        alreadyCleared: true,
        formation: Formation.yanXing,
      ),
    ];
    expect(rejected.every((decision) => !decision.allowed), isTrue);
  });

  test('守城必须持有玩家选择的阵型且不接受错内容', () {
    const kind = DurableActivityKind.massBattle;
    final stage = GameRepository.instance.getStage('stage_mass_battle_01');
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(kind: kind, stageId: stage.id),
        alreadyCleared: true,
        formation: Formation.baGua,
      ).allowed,
      isTrue,
    );
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: replayRequest(
          kind: kind,
          stageId: stage.id,
          clock: ActivityClock.realtime,
        ),
        alreadyCleared: true,
        formation: null,
      ).allowed,
      isTrue,
    );
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: replayRequest(
          kind: kind,
          stageId: stage.id,
          clock: ActivityClock.headless,
        ),
        alreadyCleared: true,
        formation: Formation.baGua,
      ).allowed,
      isTrue,
    );
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: replayRequest(
          kind: kind,
          stageId: stage.id,
          clock: ActivityClock.headless,
        ),
        alreadyCleared: true,
        formation: null,
      ).rejectionReason,
      DurableActivityAutomationRejectionReason.missingFormation,
    );
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(kind: kind, stageId: stage.id),
        alreadyCleared: true,
        formation: null,
      ).rejectionReason,
      DurableActivityAutomationRejectionReason.missingFormation,
    );
    expect(
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: GameRepository.instance.getStage('stage_light_foot_01'),
        request: request(kind: kind, stageId: stage.id),
        alreadyCleared: true,
        formation: Formation.baGua,
      ).rejectionReason,
      DurableActivityAutomationRejectionReason.wrongStageType,
    );
  });
}
