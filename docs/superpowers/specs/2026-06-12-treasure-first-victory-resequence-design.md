# 战斗结束时序重排:爆品当第一高潮

**日期**:2026-06-12
**类型**:纯 UX 时序重排(0 数值 / 0 战斗数学 / 0 numbers.yaml / 0 schema / 0 红线)
**状态**:设计已与用户拍板,待 review → writing-plans

## 背景与痛点

真玩反馈:战斗结束后**先弹全屏「勝」胜利界面、还要手点继续,掉落都没算,爆品(高阶装备印章盖落动画)反而排在最后**。爆品本是"打赢拿到神兵"的高潮,现在被「勝」结算挡在前面,顺序是反的。

### 当前时序(改之前)

```
T0 战斗判定结束(default_ground_strategy._checkBattleEnd → BattleState.result 非空)
T1 battle_screen ref.listen 边沿 → _showResultDialog:停 BGM + 播胜负 SFX + 弹 VictoryOverlay(「勝」题字 + 印章 + 统计 + 继续按钮)
T2 用户点「继续」→ VictoryOverlay 消失
T3 flow 分叉(stage_entry_flow / tower_entry_flow)→ BattleResolutionService.resolve() 此时才 roll 掉落
T4 若有 ≥重器 → TreasureDropOverlay 墨团炸裂印章盖落爆品(1.3s + 轻触继续)
T5 结算 dialog(掉落清单 + 升层 banner)→ 主线推剧情 / 塔返回
```

掉落 roll 直到"点继续之后"才发生(`BattleResolutionService.resolve` 内 `dropService.rollDrops`)。

## 目标

把爆品提为"战斗结束第一高潮",删掉挡在前面的全屏「勝」+ 强制点击;高频普通档结算顺滑。

## 新时序(改之后)

按掉落结果分三档,**roll 提前到战斗结束判定后、弹任何界面之前**:

```
【爆品档】掉落含 ≥重器(treasure_drop.min_tier)
  战斗结束 → 立即 roll → 墨团炸裂印章盖落爆品(纯仪式,印章即胜利宣告,轻触继续)
           → 结算 dialog[掉落 / 升层 / 统计]

【普通 / 无掉落档】掉落无 ≥重器(普通装备/道具,或全空)
  战斗结束 → 立即 roll → 简版「勝」淡入淡出 ~0.8s 自动(零点击)
           → 结算 dialog[掉落 / 升层 / 统计]

【战败】
  战斗结束 → 「敗」overlay(现状完全不动)→ 返回
```

有意的不对称:爆品档**轻触继续**(低频高潮值得停留),普通档**自动过**(高频场次顺滑)。

## 关键技术改动

### 1. roll 提前 —— 拆 `BattleResolutionService.resolve` 为 roll / apply 两段(硬骨头)

现在 `resolve()` 把掉落 roll 与升层、共鸣晋阶、入库等副作用绑在一坨。新方案要"先知道掉没掉重器才能选界面",必须:

- **先 roll(纯计算)**:产出 `DropResult`(及决定分档所需信息),**不写 Isar、不结算升层**。
- **后 apply(副作用)**:入库、升层、共鸣晋阶、provider 失效,**消费上一步缓存的 `DropResult`**。

**红线**:roll 只执行一次,结果缓存后传给 apply。绝不能 roll 两次(rng 一推进掉落结果就变)。roll 提前是**纯时机前移**,掉落概率/结果/入库语义全部不变。

### 2. 共享分档决策

抽一个纯函数(输入 `DropResult` + numbersConfig,输出走"爆品镜头"还是"简版勝")。mainline 与 tower 两路径都调,避免各写一遍漂移。判据沿用现有 `treasure_drop.min_tier` 门槛(`playTreasureDropIfAny` 已有的 `drops.equipments.any(tier>=minTier)` 逻辑收敛进此函数)。

## 各界面内容调整

| 界面 | 改动 |
|---|---|
| **爆品镜头**(TreasureDropContent / TreasureDropOverlay) | 动画本身不变,沿用现状(墨团炸裂 + 印章盖落 + tier 题字 + 属性 + tagline)。**不加额外「勝」字**——印章盖落即胜利宣告(能掉落必然=赢,战败恒空掉落,逻辑自洽)。它现在成为"胜利第一画面" |
| **简版「勝」**(VictoryOverlay 胜利分支) | 去掉统计行(统计挪走);保留印章符 + 「勝」题字。**改为淡入淡出 ~0.8s 自动消失,不拦点击**(原为停留+继续按钮) |
| **结算 dialog**(stage_victory_dialog / tower `_FirstClearContent`) | 底部**新增统计段**(总伤害 / 暴击数,从 VictoryOverlay 迁来);掉落清单 + 升层 banner + 共鸣 banner 保持 |
| **「敗」overlay**(VictoryOverlay 败北分支) | **完全不动**(战败无掉落,仍走红字 overlay + 继续) |

## 两条路径统一

- **mainline**(`stage_entry_flow.runStageFlow`):roll 提前 + 分档选爆品/简版勝。
- **tower 首通**(`tower_entry_flow.runTowerFlow`,isFirstClear):同上。
- **塔重打**(isFirstClear=false,farm 无奖励):归"无掉落档"→ 简版勝自动过 → dialog 显"重打不发奖"文案(现状文案保留)。

`_showResultDialog` 里现有的"停 BGM + 胜负 SFX"逻辑保留;胜利侧不再在此弹 VictoryOverlay,改由分档决策在 flow 入口处选界面(具体 wiring 落点由 plan 阶段定)。

## 非目标(明确不做)

- 不动战斗数学 / 公式 / numbers.yaml / schema / 数值红线。
- 不改掉落概率、掉落表、入库语义、升层/共鸣结算逻辑。
- 不动战败「敗」路径。
- 不动爆品动画本身的时轴 / 视觉(上一波刚定稿)。

## 测试策略

- 三档分支各一个 flow/widget 测:爆品档播 TreasureDropOverlay;普通档播简版勝;无掉落档播简版勝。
- **roll 提前回归测**:同 seed 下 roll/apply 拆分前后掉落结果、入库、升层结果完全一致(防 roll 两次 / rng 漂移)。
- 简版勝自动消失(不拦点击)的 widget 行为测。
- 统计迁入 dialog 的断言迁移(原 VictoryOverlay 统计断言 → dialog)。
- 现有「敗」路径测不动、保持绿。
- 闸门:analyze 0 + 全量绿。

## 风险

- **唯一真风险 = resolve 拆分**(技术改动 1)。若拆不干净,易出 roll 两次 / 掉落与入库不一致。plan 阶段需把 roll(纯)/ apply(副作用)边界设计清楚,并以同 seed 回归测兜底。其余均为表现层时序搬移,风险低。
