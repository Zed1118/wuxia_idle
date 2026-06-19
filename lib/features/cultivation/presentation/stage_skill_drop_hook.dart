import 'dart:math';

import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_drop_result.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

/// 技能书掉落核心(可玩性 P1a · spec §二 · 第七阶段批二④ 回传掉落结果)。
///
/// - [manualId]:真解,仅 [isFirstClear] 给(重复不再给,幂等)。
/// - [fragmentId]:残页,按 [fragmentDropProb] rng 命中掉 1,集齐阈值自动解锁(服务内判定)。
///
/// 返回 [SkillDropResult]，供战后珍稀展示分层（Task 11 消费）。
/// 同一场可同时给真解 + 残页（首通 Boss 关挂了两者时，虽罕见但合法）：
/// 结果合并为单个 [SkillDropResult]（[SkillDropResult.manualGranted] 和
/// [SkillDropResult.fragmentSkillId] 均可非空）。
Future<SkillDropResult> _applySkillDrop({
  String? manualId,
  String? fragmentId,
  required bool isFirstClear,
  required SkillUnlockService svc,
  required double fragmentDropProb,
  required Random rng,
}) async {
  // 真解分支：首通 + 本次新授 → capture granted。
  String? granted;
  if (manualId != null && isFirstClear) {
    final wasNew = await svc.grantManual(manualId);
    granted = wasNew ? manualId : null;
  }

  // 残页分支：rng 命中 → capture 残页结果。
  SkillDropResult? fragResult;
  if (fragmentId != null && rng.nextDouble() < fragmentDropProb) {
    fragResult = await svc.addFragment(fragmentId, 1);
  }

  // 合并两条分支结果。
  if (granted == null && fragResult == null) {
    return SkillDropResult.none;
  }
  return SkillDropResult(
    manualGranted: granted,
    fragmentSkillId: fragResult?.fragmentSkillId,
    fragmentCount: fragResult?.fragmentCount ?? 0,
    fragmentThreshold: fragResult?.fragmentThreshold ?? 0,
    fragmentJustUnlocked: fragResult?.fragmentJustUnlocked ?? false,
  );
}

/// 主线 Boss 胜利掉技能书(spec §二)。真解仅首通(stage 不在 [clearedStageIds]
/// 快照)给;残页按概率。**[clearedStageIds] 必须是本场写入前的快照**。
///
/// 返回 [SkillDropResult]，供战后珍稀展示分层。
Future<SkillDropResult> runStageSkillDropHookAfterVictory({
  required StageDef stage,
  required SkillUnlockService svc,
  required Set<String> clearedStageIds,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  return _applySkillDrop(
    manualId: stage.dropSkillManualId,
    fragmentId: stage.dropSkillFragmentId,
    isFirstClear: !clearedStageIds.contains(stage.id),
    svc: svc,
    fragmentDropProb: towerFragmentDropProb,
    rng: rng,
  );
}

/// 爬塔 Boss 胜利掉残页(spec §二)。爬塔只掉残页不给真解;**非首通限定**——
/// 每次 Boss 胜利都 rng 掉(重复刷 Boss 集残页是预期 grind)。
///
/// 返回 [SkillDropResult]，供战后珍稀展示分层。
Future<SkillDropResult> runTowerSkillDropHookAfterVictory({
  required TowerFloorDef floor,
  required SkillUnlockService svc,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  return _applySkillDrop(
    manualId: null,
    fragmentId: floor.dropSkillFragmentId,
    isFirstClear: false,
    svc: svc,
    fragmentDropProb: towerFragmentDropProb,
    rng: rng,
  );
}
