/// 门派成员阶位(P4.1 §12.2 default 决议 Q5=A · 三阶组织层阶位)。
///
/// **设计原则**:组织层阶位 ≠ 修炼境界,**不开新七阶**(GDD §5.3 三系锁死
/// 仅约束「境界 ↔ 装备阶 ↔ 心法阶」三系)。本枚举三阶仅用于门派内升迁:
///
/// - `initiate`:初入 — 招收当时默认起点
/// - `inner`:内门 — `totalWins ≥ inner_min_contribution`(`numbers.yaml
///   sect_management.rank_promote_threshold`)由玩家手动升
/// - `elder`:长老 — `totalWins ≥ elder_min_contribution` 由玩家手动升
///
/// 单向不可降阶(`SectMemberService.promoteRank` enforce)。Demo 阶段自动升迁
/// 规则细化挂账 1.1(spec p4_1_sect_management_spec_2026-05-25 §9 R4)。
enum SectRank {
  initiate, // 初入
  inner,    // 内门
  elder,    // 长老
}
