# P2-G2-O02：目标原语纯映射

## 目标

在 Batch7 READY 基线 `codex/phase2-g2-batch7-data-contracts-20260823`
之上，新增 `CombatObjectivePrimitiveRef` 到 `EncounterObjective` 的唯一纯
mapper。八类 S01 ref 必须一一映射到 O01 原语；`requiredTicks` 只通过 caller
显式提供的正 `tickDuration` 转为 `Duration`，不提供默认 tick，不选择任何关卡
objective 或平衡值。

## 分支与文件边界

- 分支：`codex/phase2-g2-o02-combat-objective-mapper-20260823`
- 基线：`e2c3da7690ed4f1ca4b8c7586e3049dd38b0483f`
- 新增：`lib/data/validation/combat_objective_primitive_mapper.dart`
- 新增：`test/data/validation/combat_objective_primitive_mapper_test.dart`
- 新增：本计划兼审计文件
- 禁止修改 O01/S01 公共类型、registry、GameRepository、production host、
  production data、UI、奖励、存档与任何具体关卡内容。

## 合同与验收标准

- [x] 八类 ref 精确一一映射，ID 与集合成员不增删、不重排出新语义。
- [x] `tickDuration` 为必填正 `Duration`；零值、负值和 ticks 乘法溢出 fail
  closed，不存在默认 tick。
- [x] 映射后的集合保持不可变快照；重复映射产生互不共享 owner progress 的新
  objective 实例。
- [x] O01 的 owner-bound progress、事件 kind+id 去重、replay no-op 与完成后
  no-op 行为保持。
- [x] 同 ref、同 tick 输入的类型、字段和可观察推进结果确定一致。
- [x] targeted test 通过；scoped analyze 仅覆盖两个新增 Dart 文件且 0 issue；
  `dart format`、`git diff --check` 与严格路径 diff 检查通过。
- [x] 不触及数值红线、三系锁死、在线=离线、反主流项或文案/玩法数值硬编码；
  `tickDuration` 是 caller 输入，mapper 只执行单位换算。
- [x] 本切片按明确冻结边界保持孤立，不做 production wiring；后续消费方接线不在
  O02 范围内。
- [x] 独立子 agent 只读审查通过，主会话复核真实 diff 与验证证据。

## 任务切片

1. 读取 CLAUDE/GDD、二阶段 M1、Batch7、最终 O01/S01 源码与 registry。
2. 先新增覆盖八类、非法 tick、Duration 边界/溢出、不可变性、owner/replay 和
   确定性的测试，并确认测试因 mapper 缺失而失败。
3. 新增最小纯 mapper，使测试转绿，不修改公共合同。
4. 执行 targeted test、scoped analyze、format、diff/check 与边界审计。
5. 独立审查后由主会话复验，提交实现并追加规定的 `[READY]` 空提交。

## 审计记录

- 公共合同冲突：未发现；S01 八 ref 与 O01 八 objective 参数可直接对应。
- production 接线：按任务冻结边界明确不接；本切片仅交付可供后续 caller 消费的
  纯转换合同。
- 工具链资源锁：运行任何 Flutter/Dart 测试或 analyze 前检查 Qoder、Flutter test
  与 build_runner 进程；有冲突时只记录待验，不抢串行锁。
- 红测：`flutter test --no-pub --no-test-assets
  test/data/validation/combat_objective_primitive_mapper_test.dart` 在 mapper 不存在时
  以缺文件/缺符号编译错误失败，随后才新增实现。首次两次尝试因 fresh worktree
  缺 `.dart_tool` 触发 Flutter native-assets CLI 崩溃；离线 `flutter pub get`
  只生成 gitignored 依赖元数据，tracked diff 未变化。
- Duration 溢出：本机 Dart 3.11.3 SDK 的 `int` 为 64 位二补码且溢出回绕；正乘积
  回绕为负/零时由 `<= 0` 捕获，回绕为正时回除结果不可能仍等于正
  `microsecondsPerTick`。精确最大正微秒值允许，越界 fail closed。
- 独立审查：Luna 只读审查核对八类、不可变性、owner/replay 与路径边界；在读取
  本机 `int.dart` / `duration.dart` 后撤回其初始溢出质疑，最终结论“无阻断缺陷”。
  其非法 tick 覆盖建议已采纳，测试现逐一覆盖八类 ref 的零/负 tick。
- 绿测：`flutter test --no-pub --no-test-assets -j 1
  test/data/validation/combat_objective_primitive_mapper_test.dart`，8/8 通过。
- scoped analyze：`flutter analyze --no-pub
  lib/data/validation/combat_objective_primitive_mapper.dart
  test/data/validation/combat_objective_primitive_mapper_test.dart`，2 items，0 issue。

## 当前恢复点

- 状态：实现、动态验证、独立审查与主会话验收均完成，准备提交和 READY 收口。
- 最后完成：新增八类穷尽纯映射、caller 显式正 tick 校验与 Duration 乘法溢出
  fail-closed 检查；完成独立静态审查与主会话复核，未修改公共合同。
- 下一步：最终 diff/路径检查，提交实现，再追加规定的空 READY commit。
- 已跑验证：红测 0 pass / 1 load failure（预期缺 mapper）；绿测 8/8；scoped
  analyze 2 items / 0 issue；`dart format` 两文件 0 changed；`git diff --check`
  通过；diff 仅三份允许的新文件。
- 阻塞项：无。
