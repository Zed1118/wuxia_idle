/// P2.3 飞升 + 遗物 transfer 数据模型(spec p2_3_ascension_spec_2026-05-24)。
///
/// AscensionEligibility 4 子条件 + canAscend 聚合 / AscensionResult 持 transfer
/// 摘要。无 Isar 字段(纯 value object · AscendService 返回结构)。
library;

/// 飞升 eligibility 4 子条件 + 聚合判定(Q4d 3 条件 + active 校验)。
///
/// caller 端 `ref.watch(ascensionEligibilityProvider)` 拿到本对象,据 [canAscend]
/// 决定按钮 enable / disable + tooltip 显未达 [missingReasons] 清单。
class AscensionEligibility {
  /// founder 在 SaveData.activeCharacterIds(必须 active 角色才能飞升)。
  final bool inActiveCharacters;

  /// founder.realm == wuSheng·dengFeng(Q4d 境界拦截)。
  final bool realmAtPeak;

  /// stage_inner_demon_07 已 cleared(Q4d 心魔末关拦截)。
  final bool innerDemon07Cleared;

  /// stage_06_05 已 cleared(Q4d Ch6 末关拦截)。
  final bool mainline0605Cleared;

  /// 至少 1 个 lineageRole 属弟子(disciple/senior/junior · isDiscipleRole) && isAlive=true 的徒弟(transfer target)。
  final bool hasDiscipleTarget;

  const AscensionEligibility({
    required this.inActiveCharacters,
    required this.realmAtPeak,
    required this.innerDemon07Cleared,
    required this.mainline0605Cleared,
    required this.hasDiscipleTarget,
  });

  /// 全空 / 兜底(SaveData 未初始化 / fixture 不带 ascension 段时)。
  static const AscensionEligibility blocked = AscensionEligibility(
    inActiveCharacters: false,
    realmAtPeak: false,
    innerDemon07Cleared: false,
    mainline0605Cleared: false,
    hasDiscipleTarget: false,
  );

  /// 5 子条件全 true → 飞升入口 enable。任一 false → disable + tooltip。
  bool get canAscend =>
      inActiveCharacters &&
      realmAtPeak &&
      innerDemon07Cleared &&
      mainline0605Cleared &&
      hasDiscipleTarget;

  /// 未满足子条件的中文清单(UI tooltip 用)。
  /// 顺序固定(对应 AscensionScreen 校验提示顺序)。
  List<String> get missingReasons {
    final reasons = <String>[];
    if (!inActiveCharacters) reasons.add('祖师不在出战阵容');
    if (!realmAtPeak) reasons.add('祖师未达武圣·登峰');
    if (!innerDemon07Cleared) reasons.add('心魔末关「心魔·真」未通');
    if (!mainline0605Cleared) reasons.add('飞升主线「昆仑山顶」未通');
    if (!hasDiscipleTarget) reasons.add('无可继承遗物的弟子');
    return reasons;
  }
}

/// 飞升完成 transfer 摘要(AscendService.performAscend 返回值)。
///
/// caller 端拿到本对象后:① snackbar 显「飞升渡劫已成 · 已传 N 件遗物」②
/// 跳回 main_menu · invalidate `founderBuffActiveProvider` /
/// `allEquipmentsProvider` / `activeCharactersProvider`。
class AscensionResult {
  /// 实际传出件数(spec 校验后 = `selections.length` · 在 [1, 2] 范围)。
  final int transferredCount;

  /// founder 是否已退出 active(本批永 true · founder.isActive=false 副作用)。
  final bool founderRetired;

  /// 传出的 Equipment.id 清单(UI snackbar 可显「兵器 + 甲胄」名 · order 保留)。
  final List<int> heritageEquipmentIds;

  /// 受益 disciple.id 清单(去重 · order 按 selections 插入序)。
  final List<int> beneficiaryDiscipleIds;

  /// 接任 founder 身份的弟子 id(P5+ 真传位 · null = 不传位 P2.3 一代飞升兼容路径)。
  /// 非 null 时:`promotedDisciple.isFounder=true` · founder_buff 自然接管(active 中
  /// 找到 isFounder=true → buff 激活 · spec `p5_lineage_full_spec` §Q5 0 service 改)。
  final int? promotedDiscipleId;

  const AscensionResult({
    required this.transferredCount,
    required this.founderRetired,
    required this.heritageEquipmentIds,
    required this.beneficiaryDiscipleIds,
    this.promotedDiscipleId,
  });
}
