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

按掉落结果分三档。**关键:掉落 roll 本来就在 flow 的 victory 分支、弹爆品/dialog 之前发生**(mainline `_applyVictoryResolution` / tower `rollTowerRewards` 都在 `playTreasureDropIfAny` 之前),无需移动 roll、不碰 resolve、不碰 rng:

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

### 1. VictoryOverlay 下放到 flow(核心改动)

- **现状**:`battle_screen.dart:_showResultDialog` 在战斗结束瞬间弹 `VictoryOverlay`(胜负通用,含统计 + 继续按钮),onContinue 才回调 → flow 接管 roll。这是"先勝"抢在爆品前的根因。
- **改**:`BattleScreen` 加 `deferVictoryToCaller` 开关(default false)。flow 的两个 host(`_StageBattleHost` / `_TowerBattleHost`)传 `true` → **胜利**时 BattleScreen 不弹 VictoryOverlay,直接走 `onBattleEnd` + `onVictory` 回调让 flow 接管。停 BGM + victory SFX 仍在 `_showResultDialog` 入口响,行为不变。
- **败北分支不受 defer 影响**:仍在 BattleScreen 弹「敗」overlay(现状)。`deferVictoryToCaller` 只 gate `leftWin`。
- **demo / pvp / debug 等无 flow 路径**:`deferVictoryToCaller=false`,胜利仍弹 VictoryOverlay(它们无掉落/分档,保留胜利反馈)。VictoryOverlay 本身不改。

### 2. 共享胜利仪式分档

抽 `presentVictoryCeremony(context, drops, {treasureGate})`:有 ≥重器爆品(复用 `pickTreasureHighlight != null` 判据)→ 播 `TreasureDropOverlay`(现状爆品镜头,含 reward 音);否则 → 播简版勝 `VictorySealFlash`。mainline / tower 两 flow 都调,替换现有 `playTreasureDropIfAny` 裸调用,避免各写一遍漂移。塔重打(`treasureGate=false`)→ 必走简版勝。判据沿用 `treasure_drop.min_tier` 门槛。

## 各界面内容调整

| 界面 | 改动 |
|---|---|
| **爆品镜头**(TreasureDropContent / TreasureDropOverlay) | 动画本身不变,沿用现状(墨团炸裂 + 印章盖落 + tier 题字 + 属性 + tagline)。**不加额外「勝」字**——印章盖落即胜利宣告(能掉落必然=赢,战败恒空掉落,逻辑自洽)。它现在成为"胜利第一画面" |
| **简版「勝」**(新建 `VictorySealFlash`) | 印章符 + 「勝」题字,淡入淡出 ~0.8s 自动消失(不拦点击 / 无统计 / 无按钮)。**新建而非改 VictoryOverlay**——后者保留不动 |
| **结算 dialog**(stage_victory_dialog / tower `_showVictoryDialog`) | 底部**新增统计段**(总伤害 / 暴击 / 回合,从 `finalState` 经新纯函数 `BattleStatsSummary` 算);掉落清单 + 升层 banner + 共鸣 banner 保持 |
| **VictoryOverlay**(胜负通用,现有) | **完全不动**。败北仍走它(红字「敗」+ 继续);胜利分支仅 demo/pvp/debug 等无 flow 路径走 |

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

- 三档分支测:爆品档(有重器)→ `presentVictoryCeremony` 播 TreasureDropOverlay;普通/无掉落档 → 播 VictorySealFlash。
- `deferVictoryToCaller` 测:true + leftWin → BattleScreen 不弹 VictoryOverlay、直接回调;false 或败北 → 仍弹 VictoryOverlay。
- `VictorySealFlash` 自动消失(~0.8s onDone,不拦点击)widget 行为测。
- `BattleStatsSummary.from` 纯函数测 + dialog 新增统计段断言。
- 现有 VictoryOverlay / 「敗」路径 / 掉落入库测**不动**、保持绿。
- 闸门:analyze 0 + 全量绿。

## 风险

- **整体风险低**:不碰 resolve / roll / rng / 数值 / 战斗数学。核心是把胜利结果反馈从 BattleScreen 下放到 flow(`deferVictoryToCaller` 开关)+ 新增简版勝 widget + 统计搬到 dialog,均为表现层时序搬移。
- 注意点:① `deferVictoryToCaller` 只 gate **胜利**,败北仍走 BattleScreen「敗」overlay,勿误伤;② demo/pvp/debug 等无 flow 路径默认不 defer,胜利反馈不能丢;③ 统计从 `finalState` 算,依赖 BattleScreen pop 后 `battleProvider` 状态仍在(现 `_applyVictoryResolution` 已 `ref.read(battleProvider)` 成功读到,证明在)。
