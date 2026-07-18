# 击杀特写动作快照计划

> 上游稳定点：`codex/battle-log-kill-snapshot@d5129fe6`
> 分支：`codex/battle-kill-climax-snapshot`

## 1. 目标

击杀特写必须只由真正的致死动作触发；目标后来阵亡不能让播放队列中更早的普通命中补触发峰值特写。

## 2. 方案

- `hitClimaxFor` 读取 `BattleAction.defeatedTarget`，不再回查队伍最终存活状态。
- 删除峰值判定对 `BattleState` 的无关依赖，避免调用方误用当前状态推导历史事实。
- 更新播放控制器两处生产调用与峰值纯函数测试。
- 保持“大招暴击优先于击杀”的现有表现层优先级。

## 3. 验收

- [x] 目标后来阵亡：早先命中不触发击杀特写。
- [x] 致死动作快照：即使当前目标存活也触发击杀特写。
- [x] 大招暴击 + 击杀仍优先 `ultimateCrit`。
- [x] 完整战斗模块、analyze 与双视口 UI 回归通过。
- [x] 冻结 `[READY]` 稳定点。

## 4. 当前恢复点

- **状态**：实现与验证完成，待冻结稳定点。
- **最后完成**：`hitClimaxFor` 已只读 `BattleAction.defeatedTarget`，并删除 `BattleState` 参数；播放控制器两处生产触发同步更新。
- **下一步**：提交 `[READY]` 后继续审计战斗方式的剩余边界。
- **已跑验证**：先见定向红测；峰值纯函数 7/7；完整 `test/features/battle` 703/703；`flutter analyze --no-pub` 无问题（双视口 UI 用例包含在完整回归）。
- **阻塞项**：无。
