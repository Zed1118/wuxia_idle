import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/activity/application/durable_activity_automation_service.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_automation_policy.dart';
import 'package:wuxia_idle/features/activity/domain/durable_activity_combat_run.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_automation_admission.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/gauntlet_automation_policy.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_participant_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_participation_policy.dart';
import 'package:wuxia_idle/features/tower/application/tower_automation_admission.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';

import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  test('六特殊模式各有真实 production admission owner，允许 tuple 全覆盖且不含主线', () {
    final productionConsumers = <Object>{
      TowerAutomationAdmissionService,
      DurableActivityAutomationService,
      resolveInnerDemonParticipantSnapshot,
      GauntletAutomationAdmissionService,
      ExpeditionService,
    };
    expect(productionConsumers, hasLength(5));

    final allowedByKind = <ActivityContentKind, bool>{
      ActivityContentKind.tower: TowerAutomationPolicy.evaluate(
        request: ActivityParticipationRequest(
          contentId: towerAutomationContentId(1),
          contentKind: ActivityContentKind.tower,
          characterId: 7,
          loadoutPlanId: towerAutomationLoadoutPlanId(
            floorIndex: 1,
            characterId: 7,
          ),
          participation: ActivityParticipationMode.direct,
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
          entryKind: ActivityEntryKind.sweep,
        ),
        floorIndex: 1,
        highestClearedFloor: 1,
      ).allowed,
      ActivityContentKind.lightFoot: _durableAllowed(
        DurableActivityKind.lightFoot,
        'stage_light_foot_01',
      ),
      ActivityContentKind.massBattle: _durableAllowed(
        DurableActivityKind.massBattle,
        'stage_mass_battle_01',
      ),
      ActivityContentKind.innerDemon: InnerDemonParticipationPolicy.evaluate(
        request: ActivityParticipationRequest(
          contentId: 'stage_inner_demon_01',
          contentKind: ActivityContentKind.innerDemon,
          characterId: 7,
          loadoutPlanId: innerDemonLoadoutPlanId(
            stageId: 'stage_inner_demon_01',
            characterId: 7,
          ),
          participation: ActivityParticipationMode.direct,
          controller: ActivityController.human,
          clock: ActivityClock.realtime,
          entryKind: ActivityEntryKind.firstClear,
        ),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: 7,
      ).allowed,
      ActivityContentKind.gauntlet: GauntletAutomationPolicy.evaluate(
        request: ActivityParticipationRequest(
          contentId: GauntletAutomationPolicy.gauntletId,
          contentKind: ActivityContentKind.gauntlet,
          characterId: 7,
          loadoutPlanId: 'gauntlet-plan-7',
          participation: ActivityParticipationMode.direct,
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
          entryKind: ActivityEntryKind.replay,
        ),
        clearedGauntletIds: const {GauntletAutomationPolicy.gauntletId},
      ).allowed,
      ActivityContentKind.expedition: _isExactExpeditionDispatch(
        ExpeditionService.dispatchRequestFor(characterId: 7),
      ),
    };

    expect(allowedByKind.keys.toSet(), {
      for (final kind in ActivityContentKind.values)
        if (kind != ActivityContentKind.mainline) kind,
    });
    expect(allowedByKind.values.every((allowed) => allowed), isTrue);

    final towerDurableAllowed = TowerAutomationPolicy.evaluate(
      request: towerDurableDispatchRequest(floorIndex: 1, characterId: 7),
      floorIndex: 1,
      highestClearedFloor: 1,
    ).allowed;
    expect(towerDurableAllowed, isTrue);
  });
}

bool _durableAllowed(DurableActivityKind kind, String stageId) {
  final request = ActivityParticipationRequest(
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
    participation: ActivityParticipationMode.dispatch,
    controller: ActivityController.playerBot,
    clock: ActivityClock.headless,
    entryKind: ActivityEntryKind.offlineResume,
  );
  return DurableActivityAutomationPolicy.evaluate(
    kind: kind,
    stage: GameRepository.instance.getStage(stageId),
    request: request,
    alreadyCleared: true,
    formation: kind == DurableActivityKind.massBattle
        ? Formation.yanXing
        : null,
  ).allowed;
}

bool _isExactExpeditionDispatch(ActivityParticipationRequest request) =>
    request.contentKind == ActivityContentKind.expedition &&
    request.participation == ActivityParticipationMode.dispatch &&
    request.controller == ActivityController.playerBot &&
    request.clock == ActivityClock.headless &&
    request.entryKind == ActivityEntryKind.firstClear;
