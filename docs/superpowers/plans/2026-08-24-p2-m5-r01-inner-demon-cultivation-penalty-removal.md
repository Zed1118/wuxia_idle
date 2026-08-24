# P2 M5 R01：心魔主修修炼度惩罚移除

## 合同

- 外部设计复核：Pi，精确模型 `deepseek/deepseek-v4-flash`，`high`。
- 写入者：受控 Codex 子 agent；Pi 只读复核，不直接改仓库。
- 仅修改任务登记列出的 R01 文件。
- 旧 `failure_penalty` 配置必须被拒绝，而不是继续兼容为 1.0。
- 心魔失败后主修修炼度必须保持原值；唯一保留的失败惩罚为受上限约束的内息紊乱，正常战斗计数等通用结算不受影响。

## 验证清单

- [x] 外部设计复核有命令、版本、精确模型和结论证据。
- [x] 配置键和类型入口已退役；任意 `failure_penalty`（含空 map/null）显式拒绝。
- [x] 领域/应用/战斗结算测试覆盖恒等修炼度、紊乱上限、无伤势及正常战斗计数。
- [x] 11 个定向文件 106/106 通过。
- [x] scoped analyze 10 items 为零。
- [x] Pi 对 R01 owned scope 最终 P0/P1/P2=0/0/0。

## Pi 只读复核证据

- CLI：Pi `0.84.1`；精确 selector：`deepseek/deepseek-v4-flash`，thinking `high`。
- 权限：`--no-session --no-skills --tools read,grep,find,ls --print`，无写入工具。
- 设计复核约 205 秒正常退出并给出 `DESIGN PASS`：要求 production numbers、typed schema、service 和 combat resolution 原子迁移，R02 独占 UI 陈述对齐。
- actual diff 终审约 142 秒：R01 owned code/schema/call-chain/tests 的 P0/P1/P2=0/0/0；另将当时尚未合入的 R02 旧摘要列为 batch 外部 P2=1。该项已由 R02 READY `50ae2d5c` 关闭，不越界算作 R01 缺陷。

## CLAUDE §8.2 交付证据

- 生产入口：`CombatResolutionService.resolveSnapshot` 心魔失败分支 → `InnerDemonService.applyFailurePenalty` → `InnerBreathDisorder.apply`；唯一 cultivation 写回已删除，通用结算与持久化事务保持。
- Targeted：owned 与影响回归共 11 files、106/106；scoped analyze 10 items 为零；format 10 files 零改动，diff check 通过。
- 红线：不改伤害/血量/内力上限、三系、在线离线、反主流项或玩家文案；只删除已冻结退役的 10% 失败惩罚，并对死配置 fail-closed。
- 残留风险：无存档 schema/saveVersion 变化；source 未跑 full，留给 Batch 集成；AI、tuning、host、durable 与历史审计不在本任务范围。

## 当前恢复点（CLAUDE §8.0）

- 状态：source READY 已由主控以稳定提交身份集成。
- 最后完成：source READY `83755eb5`；实现提交 `80f9a7b8`；主控集成提交 `c66e983b`。
- 下一步：Batch 联合定向、全量、独立审查与文档收口。
- 已跑验证：source 106/106，scoped analyze 0，Pi owned scope 0/0/0，worktree clean。
- 阻塞项：无；Pi 报告的 batch 外部 UI P2 已由 R02 关闭。
