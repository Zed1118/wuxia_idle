# Codex 14 分支复核 → 合并 closeout（2026-06-27）

> 一次性复核 14 个 Codex 独立 worktree/分支，13 个合入 `main` 并 push，1 个挂起。
> 最终 `main` = `0d75f49b`（已 push origin/main）。全量 `flutter analyze` 0 issue · `flutter test` **3176 passed / 1 skipped / 0 failed**。

## 复核结论一览

| 分支 | 结论 | 备注 |
|---|---|---|
| remove-pvp | 合并 | 用户拍板下线 PVP；分支自带 CLAUDE v1.24 / GDD v1.18 / ROADMAP 文档同步 |
| equipment-owner-fix | 合并 | 装备「装备中」判定真相源 owner→槽位；祖师未装备装备可售（用户确认 OK） |
| equipment-lock | 合并 | 加 `Equipment.isLocked`（Isar schema 0.32）+ 锁定保护 |
| inventory-organization | 合并 | 库存筛选/排序 + 批量候选规则（候选谓词与 service 权威谓词对齐） |
| offline-reward-breakdown | 合并 | 离线明细纯展示；修内联「小时」→ `UiStrings.hoursAmountLabel` |
| equipment-source-tracking | 合并 | 纯反查无 schema |
| resource-usage-lookup | 合并 | 物料用途反查，数据驱动 |
| save-management | 合并 | 仅本地备份（恢复刻意 stub），删除有路径守卫 |
| martial-manual-encyclopedia | 合并 | 武学百科（§5.7 替代教程弹窗） |
| redline-audit-view | 合并 | Debug 红线审计；阈值与 §5.4 一致；入口 kDebugMode 门控 |
| visual-acceptance-automation | 合并 | 视觉验收工具，不动产品玩法 |
| art-tone-audit | 合并 | 水墨色调审计：**high 级 Material 饱和色清零**；medium 4 / low 44 次级债仍列在 art_tone_audit.md（非阻断，2026-06-27 审查口径订正）|
| main-story-polish-pack | 合并 | 章末文案打磨；HEAD `c642d6c6`（=021b340a 超集，兄弟 -2/-3 已弃） |
| **breakthrough-material-gaps** | **挂起** | 见下 |

## 合并顺序（实际）

remove-pvp → visual-acceptance-automation → art-tone-audit → main-story-polish-pack → save-management → redline-audit-view → offline-reward-breakdown →（装备集群串行）equipment-owner-fix → equipment-lock → inventory-organization → equipment-source-tracking → resource-usage-lookup → martial-manual-encyclopedia

## 冲突 / 修复要点

- 装备集群 #3/#4：disposal 判定以「主分支槽位判定为权威 + 叠加真 `isLocked`」解冲突；重生成 `equipment.g.dart`（gitignored 不随 merge 带过来）。
- #6 详情页：两个顶层声明共享尾括号的结构坑，手工补 `}`，确认 `_SourceSection` 已 wire。
- 2 个 follow-up 修复提交：离线「小时」走 UiStrings；主菜单按钮计数 20→21（redline-audit 的 debug 入口在测试态渲染，全量测唯一暴露的真回归）。
- baike 新 `@riverpod techniqueCodexProvider`：合并后跑 build_runner 才有 `.g.dart`。

## 挂起：breakthrough-material-gaps（突破材料缺口提示）

**为什么不合**（实测 worktree bcf9，非凭记忆）：

1. **死代码**：`BreakthroughMaterialGapResolver` / `BreakthroughMaterialRequirement` 全 `lib/` 仅在 `breakthrough_material_gap.dart` 自引用，零生产调用方，`.resolve()` 从不被调用。
2. **唯一接线恒空**：`character_panel_screen.dart:728` 写死 `materialGaps: const BreakthroughMaterialGapViewModel.empty()` → 面板常驻一行「突破物料 / 无需额外物料」。
3. **无数据源 / 机制不存在**：`data/` 无任何突破材料消耗 yaml；本作突破是**心魔门控**（`character_advancement_service.dart`）自动进阶，非材料门控。功能前提在游戏里不存在。
4. **违原则**：§5.7（对不存在的问题常驻答案）+ §7（backlog 只承载依赖未解除/需拍板项；此为「为不存在机制铺脚手架」）。

**结论**：代码无错，但实现的是本作没有的机制；合入 = 上线死代码 + 误导性空 UI。

**重启条件**：突破真的要消耗材料、且有对应 `data/*.yaml` 配置时再捡起。

**保留物**：分支 `codex/breakthrough-material-gaps` + worktree `/Users/a10506/.codex/worktrees/bcf9/挂机武侠`（HEAD `a20c50c0`）未删，可直接续。

> **2026-06-27 续 · 已退役**：重启评估后用户拍板方案 B（不引入「突破消耗材料」机制——本作突破 = EXP + 心魔关双门控、零材料，该机制不存在）。分支 `codex/breakthrough-material-gaps` + worktree bcf9（was `a20c50c0`）**已删除**，#8 正式销账。详 PROGRESS 顶段退役条目。

## 清理（已做）

- 删 15 worktree（13 已合 + polish-pack-2/-3 + 1 个 0ac2 detached 残留）；保留 bcf9。
- 删 15 本地分支（13 已合 `-d` + 2 兄弟 `-D`）；保留 breakthrough-material-gaps。
- 删备份 tag `pre-codex-merge-backup`。
