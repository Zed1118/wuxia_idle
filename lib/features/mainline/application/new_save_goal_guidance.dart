import '../../../core/domain/enums.dart';
import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/stage_def.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../domain/mainline_replay_reward_route.dart';
import 'mainline_progress_service.dart';

enum NewSaveGoalReason {
  firstClearBoss,
  learnSkill,
  getEquipment,
  gatherMaterial,
  continueJourney,
}

class NewSaveGoalGuidance {
  const NewSaveGoalGuidance({
    required this.chapterIndex,
    required this.stageIndex,
    required this.stage,
    required this.rumorTable,
    required this.route,
    required this.reason,
  });

  final int chapterIndex;
  final int stageIndex;
  final StageDef stage;
  final DropRumorTable rumorTable;
  final MainlineReplayRewardRoute route;
  final NewSaveGoalReason reason;

  static NewSaveGoalGuidance? fromChapterEntries({
    required int chapterIndex,
    required List<StageEntry> entries,
  }) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.status != StageStatus.available) continue;
      return fromStage(
        chapterIndex: chapterIndex,
        stageIndex: i + 1,
        stage: entry.def,
      );
    }
    return null;
  }

  static NewSaveGoalGuidance fromStage({
    required int chapterIndex,
    required int stageIndex,
    required StageDef stage,
  }) {
    final rumorTable = DropRumorTable.fromDropTable(
      stage.dropTable,
      gating: FirstClearGating.scrollOnly,
    );
    final route = MainlineReplayRewardRoute.fromStage(stage);
    return NewSaveGoalGuidance(
      chapterIndex: chapterIndex,
      stageIndex: stageIndex,
      stage: stage,
      rumorTable: rumorTable,
      route: route,
      reason: _reasonFor(stage, route),
    );
  }

  static NewSaveGoalReason _reasonFor(
    StageDef stage,
    MainlineReplayRewardRoute route,
  ) {
    if (stage.dropSkillManualId != null) return NewSaveGoalReason.learnSkill;
    if (stage.isBossStage) return NewSaveGoalReason.firstClearBoss;
    if (route.kinds.contains(MainlineReplayRewardKind.equipment)) {
      return NewSaveGoalReason.getEquipment;
    }
    if (stage.dropTable.any((entry) => entry is ItemDrop)) {
      return NewSaveGoalReason.gatherMaterial;
    }
    return NewSaveGoalReason.continueJourney;
  }
}
