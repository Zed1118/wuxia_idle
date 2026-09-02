# P2 M7 第四章内容迁移计划

## 结果合同

- 单一结果：复用已集成的西凉生态、普通关/小 Boss/章末 Boss 模板与既有目标原语，把 `stage_04_02..05` 接入真实 typed catalog、runtime binding 和 production encounter factory。
- 固定分母：第四章 `1/5 → 5/5`；全主线 typed production catalog `19/105 → 23/105`。塔保持 `0/49`，legacy runtime retirement 仍开放。
- 实时基线：`main == origin/main == 9efcdeb6f7147070be891b2c2e08138651267317` 且主 checkout clean；第三章 exact-SHA CI run `33630424378` 为 `completed/success`。
- 关键阻塞：`stage_04_02..05` 的 `StageDef` 完整，但 assignment、encounter、runtime binding 均为 `0/4`；生产 factory 返回 null 后落回 legacy `Phase0aStageContentMapper.mapMainline`。
- 预期变化：只增加四条真实生产迁移路由；正式 M7 仍开放，Phase 2 仍为 `1/10`。
- 成本边界：单一第四章数据切片；约 90 分钟无生产门变化则停止扩面并重评。

## 非目标与保护边界

- 不重做 P0，不处理 `stage_02_05` 高基础随从风险，不启动 M8/M9。
- 不改 `stages.yaml`、`numbers.yaml`、敌人/玩家数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不增加玩法规则、TUNING 数值或第二套 runtime。
- 真人桌面、普通存档平衡、视觉、音频、手感和 Windows 全部继续 `DEFERRED`；自动化不得代签。

## CLAUDE.md §8.2 验收清单

1. 第四章五关各有唯一 migrated assignment、encounter 与 runtime binding，且基敌严格等于各自 `StageDef.enemyTeam.single`。
2. 真实 production repository、factory、runtime adapter、enemy AI、director、objective 与 reducer 完整消费。
3. 初始 RED；真实动态 headless 战斗覆盖敌人生成、目标、Boss 身份、终局和超时。
4. 至少两向有效 mutation 精确证红并用反向补丁还原。
5. targeted、相邻回归、`flutter analyze --no-pub lib test tool`、`dart format .`、持锁全量和标准 Gate 通过。
6. 更新 `PROGRESS.md`、task registry、本计划和审计；最终 `[READY]` 中文动宾提交且 worktree clean。

## 当前恢复点

- 分支：`codex/p2-m7-ch4-content-migration-20260902`。
- worktree：`/Users/a10506/.codex/worktrees/p2-m7-ch4-content-migration-20260902`。
- 状态：第四章 `stage_04_01..05` 已由用户授权快进进入 `main/origin`；全主线集成分子为 `23/105`。正式 M7 与 Phase 2 仍分别开放、`1/10`。
- 实现提交：`218d902d` 接入四条生产路由；`55a87d30` 把第三章全局写死水位改为保留 `19` 条下限，第四章合同独立精确守住 `23`；`7cded518` 冻结精确 Gate tip。
- 验证：有效初始 RED `0/6`；两向 mutation 分别精确 `1` / `2` 条失败，并以反向补丁和 SHA-256 还原；定向 `6/6`、主线应用 `183/183`、Phase 2 相邻 `84/84`、analyze 0 issue、整仓 format `1718` files/0 changed、持锁全量 `5893/5893` 且 `[E]` 0。
- 标准 Gate：精确范围 `9efcdeb6..7cded518` 在独立 detached worktree 复跑 full `5893/5893`、analyze 0 issue、format `1718` files/0 changed；原始 Gate 唯一失败项为已登记的 `test_deletions=1`。专用迁移校验输出 `[migration] expect 删 1 / 增 38;用例 删 0 / 增 6;登记 1 条` 与 `PASS: test_contract_migration`，因此按唯一例外口径 Gate 通过。
- 远端闭环：最终 `[READY]` tip 与 `main == origin/main == 04276bdcebc33d123a3baafdd3cdbd5a7da81a17`；exact-SHA CI run `33636410141` 为 `completed/success`，`macos-build`、格式、analyze、coverage tests、coverage ratchet 与 artifact upload 均成功。
- 阻塞项：真人桌面、普通存档平衡/手感、视觉、音频与 Windows 继续挂账；`stage_02_05` 高基础随从风险未处理。
