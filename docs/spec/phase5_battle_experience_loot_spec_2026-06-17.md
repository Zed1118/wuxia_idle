# 第五阶段 · 战斗体验与掉落优化 — Spec

> 日期：2026-06-17 · 状态：用户已拍板，开工
> 源：桌面《战斗体验与关卡掉落优化完整方案.md》（参考底稿，本 spec 不复制其全文）
> 设计支柱：GDD §5.7「战斗体验原则（爽感主旋律）」
> 命名约定：本批 = 第五阶段；内部用「主线 / 批次」细分，不嵌套「阶段」（见 memory feedback_wuxia_phase_naming）

## 0. 已锁定决策（用户拍板）

- 即拖即放、立即出手；**点击技能方块=简介浮层，拖=即放**，退掉旧「裸单击直接下发」。
- 爽感走表现层（hit-stop/残影/题字/闪白/掉落仪式），**不走数值膨胀（守 §5.2/§5.4）、不走抽卡式稀有炫耀（守 §2.1/§5.1）**。
- 首通门控 = **逐关粒度**：自动推进只到「已手动首通的最远关」，新关必手动首通；复用 `clearedStageCycleKeys`。
- 普攻降权 = **先诊断后定数值**，不预设系数。

## 1. Phase 0 已核实现状（2026-06-17 本仓实测，带 file:line）

- SkillDef 7 字段齐：`lib/data/defs/skill_def.dart:32-94`（description/internalForceCost/cooldownTurns/targetType/canInterrupt/requiresManualTrigger/powerMultiplier）。
- 战斗内力：`battle_state.dart:88-89,344`（进场满）；扣除 `default_ground_strategy.dart:477`；AI 判可用 `battle_ai.dart:139`。
- 闭关写回内力+cap：`seclusion_service.dart:358-362`。
- 内力条（无文字标签）：`character_avatar.dart:117-123`；技能按钮现显「耗N」：`battle_screen.dart:2074`，手势 onLongPress 系列 `:2148-2159`（拖招），onPressed `:2082`（现下发，将退役）。
- 残影：`projectile_trail.dart`（CustomPaint 笔触拖尾，攻击时命令式 spawn）。
- 伤害单一路径：`damage_calculator.dart:100-254`，普攻倍率 500 配 yaml。
- 掉落结构：`stage_def.dart:39` / `tower_floor_def.dart:47` 均有 `dropTable: List<DropEntry>`（`drop_entry.dart`）。
- balance_simulator：`test/tools/balance_simulator_test.dart`，出 winRate/ticks/峰值；**缺「普攻 vs 技能击杀/伤害占比」探针**。
- 首通→自动门控：**不存在**（仅 `clearedStageCycleKeys`/`clearedChapterCycleKeys` 记录 + auto/manual 二态，无强制判定）。

## 2. 主线一 · 战斗 UI 信息表达（风险低 · 先做）

铁律：文案进 `UiStrings`；简介/释义复用第四阶段帮助系统（`GlossaryTopicLabel` / `CodexIndex`），**禁造平行数据源**。

- 批次 1.1 内力条：`character_avatar.dart` 内力条加「内 X/Y」标签 + 加粗，不溢出。
- 批次 1.2 技能按钮文案：可用「耗内N · CDM」/ 冷却「冷却N」/「内力不足」（改 `UiStrings.skillCostShort` 等，现仅「耗N」、可用态不显 CD）。
- 批次 1.3 简介浮层 + 手势重构：**点击方块→简介浮层**（读 SkillDef.description/powerMultiplier/internalForceCost/cooldownTurns/targetType/特性），拖→即放；退掉裸单击下发。
- 批次 1.4 buff/debuff：贴角色头像展示 + hover 释义（复用帮助系统），优先级 影响生死 > 影响操作 > 纯数值。
- 验收：720p widget 测不溢出（含战斗指令台）+ analyze 0 + 嵌 ContextHelpButton 的屏 widget 测包 ProviderScope。

## 3. 主线二 · 参与机制(首通门控 + 即放打击感) · 普攻数值基本不动（风险高 · 2.3 即放升 xhigh）

> **2026-06-17 诊断重定调**:批次 2.1 探针实测 **普攻仅占 15.8% 伤害 / 11.3% 击杀**(技能主导,普攻是内力枯竭后兜底),**证伪「普攻过强」假设**。真问题是「战斗短(6-21 回合)+ 技能自动打完 → 玩家没参与空间」。故主线二**杠杆从「降普攻数值」转为「参与机制」**(首通门控 + 即放),普攻数值**基本不动**。

- 批次 2.1 诊断 ✅:`test/tools/battle_tempo_diagnostic_test.dart` 探针读 actionLog 按 `skill.type` 分普攻/技能。实测普攻 15.8% 伤害 / 11.3% 击杀,**证伪「普攻过强」**。局限:测 auto-battle 最优 AI 的伤害归因,非首通手动体感。
- 批次 2.2 数值:**普攻数值基本不动**(诊断已证伪过强)。仅保留观察项「内力枯竭长战收尾普攻占比偏高」(05_01 23% / Boss_06_05 33%),如后续真要微调再单独诊断+拍板,默认不改。
- 批次 2.3 即放时序：拖松手立即出手（动战斗推进节拍）。**前置：读 BattleReplayRecord（saveVer0.19）结构，设计输入时点如何落盘以保 seed 重放确定性**；只改时序不改伤害公式。此批开工前再次确认 xhigh。
- 批次 2.4 打击感表现层：扩 `projectile_trail` + hit-stop（80-120ms）+ 闪白 + 题字「破·斩·震·断」+ 镜头轻震；走 actionLog 边沿，不写 BattleState（红线）。
- 批次 2.5 首通门控：新建逐关门控，复用 `clearedStageCycleKeys`；自动推进只到已手动首通的最远关，已首通关自动复刷。守 §5.5 在线=离线（门控是模式解锁，非速度 buff）。
- 验收：普攻非主要击杀来源 / 首通有技能展示空间 / 复刷不显著拖慢 / 全红线守 / 重放确定性测。

## 4. 主线三 · 关卡/塔层掉落传闻（风险中 · 体量大）

- 复用/扩 `dropTable`（已在）→ 掉落预览数据。
- 玩家侧分组（`UiStrings`）：常可得 / 偶可得 / 少有人得 / 江湖传闻 / 首通必得；**不显百分比**。
- 进度门槛：高阶物绑章节/塔层（第N章/塔区间映射 7 阶）；三系锁死提示「机缘可遇，火候未到」。
- 展示位：关卡列表卡片简版 + 关卡详情完整版 + 塔层详情；首通必得与可重复掉落分开。
- schema 校验测：dropPreview 不缺失 / 不越阶 / 不暴露概率 / 不出现网游稀有词汇。

## 5. 波次顺序与红线守护

顺序：主线一 → 主线二 → 主线三。

红线清单：§2.1 反主流不做清单 / §5.2 数值红线（不进百万）/ §5.5 在线=离线 / §5.6 不硬编码（中文进 UiStrings、数值进 yaml）/ §5.7 爽感边界 / 三系锁死。帮助系统铁律：step/category 从 CodexIndex 派生，不开平行表。

## 6. 进度追踪

| 主线 | 批次 | 状态 |
|---|---|---|
| 一 战斗 UI 表达 | 1.1-1.4 | ✅ 闭环(d8f956e1/ba0f6227/3e7668f5) |
| 二 参与机制(门控+即放) | 2.1 ✅诊断 / 2.2 普攻不动 / 2.3-2.5 待开工(2.3 xhigh) | 进行中 |
| 三 掉落传闻 | — | 待开工 |
