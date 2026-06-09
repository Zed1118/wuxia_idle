import 'dart:math';

import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';

/// Boss 胜利后掉技能书(可玩性 P1a · spec §二)。
///
/// - 主线 [StageDef.dropSkillManualId]:首通(stage 不在 [clearedStageIds] 快照)
///   必给真解;重复通关不再给(幂等)。**[clearedStageIds] 必须是本场写入前的快照**。
/// - 爬塔 [StageDef.dropSkillFragmentId]:按 [towerFragmentDropProb] rng 命中掉 1
///   残页,集齐阈值自动解锁(服务内判定)。
Future<void> runStageSkillDropHookAfterVictory({
  required StageDef stage,
  required SkillUnlockService svc,
  required Set<String> clearedStageIds,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  final manual = stage.dropSkillManualId;
  if (manual != null && !clearedStageIds.contains(stage.id)) {
    await svc.grantManual(manual); // 首通必给
  }
  final frag = stage.dropSkillFragmentId;
  if (frag != null && rng.nextDouble() < towerFragmentDropProb) {
    await svc.addFragment(frag, 1);
  }
}
