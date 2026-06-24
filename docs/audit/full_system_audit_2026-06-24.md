# 挂机武侠 · 全系统分级审计（2026-06-24 真审计）

> **背景**：1.0 长线打磨期，用户要"梳理已完成系统还存在的缺陷"。掉落系统已于 2026-06-23 单独审完（F1-F8，见 `drop_consistency_2026-06-23.md`），本轮排除。
> **方法**：8 组只读 subagent 扇出（38 子系统全覆盖），每条 finding 必 file:line 实证 + confidence；主会话对 4 个"功能死链"High 项亲核复现（非误报）。**只产清单，逐条改前拍板。**
> HEAD 基线：`4e4419a4`（续51 F4）。saveVer 当前 `0.28`。

## 分级汇总

| 类 | 数 | 说明 |
|---|---|---|
| A 面向玩家真功能缺陷 | 1 | 已暴露给玩家却无效 |
| B 系统建好未接 game loop | 3 | B1+B2 ✅ 接通 / B3 ✅ 注释止血 pending-1.1(2026-06-24) |
| C 需拍板设计冲突/drift | 3 | 文档 vs 代码语义冲突 |
| D 配而不用死字段 + 注释 drift | 8 | 卫生债，可批量清 |
| E 散写中文 | 2 | 卫生 |
| F 已诚实标注的设计延期 | 3 | 仅留底，无需动 |

---

## A · 面向玩家的真功能缺陷

### A1 [High] 开锋槽 吸血/破甲 词条玩家可强化解锁但战斗零消费 — ✅ **resolved 2026-06-24（接通方向 · commit 5aa89cf2 · spec/plan `docs/spec/2026-06-24-forging-lifesteal-pierce-{design,plan}.md`）**
- **处置（用户拍板：接通）**：破甲绝对减防御率 `max(0,def−Σpierce)` + 吸血命中回血（实际主伤害×%，clamp maxHp，闪避不回，AOE 每命中），词条烘焙进 BattleCharacter，进战报「破甲」「吸血+N」。subagent-driven 6 task TDD，满破甲红线探针 134121<百万，全量 2876+1skip（+21 测·0 回归）。**specialSkill 槽3 单列 backlog**（需为装备设计专属技能内容 + EquipmentDef.specialSkillCandidates 配置 + availableSkills 接入 + UI 空状态解除，独立 spec）。
- **位置**：`data/numbers.yaml:616,624`（槽1/2 `available_types:[attack,speed,lifesteal,pierce]` + `bonus_value` 吸10/15·破15/20）→ 消费侧 `derived_stats.dart:222` `_forgingBonusPct` 只 switch `attack`(:200)/`speed`(:216)
- **问题**（亲核确认）：`battle_state.dart:337` 组装 `availableSkills` 不含 forgingSlots；battle/ 下唯一读 forgingSlots 的是 derived_stats:224（只取 attack/speed bonus）。玩家在槽1/2 能真选并 forge 上 lifesteal/pierce，战斗完全无效，还因"同槽互斥"挤占有效（攻/速）槽。UiStrings.forging（strings.dart:1005「攻、速、吸、破，可任选」）向玩家承诺四道词条。`damage_calculator.dart:274` 注释自承"为后续吸血/破甲扩展"。
- **specialSkill 区分**：槽3 仅 specialSkill 类型，但 `forging_panel.dart:28` 注释明示默认 `specialSkillCandidates` 为空 → UI 显示「该装备无专属技能」，玩家 forge 不上（属"未启用"，非"暴露无效"）。
- confidence：高（亲核）
- 处置：**需拍板**——接通 pierce/lifesteal 进战斗（补 build 深度），或砍掉吸/破承诺、UI+yaml 改回攻/速。pierce 已有 `piercesDefense` 基建（numbers.yaml:795），lifesteal 需战斗回血逻辑。

---

## B · 系统建好但未接入 game loop（有 deferred 注释 · 需拍板本期接否）

### B1 [Med-High] 门派事件 + 声望衰减整条链未接 game loop — ✅ **resolved 2026-06-24（接通方向 · spec `docs/spec/2026-06-24-b1-sect-event-game-loop-wiring-design.md`）**
> 接通（用户拍板·真实日历月锚+仅tournament）：`MonthlyTickCoordinator` + `checkAndTrigger` + `computeDecay` 三死符号全接进 HomeFeed 首帧 app-open 锚（复用 offline-recap 体例·守 §5.5）。新 `Sect.lastTickAt` 防同日重触发 + `SectMonthlyTickService` 纯函数编排（过期扫描每次跑 / 月度 pass `floor(elapsedDays/30)` 月 catch-up clamp ≤3 / decay 按 idle 月累扣）+ `narrative_ids` 池 rng 选 + dev-gated 立即触发按钮。mission/crisis 叙事留底 1.1+，`type=tournament` 硬编码保留正确。零 saveVer / 零战斗数值。全量 2900+1skip（**+16** 新测·0 回归）/ analyze 0。
- **位置**：`sect_event_service.dart:29`（checkAndTrigger）/ `monthly_tick.dart:9`（MonthlyTickCoordinator）/ `sect_reputation_decay.dart:21`（computeDecay）
- **问题**（亲核）：三者生产 0 调用（仅定义+test）。`sect_screen.dart:104` 有完整「active 事件列表+应战 CTA」UI，但**永不出现待结算事件**；声望永不衰减。monthly_tick 文件头自承"最简 infra stub"。`sect_event_service.dart:63` 还把 event.type 写死 tournament → 即便接通，mission 招募分支（sect_providers.dart:156）仍 dead。
- confidence：高
- 处置：wire MonthlyTickCoordinator 到时间锚 + 注册 checkAndTrigger/computeDecay，或注释止血标"未接 game loop"。

### B2 [Med] 闭关装备掉落死链 — ✅ **resolved 2026-06-24（接通方向 · commit 6f075299 · spec/plan `docs/spec/2026-06-24-b2-seclusion-equipment-drop-{design,plan}.md`）**
> 接通（用户拍板）：①`SeclusionMapDef.dropTable` 字段 + fromYaml ②`DropService.rollOneWeighted` 外层闸命中后按 dropChance 权重抽 1 件 ③numbers.yaml 5 图 dropTable（压一阶定位·守 §5.3 锁步红线测）④`computeOutputs` 接 `DropService?`（nullable 零回归）填空块 ⑤`completeRetreat` writeTxn 落库 `isar.equipments`、`obtainedFrom = UiStrings.dropSourceSeclusion`。零 saveVer / 零产出数值变更。subagent-driven 5 task TDD（每 task 两段 review）。全量 2884+1skip（**+8** 新测·0 回归）/ analyze 0。
- **位置**：`seclusion_service.dart:255`
- **问题**（亲核）：`equipment_drop_rate`(numbers.yaml 5 图 1.0/1.5)×`base_equip_drop_probability`(0.1)=10-15% 命中率配齐、roll 也算了，但 `if (equipRoll < equipProb) {}` 块体空（仅注释 Phase 4 补全），equipDrops 恒空。配了却永不掉装备。
- confidence：高
- 处置：补 seclusion dropTable 真发装备，或砍 equipmentDropRate/baseEquipDropProbability 字段标 unused。

### B3 [Med] 江湖恩怨不进战斗 — ✅ **resolved 2026-06-24（注释止血 pending-1.1）**
> 处置（用户拍板·注释止血非接入）：`bakeEnmityMultipliers`（battle_providers）+ `NpcRelationService.upsert`（class 头）各加 `UNUSED-PENDING-1.1` 可扫描头注——诚实标注整链 dormant 为故意延期（非误删死码），1.1 接 `StageDef.npcId` schema（与 D3 同源）双写真 NPC 关系后即激活，service+R5.7 红线测全留底不删。零行为变更（注释纯文档）。analyze 0 / jianghu 50 测全绿 / 2900 baseline 不变。
- **位置**：`battle_providers.dart:243`（bakeEnmityMultipliers）/ `npc_relation_service.dart:20`（upsert）
- **问题**（亲核）：bakeEnmityMultipliers 0 生产 caller、upsert 0 写入，恩怨 APM 末端乘 dormant。service+provider+红线测全建好但无路径触发。注释自承"真 NPC 接入 1.1+ 走 StageDef.npcId schema 扩"。
- confidence：高
- 处置：1.1 接入或注释标 unused-pending-1.1（与 D3 npcId 同源）。

---

## C · 需拍板的设计冲突 / drift

### C1 [需拍板] 商店经验丹"动态标价"vs GDD §6.1"固定标价·无机缘定价"
- **位置**：`shop.yaml:24-34`（price_layer_fraction）+ `shop_service.dart:25`（effectivePrice=round(founderEtl×fraction)）+ `shop_providers.dart:48`（founderEtl 随境界 invalidate）
- **问题**：经验丹标价随祖师境界推进变化。GDD §6.1（GDD.md:366）明文"固定货架·固定标价·无刷新…守 §5.1 无机缘定价"。yaml 自辩"兑换率恒定无套利"，但显示银两价非固定，与"固定标价"字面冲突，贴近 §5.1 已废除的机缘定价。
- confidence：高（代码确凿，定性需拍板）
- 处置：GDD 明文授权"ETL 恒定兑换率动态标价"并解释非机缘定价，或改回固定价（删 priceLayerFraction 分支）。

### C2 [需拍板] 奇遇↔events"加载层强校验"3 处文档宣称、代码实为静默降级
- **位置**：`encounter_event_loader.dart:99`（catch 全吞返 placeholder）vs 文档自称强校验：encounters.yaml:33-35 / encounter_def.dart:155-156 / encounter_event_loader.dart:6
- **问题**：`_enforceEncounterRedLines` 只校 trigger/threshold，从不 load events 文件 → 缺 events/<id>.yaml 显示「[文案待补]」占位、坏 outcome_id 静默 fallback OutcomeType.none（奖励无声丢失），违 §8.1"任一端缺失直接抛错"。**数据现状干净（57/57 对齐、0 mismatch），是潜在风险非活跃 bug**；lore 有真校验（_validatePresetLoreReferences），奇遇缺这道。
- confidence：高
- 处置：仿 lore 加启动期校验（缺文件抛错+outcome_id ⊇ 校验），或删 3 处虚假"强校验"文档承诺。

### C3 [需拍板] §5.4 招式倍率 per-type 分档 vs skills.yaml 实际 drift
- **位置**：`data/skills.yaml`（powerSkill 达 6400 / ultimate 低至 1500）vs schema 唯一真 sink `game_repository.dart:822` 全局 ≤8000
- **问题**：§5.4 文档"强力 1000-3000 / 大招 5000+"，实际 21+ 处 powerSkill 超 3000、ultimate 有低于 5000。per-type 分档从未被 schema 强制（只全局 ≤8000）。与"不进百万"软线一致。属文档分档 vs 实际 drift。
- confidence：高（数值实测）
- 处置：收紧 schema 按 per-type 分档校验，或把 §5.4 倍率表改"全局 ≤8000 单线"消除 drift。

---

## D · 配而不用死字段 + 注释 drift（卫生 · 可批量 TDD 清）

| # | 缺陷 | 位置 | confidence |
|---|---|---|---|
| D1 | `TechniqueDef.internalForceGrowthBonus`/`speedBonus` 死字段（真相源是 numbers.yaml techniques.tiers） | `technique_def.dart:11,28` + techniques.yaml | 高 |
| D2 | `fragment_threshold` 配而不用，生产硬编码默认 5（潜伏：当前值恰好相同） | `numbers.yaml:1711` / `tower_entry_flow.dart:175` + `stage_entry_flow.dart:219` 不传 fragmentThreshold | 高 |
| D3 | `StageDef.npcId` 死字段（5 处配置 0 读取） | `stage_def.dart:74,155` + stages.yaml ×5 | 高 |
| D4 | `Character.attributeBonsFromAdventure` 写入永不读 | `character.dart:96` / `encounter_service.dart:353` | 高 |
| D5 | 心魔 `sub_cultivation_multiplier`/`debuff_id` 死字段 | `inner_demon_def.dart:162,165` | 高 |
| D6 | 闭关 `time_range` 配而不用（时段硬编码在 dart `_isZiShi`/`_isZhengWu`） | `seclusion_service.dart:580` / numbers.yaml:1002 | 高 |
| D7 | `final_damage_formula`+`skill_multiplier_added` 死配置（0 引用） | `numbers.yaml:57-69` | 高 |
| D8 | **drift 注释 3 处**（实已实装却注释自称未接，误导审计）：正午阳刚"留挂账"(`seclusion_service.dart:74`)/ `stageBossFailRecoverProb`"0 caller"(`numbers_config.dart:2347`)/ light_foot `damage_multiplier`"不消费"(`light_foot_def.dart:79`) | 见左 | 高 |

## E · 散写中文（卫生）

| # | 缺陷 | 位置 |
|---|---|---|
| E1 | `'角色不存在'` 散写 4 处 | character_panel:128 / technique_panel:79 / cangjingge:116 / shop_service |
| E2 | narrative `'跳过'`（narrative_reader_screen:106）/ main_menu debug 标签(:399) + `'武'`装饰字（dev-gated，低） | 见左 |

## F · 已诚实标注的设计延期（仅留底 · 无需动）

- `cultivationProgressPct` +3% 修炼度（founder buff，已标 Phase5+）
- sect mission 招募分支预埋（已注释）
- 农历节日 2027+ 错日触发（festivalOn 忽略年份，1.0 后长线项）

---

## 已验证排除（非缺陷 · 防止重复审计）

- 核心公式系数全从 numbers.yaml 读，无硬编码魔数；流派 extra_effect 三件全消费；散功代价真扣。
- canEquip/canPractice 锁步（含师承遗物）硬门控；强化失败不降级；共鸣×强化×开锋(攻/速)连乘实装。
- 红线 clamp 守源头（血/内力）；招式 ≤8000 全量 enforce；装备派生越 2000 是有意终局爽感。
- H1 爬塔周目迁移已修对（版本门 + 回归测），未发现第二个非幂等迁移；§5.5 在线=离线无加速项。
- 飞升副作用全 8 步正确（遗物 inheritFrom/owner 转移/真传位 isFounder/auto_swap/stackAcrossGenerations=false）。
- 心魔失败惩罚已真接入（非 M6 零消费）、双重惩罚已修；里程碑装备授予 hook 完整。
- §5.7 商店守门（秘籍/大还丹不上架）fail-fast；§5.1 无留存机制；Image.asset errorBuilder 覆盖。
</content>
