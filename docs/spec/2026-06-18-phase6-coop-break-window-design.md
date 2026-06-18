# 第六阶段 · 三人协同（破绽窗口链路）— Spec

> 日期：2026-06-18 · 状态：用户已拍板设计方向，待 spec 审阅
> 阶段命名：第六阶段 = 三人协同（master spec P2 轴 · 见 memory feedback_wuxia_phase_naming）
> 上游愿景：`playability_upgrade_master_spec_2026-06-09.md` §四 4.2 / §13 P2「破招→破防→爆发链路」
> 设计支柱：GDD §5.7 战斗体验原则（爽感主旋律 · 走表现层不走数值膨胀）

## 0. 已锁定决策（用户拍板）

- 范围 = **协同深度**（让 3 单位真协同），**不做**渐进解锁 / 出战编成 UI。
- 协同形式 = **破绽窗口链路**（时序协同），非队伍被动 buff。
- 开窗 = **破招（现有踉跄）+ 新增破防动作**（破防不要求敌人蓄力，链路可重复）。
- 窗口收益 = **减防 + 行为（AI 集火）+ 即放提示 + 表现层反馈**，不走协同增伤数值膨胀。
- 职责 = **软引导不锁死**（autoFill 倾向模板，玩家可改 · 符合 master spec §4.2「前期固定倾向、后期自由培养」）。
- 架构 = **方案 A：泛化现有踉跄为统一「破绽窗口」**，复用 `staggerTicksRemaining` / `staggerDefenseDownOverride`，不新建并行状态。

## 1. Phase 0 已核实现状（2026-06-18 本仓实测 · 带 file:line）

- 战斗固定 3v3（`battle_state.dart` leftTeam/rightTeam ≤3）；3 单位**各打各的，协同深度≈0**。
- 破招踉跄已存在：`default_ground_strategy.dart:~600-623` canInterrupt 命中蓄力敌 → 打断 + 清蓄力 + set `staggerTicksRemaining`（`battle_state.dart:164`）+ `staggerDefenseDownOverride`（:166-169）。**仅蓄力敌可触发**。
- 窗口减防已被伤害路径读取（踉跄期防御率乘 `1 - staggerDefenseDown`），但**无显式协同**：队友不集火、AI 无感知、玩家无提示、无表现触发。
- 配置：`numbers.yaml combat.boss_charge` → `default_stagger_ticks: 2` / `stagger_defense_down: 0.3` / `interrupt_power_cap: 0.5`；per-skill `interrupt_window_bonus_ticks`（`skills.yaml:2469`，经 `SkillProficiency.interruptWindowBonus`）。
- AI 决策：`battle_ai.dart:27-69` 仅查「敌是否蓄力」（破招锁定），否则血最低；**无队友/敌 debuff 感知**。
- 即放：第五阶段 2.3 `interveneNow` / pending（拖招立即出手）；`battle_screen` `_focusSlotIndex` 多角色切换。
- 表现层：第五阶段 2.4 `impactProfileFor` + `_playAction` + `ImpactGlyphOverlay`（题字）+ flash + shake + hit-stop，全走 actionLog 边沿不写 BattleState。
- autoFill：`skill_loadout_service.dart` / `skill_loadout_resolver.dart`（波A 装配池 wiring）。
- SkillDef 字段：`skill_def.dart:33-94`（canInterrupt :51 / parse :123 / style :60 红线）。
- 内伤同源刷新语义：`InternalInjurySlot`（`battle_state.dart:124-126`）= 刷新不叠加先例。

## 2. 破绽窗口（核心概念 · 复用踉跄）

- 「破绽窗口」≡ 敌人 `staggerTicksRemaining > 0`，减防幅度 = `staggerDefenseDownOverride`。**不新建 BattleState 字段。**
- 开窗两来源写同一窗口字段：
  - **破招（现有，不动）**：canInterrupt 命中蓄力敌 → 现有逻辑。
  - **破防（新增）**：带破防效果技命中**任意存活敌**（不要求蓄力）→ set `staggerTicksRemaining = 破防窗口时长`、`staggerDefenseDownOverride = 破防减防幅度`。
- **刷新不叠加**（沿内伤同源刷新语义）：重复开窗取较强/刷新时长，不叠减防 → 防多人叠减防穿透。

## 3. 破防效果（新增技能效果 · 数据驱动）

- `SkillDef` 加字段 `defenseBreakPct`（double，默认 0.0；>0 = 命中即开破绽窗口、施加该幅度减防）。parse 沿 `canInterrupt` 体例（yaml `defense_break_pct`）。
- `default_ground_strategy` 命中后新增破防分支：非蓄力敌也 set 窗口字段（与破招走同一字段，不重复造）。
- **内容子任务（破防技覆盖）**：最小集 = 刚猛震系天然带破防 + 按流派覆盖缺口补 1-2 招；保证每流派玩家都摸得到一个开窗手。开工时核流派覆盖。
- 红线：`defenseBreakPct` + 踉跄减防经 **地板 clamp**（沿用/扩展 `interrupt_power_cap` 0.5 同类上限），有效防御不穿透到必杀。

## 4. AI 集火（battle_ai 决策扩展 · 纯逻辑无状态写）

- 目标优先级：**破招（敌蓄力）> 集火（敌处破绽窗口）> 血最低**。
- 队友（尤其高倍率爆发技）自动优先打破绽窗口内的敌 → 自动战斗里链路也成立（守 §5.5 在线=离线）。
- 仅改 `decide` 返回的 targetId 选择，不写 BattleState（守 §5.4）。

## 5. 即放钩子（玩家参与）

- 复用 2.3 即放。破绽窗口打开时，指令栏旁弹提示「破绽 · 该爆发了」，引导玩家拖爆发技。
- 玩家窗口内触发爆发时自动锁定破绽敌（targeting hint）。
- 只改目标选择 + 屏上提示，不动逻辑速度（守 §5.5）。

## 6. 表现层（复用 2.4 四件套 · actionLog 边沿）

- 开窗瞬间：破绽敌头上题字「破绽」（复用 `ImpactGlyphOverlay`）+ 破绽敌高亮（集火指示）。
- 爆发技命中破绽窗口内：升档 2.4 impact profile（更重 hit-stop/闪白/题字），协同爆发有分量。
- 全走 actionLog 边沿，不写 BattleState（沿 2.4 既定模式）。

## 7. 职责软引导（autoFill 倾向模板 · 不锁）

- autoFill 按角色倾向：大弟子→优先破防技（开窗手）/ 祖师→优先高倍率爆发技 / 二弟子→优先控制·内伤技。
- 不锁死，玩家可在藏经阁装配栏改；旧档 fallback 等价（沿波A autoFill 体例）。

## 8. 数值与文案

- `numbers.yaml`：新增 `combat.defense_break`（`window_ticks` 建议 3 · `defense_down_pct` 建议 0.25–0.35 与 `stagger_defense_down` 0.3 同档 · 共用 `interrupt_power_cap` 0.5 地板）+ AI 集火优先权重（如需）。
- `UiStrings`：「破绽」题字 / 「该爆发了」提示 / 破防效果释义（GlossaryTip 复用帮助系统）。
- 红线：数值进 yaml（§5.6）；中文进 UiStrings（§5.6）。

## 9. 红线守护清单

- **§5.4**：破防 + 踉跄减防硬 clamp 到地板，窗口刷新不叠加，集火不抬高单次输出 → 不进百万。`balance_simulator` 加「破绽窗口爆发」极值场景断言。
- **§5.5**：即放/集火不改逻辑速度，自动战斗里 AI 集火等价生效。
- **§5.6**：数值进 yaml，中文进 UiStrings。
- **§5.7**：爽感走表现层（题字/集火高亮/爆发反馈），不走数值膨胀。
- **三系锁死**：不涉及。

## 10. 测试

- 纯函数：破防开窗（非蓄力敌也开）/ 窗口减防 clamp 地板 / AI 集火选敌（破绽敌优先）/ autoFill 倾向模板。
- 红线：窗口内爆发峰值不进百万（扩 `full_build_damage_redline_test` / `balance_simulator`）。
- 确定性：窗口 + 集火经 `notifier.advance` seed 测（沿 memory feedback_battle_determinism_test_via_notifier）。
- widget：「破绽」题字 overlay + 即放提示渲染（含 ProviderScope）。

## 11. Scope / YAGNI（明确不做）

- **不做**：渐进解锁、出战编成 UI（用户本批未选）。
- **Boss 协同窗口**：本批落地后的自然续作（设计一个围绕破绽链路的 Boss）→ 记入 backlog，本 spec 不含。
- 职责保持轻：只 autoFill 倾向，不锁职业、不强制造大量角色专属技。

## 12. 批次拆分（供 writing-plans 细化）

1. 破防效果 schema（`SkillDef.defenseBreakPct` + yaml parse + `numbers.yaml combat.defense_break`）。
2. 破防开窗逻辑（`default_ground_strategy` 破防分支 + 窗口刷新不叠加 + 减防地板 clamp）。
3. AI 集火（`battle_ai.decide` 优先级 + 确定性测）。
4. 表现层（开窗题字「破绽」+ 集火高亮 + 爆发升档 impact profile）。
5. 即放提示钩子（窗口提示 + 爆发自动锁定破绽敌）。
6. 职责 autoFill 倾向模板（resolver/service 倾向 + 旧档 fallback 测）。
7. 破防技内容覆盖（按流派核缺口 + 文案 UiStrings/释义）。
8. 红线测兜底（full_build / balance_simulator 破绽爆发极值场景）。
