# P2-G2-D08：Runtime Observer 连续性回归

## 目标

在 D07 `assembleEncounter` 生产入口上补一条真实
`AttackTokenObserveOnlyObserver` 五拍组合回归，锁住 runtime 每拍 session
fork 不丢 observer、出生宽限 gate 先于 observer，以及 observe-only 路径不改变
事件、状态或 caller RNG。

## 分支

`codex/phase2-g2-d08-runtime-observer-20260823`

## 验收标准

- 仅新增独立 D08 测试与本计划，不改 production 或既有测试。
- 五拍固定为 warning=1、grace=2；宽限完成前 allocation 为空，到期拍与
  后续拍连续授予同一敌人。
- 外部持有的同一 observer 引用每拍更新 `lastAllocation`，证明逐拍 fork 未丢
  identity。
- 同 seed 有/无 observer 的逐拍 events/state/outcome/records/spawn state 全等。
- 两条路径 RNG 尾值都与精确四次 roll 的对照一致。
- targeted test、scoped analyze、format 与 `git diff --check` 通过。
- 不触及数值硬红线、三系锁死、在线=离线、反主流机制或文案/数值硬编码。

## 任务切片

1. 核对 D07 `assembleEncounter` API 与现有 fixture 体例。
2. 新增单敌五拍 production encounter 回归。
3. 运行定向验证并复核 diff。
4. 提交实现与 `[READY]` 冻结标记。

## 当前恢复点

- 状态：已完成，待提交 READY 标记。
- 最后完成：真实 AttackToken observer 五拍回归与精确 RNG 尾值断言。
- 下一步：提交实现 commit，再追加 `[READY]` 空提交。
- 已跑验证：`dart format`；targeted test 1/1；scoped analyze 0 issue；
  `git diff --check` 通过。
- 阻塞项：无。
