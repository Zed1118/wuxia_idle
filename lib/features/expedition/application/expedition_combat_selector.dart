import 'package:isar_community/isar.dart';

import 'expedition_combat.dart';
import 'phase0a_expedition_combat_runner.dart';

/// 路线 C 终态 selector：只有单角色 Phase 0A 战斗路径。
///
/// 历史多人会话必须先由 `retireLegacyMultiplayerExpeditionOnOpen`
/// 发放已暂存奖励并释放占用；误入本 seam 直接 fail-fast，不再选择
/// 旧 3v3 runner。
ExpeditionCombat expeditionCombatFor(Isar isar, {required int memberCount}) {
  if (memberCount != 1) {
    throw StateError('路线 C 远征战斗只允许单角色，got $memberCount');
  }
  return Phase0aExpeditionCombatRunner(isar);
}
