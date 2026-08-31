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

  test('轻功仅允许已首通的 dispatch + bot + headless + offlineResume', () {
    const kind = DurableActivityKind.lightFoot;
    final stage = GameRepository.instance.getStage('stage_light_foot_01');
    final allowed = DurableActivityAutomationPolicy.evaluate(
      kind: kind,
      stage: stage,
      request: request(kind: kind, stageId: stage.id),
      alreadyCleared: true,
      formation: null,
    );
    expect(allowed.allowed, isTrue);

    final rejected = <DurableActivityAutomationDecision>[
      DurableActivityAutomationPolicy.evaluate(
        kind: kind,
        stage: stage,
        request: request(kind: kind, stageId: stage.id),
        alreadyCleared: false,
        formation: null,
      ),
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
