/// P1 #42 Phase 2 §10 P1.z 机制百科分类(对齐 GDD §10.1 8 档解锁节奏)。
///
/// 每个 [CodexCategory] 对应 §10.1 的一档,与 [SaveData.tutorialStep] 1-8 映射。
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
}

extension CodexCategoryStep on CodexCategory {
  /// 返回该 category 对应的 §10.1 解锁档(1-8)。
  int get step {
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
    }
  }
}
