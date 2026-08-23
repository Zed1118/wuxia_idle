# P2-G2-E01：显式活动参与请求

## 范围

本切片提供 Phase 0A 的纯 Dart、不可变 `ActivityParticipationRequest`，把活动内容、实际角色、装配方案和参与/控制/时钟/入口选择全部作为必填字段传入。

角色主键沿用项目真实 Isar `Character.id` 类型 `int`，并拒绝非正数；`contentId` 与 `loadoutPlanId` 在构造时 trim，拒绝空值。请求实现值相等与稳定 hash。

## 明确不做

- 不解析当前掌门，不提供角色或装配方案默认值，不选择 fallback。
- 不判断 direct/dispatch、human/playerBot、realtime/headless、entryKind 的语义组合；这些由后续 `CharacterAvailabilityService` 与活动 policy 层决定。
- 不编码主线重打、扫荡、`MainlineRun` 锁定、replay/sweep policy，也不接入任何 production flow。

## 验证

- 测试覆盖全部枚举值、ID 校验与 trim、值相等/hash、语义上显式但不预判的组合及不可变公开字段。
- 仅运行对应 targeted test、限定 `dart analyze` 与 `git diff --check`。
