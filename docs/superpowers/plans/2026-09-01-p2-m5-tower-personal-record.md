# P2 M5 九霄塔个人记录

## 目标

在不改变奖励、数值、解锁、周目、战斗规则或玩家属性的前提下，新增版本化 Isar `TowerPersonalRecord` 持久 owner；手动、扫荡、持久差遣三条真实胜利路径按 exact participant 原子记录个人最高塔层与最好通关耗时。旧档无法证明历史参与者时保持个人记录为空。

## 分支

- branch: `codex/p2-m5-tower-personal-record-20260901`
- worktree: `/Users/a10506/.codex/worktrees/p2-m5-tower-personal-record-20260901`
- base: `b530d804940930628ea1b61e83b188416bc0b1d2`

## 固定验收门

1. 生产接线：`applyTowerVictorySettlement` 是手动、生产扫荡和塔持久差遣共用的胜利事务边界；同一事务内写入 `TowerProgress`、奖励 receipt、角色成长与 `TowerPersonalRecord`。
2. 持久合同：记录以存档和实际角色唯一隔离，包含记录版本、最高塔层、有效耗时中的最好成绩与最近通关时间；零/未知耗时不伪造最好成绩。
3. 迁移合同：`saveVersion 0.43.0 -> 0.44.0`，新增 collection；旧档只升版且个人记录保持空，不从存档级 `TowerProgress`、Boss 纪念或奖励 receipt 猜测参与者。
4. 可破坏证红：删除个人记录写入后，生产结算测试必须红；把 participant 写成其他角色后，多角色隔离测试必须红；旧档伪回填时迁移测试必须红。
5. 风险验证：迁移、个人记录 service、手动/扫荡/持久差遣生产路径 targeted 全绿；`flutter analyze --no-pub lib test tool`、`dart format .`、锁保护全量和最终 Gate 完成。
6. 红线说明：不改 YAML、奖励金额/概率、经济、解锁、周目、战斗参数、角色属性或 `strings.dart`；真人桌面与 Windows 目检挂账。
7. 交付状态：最终 tip 使用 `[READY]`，receipt 绑定精确 tip，工作树 clean；M5 工程矩阵仅在四项证据齐全后由 `38/42` 更新为 `39/42`，顶层 M5 保持 `0/1 BLOCKED`。

## 任务切片

1. 先写迁移、个人记录与三入口共用结算的真实 RED。
2. 新增 `TowerPersonalRecord` collection/service，接入 Isar schema 与 0.44.0 加法迁移。
3. 在 `applyTowerVictorySettlement` 的 caller-owned transaction 中按 exact participant 写记录。
4. 补多角色隔离、零耗时、事务回滚、重放防重与三生产入口证据。
5. 完成双向 mutation、targeted、analyze、format、锁保护全量、Gate、审计和 READY 冻结。

## 当前恢复点

- 状态：实现与扩展定向已完成，等待锁保护全量、提交与最终 Gate。
- 最后完成：0.44 collection/service/共享事务接线、授权登记、M5 `39/42` 审计；三向 mutation 已精确还原。
- 下一步：测试契约删除核对、提交、锁保护全量、READY tip、receipt 与最终 Gate。
- 已跑验证：初始 RED 有效；mutation `4 + 2 + 1`；扩展定向 `164/164 PASS`；analyze 0 issue；整仓 format `1704 files / 0 changed`。
- 阻塞项：无。用户已明确授权新增 collection 与 `saveVersion 0.44.0`；前一单 `strings.dart` 一次性豁免不适用于本任务。
