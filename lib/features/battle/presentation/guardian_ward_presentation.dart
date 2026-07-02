/// floor30 护法结界（Task 6）表现层纯函数。
///
/// **纯读 [BattleState]，不写结算 / 不导入 domain/strategy**：判定逻辑镜像
/// `DefaultGroundStrategy.wardMultOf`（承伤管线用于减伤计算），但此处仅供
/// 展示护罩标签 / 破界题字用，判定本身极薄（≤5 行），跨层耦合成本高于
/// 局部重复的漂移风险，故不 import 策略内部（守任务边界）。
library;

import '../domain/battle_state.dart';

/// [defender] 当前是否处于护法结界庇护中：`guardianWardMult` 非空且
/// `guardianDefIds` 非空，且同队中至少一名 `enemyDefId` 属于该列表的护法存活。
bool isGuardianWardActive(BattleCharacter defender, BattleState state) {
  if (defender.guardianWardMult == null || defender.guardianDefIds.isEmpty) {
    return false;
  }
  final team = defender.teamSide == 1 ? state.rightTeam : state.leftTeam;
  return team.any(
    (c) =>
        c.isAlive &&
        c.enemyDefId != null &&
        defender.guardianDefIds.contains(c.enemyDefId),
  );
}

/// 边沿检测（镜像 `chargeTransitionSfx` 写法）：结界单位从「生效→失效」
/// （最后一名护法阵亡）→ 返回其 characterId 列表，供调用方弹破界题字 + 闪白。
/// `prev == null`（战斗刚开始）→ 无边沿，返回空。
List<int> guardianWardBreakEvents(BattleState? prev, BattleState next) {
  if (prev == null) return const [];
  final out = <int>[];
  for (final c in [...next.leftTeam, ...next.rightTeam]) {
    if (c.guardianWardMult == null || c.guardianDefIds.isEmpty) continue;
    final wasActive = isGuardianWardActive(c, prev);
    final isActive = isGuardianWardActive(c, next);
    if (wasActive && !isActive) out.add(c.characterId);
  }
  return out;
}
