import 'dart:math';

import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';

/// 技能书掉落核心(可玩性 P1a · spec §二)。
///
/// - [manualId]:真解,仅 [isFirstClear] 给(重复不再给,幂等)。
/// - [fragmentId]:残页,按 [fragmentDropProb] rng 命中掉 1,集齐阈值自动解锁(服务内判定)。
Future<void> _applySkillDrop({
  String? manualId,
  String? fragmentId,
  required bool isFirstClear,
  required SkillUnlockService svc,
  required double fragmentDropProb,
  required Random rng,
}) async {
  if (manualId != null && isFirstClear) {
    await svc.grantManual(manualId);
  }
  if (fragmentId != null && rng.nextDouble() < fragmentDropProb) {
    await svc.addFragment(fragmentId, 1);
  }
}

/// 主线 Boss 胜利掉技能书(spec §二)。真解仅首通(stage 不在 [clearedStageIds]
/// 快照)给;残页按概率。**[clearedStageIds] 必须是本场写入前的快照**。
Future<void> runStageSkillDropHookAfterVictory({
  required StageDef stage,
  required SkillUnlockService svc,
  required Set<String> clearedStageIds,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  await _applySkillDrop(
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
Future<void> runTowerSkillDropHookAfterVictory({
  required TowerFloorDef floor,
  required SkillUnlockService svc,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  await _applySkillDrop(
    manualId: null,
    fragmentId: floor.dropSkillFragmentId,
    isFirstClear: false,
    svc: svc,
    fragmentDropProb: towerFragmentDropProb,
    rng: rng,
  );
}
