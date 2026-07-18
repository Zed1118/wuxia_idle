# 群攻同拍特效去重实施计划

> 上游稳定点：`codex/battle-experience-phase3@42eb3944`  
> 分支：`codex/battle-aoe-vfx-dedup`  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-aoe-vfx-dedup`

## 1. 目标

同一个角色在同一 tick 释放同一群攻时，只播放一次人物动作、中央流派特效、大招题字与 SFX；每个目标仍分别保留伤害飘字、受击闪、暴击/破甲/内伤特效。

## 2. 根因证据

- `DefaultGroundStrategy` 对 AOE 每个存活目标写一条连续 `BattleAction`。
- `BattleScreen` 对本次新增 action 逐条调用完整 `playAction`。
- `playAction` 同时包含共享演出与目标反馈，当前无同源 AOE 分组边界。

## 3. 验收标准（CLAUDE.md §8.2）

- [x] **生产接线**：`BattleScreen` 的 actionLog 边沿改用批量播放入口，普通单体动作保持原路径。
- [x] **targeted test**：三目标 AOE 只生成一个共享流派特效，三目标飘字全部存在；单体动作无回归。
- [x] **红线影响**：纯表现层，不改伤害、tick、AI、真气、胜负、numbers、schema/saveVersion。
- [x] **UI/UX**：1280×720 / 1440×900 战斗 smoke 无 overflow/exception/error。
- [x] **桌面语义**：不改按钮、focus、键盘或鼠标交互。
- [x] **残留风险**：跨 tick 连续 AOE 已测；暴击、会心、破绽、破招按优先级选共享代表动作。残留为真机动态捕捉极短特效峰值的观感调优，不影响功能。
- [x] **清洁度**：无生成物、capture、日志误提交；中文动宾提交并冻结 `[READY]`。

## 4. 实施切片

1. 新增失败测试，复现 3 条同源 AOE 生成 3 个共享流派特效。
2. 新增连续 AOE 分组与代表动作选择，只对代表动作播放共享反馈。
3. 将生产 actionLog 监听接到批量播放入口。
4. 跑 targeted、analyze、双视口视觉 smoke，更新恢复点并提交。

## 5. 当前恢复点

- **状态**：完成，待 `[READY]` 冻结。
- **最后完成**：生产 actionLog 改为批量播放；同源 AOE 只播一次共享演出，逐目标飘字、受击闪、暴击/破甲/内伤特效保留。
- **下一步**：从本分支 tip 创建「自动/点选战斗界面分工」切片。
- **已跑验证**：红测实证 3 个共享特效；修复后控制器 11/11、战斗 presentation + 控制器 216/216；`flutter analyze --no-pub` 0 issue；`battle_tap_live` 1280×720 / 1440×900 真实窗口目检与日志无 overflow/exception/error；debug macOS build 成功（仅上游 audioplayers Swift warning）。
- **阻塞项**：无。
