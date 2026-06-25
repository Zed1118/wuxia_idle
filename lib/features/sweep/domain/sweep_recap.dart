/// 扫荡逐关战果的单关贡献（settle 一关后由结算 service 映射产出）。
class SweepBattleOutcome {
  /// 本关掉落装备件数。
  final int equipmentDrops;

  /// 本关物品掉落（defId → 数量，含银两 `item_silver`）。
  final Map<String, int> itemsByDefId;

  /// 本关累计经验（全员）。
  final int expGained;

  /// 本关角色升层（修炼度/境界）次数。
  final int realmAdvances;

  /// 本关掉落技能残页次数（爬塔重打仅此项，守防刷红线）。
  final int skillFragments;

  const SweepBattleOutcome({
    this.equipmentDrops = 0,
    this.itemsByDefId = const {},
    this.expGained = 0,
    this.realmAdvances = 0,
    this.skillFragments = 0,
  });
}

/// 扫荡战果总账（不可变，逐关 [accumulate] 折叠）。
///
/// 收尾 recap dialog 读此显「总掉落/银两/经验/升层」（数字跳动体例复用桃花岛纪事）。
class SweepRecap {
  /// 成功扫过的关数。
  final int stagesCleared;

  /// 累计掉落装备件数。
  final int equipmentDrops;

  /// 累计物品（defId → 数量，同 defId 跨关合并）。
  final Map<String, int> itemsByDefId;

  /// 累计经验。
  final int expGained;

  /// 累计升层次数。
  final int realmAdvances;

  /// 累计技能残页数。
  final int skillFragments;

  const SweepRecap({
    required this.stagesCleared,
    required this.equipmentDrops,
    required this.itemsByDefId,
    required this.expGained,
    required this.realmAdvances,
    required this.skillFragments,
  });

  const SweepRecap.empty()
      : stagesCleared = 0,
        equipmentDrops = 0,
        itemsByDefId = const {},
        expGained = 0,
        realmAdvances = 0,
        skillFragments = 0;

  /// 折入一关战果，返回新实例（原账不变）。
  SweepRecap accumulate(SweepBattleOutcome o) {
    final merged = Map<String, int>.of(itemsByDefId);
    o.itemsByDefId.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
    return SweepRecap(
      stagesCleared: stagesCleared + 1,
      equipmentDrops: equipmentDrops + o.equipmentDrops,
      itemsByDefId: merged,
      expGained: expGained + o.expGained,
      realmAdvances: realmAdvances + o.realmAdvances,
      skillFragments: skillFragments + o.skillFragments,
    );
  }
}
