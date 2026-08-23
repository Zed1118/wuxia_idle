# P2-M1-C07：真气预留账本候选

## 任务元数据

- taskId: P2-M1-C07-QI-RESOURCE
- milestone: M1 / C07 真气资源
- owner: Codex
- branch: `codex/phase2-m1-qi-resource-20260823`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-qi-resource`

## 目标与非目标

目标：提供纯 Dart、有界真气账本候选，覆盖动作起手预留、首个生效 tick 提交、取消/中断释放并标记失败冷却、一次动作一次产气、击杀窗口上限和溢出事件数据。

非目标：不接 reducer、动作时间线、战斗 model、数据 loader、UI、存档或生产入口；不决定最终数值。

## 白名单

- `lib/features/battle/domain/phase0a/qi_resource.dart`
- `test/features/battle/domain/phase0a/qi_resource_test.dart`
- 本计划文件

禁止修改其他文件。

## 冻结合同

- `current` 始终位于 `[0, capacity]`；预留只降低 available，不立即降低 current。
- reservation/action ID 唯一；重复预留拒绝；提交/取消对同一终态幂等，跨终态操作拒绝。
- 提交只发生在调用方指定的首个生效 tick；账本不接动作时间线。
- 取消释放预留并返回 `releasedWithFailureCooldown` 标记。
- 同一 action ID 的 gain 只生效一次，适配多段动作只产一次气。
- 击杀返气按调用方传入的 windowCap 限制；容量溢出和窗口溢出均在 `QiGainResult.overflow` 暴露。
- 所有资源数值由调用方注入，账本不写玩法常量。

## 验收与验证

- TDD 覆盖边界校验、预留/提交/取消生命周期、重复 ID、一次动作产气、击杀窗口 cap、容量溢出。
- `dart format lib/features/battle/domain/phase0a/qi_resource.dart test/features/battle/domain/phase0a/qi_resource_test.dart`
- `dart analyze lib/features/battle/domain/phase0a/qi_resource.dart`
- `flutter test --no-pub test/features/battle/domain/phase0a/qi_resource_test.dart`
- 未接生产；API 待 G1 主审确认。

## 当前恢复点

- 状态：候选实现完成，format/analyze 通过；定向 Flutter 测试因 worktree 依赖环境启动失败，待审查和 READY 提交。
- 最后完成：`dart format` 与 `dart analyze lib/features/battle/domain/phase0a/qi_resource.dart` 通过；Flutter test 启动阶段异常 `Bad state: No element`，无断言结果。
- 下一步：检查 diff/白名单并提交；主审在具备 `.dart_tool` 的环境复跑 targeted test。
- 阻塞：本 worktree 缺少 `.dart_tool`，白名单禁止复制/生成依赖文件；生产接线与最终公共模型留给 G1。
- 风险：reservation 历史记录保留在内存中；未来接 reducer 时需由公共 session 决定生命周期与序列化语义。
