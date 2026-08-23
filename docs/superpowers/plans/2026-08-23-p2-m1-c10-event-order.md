# P2-M1-C10 事件顺序候选

## 目标

在 Phase 0A 领域层提供可测的事件阶段顺序与只读表现 feed schema，不接生产 reducer、model、UI 或数值结算。

## 合同

- 同一模拟 tick 严格按：合法性资源 → 起手 → 位移/选点 → 命中冻结 → 防御 → 伤害/姿态 → 状态 → 击杀资源 → 表现。
- 同阶段使用调用方注入的 `tieBreak`，相同时以 `eventId` 作确定性最终 tie-break。
- `aggregateKey`、`priority` 和 `feedKind` 仅为聚合/优先级 schema，不生成中文文案或最终数值。
- 表现 feed 是不可变投影；投影不回写或重算领域事件。
- 事件 ID、tick、tie-break、priority 必须合法，单次排序输入不得重复事件 ID。

## 验证

- `flutter analyze` 定向文件。
- `flutter test --no-pub test/features/battle/domain/phase0a/combat_event_order_test.dart`。

## 恢复点与边界

本片只新增三白名单文件。生产接线、现有 `Phase0aEvent` 迁移、UI/VFX/SFX、聚合算法和最终数值留给 G1 审核及后续任务。
