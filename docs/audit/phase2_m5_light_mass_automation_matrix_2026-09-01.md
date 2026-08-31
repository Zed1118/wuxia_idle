# Phase 2 M5 轻功/守城自动化矩阵收口

日期：2026-09-01

任务：`P2-M5-LIGHT-MASS-AUTOMATION-MATRIX`

基线：`44a5d241d3c96d58e9ef67254bfc5af2292b8cb1`

实现提交：`9a861386344e868428abb5fb101bd794c3c795dc`

## 结论

轻功、守城的自动化矩阵两格从 BLOCKED 形成可集成工程候选，M5 固定分母由 `34/42` 推至 `36/42`。顶层 M5 仍为 `0/1 BLOCKED`；真人桌面交互、视觉和 Windows 实机继续挂账，本批不把工程绿色冒充正式验收。

## 生产接线

| 通道 | typed request | 生产 owner | 门槛 |
|---|---|---|---|
| 已通关可见重打 | `direct + playerBot + realtime + replay` | `LightFootScreen` / `MassBattleScreen` → `runStageFlow` → `Phase0aMainlineBattleHost` | 消费全局 `autoPlayDefault`；首通仍人控 |
| 快速推演 | `direct + playerBot + headless + replay` | `DurableActivityAutomationService` → coordinator → 既有 Phase 0A headless runner + shared settlement | 仅已通关；守城必须先选阵型并持久化 |
| 差遣 | `dispatch + playerBot + headless + offlineResume` | 既有 durable run / occupancy / resume / report | 语义保持不变 |

三条通道均绑定玩家本次选择的 exact participant。轻功拒绝阵型；守城无画面通道缺阵型时 fail closed。未新增 reducer、runner、settlement 或持久 schema owner。

## 破坏证红

1. 把 policy 的 `direct` 通道改回拒绝：policy、service、coordinator 共 `4` 条失败，证明可见 bot 与快速推演并非由既有差遣假代。
2. 在 `runStageFlow` 忽略 direct participant controller、强制回 `human`：真实 `Phase0aMainlineBattleHost` controller 合同 `1` 条失败，实际为 `human` 而非 `playerBot`。
3. 绕过 `alreadyCleared` 门：policy 与 service 共 `2` 条失败，证明首通门不是恒真断言。

每次破坏后均用精确反向补丁恢复；恢复后相关四文件 `28/28 PASS`，工作树回到 clean。

## 验证

- focused production：`34/34 PASS`；
- 扩展 activity/light-foot/mass-battle/stage-flow/shared-runner：`82/82 PASS`；
- `flutter analyze --no-pub lib test tool`：0 issue；
- `git diff --check`：0 issue；
- 锁保护整仓全量：`5828/5828 PASS`，`[E]=0`，约 `4m55s`，末行 `All tests passed!`；
- `dart format .` 与最终项目 Gate：必须在最终 `[READY]` tip 上通过后才允许合并。

## 保留边界

- 不改 schema/saveVersion、YAML、TUNING、玩家数值、技能、奖励、经济、解锁或战斗规则；
- 不改 checkpoint 位移归因、M2/G2 结论，不启动 M3/M7；
- M5 剩余六格仍为：塔个人记录、塔 durable 差遣、心魔个人进度、断魂庄 durable 差遣、百草岭首次里程碑手动接管、百草岭 `routeId + milestoneId` 自动化解锁记录。
