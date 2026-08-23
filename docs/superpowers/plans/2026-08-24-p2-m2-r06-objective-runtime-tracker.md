# P2-M2-R06：目标运行时追踪器

## 目标与范围

在 R03 `ObjectiveController` 之上交付一个纯 application 层 tracker：精确持有单一 controller 及其 owner-bound progress lineage，接受显式 objective event，或由调用方显式将 `Phase0aEnemyDefeated` 分类为零个或多个 objective event。本切片不修改 encounter flow/session/production assembler。

- 分支：`codex/phase2-m2-r06-objective-runtime-tracker-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r06-objective-runtime-tracker`
- 基线：Batch11 READY `57f04b397d1412128535ba8f74a7e61ecdfb4577`
- 允许：tracker、对应 targeted test 与本计划。
- 禁止：flow/session/assembler、production host/data、胜负终局、reward/save/UI/YAML/tuning、task/decision registry。

## 冻结语义

- tracker 只持有一个 controller 和其 progress；默认从 `initialProgress` 开始，显式恢复只接受同 owner progress。
- combat 批次只处理 `Phase0aEnemyDefeated`；target/commander 等语义全由 caller mapper 显式给出，不按 actor ID、role 或 `defeatKind` 猜测。
- 保持 combat event 顺序及 mapper iterable 顺序；输入先防御性快照，不留外部可变引用。
- 批次映射、lazy iterable 迭代或 controller advance 任一失败，不提交任何 progress；全部成功后才一次替换。
- terminal 后返回同一 progress instance，不迭代新输入、不再调 mapper；重放去重继承 controller。

## 验收 checklist（CLAUDE §8.2）

- [x] target、commander、单 defeat 映射双事件、零事件、非 defeat 忽略均有直接测试。
- [x] combat/mapper 顺序、duplicate replay、terminal no-op 且 mapper 未调用有直接测试。
- [x] mapper 构造抛错、mapper lazy iterable 中途抛错、combat input lazy iterable 抛错均整批回滚。
- [x] 同 owner 恢复、跨 owner fail closed、暴露 progress 不可变。
- [x] targeted test、scoped analyze、format、`git diff --check` 及严格路径审计通过。
- [x] 生产接线证据：本任务按冻结边界明确不接 host；仅交付后续 runtime host 可消费的 application 合同。
- [x] 红线：0 生产数值、0 Dart 玩家文案、0 三系/在线离线/反主流触点。
- [ ] 实现与证据提交后，追加 `[READY][CODEX][P2-M2-R06]` 空提交并保持树干净。

## 任务切片

1. 完整阅读项目约束、R03/O01 合同与已否登记。
2. 红：先增 tracker 目标语义、原子回滚与 owner 测试，确认因 API 缺失编译失败。
3. 绿：新增最小纯 application tracker，不接 production host。
4. 验收：targeted、scoped analyze、format、diff/path 与生产隔离审计。
5. 更新恢复点，提交实现/证据并追加 READY 空提交。

## 当前恢复点

- 状态：实现与动态验证完成，待提交并冻结 READY。
- 最后完成：新增纯 application tracker，为输入与 mapper 输出建立不可变快照，所有 controller 推进先在局部 progress 完成再一次提交；终局严格短路。显式恢复 progress 以无副作用 owner probe 验证，跨 controller 构造即 fail closed。
- 下一步：提交实现/证据，追加 READY 空提交，交主控独立复审。
- 已跑验证：红测因 tracker 文件/API 缺失按预期编译失败；tracker targeted 11/11；`objective_controller_test.dart` 8/8；`encounter_objective_test.dart` 9/9，共 28/28；scoped `flutter analyze --no-pub` 2 items / 0 issue；format、`git diff --check` 与路径审计通过。
- 阻塞项：无。
- 残留风险：production host 与 objective-driven 胜负还未接线；本切片不宣称生产闭环。当前 sealed/final controller 在合法 owner progress 上无可注入抛错实现，因此 controller 异常的原子性由“先局部 advance、后赋值”结构保证，动态覆盖以跨 owner fail closed 和 mapper/lazy 异常回滚为代表。
