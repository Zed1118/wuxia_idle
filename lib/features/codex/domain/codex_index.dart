import 'codex_category.dart';

/// P1 #42 Phase 2 §10 P1.z 机制百科条目索引(对齐 GDD §10.1 8 档解锁节奏)。
///
/// 仅含 id 字符串 + step int + [CodexCategory] enum,**无中文文案**。
/// 文案存于 `data/narratives/codex/<id>.md`(DeepSeek 领地,2026-05-10 已落 18 篇)。
///
/// 首批 8 条对齐 §10.1 8 档(7 篇现成 + 1 篇 DeepSeek P3 派单补)。
/// 扩展条目(equipment_tiers / weapon_forging / battle_taboos 等共 10 篇江湖背景文)
/// 留 P2 滚动入库,不绑 §10.1 8 档。
class CodexIndex {
  CodexIndex._();

  /// P1.z 首批 8 条机制百科条目。
  static const List<CodexIndexEntry> entries = [
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
    // 档 8 (combat_advanced):DeepSeek P3 派单补;缺时 loader graceful 跳过,
    // 生产 UI 显「待解锁」灰显占位(tutorialStep=8 玩家才能触达,DeepSeek 派单前
    // 玩家进度尚未到达)。
    CodexIndexEntry(id: 'combat_advanced', category: CodexCategory.advanced),
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

  int get step => category.step;
}
