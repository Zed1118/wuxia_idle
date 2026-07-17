import 'codex_category.dart';

/// P1 #42 Phase 2 §10 P1.z 机制百科条目索引。
///
/// 仅含 id 字符串 + [CodexCategory] enum,**无中文文案**。
/// 文案存于 `data/narratives/codex/<id>.md`(DeepSeek 领地,2026-05-10 已落 18 篇)。
///
/// **19 条 = 8 档机制 + 4 机制补充阅读 + 7 江湖背景 lore**(2026-05-18 P2 扩段沉淀):
/// - 8 档机制(§10.1 解锁节奏):对应 [SaveData.tutorialStep] 1-8,未达档灰显占位
/// - 4 机制补充阅读(A 组):equipment_tiers / strengthening / weapon_forging / lost_techniques,
///   挂相关机制 [CodexCategory] 作扩展条目,与 8 档同走 step gating
/// - 7 江湖背景 lore(B 组):挂 [CodexCategory.lore],无 tutorialStep gating(GDD §10.2 永久可查)
///
/// UI 排序按本 entries 登记顺序(P2 Q2 拍板,代码 0 排序逻辑)。
class CodexIndex {
  CodexIndex._();

  /// 19 条机制百科 + 江湖背景条目。
  static const List<CodexIndexEntry> entries = [
    // 8 档机制(P1.z 已入,顺序 = §10.1 解锁档 step 升序)
    CodexIndexEntry(id: 'realm', category: CodexCategory.combat),
    CodexIndexEntry(id: 'resonance', category: CodexCategory.enhancement),
    CodexIndexEntry(
      id: 'techniques_and_styles',
      category: CodexCategory.techniques,
    ),
    CodexIndexEntry(
      id: 'three_styles_detail',
      category: CodexCategory.schoolCounter,
    ),
    CodexIndexEntry(id: 'retreat', category: CodexCategory.seclusion),
    CodexIndexEntry(id: 'master_disciple', category: CodexCategory.lineage),
    CodexIndexEntry(id: 'encounter_system', category: CodexCategory.encounter),
    CodexIndexEntry(id: 'combat_advanced', category: CodexCategory.advanced),

    // A 组 · 4 机制补充阅读(P2 扩段,挂现有机制 category)
    CodexIndexEntry(id: 'equipment_tiers', category: CodexCategory.combat),
    CodexIndexEntry(id: 'strengthening', category: CodexCategory.enhancement),
    CodexIndexEntry(id: 'weapon_forging', category: CodexCategory.enhancement),
    CodexIndexEntry(id: 'lost_techniques', category: CodexCategory.techniques),

    // B 组 · 7 江湖背景 lore(P2 扩段,顺序按主题密度:战斗 → 规则 → 门派 → 历史)
    CodexIndexEntry(id: 'hidden_weapons', category: CodexCategory.lore),
    CodexIndexEntry(id: 'battle_taboos', category: CodexCategory.lore),
    CodexIndexEntry(id: 'jianghu_medicine', category: CodexCategory.lore),
    CodexIndexEntry(id: 'jianghu_rules', category: CodexCategory.lore),
    CodexIndexEntry(id: 'jianghu_ranks', category: CodexCategory.lore),
    CodexIndexEntry(id: 'major_sects', category: CodexCategory.lore),
    CodexIndexEntry(id: 'famous_battles', category: CodexCategory.lore),
  ];

  /// 反查:`id` → [CodexIndexEntry] 或 null(未登记)。
  static CodexIndexEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// [CodexIndex.entries] 的元组(id + category;step 由 [CodexCategory.step] 派生)。
class CodexIndexEntry {
  final String id;
  final CodexCategory category;

  const CodexIndexEntry({required this.id, required this.category});

  /// 8 档机制返回 1-8;lore 返回 null(永久可查)。
  int? get step => category.step;
}
