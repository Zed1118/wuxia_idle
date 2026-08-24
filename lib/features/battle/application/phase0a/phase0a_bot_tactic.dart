/// 可由宿主注入的玩家 Bot 战术画像。
///
/// 画像只描述已有玩家 command 的选择顺序，不拥有战斗规则、数值或
/// 表现层信息。默认 [production] 保留旧 adapter 的“所有 ready 技能同拍
/// 请求”行为；其余画像只是在同一 command 面上选择不同的优先级。
enum Phase0aBotTactic { seekGap, assault, steadyGuard }

enum Phase0aBotAction { gather, clear, numericSkill }

/// 玩家 Bot 的 typed policy。数值门槛仍由 [Phase0aPlayerInputAdapter] 和
/// reducer 负责；policy 只决定哪些已 ready 的 command 可以被发出。
final class Phase0aBotTacticPolicy {
  /// 生产入口对显式选择的三种战术做唯一 typed 映射。
  static Phase0aBotTacticPolicy forTactic(Phase0aBotTactic tactic) =>
      switch (tactic) {
        Phase0aBotTactic.seekGap => const Phase0aBotTacticPolicy.seekGap(),
        Phase0aBotTactic.assault => const Phase0aBotTacticPolicy.assault(),
        Phase0aBotTactic.steadyGuard =>
          const Phase0aBotTacticPolicy.steadyGuard(),
      };

  Phase0aBotTacticPolicy({
    required this.tactic,
    required List<Phase0aBotAction> actionPriority,
    required Set<Phase0aBotAction> enabledActions,
    required this.parallelTacticalActions,
    required this.requiresBurstWindow,
    required this.prioritizeBurstWindowTarget,
  }) : actionPriority = List.unmodifiable(actionPriority),
       enabledActions = Set.unmodifiable(enabledActions);

  /// 兼容既有生产 Bot：三个 tactical command 均按旧逻辑独立发出。
  const Phase0aBotTacticPolicy.production()
    : tactic = null,
      actionPriority = const [
        Phase0aBotAction.gather,
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      ],
      enabledActions = const {
        Phase0aBotAction.gather,
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      },
      parallelTacticalActions = true,
      requiresBurstWindow = false,
      prioritizeBurstWindowTarget = false;

  /// 寻隙画像：保留聚怪/清场资源，只在已有 ready 数字招式中择一输出。
  const Phase0aBotTacticPolicy.seekGap()
    : tactic = Phase0aBotTactic.seekGap,
      actionPriority = const [Phase0aBotAction.numericSkill],
      enabledActions = const {Phase0aBotAction.numericSkill},
      parallelTacticalActions = false,
      requiresBurstWindow = true,
      prioritizeBurstWindowTarget = true;

  /// 强攻画像：聚怪、清场和数字招式都可在同一拍请求，沿旧生产基线。
  const Phase0aBotTacticPolicy.assault()
    : tactic = Phase0aBotTactic.assault,
      actionPriority = const [
        Phase0aBotAction.gather,
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      ],
      enabledActions = const {
        Phase0aBotAction.gather,
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      },
      parallelTacticalActions = true,
      requiresBurstWindow = false,
      prioritizeBurstWindowTarget = false;

  /// 稳守画像：优先使用已有清场 command；不凭空推导护盾或危险区。
  const Phase0aBotTacticPolicy.steadyGuard()
    : tactic = Phase0aBotTactic.steadyGuard,
      actionPriority = const [
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      ],
      enabledActions = const {
        Phase0aBotAction.clear,
        Phase0aBotAction.numericSkill,
      },
      parallelTacticalActions = false,
      requiresBurstWindow = true,
      prioritizeBurstWindowTarget = true;

  final Phase0aBotTactic? tactic;
  final List<Phase0aBotAction> actionPriority;
  final Set<Phase0aBotAction> enabledActions;
  final bool parallelTacticalActions;

  /// Whether tactical actions are held until an observable burst window.
  final bool requiresBurstWindow;

  /// Whether a visible window target outranks the ordinary nearest target.
  final bool prioritizeBurstWindowTarget;

  bool allows(Phase0aBotAction action) => enabledActions.contains(action);
}
