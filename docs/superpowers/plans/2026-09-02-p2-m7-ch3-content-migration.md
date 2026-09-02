# P2 M7 第三章内容迁移计划

## 结果合同

- 单一结果：复用已集成的门派、寺院、山匪生态与普通/斩将目标原语，把 `stage_03_01..05` 接入真实 typed catalog、runtime binding 和 production encounter factory。
- 固定分母：第三章 `0/5 → 5/5`；全主线 typed production catalog `14/105 → 19/105`。塔保持 `0/49`，legacy runtime retirement 仍开放。
- 实时基线：`main == origin/main == 52a4255fd74d1c7d86f43f846a536e52cfdec1b6`，exact-SHA CI run `33578580680` 为 `completed/success`。
- 关键阻塞：第三章五关现有 `StageDef` 完整，但 assignment、encounter、runtime binding 均为 `0/5`；生产 factory 返回 null 后落回 legacy `Phase0aStageContentMapper.mapMainline`。
- 预期变化：只增加五条真实生产迁移路由；正式 M7 仍开放，Phase 2 仍为 `1/10`。
- 成本边界：单一第三章数据切片；约 90 分钟无生产门变化则停止扩面并重评。

## 非目标与保护边界

- 不重做 P0，不处理 `stage_02_05` 高基础随从风险，不启动 M8/M9。
- 不改 `stages.yaml`、`numbers.yaml`、敌人/玩家数值、Boss 招式、掉落、奖励、经济、叙事、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不增加玩法规则、TUNING 数值或第二套 runtime。
- 真人桌面、视觉、音频、手感和 Windows 全部继续 `DEFERRED`；自动化不得代签。

## CLAUDE.md §8.2 验收清单

1. 五关各有唯一 migrated assignment、encounter 与 runtime binding，且基敌严格等于各自 `StageDef.enemyTeam.single`。
2. 真实 production repository、factory、runtime adapter、enemy AI、director、objective 与 reducer 完整消费。
3. 初始 RED；真实动态 headless 战斗覆盖敌人生成、目标、Boss 身份、终局和超时。
4. 至少两向有效 mutation 精确证红并用反向补丁还原。
5. targeted、相邻回归、`flutter analyze --no-pub lib test tool`、`dart format .`、持锁全量和标准 Gate 通过。
6. 更新 `PROGRESS.md`、task registry、本计划和审计；最终 `[READY]` 中文动宾提交且 worktree clean。

## 当前恢复点

- 分支：`codex/p2-m7-ch3-content-migration-20260902`。
- worktree：`/Users/a10506/.codex/worktrees/p2-m7-ch3-content-migration-20260902`。
- 状态：第三章 `5/5` 生产迁移已形成独立工程候选，全主线候选分子 `14/105 → 19/105`；正式 M7 与 Phase 2 仍分别开放、`1/10`。
- 下一步：冻结 `[READY]` tip，等待用户另行授权后才可评审、merge 或 push；M8/M9 不启动。
- 已跑验证：初始 RED `6`；两向 mutation 分别精确 `1` / `2` 条失败并以反向补丁和 SHA-256 还原；定向 `6/6`、Phase 2 相邻 `78/78`、主线应用 `183/183`、analyze 0 issue、整仓 format `1717` files/0 changed、持锁全量 `5887/5887` 且 `[E]` 0、锁已释放。
- 标准 Gate：对精确六文件实现范围 `52a4255f..f979e82a` 在独立 detached worktree 全量复跑 `5887/5887`，analyze 0 issue、format `1717` files/0 changed、receipt matched，最终 `PASS`。用户明确要求的 `PROGRESS.md` / registry / P0 远端事实属于随后治理尾提交；因 Gate 内建 `forbidden_files` 规则排除 `PROGRESS.md`，不伪称这部分在自动 Gate 范围内。
- 阻塞项：本候选尚未进入 main/origin，也没有本候选 CI；真人桌面、平衡/手感、视觉、音频与 Windows 继续挂账；`stage_02_05` 高基础随从风险未处理。
