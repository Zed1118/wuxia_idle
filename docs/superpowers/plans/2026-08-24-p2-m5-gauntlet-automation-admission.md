# P2 M5：断魂庄自动化准入

## 目标

把 `GAUNTLET-VISIBLE-BOT-01` 从证据/防御层接到真实 application 边界：断魂庄不允许可见 realtime bot，不允许 headless 首通，仅在 `clearedGauntletIds` 含当前断魂庄 ID 后允许确定性 headless replay。

## 实现边界

- 新增纯领域 policy 与 application admission/orchestrator；输入使用现有 `ActivityParticipationRequest`，不得从字段组合猜默认值。
- 现有 `fightCurrentStagePhase0a` 的公开 headless 路径必须经过显式准入，或收窄为只能由已准入路径调用；防止调用者绕过 Gate。
- 若显式请求改变该公开方法签名，允许同步适配唯一额外调用点 `test/features/boss_gauntlet/phase0a_gauntlet_continuation_test.dart`；不得以兼容旧测试为由保留隐式准入默认值。
- complete clear 的唯一当前证据为精确 `gauntletId` 存在于 `SaveData.clearedGauntletIds`。
- 自动执行到终关胜利后停在 `GauntletPhase.awaitingRewardChoice`，不得替玩家挑选、结算或重复抽取奖励。
- 不新增 `rulesVersion`、save migration、完整 automation key、UI、数值或模式解锁改动；这些仍是后续关闭项。

## 外部模型与验收

- 开工前和 actual diff 后分别调用 Pi `deepseek/deepseek-v4-flash` 高强度只读审查，记录命令、版本、精确 selector、退出码与 P0/P1/P2。
- actual diff 终审证据必须绑定被审查的最终 code tree/commit；终审后如再改 code/test，必须重跑终审。
- 反例覆盖 realtime+playerBot、firstClear+headless、未完整首通 replay、错误 content kind/id、绕过 service 入口和 awaitingRewardChoice 自动领奖。
- 定向测试、scoped analyze、format、diff check 和 clean worktree 全过后提交唯一 READY 恢复点。

## 恢复点

- 产品语义基线：`693ed157071e8242dc44ef81b9bae7d289809e58`；source patch diff 基线：`a6a373e137f72a69040199eb9431052f8095d1e1`。
- 执行端不得改 registry、真相文档、save schema、数据或 UI；由主控复审与集成。
