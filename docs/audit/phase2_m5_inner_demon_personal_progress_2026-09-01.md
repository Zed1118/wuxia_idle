# Phase 2 M5 心魔个人进度审计

日期：2026-09-01

任务：`P2-M5-INNER-DEMON-PERSONAL-PROGRESS`

基线：`ef2a8fe20a70f4aca90a272186cf7c936e364008`

## 结论

心魔个人进度不需要新增持久集合。U09 已在真实胜利结算事务中为每次心魔胜利写入个人作用域 `RewardClaimReceipt`；缺口是两个生产消费者仍从存档级 `MainlineProgress.clearedStageIds` 派生角色进度。本切片把角色面板和心魔关卡列表改为读取 `innerDemonProgressProvider(characterId)`，以既有 receipt 的 `contentId + participantId` 作为个人胜利事实。

这关闭 M5 心魔“记录作用域”一格，使工程矩阵从 `36/42` 推进到 `37/42`；顶层 M5 仍因另外五格保持 `0/1 BLOCKED`。旧档全局心魔通关无法证明实际角色，继续不建立个人事实；这与 U09 迁移“不猜人、不伪造奖励或墓碑”的既有边界一致。

## 生产证据

- 写端：`applyVictoryResolution` 在角色成长、全局通关事实与奖励 claim 同一事务内落库。
- 持久 owner：`RewardClaimReceipt` 的 `RewardContentKind.innerDemon`、`RewardScope.personal`、`participantId` 与 `contentId`。
- 读端：`innerDemonProgressProvider(characterId)` 校验 canonical receipt identity，并按当前 slot 和 exact participant 过滤。
- 消费者：角色面板突破区与 `InnerDemonScreen(characterId)` 共用同一 family；列表只保留非心魔的全局前置关，心魔链本身由个人进度推进。
- 刷新：心魔挑战流返回后失效当前角色 family，胜利或重打均从持久 receipt 重读。

## 破坏证红

临时移除 `receipt.participantId != characterId` 后，个人 provider 用例出现 `1` 条失败：未参战角色的实际 `clearedCount` 从预期 `0` 变为 `2`。精确反向补丁恢复过滤后同用例重新通过，证明跨角色隔离断言不是恒真。

把生产派生结果临时强制退化为空集合后，同一用例再次精确出现 `1` 条失败：实际参战者的 `clearedCount` 从预期 `2` 变为 `0`。精确反向补丁恢复真实 receipt 集合后用例通过，证明写端事实确实被生产读端消费。

## 验证

- 生产 settlement、receipt、provider、角色面板与心魔页面扩展定向：`113/113 PASS`。
- 两向破坏证红：删除 participant 隔离 `1` 条失败；强制空进度 `1` 条失败；均精确还原。
- 测试契约迁移：`expect` 删除 `6`/新增 `8`、用例删除 `2`/新增 `2`，登记 `8` 条，`PASS: test_contract_migration`。
- `flutter analyze`：`No issues found!`。
- `dart format .`：`1699 files / 0 changed`。
- 锁保护整仓全量：`5828/5828 PASS`，退出码 `0`，末行 `All tests passed!`。
- 项目 Gate：普通检查、全量、analyze、format 与 receipt 必须在最终 READY tip 通过；原始 `test_deletions` 仅允许由上述 8 条专用迁移 Gate 覆盖。

## 范围

- 未新增 schema、未提升 saveVersion，未改任何奖励、数值、概率、经济、解锁阈值、YAML TUNING、技能或战斗规则。
- 真人桌面交互、视觉和 Windows 实机继续挂账；本证据只支持工程矩阵 `37/42`，不支持正式 M5 或 Phase 2 PASS。
