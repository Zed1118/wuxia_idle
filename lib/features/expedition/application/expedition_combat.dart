import '../domain/expedition_node.dart';

/// 远征战斗协作者（B2.2 注入 seam，§4.5/§9.1）。
///
/// 结算状态机 [ExpeditionService.settle] 只依赖本接口，与 Isar 加载 / 战斗执行 /
/// 敌队构建解耦：
///   - [memberCaps]：各成员满血/满真气上限，供节点后恢复量与 fresh 首战满血起。
///   - [fight]：按节点跑一场 headless 自动战斗，返回胜负与战后存活生命/真气。
///
/// 生产实装（B2.2b）：加载 Character → 派生 caps → `BattleCharacter.fromCharacter`
/// 注入当前远征 HP/qi 建队 → `ExpeditionBattleRunner.runNodeBattle`；修炼/伤势
/// 副作用（`BattleResolutionService.resolve`）归结算事务，不在本 seam。
/// 单测注入确定性 fake，隔离 Isar/战斗/敌队，专测 6 条结算不变式。
abstract class ExpeditionCombat {
  /// characterId → 满值上限。
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> characterIds);

  /// 跑一个战斗节点。[memberStates] 是当前存活成员的 HP/qi（fresh 时为满值），
  /// [nodeSeed] 为稳定随机种子（同 run/节点结果一致）。
  /// [cycleIndex] 本次远征周目（批 B 境界段推进；显式必传——runner 文件受
  /// 「零数值字面量」红线测约束，不设默认值）。
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  });
}

/// 成员满值上限（恢复量与 fresh 满血起用）。
class ExpeditionMemberCaps {
  const ExpeditionMemberCaps({required this.maxHp, required this.maxQi});
  final int maxHp;
  final int maxQi;
}

/// 成员当前生命/真气工作值。
class ExpeditionMemberVital {
  const ExpeditionMemberVital({required this.hp, required this.qi});
  final int hp;
  final int qi;
}

/// 单个战斗节点的结算面结果（比 `ExpeditionNodeBattleResult` 轻，不依赖
/// `BattleState`，便于状态机层单测）。
class ExpeditionNodeOutcome {
  const ExpeditionNodeOutcome({
    required this.leftWin,
    required this.survivorHp,
    required this.survivorQi,
  });

  /// 玩家方是否取胜；false → 结算侧「战败即停」。
  final bool leftWin;

  /// characterId → 战后当前生命（倒下者 0）。
  final Map<int, int> survivorHp;

  /// characterId → 战后当前真气。
  final Map<int, int> survivorQi;
}
