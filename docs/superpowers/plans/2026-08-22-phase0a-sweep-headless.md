# Phase 0A 扫荡 headless 直结计划

## 目标

在不切换默认扫荡路径的前提下，新增默认关闭的 Phase 0A headless 灰度路径：主线与塔扫荡按既有顺序逐单位运行同一 reducer/bot，生成 `CombatSettlementSnapshot`，直接复用既有重打结算与 recap，不挂战斗 GUI。

## 边界

- 复用 production mapper、`Phase0aHeadlessRunner`、bot 与 neutral settlement。
- 灰度门默认关闭；旧 3v3 快进连播保持原样可回落。
- 扫荡资格、首通/重打掉落、残页、经验、周目与停止语义不变。
- 不改 YAML/GDD/数值/掉落，不 merge/push/deploy，不删除旧扫荡路径。

## 切片

1. 审计 SweepUnit、SweepScreen、settlement 与停止/失败/recap 契约。
2. 增加默认关闭的 headless 灰度门与 neutral runner seam。
3. 主线/塔单位接 production mapper + 单祖师快照 + 同核 bot。
4. settlement snapshot 接回原主线/塔重打结算，验证替补零污染。
5. 补默认回落、逐单位停止、失败 halt、live/headless/recap 回归。
6. targeted、analyze、全量与 macOS 无 GUI 编译 Gate，更新账本并建立 READY 点。

## 恢复点

- 基线：`1b1a46cb [READY] 收口 Phase 0A 塔消费面纵切`
- 分支：`codex/phase0a-tower-sweep-0822`
- worktree：`/Users/a10506/Desktop/Projects/wt-phase0a-tower-sweep-0822`
