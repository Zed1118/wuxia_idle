# Phase 0A 断魂庄历史多人兼容计划

## 目标

新增默认关闭的断魂庄 Phase 0A 灰度门与战斗路径选择器：灰度开启时仅单成员会话选择 Phase 0A，历史 2–3 人在途会话始终选择旧 3v3；灰度关闭时所有会话走旧路径。

## 分支

`codex/phase0a-gauntlet-compat-0822`

## 文件边界

- 可新增/修改：`lib/features/boss_gauntlet/application/phase0a_gauntlet_gate.dart`
- 可新增/修改：`lib/features/boss_gauntlet/application/gauntlet_combat_selector.dart`
- 可新增/修改：`test/features/boss_gauntlet/phase0a_gauntlet_gate_test.dart`
- 不得修改 `gauntlet_service.dart`、`gauntlet_entry_flow.dart`、会话模型、结算、奖励、补给和其他 feature。

## 冻结接口

- `enum GauntletCombatPath { legacy3v3, phase0a }`
- `Phase0aGauntletGate.enabled`
- `Phase0aGauntletGate.shouldUsePhase0a({required int memberCount})`
- `GauntletCombatPath gauntletCombatPathFor({required int memberCount})`
- 环境开关名：`PHASE0A_GAUNTLET_GRAY`
- 测试覆盖允许通过 `testOverride` 控制开关，tearDown 后必须复原。

## 验收标准

1. 生产接线证据：选择器位于 boss_gauntlet application 层，供主线消费；不得停在 fixture。
2. targeted test：至少覆盖默认关闭、单成员开启、2/3 成员回落旧 runner、非法成员数 fail-fast。
3. 红线：不改数值/YAML/schema/saveVersion，不新增中文散写，不改变在线=离线、三系锁死或反主流规则。
4. 风险：记录选择器尚待主分支消费的整合点；不得声称已完成 A/C。
5. `flutter analyze` 0 issue；worktree 干净；中文动宾 commit；tip 以 `[READY]` 标记。

## 任务切片

1. 红测定义灰度门与选择器契约。
2. 最小实现并跑 targeted test。
3. analyze、更新恢复点、提交并标记 READY。

## 当前恢复点

- 状态：已派发，待实现。
- 最后完成：主 agent 冻结接口与文件边界。
- 下一步：DeepSeek 先补红测，再实现灰度门/选择器。
- 已跑验证：无。
- 阻塞项：无。
