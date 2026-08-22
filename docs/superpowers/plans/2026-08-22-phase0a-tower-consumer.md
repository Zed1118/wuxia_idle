# Phase 0A 塔消费面纵切计划

## 目标

在不切换默认生产入口、不拆旧 3v3 的前提下，为塔战增加默认关闭的 Phase 0A 灰度纵切，打通真实塔层定义、单角色装配、战斗宿主、胜负结算、继续爬塔与中途退出零污染，并保持现有塔流程零回归。

## 边界

- 复用既有 `Phase0aStageContentMapper.mapTower`、reducer、表现层和 settlement snapshot。
- 灰度门默认关闭，只允许显式 `dart-define` / 测试 override。
- 不调整 YAML 数值、掉落、门票、层数或正式入口。
- 不 merge、push、deploy，不拆旧 3v3。

## 切片

1. 冻结塔入口、宿主、结算、续层、退出语义与测试矩阵。
2. 新增塔灰度门和 Phase 0A 塔宿主，复用 neutral snapshot / production mapper。
3. 将胜负 settlement 接回既有塔服务，验证继续层与退出零污染。
4. 补 live/headless 一致、默认关闭、非目标内容回落旧入口测试。
5. targeted + analyze + 149/149 预检 + macOS 双视口实机 Gate。
6. 更新 PROGRESS/BACKLOG，提交 `[READY]` 恢复点。

## 恢复点

- 基线：`e1711f36 [READY] 收口 Phase 0A 护法标签与进度底账`
- 分支：`codex/phase0a-tower-consumer-0822`
- worktree：`/Users/a10506/Desktop/Projects/wt-phase0a-tower-consumer-0822`

## 执行结果

- 实现提交：`2f2a21b9 [Phase0A] 接通塔消费面灰度纵切`
- 默认入口：`PHASE0A_TOWER_GRAY=false`；空敌队 fixture fail-closed 回落旧入口。
- 结算：0A snapshot 走 engine-neutral `resolveSnapshot`，仅结算真实参战角色；旧 3v3 仍由 legacy snapshot 适配。
- 退出：0A 系统返回记为 surrendered，clear/defeat/奖励均零消费。
- 验证：塔表现与 mapper/preflight targeted 55/55；代表层 live/headless 一致；149/149、447 runs、0 timeout；双视口 widget Gate；macOS debug 灰度编译通过；全仓 analyze 0 issue；全量 5373/0。
- 边界：未启动 GUI，未改 YAML/GDD/数值/掉落，未 merge/push/deploy，旧 3v3 未删除。
