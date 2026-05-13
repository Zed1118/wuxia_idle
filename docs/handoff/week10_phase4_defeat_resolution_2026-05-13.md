# Phase 4 W10 战斗结算扩展 Boss 战败被动散功 closeout（2026-05-13 xhigh 会话）

> 写给下一会话开局者（Mac Opus 自己）看。
> 用户开局直接同意升 xhigh，开整后未中途介入。
> PROGRESS.md「当前阶段」/「已完成」/「下一步」是单一信源；本文档补「为什么这么处理」+「Pen 验收要点」+「下次开局必读」。

---

## 1. 一句话结论

W10 Phase 4 战斗结算扩展按 xhigh 拍板 4 决策点完成：**Boss 关战败触发主修被动散功（无换修）+ 损失摘要走 NarrativeReader 新 topBanner 叠加**，普通关战败不触发，**装备不掉**。`main` HEAD `4e59e9b`，**544/544** 测试，analyze 0 issues，10 文件 +731/-7。

---

## 2. commit（本会话单 commit）

| # | hash | 类型 | 简述 |
|---|---|---|---|
| 1 | `4e59e9b` | feat | phase4-w10 Boss 战败结算扩展（被动散功 + 损失摘要 UI） |

无 tag（W10 尚未 Pen 视觉验收，W7-W10 累积一并打 v0.4.0-w10）。

---

## 3. 4 决策点拍板原因（用户授权方案）

### ① 触发范围：只 Boss 关战败结算

**理由**：T60 已设计 Boss 关战败 → narrativeDefeatId，普通关 → 直接返。沿用同一条分流逻辑：

- Boss 关本来就是「重大节点」+ 已有 defeat 文案，语义贴合
- 普通关 1.0→2.8 难度阶梯设计就是给玩家试错的，**普通关战败惩罚 = 留存焦虑**（违反 GDD §5.5）
- 跨 2 阶 Boss 设计语义（T62 stage_01_05 故意上调到 erLiu）需要「战败有重量」否则没意义

**实现**：`stage_entry_flow.dart` defeat 分支 `if (stage.isBossStage)` 才 push `_applyBossDefeatPenalty`。

### ② 不掉装备

**理由**：

- Demo 30-50 件装备总量小，丢了就真没了（GDD §2.1 禁装备分解，**没有「捡回来」路径**）
- 玩家攒到一件神物丢了 → 直接弃坑
- GDD §5.5「在线 = 离线」+ 整体克制基调暗示需谨慎

**备选方案搁置**：「装备 owner=null 入背包」给玩家捡回来机会、共鸣度软惩罚（武器破损 → 共鸣度 -X）。后期可考虑，W10 不做。

### ③ Boss 战败触发主修「无换修」散功，境界本身不动

**理由**：

- 复用 `DispelService` 算法 A（已 widget 验证过），无新算法
- `internalForce ×0.5` 已经痛了，**境界再掉 1 阶 → 卸装备（三系锁死）→ 战力雪崩 → 弃坑**
- 跨阶绝对不跨：章末 Boss 战败 = -1 阶 = 装备无法穿 = 卸装备 = 战力雪崩，玩家直接弃坑（重要红线）

**关键区分**：
- `DispelService.dispel`：玩家**主动换主修**触发，动 `mainTech.role` / `wasMainBeforeReset` / `ch.mainTechniqueId` / `ch.assistTechniqueIds`
- `DispelService.applyDefeatPenalty`（W10 新增）：Boss 战败被动触发，**绝对不动** role / wasMainBeforeReset / mainTechniqueId（同一本心法继续修），仅 progress + layer 回退 + internalForce -50%

### ④ 时序整合：损失摘要走 NarrativeReader 新 topBanner

**理由**：

- DeepSeek 已写 6 个 defeat narrative，不要让文案二次改
- 损失摘要走 UI 层叠加，不污染剧情内容
- NarrativeReaderScreen 加可选 `topBanner: Widget?`，默认 null 对其他场景（opening/victory）无影响

**实现**：`_DefeatLossBanner` widget 单独抽，展示「{角色} 内力 {before}→{after} · {心法} {oldLayer}→{newLayer} (-{N}层)」。

---

## 4. 关键决策链 / 踩坑

### 4.1 numbers.yaml `defeat` 段独立于 `dispersion`（不复用字段）

**为什么**：dispersion 是「玩家主动换主修」语义，defeat 是「Boss 战败被动惩罚」语义。两个数值同 0.50 但**字段独立**便于后期独立平衡。

```yaml
techniques:
  dispersion:
    internal_force_penalty: 0.50      # GDD §4.3 强制规则
    cultivation_penalty: 0.50

  defeat:                              # Phase 4 W10 新增
    boss_internal_force_penalty: 0.50
    boss_cultivation_penalty: 0.50
```

### 4.2 `DispelService.applyDefeatPenalty` 不调 `Technique.disperse`

**踩坑**：`TechniqueDispersion.disperse(n)` extension（technique.dart:80）副作用包含 `role = TechniqueRole.assist` + `wasMainBeforeReset = true`——这是「换主修」语义，**绝对不能**在战败被动场景调。

**改用**：直接 `mainTech.cultivationProgress *= (1 - n.defeatBossCultivationPenalty)`，复用 `_recalcLayerByRollback` 算法。

### 4.3 测试期望算错（开发时即时发现）

**踩坑**：第一次写 case「yuanMan/1500 → ×0.5=750 → 回退期望 zhongCheng」，实际算下来是 daCheng/750（与 DispelService.dispel:157 的注释例完全一致），rolled=1 而不是 2。**进度算法 A 的 prev key 是「from layer」**：`progressToNextMap[daCheng] = 900` 表示「从 daCheng 到 yuanMan 所需」。回退判定是 `current_progress >= map[prev]` 才停。

### 4.4 widget 集成测试与挂账 #31 同类风险

**踩坑**：W10 完成度上还差 `runStageFlow` Boss defeat 端到端 widget test，但和挂账 #31（MainMenu+多 provider 死循环）同类——`stage_entry_flow` 涉及 BattleNotifier + isarProvider + numbersConfigProvider + dropServiceProvider + GameRepository singleton + 真 Isar 写入。硬塞 `pumpAndSettle` 必死循环。

**当前覆盖**：
- `BattleResolutionService.resolve` 走 5 case（Boss 触发 / 普通不触发 / victory 空 / null config / 无主修）
- `DispelService.applyDefeatPenalty` 走 4 case（基本 / chuKui 边界 / 单层回退 / role 保持 main）
- `NarrativeReaderScreen.topBanner` 走 1 case（渲染 + 不传则不存在）

**未覆盖**：`runStageFlow` 串联（_applyBossDefeatPenalty 从 Isar 拉数据 → resolve → putAll → 构造 DefeatLossEntry → 推 NarrativeReader）。**Pen 视觉验收兜底**。

### 4.5 victory 路径未接 BattleResolutionService（新挂账 #32）

**自审发现**：`BattleNotifier.resolveBattle` 在 `lib/providers/battle_providers.dart:108` 已定义但**全仓库 0 调用**。`runStageFlow` victory 分支只 `MainlineProgressService.recordVictory`、`runTowerFlow` victory 分支只 `recordClear` + 首通 drop——装备 battleCount / 心法 skillUsage / 主修升层**全部未在生产路径落地**。

**W10 副作用**：Boss 关 defeat 路径副带把 battleCount/skillUsage 落了一次。Victory 路径完全没碰。

**完整修复（W11+）**：victory 双端（stage+tower）都拉 character+eq+tech → resolve(isVictory:true) → writeTxn putAll → drop 入背包，与 W10 `_applyBossDefeatPenalty` 体例对齐。

---

## 5. Pen 视觉验收 spec（W7+W8+W9+W10 累积一并派）

### 5.1 W10 核心新增（必跑）

**场景 1：章末 Boss 战败 → 损失摘要 banner**

1. P5 入口 → 主线 → Ch3 stage_03_05（章末大 Boss `武林大会·决战`，erLiu+ 跨 1-2 阶设计）
2. 故意保持低境界进战斗 → 必败（玩家方 0/3 阵亡）
3. defeat narrative 屏顶部应出现红色 banner：
   - 标题「战败 · 散功代价」
   - 每个有主修的参战角色一行「{角色名} 内力 {数字}→{数字} · {心法名} {旧层名}→{新层名} (-N层)」
4. 主修角色实际内力数值应 ×0.5（角色面板可验）
5. 主修心法 cultivationLayer 应回退（心法面板可验）
6. **不应**出现装备掉落提示（不掉装备红线）

**场景 2：普通关战败行为不变**

1. stage_01_02 / stage_02_03 等普通关（非 isBossStage）→ 故意败
2. **无任何**结算 UI，直接返 stage_list（沿用 T60 普通关分流）
3. 角色面板内力 / 心法 layer 不变

### 5.2 W7-W9 累积（沿用 W9 closeout §6 推荐）

- W7：装备 fixture 35 件，仓库面板能正确显示 7 阶 × 5 件
- W8：心法 fixture 21 本 + 63 招，心法面板能正确显示 7 阶 × 3 流派
- W9：爬塔 30 层（main_menu「问鼎九霄」→ tower_floor_list_screen 三态 + Boss outline + recordClear/recordDefeat 实地走）

### 5.3 视觉细节

- banner 颜色用 `WuxiaColors.hpLow`（红/绛系），半透明 0.15 背景 + 0.45 边框 + 红字标题
- 银行字号 12.5（与剧情正文 16 区分），不抢眼但能扫一眼读到
- 占位提示（`⚠ 剧情占位`）若同时出现应在 banner 上方

---

## 6. Week 11+ 起手指引

### 6.1 候选方向

| 优先级 | 候选 | 阻塞 | 备注 |
|---|---|---|---|
| **高** | **Pen Windows 视觉验收 W7+W8+W9+W10** | 用户在线 | 4 周累积，等用户回来 |
| **高** | **#32 victory 路径接 resolveBattle** | 无 | 与 W10 `_applyBossDefeatPenalty` 体例对齐，主线+爬塔双端 |
| 中 | **Phase 5 收尾** | 无 | #2 DDD / #12 LevelDiff / #28 闭关 e2e（`ProviderScope.overrides` 注入 tempDir Isar） |
| 低 | #30 闭关 3 维度 | §12 #7 节气清单 + 农历库 | 需用户决 |
| 低 | C 奇遇 / E 武学领悟 | §12 #6 机缘值规则 | 需用户决 |

### 6.2 推荐顺序

1. **W11**：等 Pen 视觉验收用户在线一并派（4 周累积），同时**自主推进 #32 victory 路径接 resolveBattle**（W10 自审挂账，体例已成熟）
2. **W12+**：Phase 5 收尾 / Phase 4 扩展（散功后 buff、装备耐久等）

### 6.3 模型建议

- **W11 #32 victory 路径**：复用 W10 体例，**sonnet 起步**够用；遇 finalState/Notifier 状态复杂处再升
- **Phase 5 #28 闭关 e2e widget**：先 sonnet 试，碰真 Isar 注入卡壳再升

---

## 7. 数据快照

- main HEAD: `4e59e9b` (push pending 用户决定)
- tag: 无（待 Pen 视觉验收 W7-W10 累积一并打 v0.4.0-w10）
- 测试: **544/544** 全过，analyze 0 issues
- 累计 commit（项目至今）：~76 commits
- 累计 tag：v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6（W7/W8/W9/W10 累积未打）
- Demo 内容量（GDD §7 对照）：主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / 奇遇 0/20-30（阻塞）/ 武学领悟 0/30-50（阻塞）
- 关键架构：Riverpod 3.x + Isar community 3.3.2 + nullable propagation（W6 §3.2）+ Boss 战败被动散功（W10）

---

## 8. 下次开局必读

1. PROGRESS.md「当前阶段」+「下一步」段（W11 候选）
2. 本文档 §3 4 决策点拍板原因（理解 W10 设计哲学）+ §4.5 #32 victory 路径自审发现
3. **若做 #32 victory 路径接 resolveBattle**：体例直接抄 `stage_entry_flow.dart:228-310` 的 `_applyBossDefeatPenalty`，只改 `isVictory: true` + 接 `dropResult.equipments` 装备入背包（owner=null）
4. **Pen 视觉验收派单时**：spec 把 §5.1 两个场景列清楚，W10 银行视觉是关键差异点
5. **写 widget test 触发挂账 #31 同类场景**：不要硬上 `pumpAndSettle`，优先 service 层覆盖（W10 实例：service 9 case + UI 1 case）

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 `lib/` `data/*.yaml`（顶层）`test/` `docs/handoff/`；DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`。
