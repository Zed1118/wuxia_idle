# D4 数值再平衡 tune 候选 diff(不上线)

> 起草:2026-05-29 · 5h 挂机 Batch A4 · 来源 `test/tools/balance_simulator_test.dart` 1500 模拟
> **本 doc 不动 numbers.yaml** · 候选方案待用户起床拍板后再 apply。

## 1. PoC 数据现状

PoC 跑 30 关 mainline × 50 seed = 1500 模拟,v2 校准(3v3 + 玩家境界 +1 + 数值接近 §5.4 红线 cap)结果:

- **29/30 关 100% 秒杀**(普通关 + 章末 Boss 几乎全过 · winRate 远超期望 60-90%)
- **stage_01_05 唯一 0%**(Ch1 章末「风雨渡口」· 章末跨 2 阶 Boss · xueTu vs erLiu)

## 2. stage_01_05 异常诊断

| 项 | 值 |
|---|---|
| stage.requiredRealm | xueTu(学徒)|
| enemy 主 Boss(`enemy_erLiu_umbrella`)| erLiu(二流)/ baseHp 10000 / baseAttack 750 |
| 跨阶差 | 2 阶(GDD §5.3:守方修正 0.3x / 攻方修正 2.5x)|
| 玩家校准 v2 | sanLiu(三流,超阶 1)· 仍跨 1 阶劣势 |
| 结果 | 0% leftWin(玩家全输 13.1 tick)|

**判定:设计正确**(memory `feedback_wuxia_boss_balance_crosstier`:章末 Boss 跨 1-2 阶才稳触发战败 → 战败收降叙事开关入口)。

**注意点**:
- Ch1 玩家可能尚未达 sanLiu(超阶 1)→ 学徒 vs 二流 跨 2 阶 → 玩家 0.05x 近免疫 → **首次玩家上手 stage_01_05 大概率全灭** → 玩家可能在 Ch1 学武出山阶段反复卡关
- 若该挫败感属设计意图(战败收降叙事 hook + 玩家再练几关回来打)→ 可接受
- 若用户希望 Ch1 体验更顺畅 → 可 Q1 调整:enemy 降到 sanLiu / 或加战败提示「先练几关再回来」

## 3. 数据局限(为何 PoC 不可作精确 tune 依据)

| 维度 | PoC | 真玩家 |
|---|---|---|
| 玩家组建 | 3v3 合成 + 数值 cap 偏高 | Isar 真玩家 + 装备+心法+师徒+共鸣度 build 多元 |
| 流派 | 固定刚猛 gangMeng | 三流派(刚猛/灵巧/阴柔)各 1/3 概率 |
| 境界 | stage.requiredRealm + 1(固定) | 0-3 阶不等(随玩家挂机进度)|
| skill | 1 普攻 + 1 大招 hardcode | 真心法对应招式池(每流派 7-8 招)|
| buff | 0 | 共鸣度 + 开锋 + 师承遗物 + founder buff + 心法相生 |
| 数值 cap | 接近 §5.4 红线 | 玩家实际可能 60-80% cap |

→ **PoC 数据偏极端**(全秒杀 / 唯一卡点)→ 仅用于「方向性诊断」+ **框架价值**,精确 tune 需后续接 Isar 真路径。

## 4. 数值候选方案(0-3 级,**不上线**)

### 候选 1:不动 numbers.yaml(推荐 PoC 阶段)

**理由**:PoC 数据极端 + 设计跨阶 Boss 在 memory 印证 + 不冒进破红线 → 保持现状,**用 PoC 框架做后续 H4 真路径校准**(接 Isar)。

### 候选 2:微调 Ch1 体验(可选)

仅对 stage_01_05 enemy:
```yaml
# data/stages.yaml(diff candidate · 不 apply)
- id: stage_01_05
  enemyTeam:
    - id: enemy_erLiu_umbrella
      realmTier: sanLiu      # erLiu → sanLiu(跨阶差 2 → 1)
      baseHp: 7500           # 10000 → 7500
      baseAttack: 600         # 750 → 600
      # ↑ 玩家学徒 vs 三流 boss · 跨 1 阶 · 战败概率 ~70%(仍设计性卡点)
```

**风险**:破坏 memory 印证的「章末跨 2 阶 Boss 战败收降叙事 hook」设计意图 → 需用户拍。

### 候选 3:加 Ch1 章末战败提示文案(推荐 polish · 不动数值)

不动数值,只在 stage_01_05 战败时加文案 hint:
```
narrativeDefeatId: stage_01_05_defeat
defeatNoteHint: "撑伞高人身手深不可测,你尚未到对手层次。回去寻几关磨练后再来挑战。"
```

**优点**:0 数值改动 + 设计性挫败感保留 + 玩家明确得到 next step → 体验提升。
**风险**:0 数值层风险。**强烈推荐**。

### 候选 4(后续 P5.2 / H4):接 Isar 真路径 PoC v3

- 改 `_synthPlayer` 为 `loadRealPlayer(saveSlot)` 接 Isar
- 跑 5 套 build(刚猛/灵巧/阴柔 + 心法主修 7 阶分布)→ 每关 10 seed
- 输出更接近真实玩家路径的数据
- 时长 ~2-3h xhigh,作为 H4 / D4 真 tune 入口

**推荐**:本批 PoC 后续 P5.2 真 batch 启动时跑。

## 5. 起床决策点(用户拍)

| # | 问题 | 推荐 |
|---|------|------|
| **D4-Q1** | 候选 1-3 选哪个? | **候选 3**(文案 hint · 0 数值层风险 + 设计意图保留)|
| **D4-Q2** | 是否启 PoC v3(候选 4)接 Isar 真路径? | 是(留 P5.2 / H4 阶段启动)|
| **D4-Q3** | 是否把 balance_simulator_test.dart 纳入 1519+1 测族? | **否**(数据生成器非 unit test,留 tools/ 离测族范围)|
| **D4-Q4** | output csv / summary 是否 commit 上 git? | **是**(快照便于历史对比 · 后续每次跑覆盖 + commit)|

## 6. PoC 框架长寿价值

- 已 ready 的 framework 可在 1.x / 2.0 持续复用(数值平衡是长期工作)
- 后续接 Isar 真路径只需改 50 行 `_synthPlayer`
- 1.0 ship 前可跑 3-5 次校准迭代(每次 30s 输出 + 用户拍)

## 7. 不上线动作清单

- ❌ 不动 numbers.yaml
- ❌ 不动 stages.yaml
- ❌ 不动 enemies.yaml
- ❌ 不动 narratives/
- ✅ 仅产 doc + PoC 工具(test/tools/)

---

**起床后**:用户拍 D4-Q1 到 Q4 → Claude 按 Q1 候选 apply(若 Q1 选候选 3 文案 hint,~30min)→ Q2 启动 PoC v3 留 P5.2 batch。
