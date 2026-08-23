# P2-G1-C17B 心魔旧字段清理

## 目标

在 INNER-DEMON-FAILURE-CORE-01 已冻结后，清除 5 个零生产读方 legacy 字段：`internal_force_multiplier`、`internal_force_floor_pct`、`sub_cultivation_multiplier`、`debuff_id`、`debuff_clear_via_retreat_hours`。保留并校验 `main_cultivation_multiplier`，当前 safe_default 仍为 `0.90`；不拍板 `INNER-DEMON-CULTIVATION-01`。

## 实现与证据

- `data/numbers.yaml` 的 `failure_penalty` 仅保留主修系数。
- `InnerDemonFailurePenalty` typed 字段、empty default 和 loader 仅保留主修系数；loader 对退役 key fail-fast，防止配置复活。
- `InnerDemonService` 注释同步真实语义：永久内力不变、内息紊乱走独立配置、只改主修修炼度，辅修字段不触碰。
- 测试移除对退役字段的依赖，增加主修系数解析、缺失/越界拒绝和 legacy key 拒绝证红。
- 未删除 `InnerDemonPenaltyResult` 的公共 before/after 汇总字段，未改 UI、存档 schema 或生产 API。

## 验证

- 先确认仓库检索中退役字段只存在 typed loader 的拒绝名单与测试输入，不存在生产消费。
- `dart format`、`flutter analyze`。
- `flutter test --no-pub test/features/inner_demon test/data/inner_demon_dead_config_test.dart`。
- `git diff --check` 与白名单核对。

## 恢复点与风险

- 当前切片不改变主修惩罚是否应存在的 G0 PROPOSED 决策，仅精确保留现状 ×0.90。
- 旧存档迁移不读取这些新配置字段；C17B 不扩展为存档/schema 清理，避免越界。
