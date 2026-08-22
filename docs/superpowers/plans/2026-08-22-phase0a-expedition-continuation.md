# Phase 0A 远征单角色续传计划

## 目标

新增默认关闭的远征 Phase 0A 灰度路径，复用既有 `ExpeditionCombat` seam 与离线状态机，以单角色同核 headless 战斗续传节点间 HP/Qi；旧 3v3 路径、奖励、伤势、占用和事务游标不变。

## 边界

- 新派遣在灰度开启时限单角色；历史多成员在途会话回落旧 runner。
- 每节点只使用稳定 `nodeSeed` 创建随机源，弃批重试结果一致。
- timeout 沿旧 draw 口径视为非胜利败停，不结算失败节点奖励。
- 不改 YAML/GDD/数值/掉落，不启动 GUI，不 merge/push/deploy。

## 切片

1. neutral snapshot 支持 HP/Qi 注入，mapper 增远征入口与 cycle 境界推进。
2. 新增默认关闭灰度门和独立 `Phase0aExpeditionCombatRunner`。
3. 启动追平/召回选择 runner，新派遣 UI 灰度限单人。
4. 验证稳定 seed、跨节点续传、timeout 败停、历史多成员回落和离线幂等。
5. targeted、预检、analyze、macOS 编译、全量，建立 READY。

## 恢复点

- 基线：`9ce4e1d4 [READY] 收口 Phase 0A 扫荡无头直结`
- 分支：`codex/phase0a-activity-continuation-0822`
- worktree：`/Users/a10506/Desktop/Projects/wt-phase0a-activity-continuation-0822`
