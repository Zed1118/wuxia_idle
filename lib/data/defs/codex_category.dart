/// P1 #42 Phase 2 §10 P1.z 机制百科分类(对齐 GDD §10.1 8 档解锁节奏)。
///
/// 8 档机制 [combat]-[advanced] 对应 §10.1 解锁档,与 [SaveData.tutorialStep] 1-8 映射;
/// [lore] 为 P2 扩段加入的「江湖背景」,无 tutorialStep gating(GDD §10.2 永久可查)。
enum CodexCategory {
  /// 档 1:战斗 + 境界 + 装备掉落。
  combat,

  /// 档 2:装备强化 + 装备共鸣。
  enhancement,

  /// 档 3:心法系统(主修+辅修+修炼度)。
  techniques,

  /// 档 4:三流派克制(刚猛/灵巧/阴柔)。
  schoolCounter,

  /// 档 5:闭关 + 时间锚点(节气/时辰/地点)。
  seclusion,

  /// 档 6:师徒系统(收徒+师承遗物+传承)。
  lineage,

  /// 档 7:奇遇 + 武学领悟 + 辅修心法。
  encounter,

  /// 档 8:装备开锋 + 心血结晶 + 心法相生。
  advanced,

  /// P2 扩段:江湖背景文(无 tutorialStep,永久可查)。
  lore,
}

extension CodexCategoryStep on CodexCategory {
  /// 8 档机制返回对应解锁档(1-8);[lore] 返回 null(永久可查不 gate)。
  int? get step {
    switch (this) {
      case CodexCategory.combat:
        return 1;
      case CodexCategory.enhancement:
        return 2;
      case CodexCategory.techniques:
        return 3;
      case CodexCategory.schoolCounter:
        return 4;
      case CodexCategory.seclusion:
        return 5;
      case CodexCategory.lineage:
        return 6;
      case CodexCategory.encounter:
        return 7;
      case CodexCategory.advanced:
        return 8;
      case CodexCategory.lore:
        return null;
    }
  }

  /// 是否为 8 档机制条目(用于 UI 分段 + unlockedCount 分母 = 8)。
  bool get isMechanic => step != null;

  /// 是否为 lore 江湖背景条目(永远 unlocked)。
  bool get isLore => this == CodexCategory.lore;
}
