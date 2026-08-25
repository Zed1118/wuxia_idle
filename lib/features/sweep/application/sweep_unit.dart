import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/strings.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../domain/sweep_recap.dart';
import 'sweep_settlement.dart';
import '../../../shared/battle_shared/battle_result.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../../shared/utils/math_random.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../battle/application/phase0a/phase0a_bot_tactic.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../mainline/application/phase0a_mainline_encounter_host.dart';
import '../../tower/domain/tower_automation_policy.dart';
import 'phase0a_sweep_headless_runner.dart';

/// 扫荡一个单位（主线一关 / 爬塔一层）。SweepScreen 逐个运行 Phase 0A
/// headless runner，再把终局快照接回既有事务结算。
abstract class SweepUnit {
  /// 进度展示用短标签（如「第3关 · 风波渡」「第5层」）。
  String get label;

  /// 扫荡 HUD 顶部提示。
  String get battleHint;

  /// 战斗场景背景图（null 走兜底底色）。
  String? get sceneBackgroundPath;

  /// 战斗 BGM 轨。
  BgmTrack get bgmTrack;

  /// 同核 headless 跑至终局；预算耗尽由结果显式标记。
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  });

  /// 把 headless 终局接回既有重打结算。
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    Phase0aSweepRunResult result,
  );
}

/// 主线一关扫荡单位。
class MainlineSweepUnit implements SweepUnit {
  MainlineSweepUnit({required this.stage, required this.cycle});

  final StageDef stage;
  final int cycle;

  @override
  String get label => stage.name;

  @override
  String get battleHint => stage.name;

  @override
  String? get sceneBackgroundPath => stage.sceneBackgroundPath;

  @override
  BgmTrack get bgmTrack =>
      bgmTrackForStage(stage.stageType, isBoss: stage.isBossStage);

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) => Phase0aSweepHeadlessRunner(
    isar: IsarSetup.instance,
    numbers: ref.read(numbersConfigProvider),
    rng: ref.read(mathRandomProvider),
    botPolicy: policy,
    runtimeBindingSource: ref.read(
      phase0aMainlineEncounterRuntimeBindingSourceProvider,
    ),
    routeAuthority: ref.read(phase0aMainlineEncounterRouteAuthorityProvider),
  ).runMainline(stage: stage, cycleIndex: cycle);

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    Phase0aSweepRunResult result,
  ) {
    final settlement = result.settlement;
    if (settlement == null) return Future.value(null);
    if (settlement.result != BattleResult.leftWin) return Future.value(null);
    return settleMainlineSweepVictory(
      ref: ref,
      stage: stage,
      cycle: cycle,
      settlementSnapshot: settlement,
      expectedParticipantId: result.expectedParticipantId,
    );
  }
}

/// A single already-cleared mainline stage replayed without rendering. It uses
/// the same headless kernel as sweep but remains a distinct product mode and
/// never spends sweep readiness.
class MainlineHeadlessReplayUnit implements SweepUnit {
  MainlineHeadlessReplayUnit({required this.stage, required this.cycle});

  final StageDef stage;
  final int cycle;

  @override
  String get label => stage.name;

  @override
  String get battleHint => stage.name;

  @override
  String? get sceneBackgroundPath => stage.sceneBackgroundPath;

  @override
  BgmTrack get bgmTrack =>
      bgmTrackForStage(stage.stageType, isBoss: stage.isBossStage);

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) =>
      Phase0aSweepHeadlessRunner(
        isar: IsarSetup.instance,
        numbers: ref.read(numbersConfigProvider),
        rng: ref.read(mathRandomProvider),
        botPolicy: policy,
        runtimeBindingSource: ref.read(
          phase0aMainlineEncounterRuntimeBindingSourceProvider,
        ),
        routeAuthority: ref.read(
          phase0aMainlineEncounterRouteAuthorityProvider,
        ),
      ).runMainline(
        stage: stage,
        cycleIndex: cycle,
        entryKind: ActivityEntryKind.replay,
      );

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    Phase0aSweepRunResult result,
  ) {
    final settlement = result.settlement;
    final expectedParticipantId = result.expectedParticipantId;
    if (settlement == null || expectedParticipantId == null) {
      return Future.value(null);
    }
    if (settlement.result != BattleResult.leftWin) return Future.value(null);
    return settleMainlineHeadlessReplayVictory(
      ref: ref,
      stage: stage,
      cycle: cycle,
      settlementSnapshot: settlement,
      expectedParticipantId: expectedParticipantId,
    );
  }
}

/// 爬塔一层扫荡单位。
class TowerSweepUnit implements SweepUnit {
  TowerSweepUnit({required this.floor, required this.cycleIndex});

  final TowerFloorDef floor;
  final int cycleIndex;

  @override
  String get label => UiStrings.towerFloorLabel(floor.floorIndex);

  @override
  String get battleHint => UiStrings.towerFloorLabel(floor.floorIndex);

  @override
  String? get sceneBackgroundPath => floor.sceneBackgroundPath;

  @override
  BgmTrack get bgmTrack => BgmTrack.tower;

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(
    WidgetRef ref, {
    required Phase0aBotTacticPolicy policy,
  }) async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final participantId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (id) async => await isar.characters.get(id) != null,
    );
    final request = ActivityParticipationRequest(
      contentId: towerAutomationContentId(floor.floorIndex),
      contentKind: ActivityContentKind.tower,
      characterId: participantId,
      loadoutPlanId: towerAutomationLoadoutPlanId(
        floorIndex: floor.floorIndex,
        characterId: participantId,
      ),
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.sweep,
    );
    return Phase0aSweepHeadlessRunner(
      isar: isar,
      numbers: ref.read(numbersConfigProvider),
      rng: ref.read(mathRandomProvider),
      botPolicy: policy,
    ).runTower(floor: floor, cycleIndex: cycleIndex, request: request);
  }

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    Phase0aSweepRunResult result,
  ) {
    final settlement = result.settlement;
    if (settlement == null) return Future.value(null);
    if (settlement.result != BattleResult.leftWin) return Future.value(null);
    return settleTowerSweepVictory(
      ref: ref,
      floor: floor,
      settlementSnapshot: settlement,
      admission: result.towerAutomationAdmission,
    );
  }
}
