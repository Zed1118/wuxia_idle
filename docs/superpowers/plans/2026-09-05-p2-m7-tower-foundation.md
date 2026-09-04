# Phase 2 M7 塔迁移基础门计划（2026-09-05）

## 结果合同

- 单一目标：在不迁任何楼层的前提下，建立塔 typed migration 的 route authority、精确多敌 runtime binding、护法 ID 翻译和三生产入口统一 encounter factory。
- 固定验收门：基础门 `1/1`；生产楼层分母 `49`，本批分子保持 `0`；正式 Phase 2 分母 `10`，本批不改变 `1/10`。
- 基线：`main == origin/main == 7c10ff17583addda4dd9039372f6f1b918d3a60e`，exact-SHA CI `33895342001` 成功。
- 禁区：不迁塔楼层，不改数值/奖励/经济、`saveVersion`/schema、心魔 AI、时间轴/真气生产接线，不启动 M8/M9，不代签真人或 Windows。

## 实施与验收

1. 先以缺失 `CombatContentRef`、route authority、binding source 与 factory 的编译失败建立有效 RED。
2. typed 路径严格校验 encounter/runtime 数据、entry/source 顺序双射和 guardian runtime ID 翻译；任何缺失、重复、错序、自引用或悬空均 fail closed。
3. 可见挑战、即时挂机、durable 恢复统一消费一个 factory；结算、首通、奖励、个人记录与事务 owner 不变。
4. 代表层 `1/7/14/32/42/49` 各跑 cycle `1/2`，比较 legacy/typed mechanics、终局和 settlement，并验证 live/headless 同 seed 完全一致。
5. 实做并恢复三类 mutation：多敌错绑、护法翻译断开、生产入口绕过统一 factory。
6. 通过聚焦、塔域宽回归、analyze、format、持锁全量与标准 Gate 后才允许 `[READY]` 和 no-ff 集成。

## 收口状态

- `[READY]` 候选 `431f28532b6ebd1ea07dadad22d2755192955f61` 已通过标准 Gate：独立 full `6010/6010`、analyze 0、format `1740/0 changed`、receipt matched。
- 基础门已 no-ff 合入 main；生产 migration set 仍为空，塔工程水位保持 `0/49`。本次 push 的 exact-SHA CI 由集成收尾实时核验，不在提交前预写运行号。
