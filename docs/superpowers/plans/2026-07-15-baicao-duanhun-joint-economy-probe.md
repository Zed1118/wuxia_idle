# 百草岭×断魂庄×装备强化 联合经济与时间吞吐探针 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans。诊断工具，非玩法代码；沿 `test/support/progression_battle_probe.dart` 与首通技能占比 ratchet 诊断测体例。

**Goal:** 把现有 Lv100→170 单系统吞吐探针（baicao §12.4）扩展为**跨系统经济模型**，输出快／中／慢三档 YAML 候选供用户拍板目标天数、反推 `expeditions.yaml`／`boss_gauntlets.yaml`／装备强化初值，并建 ratchet 拦截后续数值改动破坏曲线。**在 Phase A 完成、Phase B/C 数值填表前执行**（§14）。

**Architecture:** 纯诊断测（`test/tools/`），无生产代码。串联五段吞吐链，参数化三档，断言四个经济健康不变式（ratchet），不只验单次成功率公式。

**依赖：** Phase A（`ExpeditionRules`/`CharacterAdvancementService`/装备强化服务接口已在），可在 A 冻结后、B/C 填表前先跑（用规则骨架 + 占位初值）。**上游：** A2 存量溢出探针（本探针同源扩展，复用其 `applyExperience` 溢出分布段）。

**源规格：** companion §4.5（联合经济探针）＋ baicao §12.4（吞吐探针前置）＋ §3.1（存量溢出）。

---

## 吞吐链模型（§4.5）

```
百草岭每小时节点／断魂帖产出
  → 断魂庄入场频率（帖库存 ÷ 每战耗 1 帖）与三档阵容胜率
    → 命名装备选择（三选一）
      → 助炼 or 分解的机会成本
        → 心血结晶净流入／保护消耗
          → 装备 +30／+40／+49 的预期到达时间
```

## 文件结构

| 文件 | 责任 |
|---|---|
| `test/tools/joint_economy_probe_test.dart` | 五段链模型 + 三档参数 + 四不变式 ratchet + 打印三档 YAML 候选 |
| `test/support/joint_economy_model.dart` | 纯函数经济模型（可单测；探针调用） |

---

## Task 1: 经济模型纯函数

**Files:** Create `test/support/joint_economy_model.dart` + `test/support/joint_economy_model_test.dart`

- [ ] **建模（纯函数，单测覆盖每段）：**
  - `baicaoHourlyYield(policy, avgDepth) → {expPerHour, ticketPerHour, materialPerHour}`（用 `ExpeditionRules.rewardsForNode` + 节点时长换算每小时）。
  - `gauntletEntryRate(ticketStock, ticketPerHour) → entriesPerDay`。
  - `gauntletWinRate(loadout∈{入门,推荐,满配}) → double`（占位表，批3 与 C 战斗探针对齐）。
  - `enhanceReachDays(crystalNetInflow, targetLevel∈{30,40,49}) → days`（用装备强化成功率曲线 + 结晶保底成本，接装备 plan 的 `success_curve`）。
  - `namedEquipAidContribution(sameDefStack) → pctPoints`（同一命名装备反复选做助炼来源的 +pp）。
- [ ] 提交 `test: 加联合经济模型纯函数`。

## Task 2: 三档探针 + 四不变式 ratchet

**Files:** Create `test/tools/joint_economy_probe_test.dart`

- [ ] **三档输出：** 快／中／慢三组参数（远征收益率 × 断魂庄频率 × 强化成本）跑模型，`print` 三档 YAML 候选块（`expeditions.yaml`/`boss_gauntlets.yaml`/强化 `success_curve` 初值），供用户拍板目标天数。
- [ ] **四不变式 ratchet（§4.5 重点，断言而非仅打印）：**
  1. **命名装备助炼不压倒**：固定选同一命名装备的 `namedEquipAidContribution` ≤ 25pp（`expect(..., lessThanOrEqualTo(25))`），否则收藏/多样性失去意义。
  2. **结晶无自反馈失控**：重复装备分解产心血结晶的净流入速率 ≤ 消耗速率的合理倍数（无限/过快自反馈拦截）。
  3. **助炼/分解/收藏真实取舍**：三条路径的单位期望收益差 ≤ 阈值（不存在单一压倒最优）。
  4. **无强制等待**：补给（疗伤丹/行囊补给）生产速度 ≥ 断魂庄消耗速度（桃花岛产线 + 百草岭产出 vs 每战最多 3 份），否则形成强制日课型等待（违 §5.5/§7）。
- [ ] **到达时间输出：** +30/+40/+49 预期天数三档，纳入 ratchet 范围（后续数值改动破坏曲线即红）。
- [ ] 提交 `test: 加联合经济三档探针与四不变式ratchet`。

## Task 3: 结论回填

- [ ] 探针三档结果 + 用户拍板的目标天数 → 回填 `expeditions.yaml`/`boss_gauntlets.yaml`/装备 `success_curve` 初值（Phase B/C 填表用）。
- [ ] 存量溢出连跳分布（A2 探针同源）一并纳入本报告，确认「一次性兑现 vs 分段抬升」（§3.1）。
- [ ] 探针留作 ratchet（同首通技能占比诊断测体例）。

---

## 当前恢复点
- **状态：** 未开工（Phase A 完成后、B/C 填表前执行）。
- **下一步：** Task 1 经济模型纯函数。
- **已跑验证：** 接口锚点核（`ExpeditionRules.rewardsForNode`（Phase B）/`CharacterAdvancementService.applyExperience`（A2 核）/装备 `success_curve`（装备 plan §3 决议））。
- **阻塞项：** `gauntletWinRate` 三档需 C1.3 战斗探针数据对齐（可先占位跑，C 完成后校准）。

## 自检
- **Spec 覆盖：** §4.5 五段链全建模 + 四重点检查全 ratchet；§3.1 溢出分布纳入；§12.4 三档 YAML 候选 + ratchet。
- **Placeholder 扫描：** `gauntletWinRate` 占位表显式标注「C1.3 对齐」，非隐藏 TODO；其余为可跑纯函数。
- **非目标：** 不验单次成功率公式正确即收工（§4.5 明确要跨系统模型 + ratchet）。
